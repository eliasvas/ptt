#import "Basic";
#import "Compiler";

build :: () {
    w := compiler_create_workspace();
    if !w {
        print("Workspace creation failed.\n");
        return;
    }
    target_options := get_build_options(w);
	  target_options.backend = .LLVM;  
    set_optimization(*target_options, Optimization_Type.DEBUG, true);
    // set_optimization(*target_options, Optimization_Type.OPTIMIZED);
    target_options.output_type = .EXECUTABLE;      
    target_options.output_executable_name = "ssg";
    target_options.output_path = "./.build";
    set_build_options(target_options, w);
    add_build_file(tprint("game/main.jai"), w);
    set_build_options_dc(.{do_output=false});
}
main :: () {}
#run build();