#import "Basic";
#import "Input";
#import "System";

GCAM_MODE :: enum {
    FREE; //looks for input from mouse/keeb/gamepad and self-moves
    FIXED; //stays fixed in place until changed
}

gCam :: struct {
    pos : gVec3;
    front : gVec3;
    up : gVec3;
    mode : GCAM_MODE = .FREE;
    speed : float = 5.0;
}

gcam_init :: (cam : *gCam, initial_pos : gVec3 = .{0,0,0}) {
    cam.pos = initial_pos;
    cam.front = .{0,0,-1};
    cam.up = .{0,1,0};
}

gcam_update :: (cam :*gCam, dt : float = 1.0 / 60.0) {
    if gkey_down(xx gInputMouseKey.LMB) {
        cam.pos.z -= cam.speed * dt;
    }
}

gcam_make_lookat_matrix :: (cam : *gCam) -> gMat4 {
    return make_lookat_matrix(cam.pos, cam.pos + cam.front, cam.up);
}