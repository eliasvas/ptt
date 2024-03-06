#import "Basic";
#import "Input";
#import "System";
#import "Math";
#import "Window_Creation";
#import "../engine";

//SHITTY GAME IDEAS:
//3D BILLBOARDS!!!! https://kenney.nl/assets
//also i wanna procgen these! https://kenney.nl/assets/prototype-textures and maybe even 3d models out of the faces procedural meshing sounds fun
//wfc for world generation? https://www.youtube.com/watch?v=20KHNA9jTsE and https://www.youtube.com/watch?v=zIRTOgfsjl0, maybe i can do this for dungeons
//simplest game i can think ot is starfox zero clone (https://www.youtube.com/watch?v=GhQp8le67Xo), with predefined vertex model? (remember, minimal assets)
//this is a nice reference: https://www.youtube.com/watch?v=QTD4d9Z7szY
//procedural rocks??
//we need a skybox tho huh

window : gWin;

main :: () {
  ges_init();
  win_dim : gVec2 = .{800,600};
  rend_dim : gVec2 = .{800,600};
  window = gwin_create(xx win_dim.x, xx win_dim.y, GWIN_OPT.RESIZABLE | GWIN_OPT.VISIBLE); 
  grend_init(*window);

  while !ges.exit{
    ges_update();
    gwin_update(*window);
  }

  gwin_cleanup(*window);
}