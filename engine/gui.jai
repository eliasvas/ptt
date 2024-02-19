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
    text_scale : float = 0.8;
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

gui_static_label :: (s : string, r : gRect) {
    id := djb2_hash(s);
    res := false;
    pad_x := gui.style.button_pad_x;
    pad_y := gui.style.button_pad_y;
    text_r: gRect = .{r.x0 + pad_x/2, r.y0 + pad_y/2, r.w - pad_x, r.h - pad_y};
    scale := gfont_atlas_get_text_scale_to_fit_region(*grc.default_atlas,s, text_r);
    w_x,w_y := gfont_atlas_get_dim_for_string(*grc.default_atlas,s,scale);
    text_r.y0 += text_r.h/2 - w_y/2;
    text_r.x0 += text_r.w/2 - w_x/2;

    render_basic_box(r.x0,r.y0,r.w,r.h, gui.style.default_label_background_color);
    render_basic_string(s,text_r.x0, text_r.y0, scale);
}

gui_checkbox :: (s : string, r : gRect, val : *bool) -> bool {
    id := djb2_hash(s);
    res := false;
    pad_x := gui.style.button_pad_x;
    pad_y := gui.style.button_pad_y;
    text_r: gRect = .{r.x0 + pad_x/2, r.y0 + pad_y/2, r.w - pad_x, r.h - pad_y};
    scale := gfont_atlas_get_text_scale_to_fit_region(*grc.default_atlas,s, text_r);
    w_x,w_y := gfont_atlas_get_dim_for_string(*grc.default_atlas,s,scale);
    text_r.y0 += text_r.h/2 - w_y/2;
    text_r.x0 += text_r.w/2 - w_x/2;

    if gim_mouse_inside_region(r.x0, r.y0, r.w,r.h) {
        gui.hot = id;
    }

    if gui.active == id {
        if (gim.mkey_state[gInputMouseKey.LMB] == gKeyState.KEY_RELEASED) {
            if gui.hot == id {
                val.* = !val.*;
            }
            gui.active = 0;
        } 
    }else if (gui.hot == id) {
        if (gim.mkey_state[gInputMouseKey.LMB] == gKeyState.KEY_PRESSED) {
            gui.active = id;
        }
    }else {
    }

    if val.* {
        render_basic_box(r.x0,r.y0,r.w,r.h, gui.style.default_checkbox_pressed_color);
        render_basic_string(s,text_r.x0, text_r.y0, scale);
    }else {
        render_basic_box(r.x0,r.y0,r.w,r.h, gui.style.default_checkbox_color);
        render_basic_string(s,text_r.x0, text_r.y0, scale);
    } 

    return val.*;
}

gui_button :: (s : string, r : gRect) -> bool {
    id := djb2_hash(s);
    res := false;
    pad_x := gui.style.button_pad_x;
    pad_y := gui.style.button_pad_y;
    text_r: gRect = .{r.x0 + pad_x/2, r.y0 + pad_y/2, r.w - pad_x, r.h - pad_y};
    scale := gfont_atlas_get_text_scale_to_fit_region(*grc.default_atlas,s, text_r);
    w_x,w_y := gfont_atlas_get_dim_for_string(*grc.default_atlas,s,scale);
    text_r.y0 += text_r.h/2 - w_y/2;
    text_r.x0 += text_r.w/2 - w_x/2;

    if gim_mouse_inside_region(r.x0, r.y0, r.w,r.h) {
        gui.hot = id;
    }

    if gui.active == id {
        render_basic_box(r.x0,r.y0,r.w,r.h, gui.style.default_active_color);
        render_basic_string(s,text_r.x0, text_r.y0, scale);
        if (gim.mkey_state[gInputMouseKey.LMB] == gKeyState.KEY_RELEASED) {
            if gui.hot == id {
                res = true;
            }
            gui.active = 0;
        } 
    }else if (gui.hot == id) {
        render_basic_box(r.x0,r.y0,r.w,r.h, gui.style.default_hot_color);
        render_basic_string(s,text_r.x0, text_r.y0, scale);
        if (gim.mkey_state[gInputMouseKey.LMB] == gKeyState.KEY_PRESSED) {
            gui.active = id;
        }
    }else {
        render_basic_box(r.x0,r.y0,r.w,r.h, gui.style.default_color);
        render_basic_string(s,text_r.x0, text_r.y0, scale);
        //render_basic_box(pos.x, pos.y, xx (w_x), xx (w_y), gui.style.default_active_color);
        //render_basic_string(s,xx (pos.x),xx (pos.y), scale);
    }

    return res;
}




gui_slider :: (s : string, r : gRect, val : *int, minv : int, maxv : int) -> bool {
    id := djb2_hash(s);
    res := false;
    pad_x := gui.style.button_pad_x;
    pad_y := gui.style.button_pad_y;
    text_r: gRect = .{r.x0 + pad_x/2, r.y0 + pad_y/2, r.w - pad_x, r.h - pad_y};
    scale := gfont_atlas_get_text_scale_to_fit_region(*grc.default_atlas,s, text_r);
    w_x,w_y := gfont_atlas_get_dim_for_string(*grc.default_atlas,s,scale);
    text_r.y0 += text_r.h/2 - w_y/2;
    text_r.x0 += text_r.w/2 - w_x/2;

    percent : float = clamp(cast(float) (val.*+ minv) / (maxv - minv), 0.0,1.0);
    percent = 1.0 - percent;
    slider_r : gRect = .{r.x0 * percent + (r.x0 + r.w) * (1.0 - percent), r.y0, gui.style.slider_w, r.h-1};
    slider_r.x0 -= cast(float) gui.style.slider_w * (1.0 - percent);

    if gim_mouse_inside_region(r.x0, r.y0, r.w,r.h) {
        gui.hot = id;
    }

    if gui.active == id {
        mp_x := clamp((clamp(cast(float) gim.mp_x, r.x0, r.x0 + r.w) - r.x0) / r.w, 0.0, 1.0);
        val.* = minv + cast(int) ((maxv-minv) * mp_x);
        render_basic_box(r.x0,r.y0,r.w,r.h, gui.style.default_hot_color);
        render_basic_box(slider_r.x0,slider_r.y0,slider_r.w,slider_r.h, gui.style.default_slider_pressed_color);
        render_basic_string(s,text_r.x0, text_r.y0, scale);
        if (gim.mkey_state[gInputMouseKey.LMB] == gKeyState.KEY_RELEASED) {
            if gui.hot == id {
                res = true;
            }
            gui.active = 0;
        } 
    }else if (gui.hot == id) {
        render_basic_box(r.x0,r.y0,r.w,r.h, gui.style.default_hot_color);
        render_basic_box(slider_r.x0,slider_r.y0,slider_r.w,slider_r.h, gui.style.default_slider_color);
        render_basic_string(s,text_r.x0, text_r.y0, scale);
        if (gim.mkey_state[gInputMouseKey.LMB] == gKeyState.KEY_PRESSED) {
            gui.active = id;
        }
    }else {
        render_basic_box(r.x0,r.y0,r.w,r.h, gui.style.default_color);
        render_basic_box(slider_r.x0,slider_r.y0,slider_r.w,slider_r.h, gui.style.default_slider_color);
        render_basic_string(s,text_r.x0, text_r.y0, scale);
    }

    return res;
}




guiStyle :: struct {
    default_text_color : gVec4;
    default_color : gVec4;
    default_label_background_color : gVec4;
    default_panel_background_color : gVec4;
    default_checkbox_pressed_color : gVec4;
    default_checkbox_color : gVec4;
    default_slider_color : gVec4;
    default_slider_pressed_color : gVec4;
    default_active_color : gVec4;
    default_hot_color : gVec4;
    default_pressed_color : gVec4;
    default_released_color : gVec4;
    button_pad_x : float = 20.0;
    button_pad_y : float = 10.0;
    panel_pad_x : float = 10.0;
    panel_pad_y : float = 10.0;
    slider_w : float = 20.0;
}

gui_style_default :: () -> guiStyle {
    style : guiStyle;
    style.default_text_color = .{1.0,1.0,1.0,1.0};
    style.default_color = .{0.3,0.3,0.3,0.3};
    style.default_label_background_color = .{0.65,0.25,0.25,1.0};
    style.default_panel_background_color = .{0.15,0.15,0.15,1.0};
    style.default_active_color = .{0.5,0.5,0.5,1.0};
    style.default_checkbox_pressed_color = .{0.8,0.6,0.1,1.0};
    style.default_checkbox_color = .{0.25,0.25,0.25,1.0};
    style.default_slider_color = .{0.55,0.55,0.55,1.0};
    style.default_slider_pressed_color = .{0.45,0.25,0.25,1.0};
    style.default_hot_color = .{0.4,0.4,0.4,0.4};
    return style;
}

guiPanelLayout :: struct {
    x0,y0 : float;
    width : float;
    row_height : float;
    col_w : float;
    at_x : float;
    at_y : float;
};
gui_panel_layout_row :: (layout : *guiPanelLayout, column_count : int = 1) {
    layout.at_y += layout.row_height;
    layout.at_x = layout.x0;
    layout.col_w = layout.width / column_count;
}

gui_panel_layout_add_checkbox :: (layout : *guiPanelLayout, label : string, val : *bool) -> bool {
    height := layout.at_y - layout.row_height;
    on := gui_checkbox(label, .{layout.at_x,height, layout.col_w,layout.row_height}, val);
    layout.at_x += layout.col_w;
    return on;
}
gui_panel_layout_add_slider :: (layout : *guiPanelLayout, label : string, val : *int, minv : int, maxv : int) -> bool {
    height := layout.at_y - layout.row_height;
    pressed := gui_slider(label, .{layout.at_x,height, layout.col_w,layout.row_height},val, minv, maxv);
    layout.at_x += layout.col_w;
    return pressed;
}
gui_panel_layout_add_button :: (layout : *guiPanelLayout, label : string) -> bool {
    height := layout.at_y - layout.row_height;
    pressed := gui_button(label, .{layout.at_x,height, layout.col_w,layout.row_height});
    layout.at_x += layout.col_w;
    return pressed;
}
gui_panel_layout_add_title :: (layout : *guiPanelLayout, label : string) {
    gui_panel_layout_row(layout, 1);
    height := layout.at_y - layout.row_height;
    gui_static_label(label, .{layout.at_x,height, layout.col_w,layout.row_height});
}

guiPanel :: struct {
    x0, y0 : float;
    w, h: float;

    m_x, m_y : float;
}

gui_panel_layout_begin :: (panel : *guiPanel, layout : *guiPanelLayout) {
    layout.x0 = panel.x0 + gui.style.panel_pad_x / 2;
    layout.y0 = panel.y0 + gui.style.panel_pad_y / 2;
    layout.at_x = layout.x0;
    layout.at_y = layout.y0;
    render_basic_box(panel.x0, panel.y0, panel.w+ gui.style.panel_pad_x,panel.h+ gui.style.panel_pad_y/2, gui.style.default_panel_background_color);

    //if gim_mouse_inside_region(panel.x0, panel.y0, panel.x0 + panel.w, panel.y0 + panel.h) {
        //if mouse pressed where label is
        //take mouse delta and add to current panel pos
    //}
}

gui_panel_layout_end :: (panel : *guiPanel, layout : *guiPanelLayout) {
    panel.w = layout.width;
    panel.h = abs(panel.y0 - layout.at_y);

    mouse_delta_x := cast(float) gim.mp_x - panel.m_x;
    mouse_delta_y := cast(float) gim.mp_y - panel.m_y;

    mouse_over_title := gim_mouse_inside_region(panel.x0, panel.y0, panel.w, layout.row_height);

    if (gim.mkey_state[gInputMouseKey.LMB] == gKeyState.KEY_DOWN && mouse_over_title) {
        panel.x0 += mouse_delta_x;
        panel.y0 += mouse_delta_y;
    }

    panel.m_x = xx gim.mp_x;
    panel.m_y = xx gim.mp_y;
}