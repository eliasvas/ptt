#import "Basic";
#import "Input";
#import "System";
#import "Math";
#import "GL";
#import "SDL";
//TODO: now that a sphere has been generated, maybe we need some way to procgen basic PBR textures
//TODO: generate rect -> generate cube (same tc) -> generate skybox?!

//alignment
gVertex :: struct {
    pos : gVec3;
    norm : gVec3;
    tex_coord : gVec2;
}

make_vertex :: () -> gVertex {
    v : gVertex;
    return v;
}

//Generates a simple sphere mesh
//for reference: songho.ca/opengl/gl_sphere.html#example_sphere/
generate_sphere :: (radius : float = 1.0, sector_count : u32 = 8, stack_count : u32 = 8, indexed : bool = false) -> [..] gVertex, [..] u32 {
    vertices : [..] gVec3;
    normals : [..] gVec3;
    tex_coords : [..] gVec2;
    defer array_free(vertices);
    defer array_free(normals);
    defer array_free(tex_coords);

    x, y, z, xy : float;
    nx, ny, nz, length_inv := 1.0 / radius;
    s, t : float;

    sector_step := 2 * PI / sector_count;
    stack_step := PI / stack_count;
    sector_angle, stack_angle: float = 0;

    for i : 0..stack_count {
        stack_angle := PI / 2 - i * stack_step;
        xy = radius * cos(stack_angle);
        z = radius * sin(stack_angle);

        for j : 0..sector_count {
            sector_angle = j * sector_step;

            x = xy * cos(sector_angle);
            y = xy * sin(sector_angle);
            array_add(*vertices, .{x,y,z});

            nx = x * length_inv;
            ny = y * length_inv;
            nz = z * length_inv;
            array_add(*normals, .{nx,ny,nz});

            s = j / cast(float)sector_count;
            t = i / cast(float)stack_count;
            array_add(*tex_coords, .{s,t});
        }
    }
    indices : [..] u32;
    k1, k2 : u32;
    for i : 0..stack_count-1 {
        k1 = i * (sector_count + 1);
        k2 = k1 + sector_count + 1;

        for j : 0..sector_count-1 {
            if i != 0 {
                array_add(*indices, k1);
                array_add(*indices, k2);
                array_add(*indices, k1+1);
            }
            if i != (stack_count-1) {
                array_add(*indices, k1+1);
                array_add(*indices, k2);
                array_add(*indices, k2+1);
            }
            k1+=1;
            k2+=1;
        }
    }

    if indexed {
       sphere : [..] gVertex;
       for i : 0..vertices.count-1 {
           array_add(*sphere, .{ vertices[i], normals[i], tex_coords[i]});
       }
       return sphere, indices; 
    } else {
        defer array_free(indices);
        indices_empty : [..] u32;
        sphere : [..] gVertex;
        for i : indices {
            array_add(*sphere, .{ vertices[i], normals[i], tex_coords[i]});
        }
        return sphere,indices_empty;
    }
}