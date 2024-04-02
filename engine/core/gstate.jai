//The engine's global state / entrypoiny / update
#import "Basic";
#import "System";


gEngineGlobalState :: struct {
    exit : bool = false;
    dt : float64;
    prev_frame_time : float64;
    window_resized : bool;
    prev_frame_mouse_x : float;
    prev_frame_mouse_y : float;
    //array of events gathered from SDL equivalents??
}

//game engine state
ges : gEngineGlobalState = .{};

ges_init :: () {
    memset(*ges, 0, size_of(gEngineGlobalState));
}

ges_update :: () {
    ges.prev_frame_mouse_x = xx gim.mp_x;
    ges.prev_frame_mouse_y = xx gim.mp_y;
    ges.window_resized = false;
    //SDL_Delay(16);//ms to delay update
    event : SDL_Event;
    while SDL_PollEvent(*event) {
        if event.type == {
            case SDL_QUIT;
                ges.exit = true;
            // case SDL_KEYUP;
            //     if event.key.keysym.sym == SDLK_ESCAPE  ges.exit = true;
            case SDL_WINDOWEVENT;
                if event.window.event == SDL_WINDOWEVENT_RESIZED{
                    ges.window_resized = true;
                }
            case SDL_KEYDOWN;
                gim_push_event(.{xx event.key.keysym.sym,1,0, .KEY_ACTION});
            case SDL_KEYUP;
                gim_push_event(.{xx event.key.keysym.sym,0,0, .KEY_ACTION});
            case SDL_MOUSEBUTTONDOWN;
                if event.button.button == SDL_BUTTON_LEFT then gim_push_event(.{xx gInputMouseKey.LMB,1,0, .MOUSE_ACTION});
                if event.button.button == SDL_BUTTON_MIDDLE then gim_push_event(.{xx gInputMouseKey.MMB,1,0, .MOUSE_ACTION});
                if event.button.button == SDL_BUTTON_RIGHT then gim_push_event(.{xx gInputMouseKey.RMB,1,0, .MOUSE_ACTION});
            case SDL_MOUSEBUTTONUP;
                if event.button.button == SDL_BUTTON_LEFT then gim_push_event(.{xx gInputMouseKey.LMB,0,0, .MOUSE_ACTION});
                if event.button.button == SDL_BUTTON_MIDDLE then gim_push_event(.{xx gInputMouseKey.MMB,0,0, .MOUSE_ACTION});
                if event.button.button == SDL_BUTTON_RIGHT then gim_push_event(.{xx gInputMouseKey.RMB,0,0, .MOUSE_ACTION});
            case SDL_MOUSEMOTION;
                gim_push_event(.{xx event.motion.x,xx event.motion.y,0, .MOUSE_MOVE});

        }
    }
    gim_process_input();
    gui_update();
    now := seconds_since_init();
    ges.dt = now - ges.prev_frame_time;  //delta time is in seconds
    ges.prev_frame_time = now;

    //print("ms: %\n", ges.dt);
    //print("fps: %\n", 1.0 / ges.dt);

}