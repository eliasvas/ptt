#import "Basic";
#import "Compiler";
//The engine is a lib, the game is an executable ?
//OPTIMIZATION := Optimization_Type.DEBUG;
build :: () {
    game_workspace := compiler_create_workspace("Game");
    if !game_workspace {
        print("Workspace creation failed.\n");
    }else {
        target_options := get_build_options(game_workspace);
        target_options.backend = .LLVM;  
        set_optimization(*target_options, Optimization_Type.DEBUG, true);
        // set_optimization(*target_options, Optimization_Type.OPTIMIZED);
        target_options.output_type = .EXECUTABLE;      
        target_options.output_executable_name = "tt";
        target_options.output_path = "./.build";

        import_path: [..] string;
        array_add(*import_path, "engine");
        array_add(*import_path, ..target_options.import_path);
        target_options.import_path = import_path;


        set_build_options(target_options, game_workspace);
        add_build_file(tprint("game/game.jai"), game_workspace);
        set_build_options_dc(.{do_output=false});
    }

}
main :: () {}
#run build();