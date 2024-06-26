#import "Basic";
#import "Random";
#import "Input";
#import "System";
#import "Math";
#import "../engine";
#import "File";

GameScene :: enum {
  MAIN_MENU;
  OPTIONS_MENU;
  ARCADE;
  TRAINING;
}

GameState :: struct {
  current_scene : GameScene = .MAIN_MENU;
  poke_tex : oglImage;
  scalar_adv : bool = false;
  game_volume : int = 80;
  window : gWin;
  sim_start : float64;
  current_choice : s32 = 1;
  transition_speed : int = 2; //time to transition from each gameplay scene (rotation)
  transition_percent : float;
  transition_color : gVec4;

  victory_sound : gSound;
  defeat_sound : gSound;
  click_sound : gSound;

  bmusic_sound : gSound;
  bmusic_on : bool = true;

  correct_choices : int = 0;
  choice_count : int = 0;

  controls_help_alpha : float = 1.0;
}
victory_sound_bytes := #run read_entire_file("assets/sounds/victory.wav");
defeat_sound_bytes := #run read_entire_file("assets/sounds/defeat.wav");
click_sound_bytes := #run read_entire_file("assets/sounds/click.wav");
bmusic_sound_bytes := #run read_entire_file("assets/sounds/bmusic.ogg");
alltypes_tex_data := #run read_entire_file("assets/types/alltypes.png");

game_init :: (state : *GameState) {
  using state;
  ges_init();
  win_dim : gVec2 = .{800,600};
  rend_dim : gVec2 = .{800,600};
  window = gwin_create("Type Trainer ALPHA",xx win_dim.x, xx win_dim.y, GWIN_OPT.RESIZABLE | GWIN_OPT.VISIBLE); 
  grend_init(*window);
  poke_ttex := generate_texture_from_data(alltypes_tex_data.data, alltypes_tex_data.count);
  //defer free(poke_tex.data);
  ogl_image_init(*poke_tex, poke_ttex.data, xx poke_ttex.dim.x, xx poke_ttex.dim.y, oglImageFormat.RGBA8U);
  gsound_init();
  gsound_load_from_bytes(*victory_sound,"victory", victory_sound_bytes);
  gsound_load_from_bytes(*defeat_sound,"defeat", defeat_sound_bytes);
  defeat_sound.rel_volume = 2.0;
  gsound_load_from_bytes(*click_sound,"click", click_sound_bytes);
  gsound_load_from_bytes(*bmusic_sound,"bmusic", bmusic_sound_bytes);
  bmusic_sound.rel_volume = 0.5;
  gsound_play(*gs.bmusic_sound, get_game_volume(),true);
}

game_set_scene :: (state : *GameState, trans_sec : float, scene : GameScene){
  using state;
  sim_start = seconds_since_init();
  gcam_init(*grc.main_cam, .{0,0,10});
  sphere1.direction = 1.0;
  sphere2.direction = -1.0;
  //wait trans_sec
  current_scene = scene;
  grc.main_cam.mode = .FIXED;
  if scene != .TRAINING && scene != .ARCADE {
    gs.controls_help_alpha = 1.0;
    gs.correct_choices = 0;
    gs.choice_count = 0;
  }
}

game_update :: (state : *GameState) {
  using state;
  ges_update();
  gwin_update(*window);
  ogl_image_clear(*ogl_ctx.def_rt);
  gcam_update(*grc.main_cam,xx ges.dt);

  if gkey_down(27) then game_set_scene(state, 1.0, .MAIN_MENU);
  if current_scene == {
    case .MAIN_MENU;
      do_main_menu(*gs);
    case .OPTIONS_MENU;
      do_options_menu(*gs);
    case .TRAINING;
      #through;
    case .ARCADE;
       do_game();
      
    case;
      assert(false);
  }
  gsound_update();
  rend_esc_help();
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
    gsound_play(*gs.click_sound, get_game_volume());
    gs.transition_color = gVec4.{0.0,0.0,0.0,1.0};
    init_spheres();
    game_set_scene(state, 1.0, .ARCADE);
  }
  if gui_panel_layout_add_button(*layout, "Training") {
    gsound_play(*gs.click_sound, get_game_volume());
    init_spheres();
    gs.transition_color = gVec4.{0.0,0.0,0.0,0.0};
    game_set_scene(state, 1.0, .TRAINING);
  }
  gui_panel_layout_row(*layout, 1);
  if gui_panel_layout_add_button(*layout, "Options") {
    gsound_play(*gs.click_sound, get_game_volume());
    game_set_scene(state, 1.0, .OPTIONS_MENU);
  }
  gui_panel_layout_end(*main_menu_gui_panel, *layout);
  gui_panel_layout_row(*layout, 1);
  if gui_panel_layout_add_button(*layout, "Exit") {
    gsound_play(*gs.click_sound, get_game_volume());
    ges.exit = true;
  }
  gui_panel_layout_end(*main_menu_gui_panel, *layout);


  // fps_scale := 0.5;
  // fps_counter := sprint("%", formatFloat(1.0/ges.dt, width=1, trailing_width=0, zero_removal=.NO));
  // defer free(fps_counter.data);
  // fps_width, fps_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,fps_counter,fps_scale);
  // color : u32 = 0xFFFFFFFF;
  // color = (color << 20);
  // render_basic_string(fps_counter, xx (grc.window_ref.dim.x - fps_width), 0, fps_scale);
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
  num_categories := 4;
  panel_w : float = window.dim.x / 2.0;
  panel_h : float = panel_w / (num_categories * wh_ratio);
  main_menu_gui_panel.x0 = window.dim.x/2.0 - main_menu_gui_panel.w/2.0;
  main_menu_gui_panel.y0 = window.dim.y/2.0 - main_menu_gui_panel.h/2.0;
  layout : guiPanelLayout = .{width = panel_w, row_height = panel_h};
  gui_panel_layout_begin(*main_menu_gui_panel, *layout);
  gui_panel_layout_add_title(*layout, "Options");
  gui_panel_layout_row(*layout, 1);
  gui_panel_layout_add_slider(*layout, "Volume", *game_volume, 0, 100);
  //global_stream.user_volume_scale = cast(float)game_volume / 100.0;
  set_master_vol(cast(float)game_volume / 100.0);
  gui_panel_layout_row(*layout, 1);
  gui_panel_layout_add_slider(*layout, "Anim Speed", *gs.transition_speed, 0, 5);
  gui_panel_layout_row(*layout, 2);
  if gui_panel_layout_add_checkbox(*layout, "Theme", *bmusic_on) {
    if bmusic_on then gsound_play(*bmusic_sound, get_game_volume(), true); else gsound_stop(*bmusic_sound);
  }
  gui_panel_layout_add_checkbox(*layout, "scalar adv", *scalar_adv);
  gui_panel_layout_end(*main_menu_gui_panel, *layout);
  gui_panel_layout_row(*layout, 1);
  if gui_panel_layout_add_button(*layout, "Back") {
    gsound_play(*gs.click_sound, get_game_volume());
    game_set_scene(state, 1.0, .MAIN_MENU);
  }
  gui_panel_layout_end(*main_menu_gui_panel, *layout);


  // fps_scale := 0.5;
  // fps_counter := sprint("%", formatFloat(1.0/ges.dt, width=1, trailing_width=0, zero_removal=.NO));
  // defer free(fps_counter.data);
  // fps_width, fps_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,fps_counter,fps_scale);
  // color : u32 = 0xFFFFFFFF;
  // color = (color << 20);
  // render_basic_string(fps_counter, xx (grc.window_ref.dim.x - fps_width), 0, fps_scale);
  gbatch_renderer_flush(*grc.br);

}

//--------------------------------------------------
//--------------------------------------------------
// GAME 
//--------------------------------------------------
//--------------------------------------------------

do_game :: () {
  gs.transition_percent = cast(float)(min(gs.transition_speed*(seconds_since_init() - gs.sim_start),1.0));
  rend_poke_sphere(*sphere1);
  rend_poke_sphere(*sphere2);
  if gkey_pressed(#char "w")gs.current_choice = get_next_choice(gs.current_choice);
  if gkey_pressed(#char "s")gs.current_choice = get_prev_choice(gs.current_choice);
  //rend_advantage_cube(.{}, .{1,1,1,1},xx gs.current_choice);
  if gkey_pressed(#char " ") && abs(gs.transition_percent - 1.0) < 0.01 { //calc
    choice : PokeTypeAdvantage = xx gs.current_choice;
    actual : PokeTypeAdvantage = scalar_to_poke_type_advantage(type_chart[sphere2.type][sphere1.type]);
    correct : bool = (choice == actual);
    //print("choice=[%], actual=[%], status=[%]\n", choice, actual, ifx correct then "correct!" else "wrong!");
    print("% -[%]-> %\n", sphere2.type, scalar_to_poke_type_advantage(type_chart[sphere2.type][sphere1.type]), sphere1.type);
    gs.transition_color = ifx correct then gVec4.{0.0,1.0,0.0,0.3} else gVec4.{1.0,0.0,0.0,0.3};
    gen_spheres();
    if correct then gsound_play(*gs.victory_sound, get_game_volume()); else gsound_play(*gs.defeat_sound, get_game_volume());
    if correct then gs.correct_choices+=1;
    gs.choice_count +=1;
    game_set_scene(*gs, 1.0, gs.current_scene);
  }
  if gs.correct_choices > 0 {
    speed := 2.0;
    gs.controls_help_alpha -= cast(float)ges.dt * speed;
    gs.controls_help_alpha = max(0.0, gs.controls_help_alpha);
  }
  rend_select_prompt();
  rend_controls_help(); 
  if gs.current_scene == .ARCADE{
    rend_accuracy_stats();
  }
  rend_def_fullscreen();
  rend_fade_effect();
}

scalar_to_poke_type_advantage :: (scalar : float) -> PokeTypeAdvantage {
  res : PokeTypeAdvantage = .NoEffect;
  if scalar == {
    case 0.0;
      res = .NoEffect;
    case 0.5;
      res = .NotVeryEffective;
    case 1.0;
      res = .Normal;
    case 2.0;
      res = .SuperEffective;
    case;
      assert(false);
  }
  return res;
}

rend_def_fullscreen :: () {
  ogl_clear_all();
  ogl_shader_set_dynamic_state(oglShaderDynamicState.BLENDING);
  ogl_bind_vertex_buffer(*ogl_ctx.fade_vbo); //its ok, its empty
  ogl_bind_shader_object(*ogl_ctx.full_sp);
  lp : gVec3 = .{-5,5,3};
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "lightPos", oglShaderDataType.VEC3, xx *lp);
  ogl_shader_object_set_uniform(*ogl_ctx.fade_sp, "gAlbedoSpec", oglShaderDataType.VEC4, xx *gs.transition_color);
  ogl_bind_image_to_texture_slot(*ogl_ctx.def_rt, 0, 2);
  ogl_shader_object_bind_sampler_to_slot(*ogl_ctx.full_sp, "tex", 0);

  ogl_draw(oglPrimitive.TRIANGLES, 0, xx 3);
}


rend_fade_effect :: () {
  ogl_clear_all();
  ogl_shader_set_dynamic_state(oglShaderDynamicState.DEPTH_DISABLED);
  ogl_bind_vertex_buffer(*ogl_ctx.fade_vbo);
  ogl_bind_shader_object(*ogl_ctx.fade_sp);
  ogl_shader_object_set_uniform(*ogl_ctx.fade_sp, "delta", oglShaderDataType.FLOAT, xx *gs.transition_percent);
  ogl_shader_object_set_uniform(*ogl_ctx.fade_sp, "color", oglShaderDataType.VEC4, xx *gs.transition_color);
  ogl_draw(oglPrimitive.TRIANGLES, 0, xx 3);
}

rend_poke_sphere :: (sphere : *PKMNTypeSphere) {
  ogl_clear_all();
  //ogl_rt_bind(null);
  ogl_rt_bind(*ogl_ctx.def_rt); //the spheres are drawn into the deferred RT
  glyph : gFontGlyph = gfont_atlas_get_glyph_for_character(*grc.default_atlas, type_initials[xx sphere.type]);
  prev_glyph : gFontGlyph = gfont_atlas_get_glyph_for_character(*grc.default_atlas, type_initials[xx sphere.prev_type]);
  aspect := grc.window_ref.dim.x / grc.window_ref.dim.y; 
  sphere_angle := (PI) + gs.transition_percent * (PI);
  model_mat := gmat4_mul(make_rotation_matrix( sphere_angle , .{0.0,0.0,1.0}) , gmat4_mul(make_translation_matrix(.{sphere.direction * 4,0,0}),make_rotation_matrix( sphere_angle, .{0.0,0.0,-1.0})));
  view_mat := gcam_make_lookat_matrix(*grc.main_cam);
  proj_mat := make_perspective_matrix(45.0, aspect, 0.001, 50.0);

  ogl_bind_index_buffer(*ogl_ctx.sphere_ibo);
  ogl_bind_vertex_buffer(*ogl_ctx.sphere_vbo);
  //ogl_bind_vertex_buffer(*ogl_ctx.cube_vbo);
  ogl_bind_shader_object(*ogl_ctx.sp3D);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "model", oglShaderDataType.MAT4, xx *model_mat);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "view", oglShaderDataType.MAT4, xx *view_mat);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "proj", oglShaderDataType.MAT4, xx *proj_mat);
  tc_start : gVec2 = .{cast(float)(64.0 * sphere.type / gs.poke_tex.width), 0.0};
  tc_end := tc_start;
  tc_end += .{cast(float)((64.0)/ gs.poke_tex.width), 1.0};

  prev_tc_start : gVec2 = .{cast(float)(64.0 * sphere.prev_type / gs.poke_tex.width), 0.0};
  prev_tc_end := prev_tc_start;
  prev_tc_end += .{cast(float)((64.0)/ gs.poke_tex.width), 1.0};


  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "tc_start", oglShaderDataType.VEC2, xx *tc_start);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "tc_end", oglShaderDataType.VEC2, xx *tc_end);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "prev_tc_start", oglShaderDataType.VEC2, xx *prev_tc_start);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "prev_tc_end", oglShaderDataType.VEC2, xx *prev_tc_end);
  delta := min(1.0, 5 * gs.transition_percent);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "delta", oglShaderDataType.FLOAT, xx *delta);
  col : gVec4 = .{type_colors[sphere.type].x,type_colors[sphere.type].y,type_colors[sphere.type].z,1.0};
  prev_col : gVec4 = .{type_colors[sphere.prev_type].x,type_colors[sphere.prev_type].y,type_colors[sphere.prev_type].z,1.0};
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "col", oglShaderDataType.VEC4, xx *col);
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "prev_col", oglShaderDataType.VEC4, xx *prev_col);
  lp : gVec3 = .{-5,5,3};
  ogl_shader_object_set_uniform(*ogl_ctx.sp3D, "lightPos", oglShaderDataType.VEC3, xx *lp);

  //grc: gRendContext;
  //ogl_bind_image_to_texture_slot(*ogl_ctx.debug_tex, 0);
  ogl_bind_image_to_texture_slot(*gs.poke_tex, 0);
  ogl_shader_object_bind_sampler_to_slot(*ogl_ctx.sp3D, "tex", 0);
  ogl_draw_indexed(oglPrimitive.TRIANGLES, sphere_idx.count);
  //ogl_draw(oglPrimitive.TRIANGLES, 0, xx ogl_ctx.cube_vbo.count);

  ogl_clear_all();
  //rend_advantage_cube(lp, .{1,1,1,1});
}

init_spheres :: () {
  sphere1.type = xx (random_get() % cast(u64)PokeType.COUNT);
  sphere1.prev_type = sphere1.type;
  sphere2.type = xx (random_get() % cast(u64)PokeType.COUNT);
  sphere2.prev_type = sphere2.type;
}
 
gen_spheres :: () {
  sphere1.prev_type = sphere2.type;
  sphere2.prev_type = sphere1.type;
  sphere1.type = xx (random_get() % cast(u64)PokeType.COUNT);
  sphere2.type = xx (random_get() % cast(u64)PokeType.COUNT);
}

get_game_volume :: () -> float {
  return (cast(float)gs.game_volume/100.0);
}
get_next_choice :: (choice : s32) -> s32 {
  return (choice+1) % 4;
}
get_prev_choice :: (choice : s32) -> s32 {
  return ifx (choice-1)< 0 then 3 else choice-1;
}

//--------------------------------------------------
//--------------------------------------------------
// GAME UI 
//--------------------------------------------------
//--------------------------------------------------
rend_esc_help :: () {
  esc_scale := (0.5) * (grc.window_ref.dim.x/800.0);
  esc_help :string= "Esc to Menu";
  //defer free(esc_help.data);
  esc_width, esc_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,esc_help,esc_scale);
  alpha : float = ifx gs.current_scene == .MAIN_MENU then 0.2 else 0.7;
  render_basic_string(esc_help, 0, 0, esc_scale, alpha);
}

rend_controls_help :: () {
  con_scale := (0.5 + 0.01 * sin(cast(float)seconds_since_init()*5)) * (grc.window_ref.dim.x/800.0);
  con_help :string= "W/S to select, Space to commit";
  con_width, con_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,con_help,con_scale);
  //render_basic_string(con_help, 0, 0, con_scale, gs.controls_help_alpha);
  render_basic_string(con_help, grc.window_ref.dim.x/2 - con_width/2, grc.window_ref.dim.y - con_height, con_scale, gs.controls_help_alpha);
}
rend_select_prompt :: () {
  prompt_scale := (0.5) * (grc.window_ref.dim.x/800.0);

  choice : PokeTypeAdvantage = xx gs.current_choice;
  actual : PokeTypeAdvantage = scalar_to_poke_type_advantage(type_chart[sphere2.type][sphere1.type]);
  correct : bool = (choice == actual);
 
  scale_mod := ifx correct && gs.current_scene == .TRAINING then 0.01 * sin(cast(float)seconds_since_init()*7) else 0;
  scaled_prompt_scale := (0.5 + scale_mod) * (grc.window_ref.dim.x/800.0);
  biggest_prompt := sprint("%", PokeTypeAdvantage.NotVeryEffective);
  biggest_width, biggest_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,biggest_prompt,prompt_scale);
  //prompt := sprint("%", cast(PokeTypeAdvantage)gs.current_choice);
  prompt : string;
  if gs.scalar_adv {
    prompt = sprint("%", PokeTypeAdvantageScalar[gs.current_choice]);
  }else {
    prompt = sprint("%", cast(PokeTypeAdvantage)gs.current_choice);
  }
  defer free(prompt.data);
  prompt_width, prompt_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,prompt,prompt_scale);
  scaled_prompt_width, scaled_prompt_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,prompt,scaled_prompt_scale);
  col : gVec4 = .{0.95,0.95,0.95,1.0};
  if correct && gs.current_scene == .TRAINING then col = .{0.1,0.9,0.1,1.0};else if !correct && gs.current_scene == .TRAINING then col = .{0.5,0.1,0.1,1.0};
  render_string(prompt, xx (grc.window_ref.dim.x/2.0 - scaled_prompt_width/2.0), xx (grc.window_ref.dim.y/2.0 - prompt_height/2.0), scaled_prompt_scale, col);

  prev_prompt_scale := 0.4 * (grc.window_ref.dim.x/800.0);
  prev_prompt : string;
  if gs.scalar_adv {
    prev_prompt = sprint("%", PokeTypeAdvantageScalar[get_next_choice(gs.current_choice)]);
  }else {
    prev_prompt = sprint("%", cast(PokeTypeAdvantage)get_next_choice(gs.current_choice));
  }
  defer free(prev_prompt.data);
  prev_prompt_width, prev_prompt_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,prev_prompt,prev_prompt_scale);
  render_basic_string(prev_prompt, xx (grc.window_ref.dim.x/2.0 - prev_prompt_width/2.0), xx (grc.window_ref.dim.y/2.0 - prev_prompt_height/2.0 - biggest_height), prev_prompt_scale, 0.4);
 
  next_prompt_scale := 0.4 * (grc.window_ref.dim.x/800.0);
  next_prompt : string;
  if gs.scalar_adv {
    next_prompt = sprint("%", PokeTypeAdvantageScalar[get_prev_choice(gs.current_choice)]);
  }else {
    next_prompt = sprint("%", cast(PokeTypeAdvantage)get_prev_choice(gs.current_choice));
  }
  defer free(next_prompt.data);
  next_prompt_width, next_prompt_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,next_prompt,next_prompt_scale);
  render_basic_string(next_prompt, xx (grc.window_ref.dim.x/2.0 - next_prompt_width/2.0), xx (grc.window_ref.dim.y/2.0 - next_prompt_height/2.0 + biggest_height), next_prompt_scale, 0.4);
 
  gbatch_renderer_flush(*grc.br);
}
rend_accuracy_stats :: () {
  acc_scale := (0.5) * (grc.window_ref.dim.x/800.0);
  acc_counter := sprint("acc: %\%", formatFloat(ifx gs.choice_count > 0 then 100.0*(gs.correct_choices/cast(float)gs.choice_count) else 100, width=1, trailing_width=0, zero_removal=.NO));
  defer free(acc_counter.data);
  acc_width, acc_height := gfont_atlas_get_dim_for_string(*grc.default_atlas,acc_counter,acc_scale);
  render_basic_string(acc_counter, xx (grc.window_ref.dim.x - acc_width), 0, acc_scale);
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

PokeTypeAdvantageScalar : [] string = string.[ "x0","x0.5","x1","x2" ];

PokeTypeAdvantage :: enum {
  NoEffect;
  NotVeryEffective;
  Normal;
  SuperEffective;
}

PKMNTypeSphere :: struct {
  type : PokeType;
  prev_type : PokeType; //for transition
  //pos : gVec3;
  radius : float; // its pretty much scale
  direction : float;
  //collider : col;
}
