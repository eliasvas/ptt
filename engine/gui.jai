#import "Basic";
#import "Input";
#import "System";

//TODO:
//"##" string hashing for widget with same string hashes

//Some resources:
//https://www.youtube.com/watch?v=Z1qyvQsjK5Y casey's general overview, VERY important
//https://solhsa.com/imgui nice and SIMPLE overview of a basic imgui
//https://www.rfleury.com/p/ui-series-table-of-contents This is real good for a more complicated (complete) UI system


/*
Notes: 
    We need a gui system that is code-oriented (meaning no callbacks) but at the same time can
handle complicated autolayout algorithms, which are needed for any sufficiently complex application UI.
For that reason, we make a gui hierarchy each frame, with all widgets in a SEMANTIC form (no pixels). Just before
rendering we do the auto-layout algorithm, meaning multiple passes in the hierarchy to decipher the actual pixel-space
coordinates of each widget (+pipe state). This is pretty much how most Retained-mode UI libraries work. 
    To get around providing callbacks for every action like guiButton("press me", cb), we need a way to decypher the
coordinates for each widget exactly when guiButton(..) is called, and do the actions needed (e.g branch to some code / 
set widget as hot / advance animation / collapse a panel). To achieve this we use the hierarchy (+ its pixel coordinates
and stuff that are computed) from the PREVIOUS frame. This will introduce a 1-frame lag on event handling,
but its unnoticeable, and rendering is perfectly synced.
*/

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


//TODO: work a bit on the input abstraction (we dont want to access internal state like gim.mkey_state[gInputMouseKey.LMB])
gui_button :: (s : string, pos : gVec2) -> bool {
    id := djb2_hash(s);
    res := false;
    scale := 1.4;
    w_x,w_y := gfont_atlas_get_dim_for_string(*grc.default_atlas,s,scale);

    pad_x := 40;
    pad_y := 40;
    if gim_mouse_inside_region(pos.x - pad_x, pos.y - pad_y, xx (w_x + pad_x), xx (w_y + pad_y)) {
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