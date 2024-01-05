//The engine's global state / entrypoiny / update
#import "Basic";
#import "System";


gEngineGlobalState :: struct {
    exit : bool = false;
    dt : float64;
    prev_frame_time : float64;
    //array of events gathered from SDL equivalents??
}

//game engine state
ges : gEngineGlobalState = .{};

ges_init :: () {
    memset(*ges, 0, size_of(gEngineGlobalState));
}

ges_update :: () {
    SDL_Delay(1);//ms to delay update
    event : SDL_Event;
    while SDL_PollEvent(*event) {
        if event.type == {
            case SDL_QUIT;
                ges.exit = true;
            case SDL_KEYUP;
                if event.key.keysym.sym == SDLK_ESCAPE  ges.exit = true;
        }
    }
    now := get_time();
    ges.dt = (now - ges.prev_frame_time) * 1000; 
    ges.prev_frame_time = now;
    //print("ms: %\n", ges.dt);
    print("fps: %\n", 1000.0 / ges.dt);

}