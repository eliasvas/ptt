#import "Basic";
#import "Input";
#import "System";
#import "Math";
//For some reason Jai's default module has weird coordinate system, this is a try to fix it.

//This is a good writeup on the basics of 3D math:
//https://www.scratchapixel.com/lessons/3d-basic-rendering/perspective-and-orthographic-projection-matrix/projection-matrix-introduction.html
//Also Eric Lengyel's books kick ass.

//converts degrees to radians
d2r :: (deg : float) -> float {return deg * (PI / 180.0);}

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
//TODO: make these column-based indices so I know whats up
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