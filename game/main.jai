#import "Basic";
#import "Input";
Simp :: #import "Simp";
#import "System";
#import "Window_Creation";


main :: () {
  window_width  : s32 = 800;
  window_height : s32 = 600;
  render_width  : s32 = 800;
  render_height : s32 = 600;

  win := create_window(window_width, window_height, "ssg");   // (1)
  Simp.set_render_target(win);
  quit := false;
  while !quit {
    update_window_events();
    for get_window_resizes() {
        if it.window == win {
            window_width  = it.width;
            window_height = it.height;
            render_width  = window_width;
            render_height = window_height;
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
}