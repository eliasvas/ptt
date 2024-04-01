#import "Basic";
#import "Input";
#import "System";
#import "Math";
//These are the renderer's dependencies!
#import "GL";
#import "SDL";

//TODO: we need to emulate OpenGL state machine, to be able to discard VAOs and infer glVertexAttribPointers
//so we can just bind VBO/IBOs and set correct state / have a pipeline, and not mess with UGLY opengl state machine stuff.


gRendContext :: struct {

    debug_tex : oglImage;
    white_tex : oglImage;
    font_tex: oglImage;

    default_atlas : gFontAtlas;
    //+ a command buffer?!

    //TODO: This should probably be some kind of UUID, have to think about resource management
    window_ref : *gWin;
}

//NOTE: Should this be called render DEVICE instead of Context?
grc: gRendContext;

//NOTE: YOU must free the data!
gTextureData :: struct {
    data : *u8;
    cnum : u32; //3 or 4
    dim : gVec2; //shouldn't these be ints DUMBo
}


camera : gCam;

grend_init :: (window : *gWin) {
    SDL_Init(SDL_INIT_VIDEO);
    grc.default_atlas = gfont_atlas_generate();
    grc.window_ref = window;
    gbatch_renderer_2d_init();
    ogl_init();

    //white texture initialization
    white_tex := generate_debug_texture(400, 400, 1, 1, 4);
    defer free(white_tex.data);
    ogl_image_init(*grc.white_tex, white_tex.data, 400, 400, oglImageFormat.RGBA);
    ogl_image_init(*grc.font_tex, grc.default_atlas.bitmap, xx grc.default_atlas.size_x, xx grc.default_atlas.size_y, oglImageFormat.RGBA,true);

    // main GUI panel inital position 
    main_panel.x0 = 600;
    main_panel.y0 = 100;

    //initialize the main camera
    gcam_init(*camera);
}


//---------------------------------
//--------WINDOW ABSTRACTION-------
//---------------------------------

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
    win : gWin = .{.{xx ww, xx wh}, opt, null};

    
    sdl_win_args := SDL_WINDOW_OPENGL;
    sdl_win_args |= ifx opt & .RESIZABLE then SDL_WINDOW_RESIZABLE;
    sdl_win_args |= ifx opt & .VISIBLE then SDL_WINDOW_SHOWN;
    win.window = SDL_CreateWindow("Window", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, xx win.dim.x, xx win.dim.y, sdl_win_args);

    if win.window == null {
        print("Could not create window: %\n", to_string(SDL_GetError()));
    }else {
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

        gl_context : SDL_GLContext = SDL_GL_CreateContext(win.window);
        gl_load(*gl, SDL_GL_GetProcAddress);
    }
    print("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    print("GL Version = %\n", to_string(glGetString(GL_VERSION)));
    return win;
}
 
gwin_update :: (win : *gWin) {
    gwin_resize_if_necessary :: (win : *gWin) {
        if ges.window_resized {
            ww : s32;
            wh : s32;
            SDL_GetWindowSize(win.window,*ww,*wh);
            win.dim.x = xx ww;
            win.dim.y = xx wh;
            print("New window size: [%,%]\n", win.dim.x, win.dim.y);
        }
    }
    gwin_resize_if_necessary(win);
    dt := ges.dt;
    glViewport(0, 0, xx win.dim.x, xx win.dim.y);
    glClearColor(0.1, 0.1, 0.1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);


    ogl_draw_sample_scene();

    gbatch_renderer_2d_render();

    SDL_GL_SwapWindow(win.window);
}

gwin_cleanup :: (win : *gWin){
    SDL_DestroyWindow(win.window);
    memset(win, 0, size_of(gWin));
}



//---------------------------------
//--------2D BATCH RENDERER--------
//---------------------------------

//TODO: This should become a command buffer inside probably, with binding different textures and drawing

//The concept is as follows: We got a shader that renders colored rects, font and misc. icons.
//There are QuadInstances, containing all the info to render one of the three, each quad instance has
//a tex_index, meaning which of the 3 to texture, all other parameters are the same

gr2D : gBatchRenderer2D;
main_panel : guiPanel;

gBatchRenderer2D :: struct {
    quads : [..] gQuadInstance;

    vbo : oglBuf;
    sp : oglShaderObject;

    last_bound_tex : oglImage;
}

gQuadInstance :: struct {
    p0   : gVec2; //position in window coords
    p1   : gVec2;
    t0   : gVec2; //tex coord in texture's units
    t1   : gVec2;
    col0 : gVec4;
    col1 : gVec4;
    col2 : gVec4;
    col3 : gVec4;
    corner_radius : float;
    edge_softness : float;
    border_thickness : float;
}

gbatch_renderer_2d_init :: () {
    ogl_shader_object_init(*gr2D.sp,vertex_shader_ui_source, fragment_shader_ui_source);

    gr2D.vbo = ogl_make_buffer(.VERTEX, null, 0, 0);
    ogl_bind_vertex_buffer(*gr2D.vbo);
    
    ogl_shader_object_add_attrib(*gr2D.sp, ogl_make_attrib(0, oglShaderDataType.VEC2, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code p0),true));
    ogl_shader_object_add_attrib(*gr2D.sp, ogl_make_attrib(1, oglShaderDataType.VEC2, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code p1),true));
    ogl_shader_object_add_attrib(*gr2D.sp, ogl_make_attrib(2, oglShaderDataType.VEC2, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code t0),true));
    ogl_shader_object_add_attrib(*gr2D.sp, ogl_make_attrib(3, oglShaderDataType.VEC2, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code t1),true));
    ogl_shader_object_add_attrib(*gr2D.sp, ogl_make_attrib(4, oglShaderDataType.VEC4, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code col0),true));
    ogl_shader_object_add_attrib(*gr2D.sp, ogl_make_attrib(5, oglShaderDataType.VEC4, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code col1),true));
    ogl_shader_object_add_attrib(*gr2D.sp, ogl_make_attrib(6, oglShaderDataType.VEC4, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code col2),true));
    ogl_shader_object_add_attrib(*gr2D.sp, ogl_make_attrib(7, oglShaderDataType.VEC4, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code col3),true));
    ogl_shader_object_add_attrib(*gr2D.sp, ogl_make_attrib(8, oglShaderDataType.FLOAT, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code corner_radius),true));
    ogl_shader_object_add_attrib(*gr2D.sp, ogl_make_attrib(9, oglShaderDataType.FLOAT, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code edge_softness),true));
    ogl_shader_object_add_attrib(*gr2D.sp, ogl_make_attrib(10, oglShaderDataType.FLOAT, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code border_thickness),true));
    
    ogl_clear_all();
}

random_bool : bool = false;
random_bool2 : bool = true;
random_bool3 : bool = true;
random_slider_val : int = 0;
gbatch_renderer_2d_render :: () {
    num_categories := 3;
    layout : guiPanelLayout = .{width = 200, row_height = 60};
    gui_panel_layout_begin(*main_panel, *layout);
    gui_panel_layout_add_title(*layout, "graphics");
    gui_panel_layout_row(*layout, 3);
    gui_panel_layout_add_checkbox(*layout, "bloom",*random_bool);
    gui_panel_layout_add_checkbox(*layout, "negative",*random_bool3);
    if gui_panel_layout_add_button(*layout, "x") {
        print("x!\n");
    }
    gui_panel_layout_row(*layout, 2);
    gui_panel_layout_add_checkbox(*layout, "emissive", *random_bool2);
    gui_panel_layout_add_slider(*layout, "factor",*random_slider_val, 0,255);
    gui_panel_layout_end(*main_panel, *layout);
 
    fps_scale := 0.5;
    fps_counter := sprint("%", formatFloat(1.0/ges.dt, width=1, trailing_width=0, zero_removal=.NO));
    defer free(fps_counter.data);
    fps_width, fps_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,fps_counter,fps_scale);
    color : u32 = 0xFFFFFFFF;
    color = (color << 20);
    render_basic_string(fps_counter, xx (grc.window_ref.dim.x - fps_width), 0, fps_scale);
    gbatch_renderer_flush();
}

render_basic_box :: (x0 : float, y0 : float, w : float, h : float, col : gVec4, rounded : bool = true) {
    gbatch_renderer_bind_texture(grc.white_tex);
    if rounded {
        gbatch_renderer_push_quad(.{.{x0,y0},.{x0+w, y0+h}, .{0,0}, .{0,0},.{col.x,col.y,col.z,1},.{col.x,col.y,col.z,1},.{col.x,col.y,col.z,1},.{col.x,col.y,col.z,1},3,2,0});
    }else {
        gbatch_renderer_push_quad(.{.{x0,y0},.{x0+w, y0+h}, .{0,0}, .{0,0},.{col.x,col.y,col.z,1},.{col.x,col.y,col.z,1},.{col.x,col.y,col.z,1},.{col.x,col.y,col.z,1},0,0,0});
    }
}

render_basic_string :: (s : string, pos_x : float, pos_y : float, scale : float) {
    start := gVec2.{xx pos_x,xx pos_y};
    text_width, text_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,s,scale);

    //tallest in the sense of tallest POSITIVE bearing
    tallest_size_y := 0;
    for i : 0..s.count-1 {
        glyph := gfont_atlas_get_glyph_for_character(*grc.default_atlas, s[i]);
        tallest_size_y = max(tallest_size_y, glyph.bearing_y);
    }

    gbatch_renderer_bind_texture(grc.font_tex);
    cur_pos := start;
    for i : 0..s.count-1 {
        glyph := gfont_atlas_get_glyph_for_character(*grc.default_atlas, s[i]);
        cur_pos.y = start.y + (tallest_size_y - glyph.bearing_y) * scale;
        bearing_x := ifx i == 0 then 0 else glyph.bearing_x;
    
        gbatch_renderer_push_quad(.{.{xx (cur_pos.x + bearing_x * scale),xx cur_pos.y},.{xx(cur_pos.x + bearing_x * scale + glyph.size_x * scale), xx(cur_pos.y + glyph.size_y * scale)}, .{xx glyph.tc_x, xx glyph.tc_y}, .{xx (glyph.tc_x + xx glyph.size_x), xx (glyph.tc_y + xx glyph.size_y)},.{0.95,0.95,0.95,1},.{0.95,0.95,0.95,1},.{0.95,0.95,0.95,1},.{0.95,0.95,0.95,1},0,0,0});
        cur_pos.x += glyph.advance * scale;
    }
}

gbatch_renderer_flush :: () {
    ogl_clear_all();
    ogl_bind_vertex_buffer(*gr2D.vbo);
    ogl_update_buffer(*gr2D.vbo, gr2D.quads.data, cast(u32)gr2D.quads.count, size_of(gQuadInstance));
    ogl_bind_shader_object(*gr2D.sp);
    ogl_shader_object_set_uniform(*gr2D.sp,"res",oglShaderDataType.VEC2, xx *grc.window_ref.dim);
    ogl_shader_set_dynamic_state(oglShaderDynamicState.DEPTH_DISABLED | oglShaderDynamicState.BLENDING);

    ogl_bind_image_to_texture_slot(*gr2D.last_bound_tex, 0);
    ogl_shader_object_bind_sampler_to_slot(*gr2D.sp, "tex", 0);

    ogl_draw_instanced(oglPrimitive.TRIANGLE_STRIP, 0, 4, xx gr2D.quads.count); 
    gr2D.quads.count = 0;
    ogl_clear_all();
}

gbatch_renderer_bind_texture :: (tex : oglImage) {
    //TODO: some id system should be done for ALL resources from ogl
    if (tex.handle != gr2D.last_bound_tex.handle) {
        //render with current last_bound_tex to clear the quad stretchy buffer
        gbatch_renderer_flush();
    }
    gr2D.last_bound_tex = tex;
}

gbatch_renderer_push_quad :: (q : gQuadInstance) {
    //print("Quad pushed: %\n", q);
    //if tex then gbatch_renderer_bind_texture(tex, win);
    array_add(*gr2D.quads, q);
}


vertex_shader_ui_source :: #string END
#version 330 core
layout (location = 0) in vec2 p0;
layout (location = 1) in vec2 p1;
layout (location = 2) in vec2 t0;
layout (location = 3) in vec2 t1;
layout (location = 4) in vec4 color[4];
layout (location = 8) in float corner_radius;
layout (location = 9) in float edge_softness;
layout (location = 10) in float border_thickness;

uniform vec2 res;

out vec4 col;
out vec2 tc;

out VSI{
    vec4 color; //send color to next stage
    vec2 dst_pos;
    vec2 dst_center;
    vec2 dst_half_size;
    //should corner radius + softness be remapped to [0-1]? I should look better into the math at some point
    float corner_radius;
    float edge_softness;
    float border_thickness;
}vsi;
uniform sampler2D tex;

vec2 vertices[] = {
    vec2(-1.0, -1.0),
    vec2(-1.0, +1.0),
    vec2(+1.0, -1.0),
    vec2(+1.0, +1.0),
};


void main()
{
    vec2 dst_half_size = (p1 - p0) / 2;
    vec2 dst_center = (p1 + p0) / 2;
    vec2 dst_pos = vertices[gl_VertexID] * dst_half_size + dst_center;
    gl_Position = vec4(2 * dst_pos.x / res.x - 1, 2 * dst_pos.y / res.y - 1, 0.0, 1.0);
    gl_Position.y *= -1.0;

    vec2 tex_half_size = (t1 - t0) / 2;
    vec2 tex_center = (t1 + t0) / 2;
    vec2 tex_pos = vertices[gl_VertexID] * tex_half_size + tex_center;
    tc = vec2(tex_pos.x / textureSize(tex,0).x,1.0 - (tex_pos.y / textureSize(tex,0).y));
    col = color[gl_VertexID];

    vsi.dst_pos = dst_pos;
    vsi.dst_center = dst_center;
    vsi.dst_half_size = dst_half_size;
    vsi.corner_radius = corner_radius; 
    vsi.edge_softness = edge_softness;
    vsi.border_thickness = border_thickness;
} 
END
fragment_shader_ui_source :: #string END
#version 330 core
out vec4 FragColor;

float RoundedRectSDF(vec2 sample_pos,
                     vec2 rect_center,
                     vec2 rect_half_size,
                     float r)
{
  vec2 d2 = (abs(rect_center - sample_pos) -
             rect_half_size +
             vec2(r, r));
  return min(max(d2.x, d2.y), 0.0) + length(max(d2, 0.0)) - r;
}  

in vec4 col;
in vec2 tc;

in VSI {
    vec4 color; //send color to next stage
    vec2 dst_pos;
    vec2 dst_center;
    vec2 dst_half_size;
    //should corner radius + softness be remapped to [0-1]? I should look better into the math at some point
    float corner_radius;
    float edge_softness;
    float border_thickness;
}vsi;
uniform sampler2D tex;


void main()
{
    float softness = vsi.edge_softness;
    vec2 softness_padding = vec2(max(0, softness*2-1), max(0, softness*2-1));
    // sample distance
    float dist = RoundedRectSDF(vsi.dst_pos, vsi.dst_center, vsi.dst_half_size - softness_padding, vsi.corner_radius);
    // map distance => a blend factor
    float sdf_factor = 1.0 - smoothstep(0, 2*softness, dist);
    //calculate the border factor
    float border_factor = 1.f;
    // if(vsi.border_thickness != 0)
    // {
    //     vec2 interior_half_size = vsi.dst_half_size - vec2(vsi.border_thickness);
    //     float interior_radius_reduce_f = min(interior_half_size.x/vsi.dst_half_size.x, interior_half_size.y/vsi.dst_half_size.y);
    //     float interior_corner_radius = (vsi.corner_radius * interior_radius_reduce_f * interior_radius_reduce_f);
    //     float inside_d = RoundedRectSDF(vsi.dst_pos, vsi.dst_center, interior_half_size - softness_padding, interior_corner_radius);
    //     float inside_f = smoothstep(0, 2*softness, inside_d);
    //     border_factor = inside_f;
    // }
    // use sdf_factor in final color calculation
    FragColor = texture(tex, tc) * col * sdf_factor * border_factor;
}
END

