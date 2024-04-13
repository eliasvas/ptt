using Sound :: #import "Sound_Player";
#import "Random";

gSound :: struct {
    snd : Sound_Data;
    name : string;
}

gsound_init :: () {
    devices := get_devices();
    print("Sound devices: %", devices);
    sound_player_init(.{});
}

gsound_update :: () {
    Sound.update();
}

gsound_play :: (sound : *gSound, repeat : bool = false) {
    using sound;
    //stream := make_stream(*sound.snd, .MUSIC);
    //set_repeating(stream, repeat);
    //start_playing(stream);
    stream := stage_sound(*snd, .GENERAL_SFX, true);
    start_playing(stream);
}

gsound_load_from_bytes :: (sound : *gSound, id : string, data : string) {
    using sound;
    sound.name = id;
    snd = load_audio_data(id, data);
}

gsound_load_from_file :: (sound : *gSound, id : string, path : string) {
    using sound;
    sound.name = id;
    sound = load_audio_file(path);
}

stage_sound :: (data: *Sound_Data, category := Sound_Category.GENERAL_SFX, perturb := true) -> *Sound_Stream {
    stream := make_stream(data, category);
    // if perturb {
    //     stream.user_volume_scale = random_get_within_range(0.5, 1.4);
    //     stream.rate_scale        = random_get_within_range(0.7, 1.22);
    // }
    return stream;
}