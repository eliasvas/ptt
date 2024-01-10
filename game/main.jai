#import "Basic";
#import "Input";
#import "System";
#import "Math";
#import "Window_Creation";
#import "../engine";

//As a BASELINE game, we could start with a 2d roguelite with
//a lot of procgen stuff, and for sure make it 3d with skeletal
//animation, custom proc weapons? and stuff (physics?) and go from there!
//we can turn it into a silly game anytime tho
//the UI is VERY important and should be made FIRST!!(so immediate-style 2d renderer first!)


//Preliminary Plan:
//0.) Basic 2d rendering abstraction
//1.) UI Basics
//2.) VERY simple roguelite base 

window : gWin;

main :: () {
  ges_init();
  win_dim : gVec2 = .{800,600};
  rend_dim : gVec2 = .{800,600};
  window = gwin_create(xx win_dim.x, xx win_dim.y, GWIN_OPT.NONE); 
  grend_init(); //TODO: maybe pass window here?? (yes)

  while !ges.exit{
    ges_update();
    gwin_update(*window);
  }

  gwin_cleanup(*window);
}