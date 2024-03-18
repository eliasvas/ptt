#import "GL";
#import "SDL";

//based on this: https://floooh.github.io/2020/02/17/sokol-gfx-backend-tour-gl.html
//TODO: remove openGL from UI code, and make it use dis
//TODO: also https://stackoverflow.com/questions/14249634/opengl-vaos-and-multiple-buffers AND instanced attribs

/*
A graphics API abstraction layer over-OpenGL inspired by sokol-gfx 
Main difference with openGL is no global state and NO VAOS!
Because of its OpenGL 3.3 compliance, this is a GREAT compatibility layer
*/

sphere_verts,sphere_idx := #run generate_sphere(1,40,40,true);
oglContext :: struct {
    vao : GLuint;
    def_fbo : GLuint; //the default framebuffer (framebuffer 0?)

    //shader_program_3D : GLuint;
    sp3D : oglShaderObject;

    sphere_vbo : oglBuf;
    sphere_ibo : oglBuf;

    debug_gl_tex : GLuint;
    debug_tex : gTextureData;
}

//GLOBAL holding test stuff like vbo/textues, 
//in the future it should have only a global vao (for implementation)
//and maybe the default fbo
ogl_ctx : oglContext;

ogl_init :: () {
    glGenVertexArrays(1, *ogl_ctx.vao);
    glBindVertexArray(ogl_ctx.vao);

    ogl_ctx.sphere_ibo = ogl_make_buffer(.INDEX, sphere_idx.data, sphere_idx.count, size_of(u32));
    ogl_bind_index_buffer(*ogl_ctx.sphere_ibo);
    ogl_ctx.sphere_vbo = ogl_make_buffer(.VERTEX, sphere_verts.data, sphere_verts.count, size_of(gVertex));
    ogl_bind_vertex_buffer(*ogl_ctx.sphere_vbo);

    ogl_shader_object_init(*ogl_ctx.sp3D,vertex_shader_3D_source, fragment_shader_3D_source);

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
    glGenTextures(1, *ogl_ctx.debug_gl_tex);
    glBindTexture(GL_TEXTURE_2D, ogl_ctx.debug_gl_tex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);	
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    ogl_ctx.debug_tex = generate_debug_texture(400, 400, 8, 8, 4);
    //the texture data is in GPU memory via glTexImage2D, we can free after
    defer free(ogl_ctx.debug_tex.data);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 400, 400, 0, GL_RGBA, GL_UNSIGNED_BYTE, ogl_ctx.debug_tex.data);
    glGenerateMipmap(GL_TEXTURE_2D);

 
}

//TODO: this procgen should be separate file
generate_debug_texture :: (width : u32, height : u32, x_tiles : u32, y_tiles : u32, cnum : u32) -> gTextureData {
    assert(x_tiles > 0);
    assert(y_tiles > 0);
    tex_data : gTextureData;
    tex_data.data = cast (*u8) alloc (width * height * size_of(u8) * cnum);
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

oglBufType  :: enum {
    VERTEX;
    INDEX;
}

oglBuf :: struct {
    count : s64;
    size : s64; //in bytes
    type : oglBufType;

    //OpenGL State 
    handle : GLuint;
}

oglShaderAttrib :: struct {
    //OpenGL State 
    vbo_index : s8; // -1 if attrib empty 
    divisor : s8;  // -1 if not initialized 
    stride : u8;
    size : u8;
    norm : u8;
    offset : int;
    type : GLenum;
}

oglShaderObject :: struct {
    attribs : [16] oglShaderAttrib; //this should be set once!
    //OpenGL State 
    gl_program : GLuint;
}
oglShaderUniformType :: enum {
    FLOAT;
    INT;
    VEC2;
    VEC3;
    VEC4;
    MAT4;
};

ogl_reset_gl :: () {
    glBindVertexArray(0);
}

//----------------------------------------------------------------------------
// - oglShaderObject 
// TODO: shader attribs don't work, we just globally se like in openGL, we need to fix this! (maybe slots?) 
// TODO: vertex attributes should be stored here no?
//----------------------------------------------------------------------------

ogl_bind_shader_object :: (so : *oglShaderObject){
    glUseProgram(so.gl_program);
}

ogl_shader_object_set_uniform :: (so : *oglShaderObject, uniform_name : string, type : oglShaderUniformType, val : *Any){
    if type == {
        case oglShaderUniformType.INT;
            glUniform1iv(glGetUniformLocation(so.gl_program, uniform_name.data), 1, cast(*s32)val);
        case oglShaderUniformType.FLOAT;
            glUniform1fv(glGetUniformLocation(so.gl_program, uniform_name.data), 1, cast(*float)val);
        case oglShaderUniformType.VEC2;
            glUniform2fv(glGetUniformLocation(so.gl_program, uniform_name.data), 1, cast(*float)val);
        case oglShaderUniformType.VEC3;
            glUniform3fv(glGetUniformLocation(so.gl_program, uniform_name.data), 1, cast(*float)val);
        case oglShaderUniformType.VEC4;
            glUniform4fv(glGetUniformLocation(so.gl_program, uniform_name.data), 1, cast(*float)val);
        case oglShaderUniformType.MAT4;
            glUniformMatrix4fv(glGetUniformLocation(so.gl_program, uniform_name.data), 1, GL_FALSE, cast(*float)val);
        case;
            print("uknown shader type\n");
    }
}

ogl_shader_object_init :: (so : *oglShaderObject, vs_source : string, fs_source : string) ->  bool{
    res : bool;
    so.gl_program,res = gmake_gl_sp(vertex_shader_3D_source, fragment_shader_3D_source);
    return res;
}

gmake_gl_sp :: (vs_source : string, fs_source : string) -> GLuint, bool{
    gcheck_gl_shader_link_errors :: (shader_program_id : GLuint) -> bool {
        success : s32;
        glGetProgramiv (shader_program_id, GL_LINK_STATUS, *success);
        if !success {
            info_len : s32;
            glGetProgramiv (shader_program_id, GL_INFO_LOG_LENGTH, *info_len);
            info_data := cast (*u8) alloc (info_len);
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
            info_data := cast (*u8) alloc (info_len);
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

//----------------------------------------------------------------------------
// - oglBuf
//----------------------------------------------------------------------------

//The data will be written in GPU memory immediately, so the pointer can be freed right after
ogl_make_buffer :: (type : oglBufType, data : *void, data_count : u32, data_size : u32) -> oglBuf {
    buf : oglBuf;
    buf.type = type;
    buf.count = data_count;
    buf.size = data_size * data_count;

    buffer_type := ifx type == .VERTEX then GL_ARRAY_BUFFER else GL_ELEMENT_ARRAY_BUFFER;

    glGenBuffers(1, *buf.handle);
    glBindBuffer(xx buffer_type, buf.handle);
    glBufferData(xx buffer_type, buf.size,data, GL_STATIC_DRAW); //TODO: make a type for DYNAMIC/STATIC/STREAM?
    glBindBuffer(xx buffer_type, 0);
    return buf;
}

ogl_bind_index_buffer :: (b : *oglBuf) {
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, b.handle);
}

ogl_bind_vertex_buffer :: (b : *oglBuf) {
    glBindBuffer(GL_ARRAY_BUFFER, b.handle);
}

ogl_draw_sample_scene :: () {

    gcam_update(*camera,xx ges.dt);
    pos : gVec3 = .{xx sin(2*seconds_since_init()),0,-10};

    glBindVertexArray(ogl_ctx.vao);
    aspect := 800.0 / 600.0; //TODO we should get fbo width height via engine context or sth??
    model_mat := make_translation_matrix(pos);
    view_mat := gcam_make_lookat_matrix(*camera);
    proj_mat := make_perspective_matrix(45.0, aspect, 0.001, 50.0);
    
    ogl_bind_shader_object(*ogl_ctx.sp3D);
    ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "model", oglShaderUniformType.MAT4, xx *model_mat);
    ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "view", oglShaderUniformType.MAT4, xx *view_mat);
    ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "proj", oglShaderUniformType.MAT4, xx *proj_mat);
    glActiveTexture(GL_TEXTURE0);//activate texture unit 0 before binding the texture
    glBindTexture(GL_TEXTURE_2D, ogl_ctx.debug_gl_tex);
    tex : int = 0;
    ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "tex", oglShaderUniformType.INT, xx *tex);
    glDrawElements(GL_TRIANGLES, sphere_idx.count,GL_UNSIGNED_INT, xx 0);

    //glDrawArrays(GL_TRIANGLES, 0, sphere_verts.count);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}


//----------------------------------------------------------------------------
// - SHADERS
//----------------------------------------------------------------------------
 
vertex_shader_3D_source :: #string END
#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNorm;
layout (location = 2) in vec2 aTexCoord;

out vec4 col;
out vec2 tc;
out vec3 world_pos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main()
{
    col = vec4(aNorm,1.0);
    tc = aTexCoord;
    //gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    gl_Position = proj * view * model * vec4(aPos, 1.0);
    world_pos = vec3(model * vec4(aPos, 1.0));
}
END;
fragment_shader_3D_source :: #string END
#version 330 core
out vec4 FragColor;
in vec2 tc;
in vec3 world_pos;
uniform float col_mod;
uniform sampler2D tex;

in vec4 col;

void main()
{
    FragColor = texture(tex, tc) * vec4(1,1,1,1);
    //FragColor.y = world_pos.y; 
    //FragColor.x = 0;
    //FragColor.y = 0;
    //FragColor.x = world_pos.x; 
    //FragColor.z = 0;
}
END