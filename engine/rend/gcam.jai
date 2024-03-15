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
    speed : float = 8.0;
    pitch : float = 0.0;
    yaw : float = -90.0;
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

    if gkey_down(xx gInputMouseKey.LMB) {
        prev_frame_mp_x : float = ges.prev_frame_mouse_x;
        prev_frame_mp_y : float = ges.prev_frame_mouse_y;

        delta_x := gim.mp_x - prev_frame_mp_x;
        delta_y := gim.mp_y - prev_frame_mp_y;
        //print("dx :[%]", delta_x);
        sensitivity : float = 0.1;
        cam.yaw+=delta_x*sensitivity;
        cam.pitch+=delta_y*sensitivity;
        if cam.pitch > 89.0 then cam.pitch = 89.0;
        if cam.pitch < -89.0 then cam.pitch = -89.0;
        front : gVec3;
        front.x = cos(d2r(cam.yaw)) * cos(d2r(cam.pitch));
        front.y = sin(d2r(cam.pitch));
        front.z = sin(d2r(cam.yaw)) * cos(d2r(cam.pitch));
        cam.front= gvec3_norm(front);
    }
}

gcam_make_lookat_matrix :: (cam : *gCam) -> gMat4 {
    return make_lookat_matrix(cam.pos, cam.pos + cam.front, cam.up);
}