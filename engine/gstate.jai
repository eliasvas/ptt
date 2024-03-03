//The engine's global state / entrypoiny / update
#import "Basic";
#import "System";


gEngineGlobalState :: struct {
    exit : bool = false;
    dt : float64;
    prev_frame_time : float64;
    window_resized : bool;
    //array of events gathered from SDL equivalents??
}

//game engine state
ges : gEngineGlobalState = .{};

ges_init :: () {
    memset(*ges, 0, size_of(gEngineGlobalState));
}

ges_update :: () {
    ges.window_resized = false;
    SDL_Delay(1);//ms to delay update
    event : SDL_Event;
    while SDL_PollEvent(*event) {
        if event.type == {
            case SDL_QUIT;
                ges.exit = true;
            case SDL_KEYUP;
                if event.key.keysym.sym == SDLK_ESCAPE  ges.exit = true;
            case SDL_WINDOWEVENT;
                if event.window.event == SDL_WINDOWEVENT_RESIZED{
                    //print("Window resize detected, new res: [%,%]\n", window.width, window.height );
                    //SDL_GetWindowSize(window,&width,&height);
                    ges.window_resized = true;
                }
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
    ges.dt = (now - ges.prev_frame_time) * 1000; 
    ges.prev_frame_time = now;


    //print("ms: %\n", ges.dt);
    //print("fps: %\n", 1000.0 / ges.dt);

}