#import "Basic";
#import "Input";
#import "System";
/*
Current naive implementation: All keystates are stored in a flat 128 array for each ASCII character BUT LMB, MMB and RMB
are stored in positions 0,1,2 of this array for simplicity, at the start of input update, previous key values are copied to
the current state's '0' position, e.g prev = "10" (released) becomes "00" (up) and extra input events are parsed after
*/

gKeyState :: enum u8 {
    KEY_UP       :: 0x0; // 0b00
    KEY_PRESSED  :: 0x1; // 0b01
    KEY_RELEASED :: 0x2; // 0b10
    KEY_DOWN     :: 0x3; // 0b11
};

//previous state is propagated to current state, any changes to key state will be added on-top 
gkey_propagate_input_events :: (key_state : [] gKeyState) {
    for i : 0..key_state.count-1 {
        was_on : u8 = xx (key_state[i] & 1);
        key_state[i] = ((key_state[i] << 1) | xx was_on) & 0x3;
    }
}

//lshift and put the current state in position 0
gkey_update_key_state :: (prev : *gKeyState, cur : u8) { // 1 for down 0 for up
    p : u8 = cast(u8)(prev.* << 1);
    cs : u8 = (p | cur) & 0x3;
    prev.* = xx cs;
}

gkey_is_state :: (key_idx : u8, state : gKeyState) -> bool{return gim.key_state[key_idx] == state;}
gkey_released :: (key_idx : u8) -> bool{return gkey_is_state(key_idx, gKeyState.KEY_RELEASED);}
gkey_pressed :: (key_idx : u8) -> bool{return gkey_is_state(key_idx, gKeyState.KEY_PRESSED);}
gkey_up :: (key_idx : u8) -> bool{return gkey_is_state(key_idx, gKeyState.KEY_UP) | gkey_is_state(key_idx, gKeyState.KEY_RELEASED);}
gkey_down :: (key_idx : u8) -> bool{return gkey_is_state(key_idx, gKeyState.KEY_DOWN) | gkey_is_state(key_idx, gKeyState.KEY_PRESSED);}

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
    data0 : s64;
    data1 : s64;
    data2 : s64;
    type : GINPUT_EVENT_TYPE;
};

gInputManager :: struct {
    ASCII_RANGE :: 128;
    events : [..] gInputEvent;
    key_state : [ASCII_RANGE] gKeyState; 
    mp_x : float;
    mp_y : float;
};

gim : gInputManager;

gim_process_input :: () {
    gkey_propagate_input_events(gim.key_state);
    for event : gim.events {
        if event.type == {
            case .MOUSE_ACTION;
                gkey_update_key_state(*gim.key_state[event.data0], xx (event.data1 & 1));
                //print("mouse[%]=[%]\n", cast(gInputMouseKey)event.data0, event.data1);
            case .MOUSE_MOVE;
                gim.mp_x = xx event.data0;
                gim.mp_y = xx event.data1;
           case .KEY_ACTION;
                if event.data0 < gInputManager.ASCII_RANGE{
                    gkey_update_key_state(*gim.key_state[event.data0], xx (event.data1 & 1));
                }
                //print("key action for key [%]:[%]", event.data0, event.data1);
        }
        //print("event:[%]\n", event);
    }
    //print("A state: [%]\n", cast(int)gim.key_state[97]);
    //print("LMB state: [%]\n", cast(int)gim.key_state[gInputMouseKey.LMB]);
    gim.events.count = 0;
}

//TODO: can push_event resolve events immediately? this way in a single frame many events can take place
//rn, only the last one will be resolved via gim_process_input
gim_push_event :: (event : gInputEvent) {
    array_add(*gim.events, event);
}


//TODO: maybe we need a gRect struct for such cases (in the math library? some core file? IDK)
gim_mouse_inside_region :: (p_x : float, p_y : float, w_x : float, w_y : float) -> bool {
    mp_x :float = gim.mp_x;
    mp_y :float = gim.mp_y;
    if (mp_x <= p_x + w_x) && (mp_x >= p_x) && (mp_y >= p_y) && (mp_y <= p_y + w_y) then return true;
    return false;
}