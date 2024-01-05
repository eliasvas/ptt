#import "Basic";
#import "Input";
Simp :: #import "Simp";
#import "System";
#import "Window_Creation";
#import "../engine";

window : gWin;

main :: () {
  ges_init();
  win_dim : gVec2 = .{800,600};
  rend_dim : gVec2 = .{800,600};
  window = gwin_create(win_dim.x, win_dim.y, GWIN_OPT.NONE); 
  grend_init(); //@TODO: maybe pass window here??

  while !ges.exit{
    ges_update();
    gwin_update(*window);
  }

  gwin_cleanup(*window);

/*
  win := create_window(win_dim.x, win_dim.y, "ssg");   // (1)
  Simp.set_render_target(win);
  if win {
    print("Window creation successful!");
  }
  quit := false;
  while !quit {
    update_window_events();
    for get_window_resizes() {
        if it.window == win {
            win_dim.x  = it.width;
            win_dim.y  = it.height;
            rend_dim.x = win_dim.x;
            rend_dim.y = win_dim.y;
            Simp.update_window(win);
        }
    }

    Simp.clear_render_target(0.15555, 0.15555, 0.15555, 1.0);
    for events_this_frame {
        if it.type == .QUIT then 
          quit = true;
    }

    sleep_milliseconds(10);
    Simp.swap_buffers(win);
    reset_temporary_storage();
  }
*/
}