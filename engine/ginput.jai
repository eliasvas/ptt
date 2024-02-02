#import "Basic";
#import "Input";
#import "System";

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
    MOUSE_ACTION;
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
            case .MOUSE_ACTION;
                cs : u8 = ((cast(u8)gim.mkey_state[event.data0] << 1) | (xx event.data1 & 1)) & 0x3;
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


//TODO: maybe we need a gRect struct for such cases (in the math library? some core file? IDK)
gim_mouse_inside_region :: (p_x : float, p_y : float, w_x : float, w_y : float) -> bool {
    mp_x : float = xx gim.mp_x;
    mp_y : float = xx gim.mp_y;
    if (mp_x <= p_x + w_x) && (mp_x >= p_x) && (mp_y >= p_y) && (mp_y <= p_y + w_y) then return true;
    return false;
}