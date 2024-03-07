#import "Basic";
#import "Input";
#import "System";

gKeyState :: enum u8 {
    KEY_UP       :: 0x0; // 0b00
    KEY_PRESSED  :: 0x1; // 0b01
    KEY_RELEASED :: 0x2; // 0b10
    KEY_DOWN     :: 0x3; // 0b11
};

//lshift and put the current state in position 0
gkey_update_key_state :: (prev : *gKeyState, cur : u8) { // 1 for down 0 for up
    p : u8 = cast(u8)(prev.* << 1);
    cs : u8 = (p | cur) & 0x3;
    prev.* = xx cs;
}
//previous state is propagated to current state, any changes to key state will be added on-top 
gkey_propagate_input_events :: (key_state : [] gKeyState) {
    for i : 0..key_state.count-1 {
        was_on : u8 = xx (key_state[i] & 1);
        key_state[i] = ((key_state[i] << 1) | xx was_on) & 0x3;
    }
}


gInputMouseKey :: enum u8 {
    LMB;
    MMB;
    RMB;
};

GINPUT_EVENT_TYPE :: enum {
    MOUSE_MOVE;
    MOUSE_ACTION;
    KEY_ACTION;
};

gInputEvent :: struct {
    data0 : u32;
    data1 : u32;
    data2 : u32;
    type : GINPUT_EVENT_TYPE;
};

gInputManager :: struct {
    ASCII_RANGE :: 128;
    events : [..] gInputEvent;
    mkey_state : [3] gKeyState; 
    kkey_state : [ASCII_RANGE] gKeyState; 
    mp_x : u32;
    mp_y : u32;
};

gim : gInputManager;

gim_process_input :: () {
    gkey_propagate_input_events(gim.mkey_state);
    gkey_propagate_input_events(gim.kkey_state);
    for event : gim.events {
        if event.type == {
            case .MOUSE_ACTION;
                gkey_update_key_state(*gim.mkey_state[event.data0], xx (event.data1 & 1));
                //print("mouse[%]=[%]\n", cast(gInputMouseKey)event.data0, event.data1);
            case .MOUSE_MOVE;
                gim.mp_x = event.data0;
                gim.mp_y = event.data1;
           case .KEY_ACTION;
                if event.data0 < gInputManager.ASCII_RANGE{
                    gkey_update_key_state(*gim.kkey_state[event.data0], xx (event.data1 & 1));
                }
                //print("key action for key [%]:[%]", event.data0, event.data1);
        }
        //print("event:[%]\n", event);
    }
    //print("A state: [%]\n", cast(int)gim.kkey_state[97]);
    //print("LMB state: [%]\n", cast(int)gim.mkey_state[0]);
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