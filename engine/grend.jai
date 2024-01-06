#import "Basic";
#import "Input";
#import "System";
#import "GL";
#import "SDL";

gRendContext :: struct {
    vao : GLuint;
    //+ a command buffer?!
}
grend_ctx: gRendContext; //should we look this up or something? is this internal ONLY to the renderer??

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

gcheck_gl_shader_link_errors :: (shader_program_id : GLuint) -> bool {
    success : s32;
    glGetProgramiv (shader_program_id, GL_LINK_STATUS, *success);
    if !success
    {
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
    if !success
    {
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

gmake_gl_sp :: (vs_source : string, fs_source : string) -> GLuint, bool{
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
    win : gWin = .{.{ww, wh}, opt, null};

    
    win.window = SDL_CreateWindow("Window",
        SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, win.dim.x, win.dim.y,
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
  

gwin_update :: (win : *gWin) {
    dt := ges.dt;
    glViewport(0, 0, xx win.dim.x, xx win.dim.y);
    glClearColor(0.4, 0.4, 0.4, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    glUseProgram(shader_program);
    glBindVertexArray(grend_ctx.vao);
    glDrawElements(GL_TRIANGLES, 6,GL_UNSIGNED_INT, xx 0);

    SDL_GL_SwapWindow(win.window);
}

gwin_cleanup :: (win : *gWin){
    SDL_DestroyWindow(win.window);
    memset(win, 0, size_of(gWin));
}

vertices :: float.[
     0.5,  0.5, 0.0,  // top right
     0.5, -0.5, 0.0,  // bottom right
    -0.5, -0.5, 0.0,  // bottom left
    -0.5,  0.5, 0.0   // top left 
];
indices :: u32.[
    0, 1, 3,
    1, 2, 3
]; 

vertex_shader_source :: #string END
#version 330 core
layout (location = 0) in vec3 aPos;

void main()
{
    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}
END;


fragment_shader_source :: #string END
#version 330 core
out vec4 FragColor;

void main()
{
    FragColor = vec4(0.9f, 0.4f, 0.3f, 1.0f);
}
END
shader_program : u32;
grend_init :: () {
    SDL_Init(SDL_INIT_VIDEO);

    //should there be like, a reset vao so we can re-use
    //the same vao for ALL rendering?
    glGenVertexArrays(1, *grend_ctx.vao);
    glBindVertexArray(grend_ctx.vao);
    

    vbo : GLuint;
    glGenBuffers(1, *vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, vertices.count * size_of(float),vertices.data, GL_STATIC_DRAW);
    ebo : GLuint;
    glGenBuffers(1, *ebo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.count * size_of(float),indices.data, GL_STATIC_DRAW);

    shader_program = gmake_gl_sp(vertex_shader_source, fragment_shader_source);

    glBindBuffer(GL_ARRAY_BUFFER, vbo); //just in case
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * size_of(float), xx 0);
    glEnableVertexAttribArray(0);  
}

