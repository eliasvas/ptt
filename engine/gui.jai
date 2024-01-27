#import "Basic";
#import "Input";
#import "System";

//Some Notes on FONTS:
//1.) We need to load the font at COMPILE time so the executable is bundled with the font data :)
//2.) We will use stb_truetype to read the data and make glyphs
//3.) We will make a FAST OpenGL batch renderer at grend.jai which will get said glyphs and draw them
//4.) SDF?! 