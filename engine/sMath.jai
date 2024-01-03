#import "Basic";
#import "System";
//@TODO: SSE2 implementation pending


//this should be a union achyually
sVec2 :: struct {
    x : s32;
    y : s32;
}

svec2_add :: (a : sVec2, b : sVec2) -> sVec2 {
    return .{a.x + b.x, a.y + b.y};
}

svec2_sub :: (a : sVec2, b : sVec2) -> sVec2 {
    return .{a.x - b.x, a.y - b.y};
}

svec2_mult :: (a : sVec2, b : sVec2) -> sVec2 {
    return .{a.x * b.x, a.y * b.y};
}

//@TODO: An error could be returned here? MRT?
svec2_div :: (a : sVec2, b : sVec2) -> sVec2 {
    assert(b.x != 0);
    assert(b.y != 0);
    return .{a.x / b.x, a.y / b.y};
}