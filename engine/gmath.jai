#import "Basic";
#import "Input";
#import "System";
#import "Math";
//For some reason Jai's default module has weird coordinate system, this is a try to fix it.
//only column-major matrices are supported, likely in whichever API row-major matrices are needed, we need only transpose.

//I have been confused about 3D math for a while, finally i think
//im getting the hang of it, some resources i found helpful:
//https://immersivemath.com/ila/index.html
//https://zhangdoa.com/row-major-or-column-major-some-notes-about-matrix-convention
//https://github.com/HandmadeMath/HandmadeMath/issues/124

//converts degrees to radians
d2r :: (deg : float) -> float {return deg * (PI / 180.0);}
//float equals
feq :: (a : float, b : float, error : float = 0.0001) -> bool {return abs(a - b) < error;}
offset_of :: ($T: Type, ident: Code) -> s64 #expand {
  t: T;
  return cast(*void) (*t.#insert ident) - cast(*void) *t;
}

gVec2:: struct {
  x,y : float;
  #place x; r,g : float;
  #place x; arr : [2]float;
}
operator [] :: (v: gVec2, i : int) -> float {return v.arr[i];}
operator []= :: (v: *gVec2, i : int, item: float) {v.arr[i] = item;}
operator *[] :: (v: *gVec2, i : int) -> *gVec2 {return *v.arr[i];}
operator *= :: (v: *gVec2, scalar : float) {v.x *= scalar;v.y*=scalar;}
operator + :: (v: gVec2, scalar : float) -> gVec2 {return .{v.x+scalar,v.y+scalar};}
operator - :: (v: gVec2, scalar : float) -> gVec2 {return .{v.x-scalar,v.y-scalar};}
operator * :: (v: gVec2, scalar : float) -> gVec2 {return .{v.x*scalar,v.y*scalar};}
operator / :: (v: gVec2, scalar : float) -> gVec2 {return .{v.x/scalar,v.y/scalar};}
operator + :: (a: gVec2, b : gVec2) -> gVec2 {return .{a.x+b.x,a.y+b.y};}
operator - :: (a: gVec2, b : gVec2) -> gVec2 {return .{a.x-b.x,a.y-b.y};}
operator * :: (a: gVec2, b : gVec2) -> gVec2 {return .{a.x*b.x,a.y*b.y};}
operator / :: (a: gVec2, b : gVec2) -> gVec2 {return .{a.x/b.x,a.y/b.y};}
gvec2_dot :: (a : gVec2, b : gVec2) -> float {return a.x*b.x+a.y*b.y;}
gvec2_len :: (v : gVec2) -> float { return sqrt(gvec2_dot(v,v));}
gvec2_norm :: (v : gVec2) -> gVec2 {return v*(1.0/gvec2_len(v));}

gVec3:: struct {
  x,y,z : float;
  #place x; r,g,b : float;
  #place x; arr : [3]float;
}
operator [] :: (v: gVec3, i : int) -> float {return v.arr[i];}
operator []= :: (v: *gVec3, i : int, item: float) {v.arr[i] = item;}
operator *[] :: (v: *gVec3, i : int) -> *gVec3 {return *v.arr[i];}
operator *= :: (v: *gVec3, scalar : float) {v.x *= scalar;v.y*=scalar;v.z*=scalar;}
operator + :: (v: gVec3, scalar : float) -> gVec3 {return .{v.x+scalar,v.y+scalar,v.z+scalar};}
operator - :: (v: gVec3, scalar : float) -> gVec3 {return .{v.x-scalar,v.y-scalar,v.z-scalar};}
operator * :: (v: gVec3, scalar : float) -> gVec3 {return .{v.x*scalar,v.y*scalar,v.z*scalar};}
operator / :: (v: gVec3, scalar : float) -> gVec3 {return .{v.x/scalar,v.y/scalar,v.z/scalar};}
operator + :: (a: gVec3, b : gVec3) -> gVec3 {return .{a.x+b.x,a.y+b.y,a.z+b.z};}
operator - :: (a: gVec3, b : gVec3) -> gVec3 {return .{a.x-b.x,a.y-b.y,a.z-b.z};}
operator * :: (a: gVec3, b : gVec3) -> gVec3 {return .{a.x*b.x,a.y*b.y,a.z*b.z};}
operator / :: (a: gVec3, b : gVec3) -> gVec3 {return .{a.x/b.x,a.y/b.y,a.z/b.z};}
gvec3_dot :: (a : gVec3, b : gVec3) -> float {return a.x*b.x+a.y*b.y+a.z*b.z;}
gvec3_len :: (v : gVec3) -> float { return sqrt(gvec3_dot(v,v));}
gvec3_norm :: (v : gVec3) -> gVec3 {return v*(1.0/gvec3_len(v));}
gvec3_cross :: (lhs : gVec3, rhs : gVec3) -> gVec3 {return gVec3.{lhs.y*rhs.z - lhs.z*rhs.y, lhs.z*rhs.x - lhs.x*rhs.z, lhs.x*rhs.y - lhs.y*rhs.x};}

gVec4:: struct {
  x,y,z,w : float;
  #place x; r,g,b,a : float;
  #place x; arr : [4]float;
}
operator [] :: (v: gVec4, i : int) -> float {return v.arr[i];}
operator []= :: (v: *gVec4, i : int, item: float) {v.arr[i] = item;}
operator *[] :: (v: *gVec4, i : int) -> *gVec4 {return *v.arr[i];}
operator *= :: (v: *gVec4, scalar : float) {v.x *= scalar;v.y*=scalar;v.z*=scalar;v.w*=scalar;}
operator + :: (v: gVec4, scalar : float) -> gVec4 {return .{v.x+scalar,v.y+scalar,v.z+scalar,v.w+scalar};}
operator - :: (v: gVec4, scalar : float) -> gVec4 {return .{v.x-scalar,v.y-scalar,v.z-scalar,v.w-scalar};}
operator * :: (v: gVec4, scalar : float) -> gVec4 {return .{v.x*scalar,v.y*scalar,v.z*scalar,v.w*scalar};}
operator / :: (v: gVec4, scalar : float) -> gVec4 {return .{v.x/scalar,v.y/scalar,v.z/scalar,v.w/scalar};}
operator + :: (a: gVec4, b : gVec4) -> gVec4 {return .{a.x+b.x,a.y+b.y,a.z+b.z,a.w+b.w};}
operator - :: (a: gVec4, b : gVec4) -> gVec4 {return .{a.x-b.x,a.y-b.y,a.z-b.z,a.w-b.w};}
operator * :: (a: gVec4, b : gVec4) -> gVec4 {return .{a.x*b.x,a.y*b.y,a.z*b.z,a.w*b.w};}
operator / :: (a: gVec4, b : gVec4) -> gVec4 {return .{a.x/b.x,a.y/b.y,a.z/b.z,a.w/b.w};}
gvec4_dot :: (a : gVec4, b : gVec4) -> float {return a.x*b.x+a.y*b.y+a.z*b.z+a.w*b.w;}
gvec4_len :: (v : gVec4) -> float { return sqrt(gvec4_dot(v,v));}
gvec4_norm :: (v : gVec4) -> gVec4 {return v*(1.0/gvec4_len(v));}

gMat4 :: struct {
  union {
    col : [4] gVec4;
    arr : [16] float;
  }
}
GM4_IDENTITY :: gMat4.{arr = .[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1]};

sample : gMat4;


make_translation_matrix :: (pos : gVec3) -> gMat4 {
  mat := GM4_IDENTITY;
  mat.col[3][0] = pos.x;
  mat.col[3][1] = pos.y;
  mat.col[3][2] = pos.z;
  return mat;
}


make_transpose_matrix :: (mat : gMat4) -> gMat4 {
  trans : gMat4 = ---;
  for i : 0..mat.col.count-1 {
    for it,idx : mat.col[i].arr {
      trans.col[idx][i] = it;
    } 
  }
  return trans;
}

//NOTE: (-) sign messes up formatting, maybe there is a standard fix?
//like, to have also a + sign for positive floats
print_mat :: (mat : gMat4) {
  //we get the row-major form to print the column matrix row-by-row
  mat_transp := make_transpose_matrix(mat); 
  print("--------\n");
  for i : 0..mat_transp.col.count-1 {
    print("|");
    for mat_transp.col[i].arr {
      print(" %",formatFloat(it, width=1, trailing_width=2, zero_removal=.NO));
    } 
    print("|\n");
  }
  print("--------\n");
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

make_ortho_frustum :: (l : float, r : float, b : float, t : float, n : float, f : float) -> gMat4 {
  mat := GM4_IDENTITY;
  mat.col[0][0]  = 2 / (r - l);
  mat.col[1][1]  = 2 / (t - b);
  mat.col[2][2] = -2 / (f - n);
  mat.col[3][0] = -(r + l) / (r - l);
  mat.col[3][1] = -(t + b) / (t - b);
  mat.col[3][2] = -(f + n) / (f - n);
  return mat;
}
make_perspective_frustum :: (l : float, r : float, b : float, t : float, n : float, f : float) -> gMat4 {
  mat : gMat4;
  mat.col[0][0]  = 2.0 * n / (r - l);
  mat.col[1][1]  = 2.0 * n / (t - b);
  mat.col[2][0] = (r + l) / (r - l);
  mat.col[2][1] = (t + b) / (t - b);
  mat.col[2][2] = -(f + n) / (f - n);
  mat.col[2][3] = -1.0;
  mat.col[3][2]  = -2.0 * n * f / (f - n);
  return mat;
}

make_perspective_matrix :: (fov : float, aspect : float, near : float, far : float) -> gMat4 {
  fov_rad := d2r(fov);
  fov_rad = 2.0 * atan(tan(fov * 0.5) / aspect); //transform to vertical fov
  tangent := tan(fov_rad / 2.0);
  height := near * tangent;
  width := height * aspect;
  return make_perspective_frustum(-width, width, -height, height, near, far);
}

make_lookat_matrix :: (F: gVec3, R : gVec3, U : gVec3, eye : gVec3) -> gMat4 {
  res : gMat4;

  res.col[0][0] = R.x;
  res.col[0][1] = U.x;
  res.col[0][2] = -F.x;
  res.col[0][3] = 0.0;

  res.col[1][0] = R.y;
  res.col[1][1] = U.y;
  res.col[1][2] = -F.y;
  res.col[1][3] = 0.0;

  res.col[2][0] = R.z;
  res.col[2][1] = U.z;
  res.col[2][2] = -F.z;
  res.col[2][3] = 0.0;

  res.col[3][0] = -gvec3_dot(R, eye);
  res.col[3][1] = -gvec3_dot(U, eye);
  res.col[3][2] = gvec3_dot(F, eye);
  res.col[3][3] = 1.0;

  return res;
}
make_lookat_matrix :: (eye: gVec3, center : gVec3, dummy_up : gVec3) -> gMat4 {
  mat := GM4_IDENTITY;

  F : gVec3 = gvec3_norm(center - eye);
  R : gVec3 = gvec3_norm(gvec3_cross(F, dummy_up));
  U : gVec3 = gvec3_norm(gvec3_cross(R, F));
  return make_lookat_matrix(F,R,U, eye);
}

gRect :: struct {
  x0,y0,w,h : float;
}

gmath_ut :: () {
  a2 : gVec2 = .{1.0,0.0};
  b2 : gVec2 = .{0.0,1.0};
  assert(feq(gvec2_dot(a2,b2),0.0));
  assert(feq(gvec2_len(a2),1.0));
  a2 *= 2;
  assert(feq(gvec2_len(a2),2.0));
  assert(feq(gvec2_len(gvec2_norm(a2)),1.0));

  a3 : gVec3 = .{1.0,0.0,0.0};
  b3 : gVec3 = .{0.0,1.0,0.0};
  assert(feq(gvec3_dot(a3,b3),0.0));
  assert(feq(gvec3_len(a3),1.0));
  a3 *= 3;
  assert(feq(gvec3_len(a3),3.0));
  assert(feq(gvec3_len(gvec3_norm(a3)),1.0));

  a4 : gVec4 = .{1.0,0.0,0.0,0.0};
  b4 : gVec4 = .{0.0,1.0,0.0,0.0};
  assert(feq(gvec4_dot(a4,b4),0.0));
  assert(feq(gvec4_len(a4),1.0));
  a4 *= 4;
  assert(feq(gvec4_len(a4),4.0));
  assert(feq(gvec4_len(gvec4_norm(a4)),1.0));
}
#run gmath_ut();

