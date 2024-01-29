#load "gmath.jai";
#import "GL";
#import "SDL";

//This will* be a graphics API abstraction for OpenGL making it a bit _saner_ to use
//The gist is we hold all OpenGL global state and do correct transitions, also no more VAOs! 
//This might help https://developer.nvidia.com/opengl-vulkan
//also this https://hacksoflife.blogspot.com/2015/04/the-opengl-impedance-mismatch.html

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