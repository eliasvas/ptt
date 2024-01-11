#import "Basic";
#import "Input";
#import "System";
#import "Math";
//For some reason Jai's default module has weird coordinate system, this is a try to fix it.

//This is a good writeup on the basics of OpenGL-style math:
//https://www.songho.ca/opengl/index.html
//also https://learnopengl.com/ is GOAT

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
operator - :: (a: gVec3, b : gVec3) -> gVec3 {return .{a.x - b.x, a.y - b.y, a.z - b.z};}
normalize_gvec3 :: (v : gVec3) -> gVec3 {
  ret : gVec3 = v;
  inv_len := 1.0 / sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
  ret.x *= inv_len;
  ret.y *= inv_len;
  ret.z *= inv_len;
  return ret;
}
cross_gvec3 :: (lhs : gVec3, rhs : gVec3) -> gVec3 {return gVec3.{lhs.y*rhs.z - lhs.z*rhs.y, lhs.z*rhs.x - lhs.x*rhs.z, lhs.x*rhs.y - lhs.y*rhs.x};}
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


make_scale_matrix :: (axis : gVec3, angle : float) ->gMat4 {
  mat := GM4_IDENTITY;
  //TBD
  return mat;
}

make_scale_matrix :: (scale : gVec3) -> gMat4 {
  mat := GM4_IDENTITY;
  mat.col[0][0] = scale.x;
  mat.col[1][1] = scale.y;
  mat.col[2][2] = scale.z;
  return mat;
}
make_proj_matrix :: (fov : float, aspect : float, near : float, far : float) -> gMat4 {
  mat := GM4_IDENTITY;
  //TBD
  return mat;
}
//TODO: make these column-based indices so I know whats up
make_ortho_matrix :: (l : float, r : float, b : float, t : float, n : float, f : float) -> gMat4 {
  mat := GM4_IDENTITY;
  mat.arr[0]  = 2 / (r - l);
  mat.arr[5]  = 2 / (t - b);
  mat.arr[10] = -2 / (f - n);
  mat.arr[12] = -(r + l) / (r - l);
  mat.arr[13] = -(t + b) / (t - b);
  mat.arr[14] = -(f + n) / (f - n);
  return mat;
}

make_lookat_matrix :: (from : gVec3, to : gVec3, dummy_up : gVec3) -> gMat4 {
  mat := GM4_IDENTITY;

  fwd := from - to;
  fwd = normalize_gvec3(fwd);
  right := cross_gvec3(dummy_up,fwd);
  right = normalize_gvec3(xx right);
  up := cross_gvec3(fwd,right);
  up = normalize_gvec3(up);

  mat.col[0] = .{right.x,right.y,right.z,0};
  mat.col[1] = .{up.x,up.y,up.z,0};
  mat.col[2] = .{fwd.x,fwd.y,fwd.z,0};
  mat.col[3] = .{-from.x,-from.y,-from.z,1};

  return mat;
}