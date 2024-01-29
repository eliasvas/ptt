#import "Basic";
#import "Input";
#import "System";

//Some resources:
//https://www.youtube.com/watch?v=Z1qyvQsjK5Y casey's general overview, VERY important
//https://solhsa.com/imgui nice and SIMPLE overview of a basic imgui
//https://www.rfleury.com/p/ui-series-table-of-contents This is real good for a more complicated (complete) UI system


djb2_hash :: (str : string) -> u64 {
    hash : u64 = 5381;
    c : u8;
    for i : 0..str.count-1 { 
        c = str.data[i];
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
    }
    return hash;
}

guiid :: #type u64;
guiContext :: struct {
    hot : guiid; 
    active : guiid; 
}

//TODO: should this be initialized by the game/editor?
gui : guiContext;

gui_update :: () {
    //print("hot=[%], active=[%]\n", gui.hot, gui.active);
    gui.hot = 0;
    //gui.active = 0;
}


//BUG: if we change the text scale, weird things happen
//TODO: work a bit on the input abstraction (we dont want to access internal state like)
gui_button :: (s : string, pos : gVec2) -> bool {
    id := djb2_hash(s);
    res := false;
    scale := 1.4;
    w_x,w_y := gfont_atlas_get_dim_for_string(*grc.default_atlas,s,scale);

    if gim_mouse_inside_region(pos.x, pos.y, xx w_x, xx w_y) {
        gui.hot = id;
    }

    if gui.active == id {
        render_basic_string(s,xx pos.x,xx pos.y, scale,U32_MAX, true);
        if (gim.mkey_state[gInputMouseKey.LMB] == gKeyState.KEY_RELEASED) {
            if gui.hot == id {
                res = true;
                gui.active = 0;
            }
        } 
    }else if (gui.hot == id) {
        render_basic_string(s,xx pos.x,xx pos.y, scale,U32_MAX/2, true);
        if (gim.mkey_state[gInputMouseKey.LMB] == gKeyState.KEY_PRESSED) {
            gui.active = id;
        }
    }else {
        render_basic_string(s,xx pos.x,xx pos.y, scale,U32_MAX/300, true);
    }

    return res;
}