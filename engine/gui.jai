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
    style : guiStyle = #run gui_style_default();
    text_scale : float = 0.7;
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
    scale := gui.text_scale;
    w_x,w_y := gfont_atlas_get_dim_for_string(*grc.default_atlas,s,scale);

    max_possible_height := gfont_atlas_get_max_glyph_height(*grc.default_atlas, scale);

    pad_x := gui.style.button_pad_x;
    pad_y := gui.style.button_pad_y;
    if gim_mouse_inside_region(pos.x, pos.y, xx (w_x + pad_x), xx (w_y + pad_y)) {
        gui.hot = id;
    }

    if gui.active == id {
        render_basic_box(pos.x, pos.y, xx (w_x + pad_x), xx (w_y + pad_y), gui.style.default_active_color);
        render_basic_string(s,xx (pos.x + pad_x/2),xx (pos.y+pad_y/2), scale);
        if (gim.mkey_state[gInputMouseKey.LMB] == gKeyState.KEY_RELEASED) {
            if gui.hot == id {
                res = true;
            }
            gui.active = 0;
        } 
    }else if (gui.hot == id) {
        render_basic_box(pos.x, pos.y, xx (w_x + pad_x), xx (w_y + pad_y), gui.style.default_hot_color);
        render_basic_string(s,xx (pos.x + pad_x/2),xx (pos.y+pad_y/2), scale);
        if (gim.mkey_state[gInputMouseKey.LMB] == gKeyState.KEY_PRESSED) {
            gui.active = id;
        }
    }else {
        render_basic_box(pos.x, pos.y, xx (w_x + pad_x), xx (w_y + pad_y), gui.style.default_color);
        render_basic_string(s,xx (pos.x + pad_x/2),xx (pos.y+pad_y/2), scale);
        //render_basic_box(pos.x, pos.y, xx (w_x), xx (w_y), gui.style.default_active_color);
        //render_basic_string(s,xx (pos.x),xx (pos.y), scale);
    }

    return res;
}



guiStyle :: struct {
    default_text_color : gVec4;
    default_color : gVec4;
    default_active_color : gVec4;
    default_hot_color : gVec4;
    button_pad_x : float = 30.0;
    button_pad_y : float = 20.0;
}

gui_style_default :: () -> guiStyle {
    style : guiStyle;
    style.default_text_color = .{1.0,1.0,1.0,1.0};
    style.default_color = .{0.3,0.3,0.3,0.3};
    style.default_active_color = .{0.5,0.5,0.5,0.5};
    style.default_hot_color = .{0.4,0.4,0.4,0.4};
    return style;
}