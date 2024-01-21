#import "freetype-2.12.1";

//TODO: We should generate the whole atlas as a bitmap?
//TODO: The font should be baked in the .exe
//TODO: SDF?



//This is a glyph WITH its bitmap!
gFontGlyphLoose :: struct {
    c : u8;
    size_x, size_y : u32;
    bearing_x, bearing_y : s32;
    advance : s32;
    bitmap : *u8; //one byte per pixel (opacity)
};

//There should be a bitmap with all the characters PACKED, and then
//a linear array that has all 128 characters mapped, along with glyph info

ft_init :: () {
    ft_lib : FT_Library;
    face : FT_Face;
    //defer FT_Done_Face(face); //FIXME: There is a memory leak here? why cant we 'Done' the face tho?
    defer FT_Done_FreeType(ft_lib);


    error := FT_Init_FreeType(*ft_lib);
    if error {
        print("FT error: %", error);
    }
    //FIXME: This is WRONGGGGGGGG, we are we adding a path like this HUH
    ttf_name := ".build/Roboto-Medium.ttf";
    error = FT_New_Face(ft_lib, ttf_name.data, 0, *face);
    if error {
        print("error loading TTF [%] : %", ttf_name, error);
    }

    FT_Set_Pixel_Sizes(face, 0, 64);

    loose_glyphs : [128] gFontGlyphLoose;
    //TODO: Why exception when 0..128??? Are some characters not implemented or something?
    for i : 33..127 {
        loose_glyphs[i] = gfont_get_glyph_for_character(face,xx i);
    }
    gfont_generate_atlas(loose_glyphs);
}


gfont_get_glyph_for_character :: (face : FT_Face, c : u8) -> gFontGlyphLoose {
    err := FT_Load_Char(face, c, FT_LOAD_RENDER); //should this be freed?
    byte_count := face.glyph.bitmap.width*face.glyph.bitmap.rows;
    bitmap : *u8 = alloc(size_of(u8) * byte_count);
    memcpy(dest = bitmap, source = face.glyph.bitmap.buffer, count = size_of(u8) * byte_count);
    return .{c, face.glyph.bitmap.width, face.glyph.bitmap.rows,face.glyph.bitmap_left,face.glyph.bitmap_top, face.glyph.advance.x, bitmap};
}

gFontGlyph :: struct {
    c : u8;// this is not really neaded
    size_x, size_y : u64; //size of glyph in pixels
    bearing_x, bearing_y : s64; //offset to left_top coord of glyph
    tc_x, tc_y : s64; //texture coordinated wrt (0,0) in tl
    advance : u32; //how much to advance to put the next glyph
};

gFontAtlas :: struct {
    glyphs : [128] gFontGlyph;
    bitmap : *u8; // GL_RED
    size_x : s32;
    size_y : s32;
}

gfont_atlas : gFontAtlas;

//This is the dumbest implementation possible, just to see that it works, we just advance in the texture
//and write the next character as well as populating its glyph info, for fast lookups
gfont_generate_atlas :: (loose_glyphs : [] gFontGlyphLoose) {
    start := get_time();
    //0. calculate the size of the texture from all gFontGlyphLoose's (for now only one dimension : sum_x,max_y)
    max_y := 0;
    sum_x := 0;
    for i : 0..loose_glyphs.count-1{
       sum_x += loose_glyphs[i].size_x; 
       max_y = max(max_y,loose_glyphs[i].size_y); 
    }
    gfont_atlas.bitmap = alloc(size_of(u8) * sum_x * max_y); //GL_RED texture
    gfont_atlas.size_x = xx sum_x;
    gfont_atlas.size_y = xx max_y;
    //1. iterate through all gFontGlyphLoose's and memcpy them to the empty texture (we'll memcpy each line for fast?)
    sum_advance := 0;
    for i : 0..loose_glyphs.count-1 {
        for y : 0..max(loose_glyphs[i].size_y,1)-1 {
            memcpy(dest = *gfont_atlas.bitmap[sum_advance + (loose_glyphs[i].size_y-y) * sum_x], source = *loose_glyphs[i].bitmap[y * loose_glyphs[i].size_x], count = loose_glyphs[i].size_x);
        }
        sum_advance += loose_glyphs[i].size_x;
    }
    //2. put correct gFontGlyph's in the same-indexed array 
    sum_advance = 0;
    for i : 0..loose_glyphs.count-1 {
        gfont_atlas.glyphs[i] = .{
            c = loose_glyphs[i].c, 
            size_x = loose_glyphs[i].size_x, 
            size_y = loose_glyphs[i].size_y,
            bearing_x = loose_glyphs[i].bearing_x, //make bearing wrt top of bitmap (0,0 in tl)
            bearing_y = loose_glyphs[i].bearing_y,  //make bearing wrt top of bitmap
            tc_x = sum_advance, //tc in atlas
            tc_y = max_y - loose_glyphs[i].size_y-1, //tc in atlas
            advance = xx loose_glyphs[i].advance >> 6 //TODO: subpixel rendering? 
        };
        sum_advance += loose_glyphs[i].size_x;
    }
    print("Font Altas generation Done [%ms]\n", (get_time()-start)*1000);
}

gfont_atlas_get_glyph_for_character :: (c : u8) -> gFontGlyph {
    return gfont_atlas.glyphs[xx c];
}
