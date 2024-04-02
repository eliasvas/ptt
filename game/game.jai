#import "Basic";
#import "Input";
#import "System";
#import "Math";
#import "../engine";

//SHITTY GAME IDEA to test the engine works as expected:
//We can make a Pokemon Type Trainer App. There will be 2-4 PBR type balls and the player must choose the ones that match


GameScene :: enum {
  MAIN_MENU;
  OPTIONS_MENU;
  ARCADE;
  PRACTICE;
}
GameState :: struct {
  current_scene : GameScene = .MAIN_MENU;
  animations_on : bool = true;
  effects_on : bool = false;
  game_volume : int = 80;
  window : gWin;
}
game_init :: (state : *GameState) {
  using state;
  ges_init();
  win_dim : gVec2 = .{800,600};
  rend_dim : gVec2 = .{800,600};
  window = gwin_create("Type Trainer ALPHA",xx win_dim.x, xx win_dim.y, GWIN_OPT.RESIZABLE | GWIN_OPT.VISIBLE); 
  grend_init(*window);
}
game_set_scene :: (state : *GameState, trans_sec : float, scene : GameScene){
  using state;
  //wait trans_sec
  current_scene = scene;
}

game_update :: (state : *GameState) {
  using state;
  ges_update();
  gwin_update(*window);

  if gkey_down(27) then game_set_scene(state, 1.0, .MAIN_MENU);
  if current_scene == {
    case .MAIN_MENU;
      do_main_menu(*gs);
    case .OPTIONS_MENU;
      do_options_menu(*gs);
    case .PRACTICE;
      ogl_draw_sample_scene();
    case .ARCADE;
      ogl_draw_sample_scene();
    case;
    assert(false);
  }

}

game_exit :: (state : *GameState) {
  using state;
  gwin_cleanup(*window);
}

gs : GameState;

main :: () {
  game_init(*gs);
  while !ges.exit{
    game_update(*gs);
  }
  game_exit(*gs);
}


//--------------------------------------------------
//--------------------------------------------------
//MAIN_MENU
//--------------------------------------------------
//--------------------------------------------------
main_menu_gui_panel: guiPanel = .{0,0,100,100,100,100, false};
do_main_menu :: (state : *GameState) {
  using state;
  wh_ratio : float = 2.0;
  num_categories := 3;
  panel_w : float = window.dim.x / 2.0;
  panel_h : float = panel_w / (num_categories * wh_ratio);
  main_menu_gui_panel.x0 = window.dim.x/2.0 - main_menu_gui_panel.w/2.0;
  main_menu_gui_panel.y0 = window.dim.y/2.0 - main_menu_gui_panel.h/2.0;
  layout : guiPanelLayout = .{width = panel_w, row_height = panel_h};
  gui_panel_layout_begin(*main_menu_gui_panel, *layout);
  gui_panel_layout_add_title(*layout, "Type Trainer");
  gui_panel_layout_row(*layout, 2);
  if gui_panel_layout_add_button(*layout, "Arcade") {
    game_set_scene(state, 1.0, .ARCADE);
  }
  if gui_panel_layout_add_button(*layout, "Practice") {
    game_set_scene(state, 1.0, .PRACTICE);
  }
  gui_panel_layout_row(*layout, 1);
  if gui_panel_layout_add_button(*layout, "Options") {
    game_set_scene(state, 1.0, .OPTIONS_MENU);
  }
  gui_panel_layout_end(*main_menu_gui_panel, *layout);
  gui_panel_layout_row(*layout, 1);
  if gui_panel_layout_add_button(*layout, "Exit") {
    ges.exit = true;
  }
  gui_panel_layout_end(*main_menu_gui_panel, *layout);


  fps_scale := 0.5;
  fps_counter := sprint("%", formatFloat(1.0/ges.dt, width=1, trailing_width=0, zero_removal=.NO));
  defer free(fps_counter.data);
  fps_width, fps_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,fps_counter,fps_scale);
  color : u32 = 0xFFFFFFFF;
  color = (color << 20);
  render_basic_string(fps_counter, xx (grc.window_ref.dim.x - fps_width), 0, fps_scale);

  gbatch_renderer_flush();

}
//--------------------------------------------------
//--------------------------------------------------
// OPTIONS_MENU
//--------------------------------------------------
//--------------------------------------------------
options_menu_gui_panel: guiPanel;
do_options_menu :: (state : *GameState) {
  using state;
  wh_ratio : float = 2.0;
  num_categories := 3;
  panel_w : float = window.dim.x / 2.0;
  panel_h : float = panel_w / (num_categories * wh_ratio);
  main_menu_gui_panel.x0 = window.dim.x/2.0 - main_menu_gui_panel.w/2.0;
  main_menu_gui_panel.y0 = window.dim.y/2.0 - main_menu_gui_panel.h/2.0;
  layout : guiPanelLayout = .{width = panel_w, row_height = panel_h};
  gui_panel_layout_begin(*main_menu_gui_panel, *layout);
  gui_panel_layout_add_title(*layout, "Options");
  gui_panel_layout_row(*layout, 1);
  gui_panel_layout_add_slider(*layout, "Volume", *game_volume, 0, 100);
  gui_panel_layout_row(*layout, 2);
  gui_panel_layout_add_checkbox(*layout, "Anims", *animations_on);
  gui_panel_layout_add_checkbox(*layout, "Effects", *effects_on);
  gui_panel_layout_end(*main_menu_gui_panel, *layout);
  gui_panel_layout_row(*layout, 1);
  if gui_panel_layout_add_button(*layout, "Back") {
    game_set_scene(state, 1.0, .MAIN_MENU);
  }
  gui_panel_layout_end(*main_menu_gui_panel, *layout);


  fps_scale := 0.5;
  fps_counter := sprint("%", formatFloat(1.0/ges.dt, width=1, trailing_width=0, zero_removal=.NO));
  defer free(fps_counter.data);
  fps_width, fps_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,fps_counter,fps_scale);
  color : u32 = 0xFFFFFFFF;
  color = (color << 20);
  render_basic_string(fps_counter, xx (grc.window_ref.dim.x - fps_width), 0, fps_scale);

  gbatch_renderer_flush();

}