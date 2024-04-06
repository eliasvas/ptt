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
    using cam;
    pos = initial_pos;
    front = .{0,0,-1};
    up = .{0,1,0};
}

gcam_update :: (cam :*gCam, dt : float = 1.0 / 60.0) {
    using cam;
    //TODO: augment input system so we can pass enums for keyboard keys not just ASCII
    if gkey_down(119){ //key w
        pos += front * speed * dt;
    }
    if gkey_down(115){ //key s
        pos -= front * speed * dt;
    }
    if gkey_down(97){ //key a
        pos -= gvec3_norm(gvec3_cross(front,up)) * speed * dt;
    }
    if gkey_down(100){ //key d
        pos += gvec3_norm(gvec3_cross(front,up)) * speed * dt;
    }

    if gkey_down(xx gInputMouseKey.RMB) {
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