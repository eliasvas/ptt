#import "GL";
#import "SDL";
#import "stb_image";

//based on this: https://floooh.github.io/2020/02/17/sokol-gfx-backend-tour-gl.html

//TODO: right now we don't really handle global state, we SHOULD
//TODO: all 'objects' should have same interface e.g init/create/make delete/cleanup/dealloc JUST CHOOSE ONE
//TODO: all USER facing calls e.g bind_vertex_buffer should at least have a pointer to the oglContext for state-keeping 
//TODO: also after that make alloc dealloc ofor all ogl's data types, we have some garbare rn i think
//TODO: viewport/scissor/clearing

/*
A graphics API abstraction layer over-OpenGL inspired by sokol-gfx 
Main difference with openGL is no global state and NO VAOS!
Because of its OpenGL 3.3 compliance, this is a GREAT compatibility layer
*/

cube_verts,cube_idx := #run generate_cube();
sphere_verts_old,sphere_idx_old := #run generate_sphere(1,40,40,true);
sphere_verts,sphere_idx := #run generate_cube_sphere(1.4,true);

oglContext :: struct {
    vao : GLuint;

    //shader_program_3D : GLuint;
    sp3D : oglShaderObject;
    fade_sp : oglShaderObject;
    full_sp : oglShaderObject;

    fade_vbo : oglBuf;

    sphere_vbo : oglBuf;
    sphere_ibo : oglBuf;

    cube_vbo : oglBuf;
    cube_ibo : oglBuf;


    debug_tex : oglImage;
    def_rt : oglImage;

    MAX_TEX_SLOTS :: 8;
    MAX_ATTRIBS   :: 16;
}

//GLOBAL holding test stuff like vbo/textues, 
//in the future it should have only a global vao (for implementation)
//and maybe the default fbo
ogl_ctx : oglContext;


ogl_init :: () {
    glGenVertexArrays(1, *ogl_ctx.vao);
    ogl_clear_all();

    ogl_ctx.sphere_ibo = ogl_make_buffer(.INDEX, sphere_idx.data, sphere_idx.count, size_of(u32));
    ogl_ctx.sphere_vbo = ogl_make_buffer(.VERTEX, sphere_verts.data, sphere_verts.count, size_of(gVertex));
    ogl_ctx.cube_vbo = ogl_make_buffer(.VERTEX, cube_verts.data, cube_verts.count, size_of(gVertex));
    //ogl_ctx.cube_ibo = ogl_make_buffer(.INDEX, cube_idx.data, cube_idx.count, size_of(u32));

    ogl_shader_object_init(*ogl_ctx.sp3D,vertex_shader_3D_source, fragment_shader_3D_source);
    ogl_shader_object_add_attrib(*ogl_ctx.sp3D, ogl_make_attrib(0, oglShaderDataType.VEC3, size_of(gVertex), xx offset_of(gVertex, #code pos)));
    ogl_shader_object_add_attrib(*ogl_ctx.sp3D, ogl_make_attrib(1, oglShaderDataType.VEC3, size_of(gVertex), xx offset_of(gVertex, #code norm)));
    ogl_shader_object_add_attrib(*ogl_ctx.sp3D, ogl_make_attrib(2, oglShaderDataType.VEC2, size_of(gVertex), xx offset_of(gVertex, #code tex_coord)));

    ogl_ctx.fade_vbo = ogl_make_buffer(.VERTEX, null, 0, 0);
    ogl_shader_object_init(*ogl_ctx.fade_sp, vert_fade_sp_source, frag_fade_sp_source);
    ogl_shader_object_init(*ogl_ctx.full_sp, vert_full_sp_source, frag_full_sp_source);
    //debug texture initialization
    t_w : u32 = 400;
    t_h : u32 = 400;
    debug_tex := generate_debug_texture(t_w, t_h, 8, 8, 4);
    defer free(debug_tex.data);
    ogl_image_init(*ogl_ctx.debug_tex, debug_tex.data, t_w, t_h, oglImageFormat.RGBA8U);
    //TODO: should this be resized on higher resolutions??? (yes)
    ogl_image_init(*ogl_ctx.def_rt, null, xx grc.window_ref.dim.x, xx grc.window_ref.dim.y, oglImageFormat.RGBA32F);

    ogl_clear_all();
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

generate_texture_from_data :: (data : *u8, count : s64) -> gTextureData {
    tex_data : gTextureData;
    w : s32;
    h : s32;
    chan : s32;
    //stbi_set_flip_vertically_on_load(1);
    image_data := stbi_load_from_memory(data, xx count, *w, *h, *chan, 0);
    tex_data.dim.x = cast(float)w;
    tex_data.dim.y = cast(float)h;
    tex_data.cnum = xx chan;
    tex_data.data = xx image_data;
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
    vbo_idx : u32;
    stride : u32;
    offset : u32;
    type : oglShaderDataType;
    instanced : bool;
}

ogl_clear_all :: () {
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    for i : 0..oglContext.MAX_ATTRIBS-1 {
        glDisableVertexAttribArray(cast(u32)i);
    }
    for i : 0..oglContext.MAX_TEX_SLOTS-1 {
        glActiveTexture(GL_TEXTURE0 + cast(u32)i);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
    glBindTexture(GL_TEXTURE_CUBE_MAP, 0);

    //...
    //...
    //...
    glBindVertexArray(ogl_ctx.vao);
    glEnable(GL_DEPTH_TEST);
    //glDisable(GL_BLEND);
    glEnable(GL_BLEND);
}
//----------------------------------------------------------------------------
// - oglShaderDymamicState
//----------------------------------------------------------------------------
oglShaderDynamicState :: enum {
    DEPTH_DISABLED :: 1;
    BLENDING :: 2;
}

ogl_shader_set_dynamic_state :: (state : oglShaderDynamicState) {
    if (cast(u32)state) & (1 << oglShaderDynamicState.DEPTH_DISABLED-1) {
        glDisable(GL_DEPTH_TEST);
    }
    if (cast(u32)state) & (1 << oglShaderDynamicState.BLENDING-1) {
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_BLEND);
    }
}
//----------------------------------------------------------------------------
// - oglImage
// Handles render targets (color/depth) AND regular images
//TODO: different image formats (especially floating point)
//----------------------------------------------------------------------------
oglImageType :: enum {
    TEXTURE;
    RT;
};

oglImageFormat :: enum {
    RGBA8U;
    RGBA32F;
}
oglImage :: struct {
    handle : GLuint;
    width : u32;
    height: u32;
    format : oglImageFormat;
    type : oglImageType;
    //optional: only configured for RTs (RT_COL -> colors) (RT_DS -> rbo) 
    attachments : [4] GLuint;
}

//TODO: in case of RT, should we bind it first
ogl_image_clear:: (img : *oglImage) {
    using img;
    ogl_rt_bind(img);
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    ogl_rt_bind(null);
}

ogl_rt_bind :: (img : *oglImage) {
    using img;
    if (img == null) then glBindFramebuffer(GL_FRAMEBUFFER, 0); else glBindFramebuffer(GL_FRAMEBUFFER, handle);
}

//TODO: should a 'type' be introduced, switching on the format is wrong
ogl_image_init :: (img : *oglImage, tex_data : *u8, tex_w : u32, tex_h : u32, fmt : oglImageFormat, is_font : bool = false) -> bool {
    using img;
    width = tex_w;
    height = tex_h;
    format = fmt;
    if format == {
        case .RGBA8U; // normal textures
            type = .TEXTURE;
            glGenTextures(1, *handle);
            glBindTexture(GL_TEXTURE_2D, handle);
            glPixelStorei(GL_UNPACK_ALIGNMENT, 1); // NOTE: is this really needed? its used only for font rendering random access
            if is_font {
                glPixelStorei(GL_UNPACK_ALIGNMENT, 1); // NOTE: is this really needed? its used only for font rendering random access
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_R, GL_RED);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_G, GL_RED);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_B, GL_RED);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_SWIZZLE_A, GL_RED);
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, tex_w, tex_h, 0, GL_RED, GL_UNSIGNED_BYTE, xx tex_data);
                glGenerateMipmap(GL_TEXTURE_2D);
            } else  {
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);	
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
                glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, tex_w, tex_h, 0, GL_RGBA, GL_UNSIGNED_BYTE, xx tex_data);
                glGenerateMipmap(GL_TEXTURE_2D);
            }
        case .RGBA32F; // framebuffers
            type = .RT;
            glGenFramebuffers(1, *handle);
            glBindFramebuffer(GL_FRAMEBUFFER, handle);
            
            // - position color buffer
            glGenTextures(1, *attachments[0]);
            glBindTexture(GL_TEXTURE_2D, attachments[0]);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, tex_w, tex_h, 0, GL_RGBA, GL_FLOAT, null);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, attachments[0], 0);
            
            // - normal color buffer
            glGenTextures(1, *attachments[1]);
            glBindTexture(GL_TEXTURE_2D, attachments[1]);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, tex_w, tex_h, 0, GL_RGBA, GL_FLOAT, null);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT1, GL_TEXTURE_2D, attachments[1], 0);
            
            // - color + specular color buffer
            glGenTextures(1, *attachments[2]);
            glBindTexture(GL_TEXTURE_2D, attachments[2]);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA32F, tex_w, tex_h, 0, GL_RGBA, GL_FLOAT, null);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT2, GL_TEXTURE_2D, attachments[2], 0);

            attachments_gl : [3] u32 = u32.[ GL_COLOR_ATTACHMENT0, GL_COLOR_ATTACHMENT1, GL_COLOR_ATTACHMENT2 ];
            glDrawBuffers(3, *attachments_gl[0]);

            rbo : GLuint;
            glGenRenderbuffers(1, *rbo);
            glBindRenderbuffer(GL_RENDERBUFFER, rbo); 
            glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8, tex_w, tex_h);  
            glBindRenderbuffer(GL_RENDERBUFFER, 0);
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_RENDERBUFFER, rbo);

            assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
        case;
            assert(false);
        }
    return (handle != 0);
}

ogl_image_deinit :: (img : *oglImage) {
    using img;
    if type == {
        case .RT;
            glDeleteTextures(1,*handle);
        case .TEXTURE;
            glDeleteFramebuffers(1,*handle);
    }
}


ogl_bind_image_to_texture_slot :: (img : *oglImage, tex_slot : u32, attachment : u32 = 0) {
    using img;
    glActiveTexture(GL_TEXTURE0 + tex_slot);
    if type == {
        case .RT;
            glBindTexture(GL_TEXTURE_2D, attachments[attachment]);
        case .TEXTURE;
            glBindTexture(GL_TEXTURE_2D, handle);
    }
}


//----------------------------------------------------------------------------
// - oglShaderObject 
//TODO: multiple vertex buffers not supported https://stackoverflow.com/questions/14249634/opengl-vaos-and-multiple-buffers
//----------------------------------------------------------------------------

ogl_make_attrib :: (vbo_idx : u32, type : oglShaderDataType, stride : u32, offset : u32, instanced : bool = false) -> oglShaderAttrib {
    sa : oglShaderAttrib;
    sa.vbo_idx = vbo_idx;
    sa.stride = stride;
    sa.offset = offset;
    sa.type = type;
    sa.instanced = instanced;
    return sa;
}

ogl_bind_attrib :: (attrib : *oglShaderAttrib) {
    glEnableVertexAttribArray(attrib.vbo_idx);
    if attrib.type == oglShaderDataType.INT
        glVertexAttribIPointer(attrib.vbo_idx, xx ogl_get_component_num_for_data_type(attrib.type), GL_FLOAT, attrib.stride, xx attrib.offset);
    else
        glVertexAttribPointer(attrib.vbo_idx, xx ogl_get_component_num_for_data_type(attrib.type), GL_FLOAT, GL_FALSE, attrib.stride, xx attrib.offset);
    glVertexAttribDivisor(attrib.vbo_idx, cast(u32)attrib.instanced);
}

ogl_get_component_num_for_data_type :: (type : oglShaderDataType) -> u32 {
    comp_count : u32 = 0;
    if type == {
        case .FLOAT;
            comp_count = 1;
        case .INT;
            comp_count = 1;
        case .VEC2;
            comp_count = 2;
        case .VEC3;
            comp_count = 3;
        case .VEC4;
            comp_count = 4;
        case .MAT4;
            comp_count = 16;
        case;
        assert(false);
    }
    return comp_count;
}

oglShaderObject :: struct {
    attribs : [..] oglShaderAttrib; //this should be set once!
    //OpenGL State 
    gl_program : GLuint;
}
oglShaderDataType :: enum {
    FLOAT;
    INT;
    VEC2;
    VEC3;
    VEC4;
    MAT4;
};


ogl_bind_shader_object :: (so : *oglShaderObject){
    glUseProgram(so.gl_program);
    ogl_shader_object_bind_attribs(so);
}

ogl_shader_object_cleanup :: (so : *oglShaderObject) {
    array_free(*so.attribs);
}

ogl_shader_object_add_attrib :: (so : *oglShaderObject, attrib : oglShaderAttrib) {
    array_add(*so.attribs, attrib);
}

ogl_shader_object_bind_attribs :: (so : *oglShaderObject){
    for i : 0..so.attribs.count-1 {
        ogl_bind_attrib(*so.attribs[i]);
    }
}

ogl_shader_object_bind_sampler_to_slot :: (so : *oglShaderObject, uniform_name : string, tex_slot : u32){
    ogl_shader_object_set_uniform(so, uniform_name, oglShaderDataType.INT, xx *tex_slot);
}

ogl_shader_object_set_uniform :: (so : *oglShaderObject, uniform_name : string, type : oglShaderDataType, val : *Any){
    if type == {
        case oglShaderDataType.INT;
            glUniform1iv(glGetUniformLocation(so.gl_program, uniform_name.data), 1, cast(*s32)val);
        case oglShaderDataType.FLOAT;
            glUniform1fv(glGetUniformLocation(so.gl_program, uniform_name.data), 1, cast(*float)val);
        case oglShaderDataType.VEC2;
            glUniform2fv(glGetUniformLocation(so.gl_program, uniform_name.data), 1, cast(*float)val);
        case oglShaderDataType.VEC3;
            glUniform3fv(glGetUniformLocation(so.gl_program, uniform_name.data), 1, cast(*float)val);
        case oglShaderDataType.VEC4;
            glUniform4fv(glGetUniformLocation(so.gl_program, uniform_name.data), 1, cast(*float)val);
        case oglShaderDataType.MAT4;
            glUniformMatrix4fv(glGetUniformLocation(so.gl_program, uniform_name.data), 1, GL_FALSE, cast(*float)val);
        case;
            print("uknown shader type\n");
    }
}

ogl_shader_object_init :: (so : *oglShaderObject, vs_source : string, fs_source : string) ->  bool{
    res : bool;
    so.gl_program,res = gmake_gl_sp(vs_source, fs_source);
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
    ogl_update_buffer(*buf, data,data_count,data_size);
    glBindBuffer(xx buffer_type, 0);
    return buf;
}
ogl_update_buffer :: (buf : *oglBuf, data : *void, data_count : u32, data_size : u32) {
    ogl_bind_vertex_buffer(buf);
    buf.count = data_count;
    buf.size = data_size * data_count;
    buffer_type := ifx buf.type == .VERTEX then GL_ARRAY_BUFFER else GL_ELEMENT_ARRAY_BUFFER;
    if data != null {
        glBufferData(xx buffer_type, buf.size,data, GL_STREAM_DRAW); //TODO: make a type for DYNAMIC/STATIC/STREAM?
    }
}

ogl_bind_index_buffer :: (b : *oglBuf) {
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, b.handle);
}

ogl_bind_vertex_buffer :: (b : *oglBuf) {
    glBindBuffer(GL_ARRAY_BUFFER, b.handle);
}

oglPrimitive :: enum {
    TRIANGLES;
    TRIANGLE_STRIP;
    TRIANGLE_FAN;
}

ogl_prim_to_gl_prim :: (prim : oglPrimitive) -> GLuint {
    gl_p : GLuint= GL_TRIANGLES;
    if prim == {
        case .TRIANGLES;
            gl_p = GL_TRIANGLES;
        case .TRIANGLE_STRIP;
            gl_p = GL_TRIANGLE_STRIP;
        case .TRIANGLE_FAN;
            gl_p = GL_TRIANGLE_FAN;
        case;
        assert(false);
    }
    return gl_p;
}


ogl_draw :: (prim : oglPrimitive, first : u32, count : u32) {
    glDrawArrays(ogl_prim_to_gl_prim(prim), xx first, xx count);
}

ogl_draw_instanced :: (prim : oglPrimitive, first : u32, count : u32, instance_count : u32) {
    glDrawArraysInstanced(ogl_prim_to_gl_prim(prim), cast(s32)first, count, instance_count);
}

ogl_draw_indexed :: (prim : oglPrimitive, count : u32) {
    glDrawElements(ogl_prim_to_gl_prim(prim), count, GL_UNSIGNED_INT, xx 0);
}

//----------------------------------------------------------------------------
// - SHADERS
//----------------------------------------------------------------------------
vertex_shader_3D_source :: #string END
#version 330 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNorm;
layout (location = 2) in vec2 aTexCoord;

out vec2 tc;
out vec3 world_pos;
out vec3 aNormal;
out vec3 aFragPos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main()
{
    tc = aTexCoord;
    aNormal = aNorm;
    aFragPos = vec3(model* vec4(aPos,1.0));
    //gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
    gl_Position = proj * view * model * vec4(aPos, 1.0);
    world_pos = vec3(model * vec4(aPos, 1.0));
}
END;
fragment_shader_3D_source :: #string END
#version 330 core
layout (location = 0) out vec4 gPosition; //only first 3 used
layout (location = 1) out vec4 gNormal; //only first 3 used
layout (location = 2) out vec4 gAlbedoSpec;
in vec2 tc;
in vec3 world_pos;
in vec3 aNormal;
in vec3 aFragPos;
uniform vec2 tc_start;
uniform vec2 tc_end;
uniform vec2 prev_tc_start;
uniform vec2 prev_tc_end;
uniform float delta;
uniform vec4 col;
uniform vec4 prev_col;
uniform sampler2D tex;

vec3 lightColor = vec3(0.8,0.8,0.8);
uniform vec3 lightPos;
//vec3 lightPos = vec3(-5,0,3);

void main()
{
    //vec2 new_tc = vec2(tc.x, tc.y) * 3 - 1;
    vec2 neww_tc = tc_start + (tc) * (tc_end - tc_start);
    vec3 col_tex = texture(tex, neww_tc).rgb * vec3(1,1,1);

    vec2 neww_tc_prev = prev_tc_start + tc * (prev_tc_end - prev_tc_start);
    vec3 col_tex_prev = texture(tex, neww_tc_prev).rgb * vec3(1,1,1);

    col_tex = col_tex_prev * (1.0 - delta) + col_tex * delta;

    // if (new_tc.x > 1.0) col = vec3(0,0,0);
    // if (new_tc.x < 0.0) col = vec3(0,0,0);
    // col *= -1.0;
    // col +=1.0;
    col_tex = 1.0 - col_tex;

    //-PHONG-
    float ambientStrength = 0.9;
    vec3 ambient = ambientStrength * lightColor;
    vec3 norm = normalize(aNormal);
    vec3 lightDir = normalize(lightPos - aFragPos); 
    float diff = max(dot(norm, normalize(lightDir)), 0.0);
    vec3 diffuse = diff * lightColor;
    vec3 result = (ambient + diffuse) * (col.xyz * delta + prev_col.xyz * (1.0 - delta)) * col_tex.xyz;

    gPosition = vec4(diffuse, 1.0);
    gNormal = vec4(norm, 1.0);
    gAlbedoSpec = vec4(result, 1.0);
}
END


vert_full_sp_source :: #string END
#version 330 core
out vec2 outUV;
void main() 
{
    outUV = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2);
    gl_Position = vec4(outUV * 2.0f + -1.0f, 0.0f, 1.0f);
}
END;
frag_full_sp_source:: #string END
#version 330 core
out vec4 FragColor;
uniform sampler2D gPosition;
uniform sampler2D gNormal;
uniform sampler2D gAlbedoSpec;
uniform vec3 lightPos; //for toon shading 
in vec2 outUV; //maybe this can become some onscreen effect
float fraction = 7.01;
void main()
{
    float Pixels = max(textureSize(gAlbedoSpec,0).x, textureSize(gAlbedoSpec,0).y) *3.0;
    float dx = 15.0 * (1.0 / Pixels);
    float dy = 10.0 * (1.0 / Pixels);
    vec2 Coord = vec2(dx * floor(outUV.x / dx), dy * floor(outUV.y / dy));


    FragColor = texture(gAlbedoSpec, outUV);
    float intensity;
    vec4 color_mod;
    vec3 vertLightDir = normalize(texture(gPosition, outUV).xyz - lightPos); 
    intensity = max(0.0, dot(vertLightDir, texture(gNormal, outUV).xyz));

    if (intensity > pow(0.95, fraction)) {
        color_mod = vec4(vec3(1.0), 1.0);
    } else if (intensity > pow(0.5, fraction)) {
        color_mod = vec4(vec3(0.6), 1.0);
    } else if (intensity > pow(0.25, fraction)) {
        color_mod = vec4(vec3(0.4), 1.0);
    } else {
        color_mod = vec4(vec3(0.2), 1.0);
    }
    //FragColor = color_mod * texture(gAlbedoSpec,outUV);
}
END


vert_fade_sp_source :: #string END
#version 330 core
out vec2 outUV;
void main() 
{
    outUV = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2);
    gl_Position = vec4(outUV * 2.0f + -1.0f, 0.0f, 1.0f);
}
END;
frag_fade_sp_source:: #string END
#version 330 core
out vec4 FragColor;
in vec2 outUV; //maybe this can become some onscreen effect
uniform sampler2D tex;
uniform vec4 color;
uniform float delta;
void main()
{
    FragColor = color * (1.0-delta);
}
END