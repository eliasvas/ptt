using Sound :: #import "Sound_Player";
#import "Random";

gSoundType :: enum {
    SFX;
    MUSIC;
}

gSound :: struct {
    snd : Sound_Data;
    stream : *Sound_Stream;
    name : string;
    type : gSoundType = .SFX;
    rel_volume : float = 10.0;
}

gsound_init :: () {
    devices := get_devices();
    print("Sound devices: %", devices);
    sound_player_init(.{});
}

gsound_update :: () {
    Sound.update();
}

gsound_stop :: (sound : *gSound) {
    using sound;
    stop_stream_abruptly(*snd);
}

gsound_play :: (sound : *gSound,volume : float, repeat : bool = false) {
    using sound;
    if (type == .MUSIC) {
        stream = make_stream(*sound.snd, .MUSIC);
        set_repeating(stream, repeat);
        start_playing(stream);
    }
    else {
        stream = stage_sound(*snd, .GENERAL_SFX, rel_volume*volume);
        start_playing(stream);
    }

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

set_master_vol :: (val : float) {
    set_master_volume(val);
}

stage_sound :: (data: *Sound_Data, category := Sound_Category.GENERAL_SFX, volume : float=1.0) -> *Sound_Stream {
    stream := make_stream(data, category);
    stream.user_volume_scale = volume;
    stream.rate_scale        = 1.0;
    return stream;
}