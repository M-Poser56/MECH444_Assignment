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

Box(100) = {xmin, ymin, zmin, xmax-xmin, ymax-ymin, zmax-zmin}; //create computational box
fluid() = BooleanDifference{ Volume{100}; Delete; }{ Volume{body()}; Delete; }; //create mesh around the outline of the .step file


//??????
e = 1e-3;
inlet()  = Surface In BoundingBox{xmin-e, ymin-e, zmin-e, xmin+e, ymax+e, zmax+e};
outlet() = Surface In BoundingBox{xmax-e, ymin-e, zmin-e, xmax+e, ymax+e, zmax+e};
bottom() = Surface In BoundingBox{xmin-e, ymin-e, zmin-e, xmax+e, ymin+e, zmax+e};
top()    = Surface In BoundingBox{xmin-e, ymax-e, zmin-e, xmax+e, ymax+e, zmax+e};
side1()  = Surface In BoundingBox{xmin-e, ymin-e, zmin-e, xmax+e, ymax+e, zmin+e};
side2()  = Surface In BoundingBox{xmin-e, ymin-e, zmax-e, xmax+e, ymax+e, zmax+e};

bodyS() = Abs(Boundary{ Volume{fluid()}; });
bodyS() -= {inlet(), outlet(), top(), bottom(), side1(), side2()};




//??????????
Mesh.MeshSizeMax = 0.5*L;
Mesh.MeshSizeFromCurvature = 30;      // lower than 81: 3D cell count explodes
Mesh.MeshSizeExtendFromBoundary = 0;
Mesh.MeshSizeFromPoints = 0;

Field[1] = Distance;
Field[1].SurfacesList = {bodyS()};    // "FacesList" in older Gmsh
Field[1].Sampling = 100;

Field[2] = Threshold;                 // fine near body, coarse far away
Field[2].InField = 1;
Field[2].SizeMin = 0.35*L; //alter size to reduce cells
Field[2].SizeMax = 0.5*L;
Field[2].DistMin = 0.02*L;
Field[2].DistMax = 1.0*L;

Field[3] = Box;                       // wake refinement, now with Z limits
Field[3].VIn = 0.35*L;  Field[3].VOut = 0.5*L; //alter size to reduce cells
Field[3].XMin = -1*L;   Field[3].XMax = 5*L;
Field[3].YMin = -1*L;   Field[3].YMax = 1*L;
Field[3].ZMin = -1*L;   Field[3].ZMax = 1*L;
Field[3].Thickness = 2*L;

Field[4] = Min;
Field[4].FieldsList = {2, 3};
Background Field = 4;




//???????????
Physical Volume("fluid")  = {fluid()};
Physical Surface("inlet") = {inlet()};
Physical Surface("outlet")= {outlet()};
Physical Surface("top")   = {top()};
Physical Surface("bottom")= {bottom()};
Physical Surface("sides") = {side1(), side2()};
Physical Surface("body")  = {bodyS()};

Mesh.Algorithm   = 11;    // see week 4 intro to meshing slides
Mesh.Algorithm3D = 10;   // HXT (fast, parallel); 1 = Delaunay if it complains
Mesh.Optimize = 1;
Mesh.OptimizeNetgen = 1;
Mesh.MshFileVersion = 2.2;   // safest format for gmshToFoam






