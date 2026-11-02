SetFactory("OpenCASCADE");
Geometry.OCCTargetUnit = "M"; // Convert mm to m
body() = ShapeFromFile("FluidsProject_5.step");

L = 1.34;  //characteristic length, bumper width for 1.0 fairings model

//basic x, y, and z computational limits. These we can increase/decrease based on computational mesh sensitivity analysis
//these limit values are the computational domain values used in the mesh sensitivity analysis
//when meshed, cell amount should match table 4 in the V&V document. Current configuration is (1), very coarse
xmin = -2.5*L; xmax = 3.5*L;
ymin = -2*L; ymax =  2*L;
zmin = -0.4*L; zmax =  1.75*L;

// Find the body's center from its bounding box
bb() = BoundingBox Volume{body(0)};
xc = (bb(0) + bb(3))/2;
yc = (bb(1) + bb(4))/2;
zc = (bb(2) + bb(5))/2;

//Rotate 180 degrees about z axis (STEP file comes in backwards if left alone)
Rotate {{0, 0, 1}, {xc, yc, zc}, Pi} { Volume{body()}; }

// Move that center to the origin (kart fairings offset if left alone due to CAD issues)
Translate {-xc, -yc, -zc} { Volume{body()}; }


//define the box which surrounds our kart, and define the fluid as the body which is: box - kart
Box(100) = {xmin, ymin, zmin, xmax-xmin, ymax-ymin, zmax-zmin}; //create computational box
fluid() = BooleanDifference{ Volume{100}; Delete; }{ Volume{body()}; Delete; }; //create mesh around the outline of the .step file


//this starts to select our boundary condition faces. We have sides, top/bottom, front/back defined by 
//makking little bounding boxes around our x y and z limits, and setting all enclosed faces in those bounding boxes to 
//be faces/tags (referenced later and linked to open foam)
e = 1e-3;  //tolerance for selecting faces on each plane
inlet()  = Surface In BoundingBox{xmin-e, ymin-e, zmin-e, xmin+e, ymax+e, zmax+e};  //x = xmin
outlet() = Surface In BoundingBox{xmax-e, ymin-e, zmin-e, xmax+e, ymax+e, zmax+e};  //x = xmax
side1()  = Surface In BoundingBox{xmin-e, ymin-e, zmin-e, xmax+e, ymin+e, zmax+e};  //y = ymin
side2()  = Surface In BoundingBox{xmin-e, ymax-e, zmin-e, xmax+e, ymax+e, zmax+e};  //y = ymax
bottom() = Surface In BoundingBox{xmin-e, ymin-e, zmin-e, xmax+e, ymax+e, zmin+e};  //z = zmin (ground)
top()    = Surface In BoundingBox{xmin-e, ymin-e, zmax-e, xmax+e, ymax+e, zmax+e};  //z = zmax

//all remaining faces in the fluid volume, which are not the ones subtracted (second line below), are assigned as our kart's 'body'
//these are all lumped together, will be added/treated and have the same wall function to treat the kart as a singular entity
bodyS() = Abs(Boundary{ Volume{fluid()}; });
bodyS() -= {inlet(), outlet(), top(), bottom(), side1(), side2()};




//basic global mesh size configurations, this determines the certain regions and cell size stepping based on distance from the kart
Mesh.MeshSizeMax = 0.6*L;             //global ceiling, no cell can be larger than this
Mesh.MeshSizeFromCurvature = 30;      
Mesh.MeshSizeExtendFromBoundary = 0;
Mesh.MeshSizeFromPoints = 0;

Field[1] = Distance;
Field[1].SurfacesList = {bodyS()};
Field[1].Sampling = 100;

Field[2] = Threshold;
Field[2].InField = 1;
Field[2].SizeMin = 0.03*L; //alter size to reduce cells
Field[2].SizeMax = 0.6*L;
Field[2].DistMin = 0.02*L;
Field[2].DistMax = 4*L;

Field[3] = Box;
Field[3].VIn = 0.2*L;  Field[3].VOut = 0.6*L; //alter size to reduce cells
Field[3].XMin = -1*L;   Field[3].XMax = 5*L;
Field[3].YMin = -1*L;   Field[3].YMax = 1*L;
Field[3].ZMin = -1*L;   Field[3].ZMax = 1*L;
Field[3].Thickness = 2*L;



//the below additions helped with the divergent solution issue, handles the cells near to the thin kart fairing edges
bodyC() = Abs(Boundary{ Surface{bodyS()}; });

Field[5] = Distance;
Field[5].CurvesList = {bodyC()};
Field[5].Sampling = 200;

Field[6] = Threshold;
Field[6].InField = 5;
Field[6].SizeMin = 0.015;
Field[6].SizeMax = 0.03*L;
Field[6].DistMin = 0.005;
Field[6].DistMax = 0.10;
Field[6].StopAtDistMax = 1;

Field[4] = Min;
Field[4].FieldsList = {2, 3, 6};
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
Mesh.Algorithm   = 6;    //see week 4 intro to meshing slides
Mesh.Algorithm3D = 10;   //for the volume, while above step controls the meshing for faces
Mesh.Optimize = 1;
Mesh.OptimizeNetgen = 1;
Mesh.MshFileVersion = 2.2;






