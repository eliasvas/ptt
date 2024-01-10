#import "Basic";
#import "Input";
#import "System";
#import "Math";
//TODO: I should make my own vector/matrix types.. no?
//why THE FUCK are jai matrices ROW FUCKING MAJOR??????
//For some reason Jai's default module has weird coordinate system, this is a try to fix it.
//We use a _right_ handed negative z-axis forward coordinate system, much like OpenGL does, 
//we can convert for other graphics APIs on the fly

offset_of :: ($T: Type, ident: Code) -> s64 #expand {
    t: T;
    return cast(*void) (*t.#insert ident) - cast(*void) *t;
}

make_translation_matrix :: (pos : Vector3) -> Matrix4 {
    mat := Matrix4_Identity;
    mat.coef[0][3] = pos.x;
    mat.coef[1][3] = pos.y;
    mat.coef[2][3] = pos.z;
    return mat;
}


make_proj_matrix :: (fov : float, aspect : float, near : float, far : float) -> Matrix4 {
    mat := Matrix4_Identity;

    return mat;
}
make_ortho_matrix :: (l : float, r : float, b : float, t : float, n : float, f : float) -> Matrix4 {
    mat := Matrix4_Identity;
    mat.coef[0][0] = 1.0 / r;
    mat.coef[1][1] = 1.0 / t;
    mat.coef[2][2] = -2.0 / (f-n);
    mat.coef[3][2] = -(f+n) / (f-n);
    mat.coef[3][3] = 1.0;

    return mat;
}