#load "gmath.jai";
#import "GL";
#import "SDL";

//This will* be a graphics API abstraction for OpenGL making it a bit _saner_ to use
//The gist is we hold all OpenGL global state and do correct transitions, also no more VAOs! 
//This might help https://developer.nvidia.com/opengl-vulkan
//also this https://hacksoflife.blogspot.com/2015/04/the-opengl-impedance-mismatch.html