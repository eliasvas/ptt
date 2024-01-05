#import "Basic";
#import "System";
//@TODO: SSE2 implementation pending


//this should be a union achyually
gVec2 :: struct {
    x : s32;
    y : s32;
}

gvec2_add :: (a : gVec2, b : gVec2) -> gVec2 {
    return .{a.x + b.x, a.y + b.y};
}

gvec2_sub :: (a : gVec2, b : gVec2) -> gVec2 {
    return .{a.x - b.x, a.y - b.y};
}

gvec2_mult :: (a : gVec2, b : gVec2) -> gVec2 {
    return .{a.x * b.x, a.y * b.y};
}

//@TODO: An error could be returned here? MRT?
gvec2_div :: (a : gVec2, b : gVec2) -> gVec2 {
    assert(b.x != 0);
    assert(b.y != 0);
    return .{a.x / b.x, a.y / b.y};
}