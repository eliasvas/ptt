#import "Basic";
#import "Input";
#import "System";

//TODO: maybe mouse sensitivity should be in global engine config, do camera can become more/less responsive
GCAM_MODE :: enum {
    FREE; //looks for input from mouse/keeb/gamepad and self-moves
    FIXED; //stays fixed in place until changed
}

gCam :: struct {
    pos : gVec3;
    front : gVec3;
    up : gVec3;
    mode : GCAM_MODE = .FREE;
    speed : float = 1.0;
}

gcam_init :: (cam : *gCam, initial_pos : gVec3 = .{0,0,0}) {
    cam.pos = initial_pos;
    cam.front = .{0,0,-1};
    cam.up = .{0,1,0};
}

gcam_update :: (cam :*gCam, dt : float = 1.0 / 60.0) {
    //TODO: augment input system so we can pass enums for keyboard keys not just ASCII
    if gkey_down(119){ //key w
        cam.pos += camera.front * cam.speed * dt;
    }
    if gkey_down(115){ //key s
        cam.pos -= camera.front * cam.speed * dt;
    }
    if gkey_down(97){ //key a
        cam.pos -= gvec3_norm(gvec3_cross(camera.front,camera.up)) * cam.speed * dt;
    }
    if gkey_down(100){ //key d
        cam.pos += gvec3_norm(gvec3_cross(camera.front,camera.up)) * cam.speed * dt;
    }
}

gcam_make_lookat_matrix :: (cam : *gCam) -> gMat4 {
    return make_lookat_matrix(cam.pos, cam.pos + cam.front, cam.up);
}