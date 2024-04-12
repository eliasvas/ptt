#import "Basic";
#import "Random";
#import "Input";
#import "System";
#import "Math";
#import "../engine";

//SHITTY GAME IDEA to test the engine works as expected:
//We can make a Pokemon Type Trainer App. There will be 2-4 PBR type balls and the player must choose the ones that match

//PRIMARY feedback loop should be on-screen effects, like red fade for wrong and green fade for success + sounds?
//also gameplay transition should be texture interpolation of previous and next type and to go to starting pos and restart simulation
//also implement some form of stylized rendering, even if its just a post-proc effect, blin-phong is boring as SHIT
//These + a simple deferred renderer that will render the type spheres with a pre-loaded texture should be enough

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
  sim_start : float64;
  current_choice : s32 = 1;
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
  sim_start = seconds_since_init();
  gcam_init(*grc.main_cam, .{0,0,10});
  sphere1.direction = 1.0;
  sphere1.type = xx (random_get() % cast(u64)PokeType.COUNT);
  sphere2.direction = -1.0;
  sphere2.type = xx (random_get() % cast(u64)PokeType.COUNT);
  //wait trans_sec
  current_scene = scene;
}

game_update :: (state : *GameState) {
  using state;
  ges_update();
  gwin_update(*window);
  gcam_update(*grc.main_cam,xx ges.dt);

  if gkey_down(27) then game_set_scene(state, 1.0, .MAIN_MENU);
  if current_scene == {
    case .MAIN_MENU;
      do_main_menu(*gs);
    case .OPTIONS_MENU;
      do_options_menu(*gs);
    case .PRACTICE;
      rend_poke_sphere(*sphere1);
      rend_poke_sphere(*sphere2);
      if gkey_pressed(119)current_choice += 1;
      if gkey_pressed(115)current_choice -= 1;
      current_choice = xx max(0,min(2,current_choice));
      rend_cube_in_pos(.{}, .{1,1,1,1},xx( #char "0" + current_choice));
    case .ARCADE;
      rend_poke_sphere(*sphere1);
      rend_poke_sphere(*sphere2);   
      if gkey_pressed(119)current_choice += 1;
      if gkey_pressed(115)current_choice -= 1;
      current_choice = xx max(0,min(2,current_choice));
      rend_cube_in_pos(.{}, .{1,1,1,1},xx( #char "0" + current_choice));
    case;
      assert(false);
  }

}

game_exit :: (state : *GameState) {
  using state;
  gwin_cleanup(*window);
}

gs : GameState;

sphere1 : PKMNTypeSphere;
sphere2 : PKMNTypeSphere;

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

  gbatch_renderer_flush(*grc.br);

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

  gbatch_renderer_flush(*grc.br);

}

//--------------------------------------------------
//--------------------------------------------------
// GAME 
//--------------------------------------------------
//--------------------------------------------------

rend_cube_in_pos :: (pos : gVec3, col : gVec4, c : u8) {
  ogl_clear_all();
  model_mat := make_translation_matrix(pos);
  view_mat := gcam_make_lookat_matrix(*grc.main_cam);
  proj_mat := make_perspective_matrix(45.0, 800.0/600.0, 0.001, 50.0);
  glyph : gFontGlyph = gfont_atlas_get_glyph_for_character(*grc.default_atlas, c);

  ogl_bind_vertex_buffer(*ogl_ctx.cube_vbo);
  ogl_bind_shader_object(*ogl_ctx.sp3D);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "model", oglShaderDataType.MAT4, xx *model_mat);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "view", oglShaderDataType.MAT4, xx *view_mat);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "proj", oglShaderDataType.MAT4, xx *proj_mat);
  tc_start : gVec2 = .{cast(float)glyph.tc_x / grc.default_atlas.size_x, cast(float)0.0 / grc.default_atlas.size_y};
  tc_end := tc_start;
  tc_end += .{cast(float)glyph.size_x / grc.default_atlas.size_x, cast(float)glyph.size_y / grc.default_atlas.size_y};
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "tc_start", oglShaderDataType.VEC2, xx *tc_start);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "tc_end", oglShaderDataType.VEC2, xx *tc_end);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "col", oglShaderDataType.VEC4, xx *col);
  lp : gVec3 = .{-5,5,3};
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "lightPos", oglShaderDataType.VEC3, xx *lp);
  ogl_bind_image_to_texture_slot(*grc.font_tex, 0);
  ogl_shader_object_bind_sampler_to_slot(*ogl_ctx.sp3D, "tex", 0);
  ogl_draw(oglPrimitive.TRIANGLES, 0, xx ogl_ctx.cube_vbo.count);

  ogl_clear_all();
}


rend_poke_sphere :: (sphere : *PKMNTypeSphere) {
  ogl_clear_all();
  //ogl_image_bind(*ogl_ctx.def_fbo);
  glyph : gFontGlyph = gfont_atlas_get_glyph_for_character(*grc.default_atlas, type_initials[xx sphere.type]);
  aspect := 800.0 / 600.0; 
  sphere_angle := (PI/2) + cast(float)(min(seconds_since_init() - gs.sim_start,1.0)) * (PI/2);
  model_mat := gmat4_mul(make_rotation_matrix( sphere_angle , .{0.0,0.0,1.0}) , gmat4_mul(make_translation_matrix(.{sphere.direction * 4,0,0}),make_rotation_matrix( sphere_angle, .{0.0,0.0,-1.0})));
  view_mat := gcam_make_lookat_matrix(*grc.main_cam);
  proj_mat := make_perspective_matrix(45.0, aspect, 0.001, 50.0);

  //ogl_bind_index_buffer(*ogl_ctx.sphere_ibo);
  //ogl_bind_vertex_buffer(*ogl_ctx.sphere_vbo);
  ogl_bind_vertex_buffer(*ogl_ctx.cube_vbo);
  ogl_bind_shader_object(*ogl_ctx.sp3D);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "model", oglShaderDataType.MAT4, xx *model_mat);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "view", oglShaderDataType.MAT4, xx *view_mat);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "proj", oglShaderDataType.MAT4, xx *proj_mat);
  tc_start : gVec2 = .{cast(float)glyph.tc_x / grc.default_atlas.size_x, cast(float)0.0 / grc.default_atlas.size_y};
  tc_end := tc_start;
  tc_end += .{cast(float)glyph.size_x / grc.default_atlas.size_x, cast(float)glyph.size_y / grc.default_atlas.size_y};
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "tc_start", oglShaderDataType.VEC2, xx *tc_start);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "tc_end", oglShaderDataType.VEC2, xx *tc_end);
  col : gVec4 = .{type_colors[sphere.type].x,type_colors[sphere.type].y,type_colors[sphere.type].z,1.0};
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "col", oglShaderDataType.VEC4, xx *col);
  lp : gVec3 = .{-5,5,3};
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "lightPos", oglShaderDataType.VEC3, xx *lp);

  //grc: gRendContext;
  //ogl_bind_image_to_texture_slot(*ogl_ctx.debug_tex, 0);
  ogl_bind_image_to_texture_slot(*grc.font_tex, 0);
  ogl_shader_object_bind_sampler_to_slot(*ogl_ctx.sp3D, "tex", 0);
  //ogl_draw_indexed(oglPrimitive.TRIANGLES, sphere_idx.count);
  ogl_draw(oglPrimitive.TRIANGLES, 0, xx ogl_ctx.cube_vbo.count);

  ogl_clear_all();
  //rend_cube_in_pos(lp, .{1,1,1,1});
}

//--------------------------------------------------
//--------------------------------------------------
// POKEMON STUFF 
//--------------------------------------------------
//--------------------------------------------------
PokeType :: enum {
  NORMAL;
  FIGHTING;
  FLYING;
  POISON;
  GROUND;
  ROCK;
  BUG;
  GHOST;
  STEEL;
  FIRE;
  WATER;
  GRASS;
  ELECTRIC;
  PSYCHIC;
  ICE;
  DRAGON;
  DARK;
  FAIRY;
  COUNT; // i should 'learn' jai at some point
};

type_initials : [PokeType.COUNT] u8= .[ cast(u8)#char "n", cast(u8)#char "f", cast(u8)#char "f", cast(u8)#char "p", cast(u8)#char "g", cast(u8)#char "r", cast(u8)#char "b", cast(u8)#char "g", cast(u8)#char "s", cast(u8)#char "f", cast(u8)#char "w", cast(u8)#char "g", cast(u8)#char "e", cast(u8)#char "p", cast(u8)#char "i", cast(u8)#char "d", cast(u8)#char "d", cast(u8)#char "f" ];

type_chart : [PokeType.COUNT] [PokeType.COUNT] float = .[
  float.[1,1,1,1,1,0.5,1,0,0.5,1,1,1,1,1,1,1,1,1],
  float.[2,1,0.5,0.5,1,2,0.5,0,2,1,1,1,1,0.5,2,1,2,0.5],
  float.[1,2,1,1,1,0.5,2,1,0.5,1,1,2,0.5,1,1,1,1,1],
  float.[1,1,1,0.5,0.5,0.5,1,0.5,0,1,1,2,1,1,1,1,1,2],
  float.[1,1,0,2,1,2,0.5,1,2,2,1,0.5,2,1,1,1,1,1],
  float.[1,0.5,2,1,0.5,1,2,1,0.5,2,1,1,1,1,2,1,1,1],
  float.[1,0.5,0.5,0.5,1,1,1,0.5,0.5,0.5,1,2,1,2,1,1,2,0.5],
  float.[0,1,1,1,1,1,1,2,1,1,1,1,1,2,1,1,0.5,1],
  float.[1,1,1,1,1,2,1,1,0.5,0.5,0.5,1,0.5,1,2,1,1,2],
  float.[1,1,1,1,1,0.5,2,1,2,0.5,0.5,2,1,1,2,0.5,1,1],
  float.[1,1,1,1,2,2,1,1,1,2,0.5,0.5,1,1,1,0.5,1,1],
  float.[1,1,0.5,0.5,2,2,0.5,1,0.5,0.5,2,0.5,1,1,1,0.5,1,1],
  float.[1,1,2,1,0,1,1,1,1,1,2,0.5,0.5,1,1,0.5,1,1],
  float.[1,2,1,2,1,1,1,1,0.5,1,1,1,1,0.5,1,1,0,1],
  float.[1,1,2,1,2,1,1,1,0.5,0.5,0.5,2,1,1,0.5,2,1,1],
  float.[1,1,1,1,1,1,1,1,0.5,1,1,1,1,1,1,2,1,0],
  float.[1,0.5,1,1,1,1,1,2,1,1,1,1,1,2,1,1,0.5,0.5],
  float.[1,2,1,0.5,1,1,1,1,0.5,0.5,1,1,1,1,1,2,2,1],
];
type_colors : [PokeType.COUNT] gVec3 = .[
  gVec3.{0.65,0.65,0.47},
  gVec3.{0.76,0.18,0.15},
  gVec3.{0.66,0.56,0.95},
  gVec3.{0.63,0.24,0.63},
  gVec3.{0.88,0.74,0.39},
  gVec3.{0.71,0.63,0.21},
  gVec3.{0.65,0.72,0.10},
  gVec3.{0.45,0.34,0.59},
  gVec3.{0.71,0.71,0.80},
  gVec3.{0.93,0.50,0.18},
  gVec3.{0.38,0.56,0.94},
  gVec3.{0.47,0.78,0.29},
  gVec3.{0.96,0.81,0.17},
  gVec3.{0.97,0.33,0.52},
  gVec3.{0.58,0.85,0.83},
  gVec3.{0.43,0.20,0.98},
  gVec3.{0.43,0.34,0.27},
  gVec3.{0.83,0.52,0.67}
];

type_test :: () {
  assert(type_chart[PokeType.FIRE][PokeType.WATER] == 0.5);
  assert(type_chart[PokeType.WATER][PokeType.FIRE] == 2.0);
  assert(type_chart[PokeType.WATER][PokeType.ELECTRIC] == 1.0);
  assert(type_chart[PokeType.ELECTRIC][PokeType.WATER] == 2.0);
  assert(type_chart[PokeType.DRAGON][PokeType.FAIRY] == 0.0);
}
#run type_test();

PKMNTypeSphere :: struct {
  type : PokeType;
  //pos : gVec3;
  radius : float; // its pretty much scale
  direction : float;
  //collider : col;
}
