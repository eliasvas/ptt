#import "Basic";
#import "Input";
#import "System";
#import "Math";
//For some reason Jai's default module has weird coordinate system, this is a try to fix it.

//We use a _right_ handed negative z-axis forward coordinate system, much like OpenGL does, along with _column_ major matrices, like in Direct3D.
//DEBATE: Should we use column or row major matrices in the future??

//This is a good writeup on the basics:
//https://www.scratchapixel.com/lessons/mathematics-physics-for-computer-graphics/geometry/points-vectors-and-normals.html

gVec2:: struct {
  x,y : float;
  #place x; r,g : float;
  #place x; arr : [2] float;
}
operator [] :: (v: gVec2, i: int) -> float {return v.arr[i];}
operator []= :: (v: *gVec2, i: int, item: float) {v.arr[i] = item;}
operator *[] :: (v: *gVec2, i: int) -> *gVec2 {return *v.arr[i];}
operator *= :: (v: *gVec2, scalar: float) {for obj.arr obj.array[it] *= scalar;}
gVec3:: struct {
  x,y,z : float;
  #place x; r,g,b : float;
  #place x; arr : [3] float;
}
operator [] :: (v: gVec3, i: int) -> float {return v.arr[i];}
operator []= :: (v: *gVec3, i: int, item: float) {v.arr[i] = item;}
operator *[] :: (v: *gVec3, i: int) -> *gVec3 {return *v.arr[i];}
operator *= :: (v: *gVec3, scalar: float) {for obj.arr obj.array[it] *= scalar;}
gVec4:: struct {
  x,y,z,w : float;
  #place x; r,g,b,a : float;
  #place x; arr : [4] float;
}
operator [] :: (v: gVec4, i: int) -> float {return v.arr[i];}
operator []= :: (v: *gVec4, i: int, item: float) {v.arr[i] = item;}
operator *[] :: (v: *gVec4, i: int) -> *gVec4 {return *v.arr[i];}
operator *= :: (v: *gVec4, scalar: float) {for obj.arr obj.array[it] *= scalar;}


gMat4 :: struct {
  union {
    col : [4] gVec4;
    arr : [16] float;
  }
}
GM4_IDENTITY :: gMat4.{arr = .[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]};

sample : gMat4;

offset_of :: ($T: Type, ident: Code) -> s64 #expand {
    t: T;
    return cast(*void) (*t.#insert ident) - cast(*void) *t;
}

make_translation_matrix :: (pos : gVec3) -> gMat4 {
    mat := GM4_IDENTITY;
    mat.col[3][0] = pos.x;
    mat.col[3][1] = pos.y;
    mat.col[3][2] = pos.z;
    return mat;
}


//For more info on the matrices:
//https://www.scratchapixel.com/lessons/3d-basic-rendering/perspective-and-orthographic-projection-matrix/projection-matrix-introduction.html
make_proj_matrix :: (fov : float, aspect : float, near : float, far : float) -> gMat4 {
    mat := GM4_IDENTITY;

    return mat;
}
make_ortho_matrix :: (l : float, r : float, b : float, t : float, n : float, f : float) -> gMat4 {
    mat := GM4_IDENTITY;
    mat.col[0][0] = 1.0 / r;
    mat.col[1][1] = 1.0 / t;
    mat.col[2][2] = -2.0 / (f-n);
    mat.col[3][2] = -(f+n) / (f-n);
    mat.col[3][3] = 1.0;

    return mat;
}

//Implementation based on:
//https://www.scratchapixel.com/lessons/3d-basic-rendering/3d-viewing-pinhole-camera/implementing-virtual-pinhole-camera.html
//https://www.scratchapixel.com/lessons/mathematics-physics-for-computer-graphics/lookat-function/framing-lookat-function.html
//the matrix should [ r u f t] columns, we make the row version of it and then transpose!  
make_lookat_matrix :: (from : Vector3, to : Vector3, dummy_up : Vector3) -> Matrix4 {
    mat := Matrix4_Identity;

    fwd := from - to;
    normalize(*fwd); //TODO: look up the exact implementation of normalize
    right := cross(.{0,1,0}, fwd);
    normalize(*right);
    up := cross(fwd, right);
    normalize(*up);

    mat.v[0] = .{right.x,right.y,right.z,0};
    mat.v[1] = .{up.x,up.y,up.z,0};
    mat.v[2] = .{fwd.x,fwd.y,fwd.z,0};
    mat.v[3] = .{from.x,from.y,from.z,1};

    //transpose if it was row major
    //mat = transpose(mat);

    return mat;
}