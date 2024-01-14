#import "Basic";
#import "Input";
#import "System";
#import "Math";
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

    shader_program_ui : GLuint;
    ui_vao : GLuint;
    //ui_vbo : GLuint;
    ui_instance_vbo : GLuint;
    white_tex : gTextureData;
    white_gl_tex : GLuint;
    //+ a command buffer?!
}

//NOTE: Should this be called render DEVICE instead of Context?
grc: gRendContext;
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


gwin_create :: (ww : s32, wh : s32, opt : GWIN_OPT) -> gWin {
    win : gWin = .{.{xx ww, xx wh}, opt, null};

    
    win.window = SDL_CreateWindow("Window",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, xx win.dim.x, xx win.dim.y,
        SDL_WINDOW_OPENGL|SDL_WINDOW_SHOWN|SDL_WINDOW_RESIZABLE);

    if win.window == null {
        print("Could not create window: %\n", to_string(SDL_GetError()));
    }else {
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);

        gl_context : SDL_GLContext = SDL_GL_CreateContext(win.window);
        gl_load(*gl, SDL_GL_GetProcAddress);
        //rdr := SDL_CreateRenderer( win.window, -1, 0);
    }
    print("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    print("GL Version = %\n", to_string(glGetString(GL_VERSION)));
    return win;
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
    glUniform1i(glGetUniformLocation(grc.shader_program_3D, "tex"), 0);
    glUniform1f(glGetUniformLocation(grc.shader_program_3D, "col_mod"), xx abs(sin(get_time()/2.0)) );
    glDrawElements(GL_TRIANGLES, sphere_idx.count,GL_UNSIGNED_INT, xx 0);
    //glDrawArrays(GL_TRIANGLES, 0, sphere_verts.count);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
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
    glClearColor(0.2, 0.2, 0.2, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    draw_sample_sphere_in_position(.{0,0,-30});

    //draw UI
    glBindVertexArray(grc.ui_vao);
    glUseProgram(grc.shader_program_ui);
    glUniform2f(glGetUniformLocation(grc.shader_program_ui, "res"), xx 800.0, xx 600.0);
    glActiveTexture(GL_TEXTURE0);//activate texture unit 0 before binding the texture
    glBindTexture(GL_TEXTURE_2D, grc.debug_gl_tex);
    glUniform1i(glGetUniformLocation(grc.shader_program_ui, "tex"), 0);
    glDrawArraysInstanced(GL_TRIANGLE_STRIP, 0, 4, xx 2);

    SDL_GL_SwapWindow(win.window);
}

gwin_cleanup :: (win : *gWin){
    SDL_DestroyWindow(win.window);
    memset(win, 0, size_of(gWin));
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

vertex_shader_ui_source :: #string END
#version 330 core
layout (location = 0) in vec2 p0;
layout (location = 1) in vec2 p1;
layout (location = 2) in vec2 t0;
layout (location = 3) in vec2 t1;
layout (location = 4) in vec4 color[4];

uniform vec2 res;

out vec4 col;
out vec2 tc;
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
    tc = vec2(2 * tex_pos.x / textureSize(tex,0).x, 2 * tex_pos.y / textureSize(tex,0).y);
    col = color[gl_VertexID];
} 
END
fragment_shader_ui_source :: #string END
#version 330 core
out vec4 FragColor;
  
in vec4 col;
in vec2 tc;

uniform sampler2D tex;

void main()
{
    FragColor = texture(tex, tc) * col;
}
END


QuadInstance :: struct {
    p0  : gVec2; //position in window coords
    p1  : gVec2;
    t0  : gVec2; //tex coord in texture's units
    t1  : gVec2;
    col0 : gVec4;
    col1 : gVec4;
    col2 : gVec4;
    col3 : gVec4;
}

grend_init :: () {
    SDL_Init(SDL_INIT_VIDEO);
    glEnable(GL_DEPTH_TEST);

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

    //quad initialization
    grc.shader_program_ui = gmake_gl_sp(vertex_shader_ui_source, fragment_shader_ui_source);
    glGenVertexArrays(1, *grc.ui_vao);
    glBindVertexArray(grc.ui_vao);
    offsets :: QuadInstance.[ .{.{0,0},.{300,300}, .{0,0}, .{400,400},.{1,0,0,1},.{0,1,0,1},.{0,0,1,1},.{0,0,0,1}}, .{.{300,300},.{400,400}, .{0,0}, .{200,400},.{1,0,1,1}, .{1,0,1,1},.{1,1,1,1},.{1,1,1,1}}];
    glGenBuffers(1, *grc.ui_instance_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, grc.ui_instance_vbo);
    glBufferData(GL_ARRAY_BUFFER, offsets.count * size_of(QuadInstance),offsets.data, GL_STREAM_DRAW);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, size_of(QuadInstance), xx offset_of(QuadInstance, #code p0));
    glVertexAttribDivisor(0, 1);
    glEnableVertexAttribArray(0); 
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, size_of(QuadInstance), xx offset_of(QuadInstance, #code p1));
    glVertexAttribDivisor(1, 1);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, size_of(QuadInstance), xx offset_of(QuadInstance, #code t0));
    glVertexAttribDivisor(2, 1);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(3, 2, GL_FLOAT, GL_FALSE, size_of(QuadInstance), xx offset_of(QuadInstance, #code t1));
    glVertexAttribDivisor(3, 1);
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(4, 4, GL_FLOAT, GL_FALSE, size_of(QuadInstance), xx offset_of(QuadInstance, #code col0));
    glVertexAttribDivisor(4, 1);
    glEnableVertexAttribArray(4);
    glVertexAttribPointer(5, 4, GL_FLOAT, GL_FALSE, size_of(QuadInstance), xx offset_of(QuadInstance, #code col1));
    glVertexAttribDivisor(5, 1);
    glEnableVertexAttribArray(5);
    glVertexAttribPointer(6, 4, GL_FLOAT, GL_FALSE, size_of(QuadInstance), xx offset_of(QuadInstance, #code col2));
    glVertexAttribDivisor(6, 1);
    glEnableVertexAttribArray(6);
    glVertexAttribPointer(7, 4, GL_FLOAT, GL_FALSE, size_of(QuadInstance), xx offset_of(QuadInstance, #code col3));
    glVertexAttribDivisor(7, 1);
    glEnableVertexAttribArray(7);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);


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
    //glGenerateMipmap(GL_TEXTURE_2D);

}

