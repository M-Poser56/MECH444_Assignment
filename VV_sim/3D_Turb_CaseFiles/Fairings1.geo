SetFactory("OpenCASCADE");
Geometry.OCCTargetUnit = "M"; // Convert mm to m
body() = ShapeFromFile("FluidsProject.step");

L = 1.34;  //characteristic length, bumper width for 1.0 model

//basic x, y, and z computational limits. These we can increase/decrease based on computational mesh sensitivity analysis
xmin = -5*L; xmax = 15*L;
ymin = -5*L; ymax =  5*L;
zmin = -0.4*L; zmax =  5*L;

// Find the body's center from its bounding box
bb() = BoundingBox Volume{body(0)};
xc = (bb(0) + bb(3))/2;
yc = (bb(1) + bb(4))/2;
zc = (bb(2) + bb(5))/2;

// Rotate 180 degrees about a vertical (y) axis through that center
Rotate {{0, 0, 1}, {xc, yc, zc}, Pi} { Volume{body()}; }

// Move that center to the origin (kart fairings currently offset due to CAD issues)
Translate {-xc, -yc, -zc} { Volume{body()}; }


//define the box which surrounds our kart, and define the fluid as the body which is: box - kart
Box(100) = {xmin, ymin, zmin, xmax-xmin, ymax-ymin, zmax-zmin}; //create computational box
fluid() = BooleanDifference{ Volume{100}; Delete; }{ Volume{body()}; Delete; }; //create mesh around the outline of the .step file


//this starts to select our boundary condition faces. We have sides, top/bottom, front/back defined by 
//makking little bounding boxes around our x y and z limits, and setting all enclosed faces in those bounding boxes to 
//be faces/tags (referenced later and linked to open foam)
e = 1e-3;  //tolerance for selecting faces on each plane
inlet()  = Surface In BoundingBox{xmin-e, ymin-e, zmin-e, xmin+e, ymax+e, zmax+e};  // x = xmin
outlet() = Surface In BoundingBox{xmax-e, ymin-e, zmin-e, xmax+e, ymax+e, zmax+e};  // x = xmax
side1()  = Surface In BoundingBox{xmin-e, ymin-e, zmin-e, xmax+e, ymin+e, zmax+e};  // y = ymin
side2()  = Surface In BoundingBox{xmin-e, ymax-e, zmin-e, xmax+e, ymax+e, zmax+e};  // y = ymax
bottom() = Surface In BoundingBox{xmin-e, ymin-e, zmin-e, xmax+e, ymax+e, zmin+e};  // z = zmin (ground)
top()    = Surface In BoundingBox{xmin-e, ymin-e, zmax-e, xmax+e, ymax+e, zmax+e};  // z = zmax

//all remaining faces in the fluid volume, which are not the ones subtracted (second line below), are assigned as our kart's 'body'
//these are all lumped together, will be added/treated and have the same wall function to treat the kart as a singular entity
bodyS() = Abs(Boundary{ Volume{fluid()}; });
bodyS() -= {inlet(), outlet(), top(), bottom(), side1(), side2()};




//basic global mesh size configurations, this determines the certain regions and cell size stepping based on distance from the kart
Mesh.MeshSizeMax = 0.2*L;
Mesh.MeshSizeFromCurvature = 30;      
Mesh.MeshSizeExtendFromBoundary = 0;
Mesh.MeshSizeFromPoints = 0;

Field[1] = Distance;
Field[1].SurfacesList = {bodyS()};    // "FacesList" in older Gmsh
Field[1].Sampling = 100;

Field[2] = Threshold;                 // fine near body, coarse far away
Field[2].InField = 1;
Field[2].SizeMin = 0.02*L; //alter size to reduce cells
Field[2].SizeMax = 0.2*L;
Field[2].DistMin = 0.02*L;
Field[2].DistMax = 1.5*L;

Field[3] = Box;                       // wake refinement, now with Z limits
Field[3].VIn = 0.08*L;  Field[3].VOut = 0.2*L; //alter size to reduce cells
Field[3].XMin = -1*L;   Field[3].XMax = 5*L;
Field[3].YMin = -1*L;   Field[3].YMax = 1*L;
Field[3].ZMin = -1*L;   Field[3].ZMax = 1*L;
Field[3].Thickness = 2*L;

//EDGE REFINEMENT (better resolves the flow at the bumper edges)
//The first sim's blow-up started at the sharp edges of the bumpers. The rear bumper is only 1 cm thick,
//but the cells around it were ~2.7 cm, so not even one cell fit across its edge. This is an ACCURACY
//improvement - the divergence itself was fixed by the k/epsilon values (tested on the old mesh).
//Fields 5 and 6 make the cells small right at the kart's edges (corners), then grow them back to the
//normal near-body size.

//collect every edge (curve) of the kart. Boundary{} of a surface returns the curves around it, with a
//+/- sign for direction. Abs() drops the sign since the Distance field just wants the curve numbers.
//NOTE: this grabs ALL kart edges, including CAD seams on smooth surfaces, not just the sharp bumper edges.
//If the cell count gets too high, replace bodyC() with just the bumper edge curve numbers (from gmsh GUI)
bodyC() = Abs(Boundary{ Surface{bodyS()}; });

Field[5] = Distance;                  // like Field[1], but distance to the kart EDGES instead of its surfaces
Field[5].CurvesList = {bodyC()};      // "EdgesList" in older Gmsh
Field[5].Sampling = 200;              // points per curve used to measure distance (1.3 m bumper edge -> 1 every 6.5 mm)

Field[6] = Threshold;                 // turns Field 5's distance into a cell size, same idea as Field[2]
Field[6].InField = 5;
Field[6].SizeMin = 0.003;             // 3 mm cells at the edges -> ~3 cells across the 1 cm bumper
Field[6].SizeMax = 0.02*L;            // grows back to the near-body size used in Field[2]
Field[6].DistMin = 0.005;             // within 5 mm of an edge, use SizeMin
Field[6].DistMax = 0.10;              // between 5 mm and 10 cm, size grows linearly (~25% per cell, smooth for tets)
Field[6].StopAtDistMax = 1;           // IMPORTANT: beyond DistMax this field stops setting a size. Without this,
                                      // Threshold applies SizeMax (2.7 cm) to the WHOLE domain = billions of cells

//Min takes the smallest cell size any field asks for, at each point in the domain.
//Field 6 wins near the edges, Fields 2 and 3 control everything else exactly as before.
Field[4] = Min;
Field[4].FieldsList = {2, 3, 6};      // was {2, 3}; added 6 for edge refinement
Background Field = 4;




//Physical boundary conditions - these will need to be set/worked with in openfoam, this is what is being referenced in the 0/p, 0/U files
Physical Volume("fluid")  = {fluid()};
Physical Surface("inlet") = {inlet()};
Physical Surface("outlet")= {outlet()};
Physical Surface("top")   = {top()};
Physical Surface("bottom")= {bottom()};
Physical Surface("sides") = {side1(), side2()};
Physical Surface("body")  = {bodyS()};


//our mesh algorithm and cell shaping, final generation steps for gmsh -3 to do its thang
Mesh.Algorithm   = 6;    // see week 4 intro to meshing slides
Mesh.Algorithm3D = 10;   //for the volume, while above step controls the meshing for faces
Mesh.Optimize = 1;
Mesh.OptimizeNetgen = 1;
Mesh.MshFileVersion = 2.2;   // safest format for gmshToFoam






