#import "Basic";
#import "Input";
#import "System";
#import "Math";
#import "Window_Creation";
#import "../engine";

//TODO: sound generator, to get familiar with audio programming, we will write our own WAV in a dynamic array and play via Sound_Player

//SHITTY GAME IDEA to test the engine works as expected:
//Maybe this can lead to CLAY shaded pacman or similar test game??? not sure if possible in glsl tho (similar to this https://www.youtube.com/watch?v=mbVCrNdKaMk)
//The order we need stuff is gui -> compmlete ogl + deferred pseudo PBR -> basic gameplay / menus -> skeletal animations -> extra gameplay likep powerups
//EXTRA: The "deformation" of the clay could partially be controlled by the music!! haven't really delved into audio tho so thats a nice little project
//EXTRA: a particle system for eating stuff / dying / killing / speedup will make the game fire
//PREREQ: smoothed cube + its PBR textures will be needed maybe!
//Maybe I should speedrun with what I have to make it playable and THEN polish with clay PBR shader / new ui system / decibel thing wtv

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