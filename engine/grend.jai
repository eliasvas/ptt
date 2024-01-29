#import "Basic";
#import "Input";
#import "System";
#import "Math";
//These are the renderer's dependencies!
#import "GL";
#import "SDL";

//TODO: we need to emulate OpenGL state machine, to be able to discard VAOs and infer glVertexAttribPointers
//so we can just bind VBO/IBOs and set correct state / have a pipeline, and not mess with UGLY opengl state machine stuff.

sphere_verts,sphere_idx := #run generate_mesh(1,40,40,true);

//TODO: generate a sphere, like the texture, also use together?!
gRendContext :: struct {

    shader_program_3D : GLuint;
    sphere_vao : GLuint;
    sphere_vbo : GLuint;
    sphere_ibo : GLuint;

    debug_tex : gTextureData;
    debug_gl_tex : GLuint;

    white_tex : gTextureData;
    white_gl_tex : GLuint;

    font_gl_tex : GLuint;
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

generate_debug_texture :: (width : u32, height : u32, x_tiles : u32, y_tiles : u32, cnum : u32) -> gTextureData {
    assert(x_tiles > 0);
    assert(y_tiles > 0);
    tex_data : gTextureData;
    tex_data.data = cast (*u8) alloc (width * height * size_of(u8) * cnum, temp);
    tex_data.dim = .{xx width, xx height};
    tex_data.cnum = cnum;
    for pix : 0..width*height+1 {
        pixel_x : u32 = (pix % width);
        pixel_y : u32 = (pix / width);
        pixel_index : u32 = ( pixel_x + pixel_y * width ) * cnum;

        xtile_white : bool = pixel_x / (width / x_tiles) % 2 == 0;
        ytile_white : bool = (height-pixel_y) / (height / y_tiles) % 2 == 0;

        color := ifx xtile_white ^ ytile_white then 0 else 255;
        tex_data.data[pixel_index + 0] = xx color;
        tex_data.data[pixel_index + 1] = xx color;
        tex_data.data[pixel_index + 2] = xx color;
        if cnum == 4{
            tex_data.data[pixel_index + 3] = 255;
        }

    }
    return tex_data;
}

gmake_gl_sp :: (vs_source : string, fs_source : string) -> GLuint, bool{
    gcheck_gl_shader_link_errors :: (shader_program_id : GLuint) -> bool {
        success : s32;
        glGetProgramiv (shader_program_id, GL_LINK_STATUS, *success);
        if !success {
            info_len : s32;
            glGetProgramiv (shader_program_id, GL_INFO_LOG_LENGTH, *info_len);
            info_data := cast (*u8) alloc (info_len, temp);
            defer free(info_data);
            glGetProgramInfoLog (shader_program_id, xx info_len, xx *info_len, info_data);
            result : string;
            result.data = info_data;
            result.count = info_len;
            print("Shader link error: %\n", result);
        }
        return (success == 0);
    }
    gcheck_gl_shader_compile_errors :: (shader_id : GLuint) -> bool {
        success : s32;
        glGetShaderiv (shader_id, GL_COMPILE_STATUS, *success);
        if !success {
            info_len : s32;
            glGetShaderiv (shader_id, GL_INFO_LOG_LENGTH, *info_len);
            info_data := cast (*u8) alloc (info_len, temp);
            defer free(info_data);
            glGetShaderInfoLog (shader_id, xx info_len, xx *info_len, info_data);
            result : string;
            result.data = info_data;
            result.count = info_len;
            print("Shader compilation error: %\n", result);
        }
        return (success == 0);
    }
    sp : GLuint;

    vs : GLuint;
    vs = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vs, 1, *vs_source.data, null);
    glCompileShader(vs);
    defer glDeleteShader(vs);
    if gcheck_gl_shader_compile_errors(vs) then return sp, false;

    fs : GLuint;
    fs = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fs, 1, *fs_source.data, null);
    glCompileShader(fs);
    defer glDeleteShader(fs);
    if gcheck_gl_shader_compile_errors(fs) then return sp, false;

    sp = glCreateProgram();
    glAttachShader(sp, vs);
    glAttachShader(sp, fs);
    glLinkProgram(sp);
    if gcheck_gl_shader_link_errors(sp) then return sp, false;

    return sp, true;
}
 
//Note: This is made just to check that 3D rendering works (jk)
draw_sample_sphere_in_position :: (pos : gVec3){
    
    glBindVertexArray(grc.sphere_vao);
    glUseProgram(grc.shader_program_3D);
    aspect := 800.0 / 600.0;
    model_mat := make_translation_matrix(pos);
    cam_pos : gVec3 = .{10,xx sin(get_time()) * 50.0,0};
    view_mat := make_lookat_matrix(cam_pos,.{0,0,-30}, .{0,1,0});
    ortho_mat := make_perspective_matrix(45.0, 800.0 / 600.0, 0.1, 100.0);
    glUniformMatrix4fv(glGetUniformLocation(grc.shader_program_3D, "model"),1, GL_FALSE, xx *model_mat);
    glUniformMatrix4fv(glGetUniformLocation(grc.shader_program_3D, "view"),1, GL_FALSE, xx *view_mat);
    glUniformMatrix4fv(glGetUniformLocation(grc.shader_program_3D, "proj"),1, GL_FALSE, xx *ortho_mat);
    glActiveTexture(GL_TEXTURE0);//activate texture unit 0 before binding the texture
    glBindTexture(GL_TEXTURE_2D, grc.debug_gl_tex);
    glUniform1i(glGetUniformLocation(grc.shader_program_3D, "tex[0]"), 0);
    glUniform1f(glGetUniformLocation(grc.shader_program_3D, "col_mod"), xx abs(sin(get_time()/2.0)) );
    glDrawElements(GL_TRIANGLES, sphere_idx.count,GL_UNSIGNED_INT, xx 0);
    //glDrawArrays(GL_TRIANGLES, 0, sphere_verts.count);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}
vertex_shader_3D_source :: #string END
#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNorm;
layout (location = 2) in vec2 aTexCoord;

out vec4 col;
out vec2 tc;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main()
{
    col = vec4(aNorm,1.0);
    tc = aTexCoord;
    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    gl_Position = proj * view * model * vec4(aPos, 1.0);
}
END;
fragment_shader_3D_source :: #string END
#version 330 core
out vec4 FragColor;
in vec2 tc;
uniform float col_mod;
uniform sampler2D tex;

in vec4 col;

void main()
{
    FragColor = texture(tex, tc) * (col_mod/2 + 0.5);
}
END

grend_init :: (window : *gWin) {
    SDL_Init(SDL_INIT_VIDEO);
    grc.default_atlas = gfont_atlas_generate();
    grc.window_ref = window;
    glEnable(GL_DEPTH_TEST);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    gbatch_renderer_2d_init();

    //should there be like, a reset vao so we can re-use
    //the same vao for ALL rendering?
    glGenVertexArrays(1, *grc.sphere_vao);
    glBindVertexArray(grc.sphere_vao);
    

    //debug sphere initialization
    glGenBuffers(1, *grc.sphere_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, grc.sphere_vbo);
    glBufferData(GL_ARRAY_BUFFER, sphere_verts.count * size_of(gVertex),sphere_verts.data, GL_STATIC_DRAW);
    glGenBuffers(1, *grc.sphere_ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, grc.sphere_ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sphere_idx.count * size_of(u32),sphere_idx.data, GL_STATIC_DRAW);
    grc.shader_program_3D = gmake_gl_sp(vertex_shader_3D_source, fragment_shader_3D_source);
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, size_of(gVertex), xx offset_of(gVertex, #code pos));
    glVertexAttribDivisor(1, 0);
    glEnableVertexAttribArray(0);   
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, size_of(gVertex), xx offset_of(gVertex, #code norm));
    glVertexAttribDivisor(1, 0);
    glEnableVertexAttribArray(1); 
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, size_of(gVertex), xx offset_of(gVertex, #code tex_coord));
    glVertexAttribDivisor(2, 0);
    glEnableVertexAttribArray(2);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    //debug texture initialization
    glGenTextures(1, *grc.debug_gl_tex);
    glBindTexture(GL_TEXTURE_2D, grc.debug_gl_tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);	
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    grc.debug_tex = generate_debug_texture(400, 400, 8, 8, 4);
    //the texture data is in GPU memory via glTexImage2D, we can free after
    defer free(grc.debug_tex.data);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 400, 400, 0, GL_RGBA, GL_UNSIGNED_BYTE, grc.debug_tex.data);
    glGenerateMipmap(GL_TEXTURE_2D);

    //white texture initialization
    glGenTextures(1, *grc.white_gl_tex);
    glBindTexture(GL_TEXTURE_2D, grc.white_gl_tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);	
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    grc.white_tex = generate_debug_texture(400, 400, 1, 1, 4);
    //the texture data is in GPU memory via glTexImage2D, we can free after
    defer free(grc.white_tex.data);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 400, 400, 0, GL_RGBA, GL_UNSIGNED_BYTE, grc.white_tex.data);
    glGenerateMipmap(GL_TEXTURE_2D);


    //font atlas initialization
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    glGenTextures(1, *grc.font_gl_tex);
    glBindTexture(GL_TEXTURE_2D, grc.font_gl_tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_R, GL_RED);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_G, GL_RED);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_B, GL_RED);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_A, GL_RED);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, xx grc.default_atlas.size_x, xx grc.default_atlas.size_y, 0, GL_RED, GL_UNSIGNED_BYTE, grc.default_atlas.bitmap);
    glGenerateMipmap(GL_TEXTURE_2D);
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
    win.window = SDL_CreateWindow("Window", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
                                    xx win.dim.x, xx win.dim.y, sdl_win_args);

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

    //draw_sample_sphere_in_position(.{0,0,-30});
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

gBatchRenderer2D :: struct {
    quads : [..] gQuadInstance;

    //OpenGL garbo
    vao : GLuint;
    vbo : GLuint;
    sp : GLuint;

    last_bound_tex : GLuint;
}

gQuadInstance :: struct {
    p0  : gVec2; //position in window coords
    p1  : gVec2;
    t0  : gVec2; //tex coord in texture's units
    t1  : gVec2;
    col0 : gVec4;
    col1 : gVec4;
    col2 : gVec4;
    col3 : gVec4;
    corner_radius : float;
    edge_softness : float;
    border_thickness : float;
}

gbatch_renderer_2d_init :: () {
    gr2D.sp = gmake_gl_sp(vertex_shader_ui_source, fragment_shader_ui_source);
    glGenVertexArrays(1, *gr2D.vao);
    glBindVertexArray(gr2D.vao);
    glGenBuffers(1, *gr2D.vbo);
    glBindBuffer(GL_ARRAY_BUFFER, gr2D.vbo);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code p0));
    glVertexAttribDivisor(0, 1);
    glEnableVertexAttribArray(0); 
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code p1));
    glVertexAttribDivisor(1, 1);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code t0));
    glVertexAttribDivisor(2, 1);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(3, 2, GL_FLOAT, GL_FALSE, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code t1));
    glVertexAttribDivisor(3, 1);
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(4, 4, GL_FLOAT, GL_FALSE, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code col0));
    glVertexAttribDivisor(4, 1);
    glEnableVertexAttribArray(4);
    glVertexAttribPointer(5, 4, GL_FLOAT, GL_FALSE, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code col1));
    glVertexAttribDivisor(5, 1);
    glEnableVertexAttribArray(5);
    glVertexAttribPointer(6, 4, GL_FLOAT, GL_FALSE, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code col2));
    glVertexAttribDivisor(6, 1);
    glEnableVertexAttribArray(6);
    glVertexAttribPointer(7, 4, GL_FLOAT, GL_FALSE, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code col3));
    glVertexAttribDivisor(7, 1);
    glEnableVertexAttribArray(7);
    glVertexAttribPointer(8, 1, GL_FLOAT, GL_FALSE, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code corner_radius));
    glVertexAttribDivisor(8, 1);
    glEnableVertexAttribArray(8);
    glVertexAttribPointer(9, 1, GL_FLOAT, GL_FALSE, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code edge_softness));
    glVertexAttribDivisor(9, 1);
    glEnableVertexAttribArray(9);
    glVertexAttribPointer(10, 1, GL_FLOAT, GL_FALSE, size_of(gQuadInstance), xx offset_of(gQuadInstance, #code border_thickness));
    glVertexAttribDivisor(10, 1);
    glEnableVertexAttribArray(10);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

}

gbatch_renderer_2d_render :: () {
    glDisable(GL_DEPTH_TEST);
    // gbatch_renderer_bind_texture(grc.white_gl_tex);
    // gbatch_renderer_push_quad(.{.{0,0},.{302,302}, .{0,0}, .{0,0},.{1,1,1,1},.{1,1,1,1},.{1,1,1,1},.{1,1,1,1},10,3,0.0});
    // gbatch_renderer_bind_texture(grc.debug_gl_tex);
    // gbatch_renderer_push_quad(.{.{2,2},.{300,300}, .{0,0}, .{400,400},.{0,1,0,1},.{1,0,1,1},.{1,1,0,1},.{1,0,1,1},10,3,0.0});
    // gbatch_renderer_bind_texture(grc.font_gl_tex);
    // glyph := gfont_atlas_get_glyph_for_character(*grc.default_atlas, #char "e");
    // print("glyph e : %\n",glyph);
    // glyph2 := gfont_atlas_get_glyph_for_character(*grc.default_atlas, #char "H");
    // print("glyph H : %\n",glyph2);
    // scale := 2.0;
    // gbatch_renderer_bind_texture(grc.white_gl_tex);
    // gbatch_renderer_push_quad(.{.{300,100},.{300.0 + glyph.size_x * scale ,100.0 + glyph.size_y * scale}, .{xx glyph.tc_x, xx glyph.tc_y}, .{xx (glyph.tc_x + xx glyph.size_x), xx (glyph.tc_y + xx glyph.size_y)},.{1,0,0,1},.{1,0,0,1},.{1,0,0,1},.{1,0,0,1},0,0,0});
    // gbatch_renderer_bind_texture(grc.font_gl_tex);
    // gbatch_renderer_push_quad(.{.{300,100},.{300.0 + glyph.size_x * scale ,100.0 + glyph.size_y * scale}, .{xx glyph.tc_x, xx glyph.tc_y}, .{xx (glyph.tc_x + xx glyph.size_x), xx (glyph.tc_y + xx glyph.size_y)},.{1,1,1,1},.{1,1,1,1},.{1,1,1,1},.{1,1,1,1},0,0,0});

    // hello_width, hello_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,"Hello There",1.0);
    // render_basic_string("Hello There",xx (grc.window_ref.dim.x/2 - hello_width/2),xx( grc.window_ref.dim.y /2 - hello_height/2), 1.0,U32_MAX /2, true);

    if (gui_button("Click me!", .{300,300})) {
        print("Button click!");
    }

    fps_scale := 0.5;
    fps_counter := sprint("%", formatFloat(1000.0/ges.dt, width=1, trailing_width=0, zero_removal=.NO));
    defer free(fps_counter.data);
    fps_width, fps_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,fps_counter,fps_scale);
    render_basic_string(fps_counter, xx (grc.window_ref.dim.x - fps_width), 0, fps_scale, (U32_MAX << 24) );
    gbatch_renderer_flush();

}

//TODO: color shifting don't work right (read up a bit on jai binary operations prb)
render_basic_string :: (s : string, pos_x : s32, pos_y : s32, scale : float,text_color : u32 = U32_MAX, render_box : bool = false) {
    start := gVec2.{xx pos_x,xx pos_y};
    text_width, text_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,s,scale);
    if render_box {
        gbatch_renderer_bind_texture(grc.white_gl_tex);
        pad_x := 20;
        pad_y := 20;
        gbatch_renderer_push_quad(.{.{xx (start.x-pad_x),xx (start.y - pad_y)},.{xx(start.x + text_width + pad_x), xx(start.y + text_height + pad_y)}, .{0,0}, .{0,0},.{1,0,0.5,1},.{1,0,0.5,1},.{1,0,0.5,1},.{1,0,0.5,1},10,6,0});
    }
    gbatch_renderer_bind_texture(grc.font_gl_tex);
    cur_pos := start;

    biggest_size_y := 0;
    for i : 0..s.count-1 {
        glyph := gfont_atlas_get_glyph_for_character(*grc.default_atlas, s[i]);
        biggest_size_y = max(biggest_size_y, glyph.size_y);
    }
    for i : 0..s.count-1 {
        glyph := gfont_atlas_get_glyph_for_character(*grc.default_atlas, s[i]);
        cur_pos.y = start.y + biggest_size_y * scale - glyph.size_y * scale;// + (glyph.size_y - glyph.bearing_y);
        bearing_x := ifx i == 0 then 0 else glyph.bearing_x;
        tex_r := ((text_color >> (32 - 8)) & 0xffff) / 255.0;
        tex_g := ((text_color >> (32 - 16)) & 0xffff) / 255.0;
        tex_b := ((text_color >> (32 - 24)) & 0xffff) / 255.0;
        gbatch_renderer_push_quad(.{.{xx (cur_pos.x + bearing_x * scale),xx cur_pos.y},.{xx(cur_pos.x + bearing_x * scale + glyph.size_x * scale), xx(cur_pos.y + glyph.size_y * scale)}, .{xx glyph.tc_x, xx glyph.tc_y}, .{xx (glyph.tc_x + xx glyph.size_x), xx (glyph.tc_y + xx glyph.size_y)},.{tex_r,tex_g,tex_b,1},.{tex_r,tex_g,tex_b,1},.{tex_r,tex_g,tex_b,1},.{tex_r,tex_g,tex_b,1},0,0,0});
        cur_pos.x += glyph.advance * scale;
    }

}

gbatch_renderer_flush :: () {
    glBindVertexArray(gr2D.vao);
    glBindBuffer(GL_ARRAY_BUFFER, gr2D.vbo);
    glBufferData(GL_ARRAY_BUFFER, gr2D.quads.count * size_of(gQuadInstance),gr2D.quads.data, GL_STREAM_DRAW);
    glUseProgram(gr2D.sp);
    glUniform2f(glGetUniformLocation(gr2D.sp, "res"), xx grc.window_ref.dim.x, xx grc.window_ref.dim.y);
    glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, xx gr2D.quads.count);
    gr2D.quads.count = 0;
}
//TODO: make this engine texture, not OpenGL
gbatch_renderer_bind_texture :: (tex : GLuint) {
    if (tex != gr2D.last_bound_tex) {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, gr2D.last_bound_tex);
        glUniform1i(glGetUniformLocation(gr2D.sp, "tex"), 0);
        gbatch_renderer_flush();
    }
    gr2D.last_bound_tex = tex;
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, gr2D.last_bound_tex);
    glUniform1i(glGetUniformLocation(gr2D.sp, "tex"), 0);

}

gbatch_renderer_push_quad :: (q : gQuadInstance, tex : GLuint = 0) {
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

//TODO: put all these in uniforms in a fucking struct
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

