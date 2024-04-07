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

gmath_lin_comb :: (l : gVec4, r : gMat4) -> gVec4 {
  res : gVec4;

  res.x = l[0] * r.col[0].x;
  res.y = l[0] * r.col[0].y;
  res.z = l[0] * r.col[0].z;
  res.w = l[0] * r.col[0].w;

  res.x += l[1] * r.col[1].x;
  res.y += l[1] * r.col[1].y;
  res.z += l[1] * r.col[1].z;
  res.w += l[1] * r.col[1].w;

  res.x += l[2] * r.col[2].x;
  res.y += l[2] * r.col[2].y;
  res.z += l[2] * r.col[2].z;
  res.w += l[2] * r.col[2].w;

  res.x += l[3] * r.col[3].x;
  res.y += l[3] * r.col[3].y;
  res.z += l[3] * r.col[3].z;
  res.w += l[3] * r.col[3].w;

  return res;
}


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

make_perspective_matrix :: (fov : float, aspect : float, near : float, far : float) -> gMat4 {
  fov_rad := d2r(fov);
  res := GM4_IDENTITY;

  cot : float= 1.0 / tan(fov_rad / 2.0);
  res.col[0][0] = cot / aspect;
  res.col[1][1] = cot;
  res.col[2][3] = -1.0;

  res.col[2][2] = (near + far) / (near - far);
  res.col[3][2] = (2.0 * near * far) / (near - far);
  return res;
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

make_rotation_matrix :: (angle : float, axiss : gVec3) -> gMat4 {
  res := GM4_IDENTITY;

  axis := gvec3_norm(axiss);

  sin_theta : float = sin(angle);
  cos_theta : float = cos(angle);
  cos_val : float = 1.0 - cos_theta;

  res.col[0][0] = (axis.x * axis.z * cos_val) + cos_theta;
  res.col[0][1] = (axis.x * axis.y * cos_val) + (axis.z * sin_theta);
  res.col[0][2] = (axis.x * axis.z * cos_val) - (axis.y * sin_theta);

  res.col[1][0] = (axis.y * axis.x * cos_val) - (axis.z * sin_theta);
  res.col[1][1] = (axis.y * axis.y * cos_val) + cos_theta;
  res.col[1][2] = (axis.y * axis.z * cos_val) + (axis.x * sin_theta);

  res.col[2][0] = (axis.z * axis.x * cos_val) + (axis.y * sin_theta);
  res.col[2][1] = (axis.z * axis.y * cos_val) - (axis.x * sin_theta);
  res.col[2][2] = (axis.z * axis.z * cos_val) + cos_theta;

  return res;
}

gmat4_inv :: (mat : gMat4) -> gMat4 {
  c01 : gVec3 = gvec3_cross(.{mat.col[0][0], mat.col[0][1],mat.col[0][2]}, .{mat.col[1][0], mat.col[1][1],mat.col[1][2]});
  c23 : gVec3 = gvec3_cross(.{mat.col[2][0], mat.col[2][1],mat.col[2][2]}, .{mat.col[3][0], mat.col[3][1],mat.col[3][2]});
  b10 : gVec3 = gVec3.{mat.col[0].x,mat.col[0].y, mat.col[0].z} * mat.col[1].w - gVec3.{mat.col[1].x,mat.col[1].y, mat.col[1].z} * mat.col[0].w;
  b32 : gVec3 = gVec3.{mat.col[2].x,mat.col[2].y, mat.col[2].z} * mat.col[3].w - gVec3.{mat.col[3].x,mat.col[3].y, mat.col[3].z} * mat.col[2].w;

  invDet : float = 1.0 / (gvec3_dot(c01, b32)+gvec3_dot(c23,b10));
  c01 *= invDet;
  c23 *= invDet;
  b10 *= invDet;
  b32 *= invDet;

  result : gMat4;
  comp : gVec3 = gvec3_cross(.{mat.col[1].x,mat.col[1].y, mat.col[1].z}, b32) + c23 * mat.col[1].w;
  result.col[0] = gVec4.{comp.x, comp.y,comp.z, -gvec3_dot(.{mat.col[1].x,mat.col[1].y, mat.col[1].z}, c23)};
  comp = gvec3_cross(b32, .{mat.col[0].x,mat.col[0].y, mat.col[0].z}) - c23 * mat.col[0].w;
  result.col[1] = gVec4.{comp.x, comp.y,comp.z, +gvec3_dot(.{mat.col[0].x,mat.col[0].y, mat.col[0].z}, c23)};
  comp = gvec3_cross(.{mat.col[3].x,mat.col[3].y, mat.col[3].z}, b10) + c01 * mat.col[3].w;
  result.col[2] = gVec4.{comp.x, comp.y,comp.z, -gvec3_dot(.{mat.col[3].x,mat.col[3].y, mat.col[3].z}, c01)};
  comp = gvec3_cross(b10, .{mat.col[2].x,mat.col[2].y, mat.col[2].z}) - c01 * mat.col[2].w;
  result.col[3] = gVec4.{comp.x, comp.y,comp.z, +gvec3_dot(.{mat.col[2].x,mat.col[2].y, mat.col[2].z}, c01)};
  return make_transpose_matrix(result);
}

gmat4_mul :: (l : gMat4, r : gMat4) ->gMat4 {
  res : gMat4;
  res.col[0] = gmath_lin_comb(r.col[0],l);
  res.col[1] = gmath_lin_comb(r.col[1],l);
  res.col[2] = gmath_lin_comb(r.col[2],l);
  res.col[3] = gmath_lin_comb(r.col[3],l);
  return res;
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

