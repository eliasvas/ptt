#import "Basic";
#import "Input";
#import "System";

//Some Notes on FONTS:
//1.) We need to load the font at COMPILE time so the executable is bundled with the font data :)
//2.) We will use stb_truetype to read the data and make glyphs
//3.) We will make a FAST OpenGL batch renderer at grend.jai which will get said glyphs and draw them
//4.) SDF?! 

gKeyState :: enum u8 {
    KEY_UP       :: 0x0;
    KEY_PRESSED  :: 0x1;
    KEY_RELEASED :: 0x2;
    KEY_DOWN     :: 0x3;
};

gInputMouseKey :: enum u8 {
    LMB;
    MMB;
    RMB;
};

GINPUT_EVENT_TYPE :: enum {
    MOUSE_MOVE;
    MOUSE_CLICK;
    KEY_UP;
    KEY_DOWN;
};

gInputEvent :: struct {
    data0 : u32;
    data1 : u32;
    data2 : u32;
    type : GINPUT_EVENT_TYPE;
};

gInputManager :: struct {
    events : [..] gInputEvent;
    mkey_state : [3] gKeyState; 
    mp_x : u32;
    mp_y : u32;
};

gim : gInputManager;

gim_process_input :: () {
    //TODO: search up jai docs, how to do this with slice/array iteration
    for i : 0..2 {
        gim.mkey_state[i] = ((gim.mkey_state[i] << 1) | (gim.mkey_state[i] & 1)) & 0x3;
    }
    for event : gim.events {
        if event.type == {
            case .MOUSE_CLICK;
                cs : u8 = xx gim.mkey_state[event.data0];
                cs <<= 1;
                cs |= xx event.data1;
                cs &= 0x3;
                gim.mkey_state[event.data0] = xx cs;
                //print("mouse[%]=[%]\n", cast(gInputMouseKey)event.data0, event.data1);
            case .MOUSE_MOVE;
                gim.mp_x = event.data0;
                gim.mp_y = event.data1;
                //print("mp_x=[%], mp_y=[%]\n", gim.mp_x, gim.mp_y);
        }
        //print("event:[%]\n", event);
    }
    gim.events.count = 0;
}

//TODO: can push_event resolve events immediately? this way in a single frame many events can take place
//rn, only the last one will be resolved via gim_process_input
gim_push_event :: (event : gInputEvent) {
    array_add(*gim.events, event);
}