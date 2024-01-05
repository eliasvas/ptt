#import "Basic";
#import "Input";
#import "System";
#import "GL";
#import "SDL";


gWin :: struct {
    dim : gVec2;
    opt : GWIN_OPT;
    window : *SDL_Window;
}

GWIN_OPT :: enum {
    NONE;
    VISIBLE;
    RESIZABLE;
}

gwin_create :: (ww : s32, wh : s32, opt : GWIN_OPT) -> gWin {
    win : gWin = .{.{ww, wh}, opt, null};

    win.window = SDL_CreateWindow("Window",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, win.dim.x, win.dim.y,
        SDL_WINDOW_OPENGL|SDL_WINDOW_SHOWN);

    if win.window == null {
        print("Could not create window: %\n", to_string(SDL_GetError()));
    }
    return win;
}

gwin_cleanup :: (win : *gWin){
    SDL_DestroyWindow(win.window);
    memset(win, 0, size_of(gWin));
}

grend_init :: () {
    SDL_Init(SDL_INIT_VIDEO);
}

