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
    }else {
        //Should this be saved somewhere??
        gl_context : SDL_GLContext = SDL_GL_CreateContext(win.window);
    }
    return win;
}

gwin_update :: (win : *gWin) {
    dt := ges.dt;
    glViewport(0, 0, xx win.dim.x, xx win.dim.y);
    glClearColor(1.0, 0.3, 0.4, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    SDL_GL_SwapWindow(win.window);
}

gwin_cleanup :: (win : *gWin){
    SDL_DestroyWindow(win.window);
    memset(win, 0, size_of(gWin));
}

grend_init :: () {
    SDL_Init(SDL_INIT_VIDEO);
}

