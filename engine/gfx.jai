#import "GL";
#import "SDL";

//This will* be a _graphics API abstraction_ for OpenGL making it a bit _saner_ to use
//The gist is we hold all OpenGL global state and do correct transitions, also no more VAOs! 
//This might help https://developer.nvidia.com/opengl-vulkan
//also this https://hacksoflife.blogspot.com/2015/04/the-opengl-impedance-mismatch.html
//TODO: remove openGL from UI code, and make it use dis

//Sample usage:
/*
vertices,indices := gobj_read("filepath.obj");
vertex_attribs := .[.{float, 3, 0 * size_of(float)}, .{float, 3, 3 * size_of(float)}];
shader_obj : gfxShaderID = gshader_create(".vert", ".frag", vert_attribs);
vbo : gfxBufID = gbuf_create(*vertices, VBO);
ibo : gfxBufID = gbuf_create(*indices, IBO);

..

gfxBindVBO(vbo);
gfxBindIBO(ibo);
gfxBindShaderObject(shader_obj);
gfxRenderIndexed(gfxTriangles);

*/

sphere_verts,sphere_idx := #run generate_mesh(1,40,40,true);
gfxContext :: struct {
    vao : GLuint;

    shader_program_3D : GLuint;

    sphere_vbo : GLuint;
    sphere_ibo : GLuint;

    debug_gl_tex : GLuint;
    debug_tex : gTextureData;
}

gfx : gfxContext;

gfx_context_init :: () {
    glGenVertexArrays(1, *gfx.vao);
    glBindVertexArray(gfx.vao);


    //debug sphere initialization
    glGenBuffers(1, *gfx.sphere_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, gfx.sphere_vbo);
    glBufferData(GL_ARRAY_BUFFER, sphere_verts.count * size_of(gVertex),sphere_verts.data, GL_STATIC_DRAW);
    glGenBuffers(1, *gfx.sphere_ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, gfx.sphere_ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sphere_idx.count * size_of(u32),sphere_idx.data, GL_STATIC_DRAW);
    gfx.shader_program_3D = gmake_gl_sp(vertex_shader_3D_source, fragment_shader_3D_source);
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
    glGenTextures(1, *gfx.debug_gl_tex);
    glBindTexture(GL_TEXTURE_2D, gfx.debug_gl_tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);	
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    gfx.debug_tex = generate_debug_texture(400, 400, 8, 8, 4);
    //the texture data is in GPU memory via glTexImage2D, we can free after
    defer free(gfx.debug_tex.data);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 400, 400, 0, GL_RGBA, GL_UNSIGNED_BYTE, gfx.debug_tex.data);
    glGenerateMipmap(GL_TEXTURE_2D);

 
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

gfxBufType  :: enum {
    VERTEX;
    INDEX;
}

gfxBUF :: struct {
    //--OpenGL specifnig
    vbo : GLuint;
}

gfx_draw_sample_scene :: () {
    pos : gVec3 = .{0,0,-30};
    glClearColor(0.1, 0.1, 0.1, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glDisable(GL_BLEND);

    glBindVertexArray(gfx.vao);
    glUseProgram(gfx.shader_program_3D);
    aspect := 800.0 / 600.0;
    model_mat := make_translation_matrix(pos);
    cam_pos : gVec3 = .{10,xx sin(get_time()) * 50.0,0};
    view_mat := make_lookat_matrix(cam_pos,.{0,0,-30}, .{0,1,0});
    ortho_mat := make_perspective_matrix(45.0, 800.0 / 600.0, 0.1, 100.0);
    glUniformMatrix4fv(glGetUniformLocation(gfx.shader_program_3D, "model"),1, GL_FALSE, xx *model_mat);
    glUniformMatrix4fv(glGetUniformLocation(gfx.shader_program_3D, "view"),1, GL_FALSE, xx *view_mat);
    glUniformMatrix4fv(glGetUniformLocation(gfx.shader_program_3D, "proj"),1, GL_FALSE, xx *ortho_mat);
    glActiveTexture(GL_TEXTURE0);//activate texture unit 0 before binding the texture
    glBindTexture(GL_TEXTURE_2D, gfx.debug_gl_tex);
    glUniform1i(glGetUniformLocation(gfx.shader_program_3D, "tex"), 0);
    glUniform1f(glGetUniformLocation(gfx.shader_program_3D, "col_mod"), xx abs(sin(get_time()/2.0)) );
    glDrawElements(GL_TRIANGLES, sphere_idx.count,GL_UNSIGNED_INT, xx 0);
    //glDrawArrays(GL_TRIANGLES, 0, sphere_verts.count);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
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

gfxSP :: struct {
    program : GLuint;
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