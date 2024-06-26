#import "freetype-2.12.1";
#import "System";
#import "File";

font_data := #run read_entire_file("assets/fonts/Roboto/Roboto-Medium.ttf");

//This is a glyph WITH its bitmap!
gFontGlyphLoose :: struct {
    c : u8;
    size_x, size_y : s32;
    bearing_x, bearing_y : s32;
    advance : s32;
    bitmap : *u8; //one byte per pixel (opacity)
};

freetype_create_loose_glyphs :: () -> [] gFontGlyphLoose {
    ft_lib : FT_Library;
    face : FT_Face;
    //defer FT_Done_Face(face); //FIXME: There is a memory leak here? why cant we 'Done' the face tho?
    defer FT_Done_FreeType(ft_lib);


    error := FT_Init_FreeType(*ft_lib);
    if error {
        print("FT error: %", error);
    }

    //ttf_name := font_filepath;
    //error = FT_New_Face(ft_lib, ttf_name.data, 0, *face); <--this is how to load a ttf from disk, we load it from memory

    error = FT_New_Memory_Face(ft_lib, font_data.data,xx font_data.count, 0, *face);

    if error {
        print("error loading TTF");
    }

    FT_Set_Pixel_Sizes(face, 0, 64);

    loose_glyphs : [..] gFontGlyphLoose;
    array_resize(*loose_glyphs, 128);
    //TODO: Why exception when 0..128??? Are some characters not implemented or something?
    for i : 32..127 {
        loose_glyphs[i] = gfont_get_glyph_for_character(face,xx i);
    }
    return loose_glyphs;
}


gfont_get_glyph_for_character :: (face : FT_Face, c : u8) -> gFontGlyphLoose {
    err := FT_Load_Char(face, c, FT_LOAD_RENDER); //should this be freed?
    byte_count := face.glyph.bitmap.width*face.glyph.bitmap.rows;
    bitmap : *u8 = alloc(size_of(u8) * byte_count);
    memcpy(dest = bitmap, source = face.glyph.bitmap.buffer, count = size_of(u8) * byte_count);
    return .{c, xx face.glyph.bitmap.width, xx face.glyph.bitmap.rows,face.glyph.bitmap_left,face.glyph.bitmap_top, xx face.glyph.advance.x, bitmap};
}

gFontGlyph :: struct {
    c : u8;// this is not really neaded
    size_x, size_y : s64; //size of glyph in pixels
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


//This is the dumbest implementation possible, just to see that it works, we just advance in the texture
//and write the next character as well as populating its glyph info, for fast lookups
gfont_atlas_generate :: () -> gFontAtlas {
    loose_glyphs := freetype_create_loose_glyphs(); 
    //defer free(loose_glyphs);
    atlas : gFontAtlas;
    start := seconds_since_init();
    //0. calculate the size of the texture from all gFontGlyphLoose's (for now only one dimension : sum_x,max_y)
    max_y := 0;
    sum_x := 0;
    for i : 0..loose_glyphs.count-1{
       sum_x += loose_glyphs[i].size_x; 
       max_y = max(max_y,loose_glyphs[i].size_y); 
    }
    atlas.bitmap = alloc(size_of(u8) * sum_x * max_y); //GL_RED texture
    atlas.size_x = xx sum_x;
    atlas.size_y = xx max_y;
    //1. iterate through all gFontGlyphLoose's and memcpy them to the empty texture (we'll memcpy each line for fast?)
    sum_advance := 0;
    for i : 0..loose_glyphs.count-1 {
        for y : 0..max(loose_glyphs[i].size_y,1)-1 {
            memcpy(dest = *atlas.bitmap[sum_advance + (loose_glyphs[i].size_y-y) * sum_x], source = *loose_glyphs[i].bitmap[y * loose_glyphs[i].size_x], count = loose_glyphs[i].size_x);
        }
        sum_advance += loose_glyphs[i].size_x;
    }
    //2. put correct gFontGlyph's in the same-indexed array 
    sum_advance = 0;
    for i : 0..loose_glyphs.count-1 {
        atlas.glyphs[i] = .{
            c = loose_glyphs[i].c, 
            size_x = loose_glyphs[i].size_x, //xsize in pixels
            size_y = loose_glyphs[i].size_y, //ysize in pixels
            bearing_x = loose_glyphs[i].bearing_x, //make bearing wrt top of bitmap (0,0 in tl)
            bearing_y = loose_glyphs[i].bearing_y,  //make bearing wrt top of bitmap
            tc_x = sum_advance, //tc in atlas texture
            tc_y = max_y - loose_glyphs[i].size_y - 1, //tc in atlas
            advance = xx loose_glyphs[i].advance >> 6
        };
        sum_advance += loose_glyphs[i].size_x;
        //print("glyph[%]=%\n", i, atlas.glyphs[i]);
    }
    print("Font Altas generation Done [%ms]\n", (seconds_since_init()-start)*1000);
    return atlas;
}

gfont_atlas_get_text_scale_to_fit_region :: (atlas : *gFontAtlas, s : string, region : gRect) -> float {
    using atlas;
    f_w,f_h : float = gfont_atlas_get_dim_for_string(atlas,s,1.0);
    ratio_w := (region.w / f_w);
    ratio_h := (region.h / f_h);
    return min(ratio_w, ratio_h);
}


// gfont_atlas_get_max_glyph_height :: (atlas : *gFontAtlas, scale : float = 1.0) -> float {
//     max_h : float = 0;
//     for glyph : atlas.glyphs {
//         max_h = max(max_h, glyph.size_y * scale);
//     }
//     return max_h;
// }

gfont_atlas_deinit :: (atlas : *gFontAtlas) {
    using atlas;
    free(atlas.bitmap);
}

gfont_atlas_get_glyph_for_character :: (atlas : *gFontAtlas, c : u8) -> gFontGlyph {
    using atlas;
    return glyphs[xx c];
}

// Returns the rect produced by a string
gfont_atlas_get_dim_for_string :: (atlas : *gFontAtlas,s : string, scale : float = 1.0) -> width : float, height : float {
    using atlas;
    if s.count == 0 then return 0,0;
    advance_x : float = 0;
    max_h_above_baseline : float = 0;
    max_h_below_baseline : float = 0;
    for i : 0..s.count-1 {
        glyph := gfont_atlas_get_glyph_for_character(atlas,s[i]);
        advance_x += xx(scale * (glyph.advance));
        max_h_above_baseline = max(max_h_above_baseline, xx(scale*(glyph.bearing_y)));
        max_h_below_baseline = max(max_h_below_baseline, xx(scale*(glyph.size_y - glyph.bearing_y)));
        //print("%", s);
    }
    advance_x -= gfont_atlas_get_glyph_for_character(atlas,s[s.count-1]).bearing_x;
    return advance_x,(max_h_above_baseline + max_h_below_baseline);
}