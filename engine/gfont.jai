#import "freetype-2.12.1";

//TODO: We should generate the whole atlas as a bitmap?
//TODO: The font should be baked in the .exe
//TODO: SDF?

ft_lib : FT_Library;
face : FT_Face;

// FT_Done_Face(face);
// FT_Done_FreeType(ft);

ft_init :: () -> bool {
    error := FT_Init_FreeType(*ft_lib);
    if error {
        print("FT error: %", error);
    }
    //FIXME: This is WRONGGGGGGGG, we are we adding a path like this HUH
    ttf_name := ".build/CaskaydiaCoveNerdFont-Regular.ttf";
    error = FT_New_Face(ft_lib, ttf_name.data, 0, *face);
    if error {
        print("error loading TTF [%] : %", ttf_name, error);
    }

    FT_Set_Pixel_Sizes(face, 0, 48);

    return xx(error);
}


gfont_get_bitmap_for_character :: (c : u8) -> [..]u8, u32, u32, s32, s32 {
    FT_Load_Char(face, c, FT_LOAD_RENDER);
    bitmap : [..] u8;
    for i : 0..face.glyph.bitmap.width*face.glyph.bitmap.rows-1 {
        array_add(*bitmap, xx face.glyph.bitmap.buffer[i]);
    }

    return bitmap, face.glyph.bitmap.width, face.glyph.bitmap.rows, face.glyph.bitmap_left, face.glyph.bitmap_top;
}
