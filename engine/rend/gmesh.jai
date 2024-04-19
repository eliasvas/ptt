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


// void Cubesphere::buildVerticesSmooth()
// {
//     // generate unit-length verties in +X face
//     std::vector<float> unitVertices = Cubesphere::getUnitPositiveX(vertex_count_per_row);

//     // clear memory of prev arrays
//     clearArrays();

//     float x, y, z, s, t;
//     int k = 0, k1, k2;

//     // build +X face
//     for(unsigned int i = 0; i < vertex_count_per_row; ++i)
//     {
//         k1 = i * vertex_count_per_row;     // index for curr row
//         k2 = k1 + vertex_count_per_row;    // index for next row
//         t = (float)i / (vertex_count_per_row - 1);

//         for(unsigned int j = 0; j < vertex_count_per_row; ++j, k += 3, ++k1, ++k2)
//         {
//             x = unitVertices[k];
//             y = unitVertices[k+1];
//             z = unitVertices[k+2];
//             s = (float)j / (vertex_count_per_row - 1);
//             addVertex(x*radius, y*radius, z*radius);
//             addNormal(x, y, z);
//             addTexCoord(s, t);

//             // add indices
//             if(i < (vertex_count_per_row-1) && j < (vertex_count_per_row-1))
//             {
//                 addIndices(k1, k2, k1+1);
//                 addIndices(k1+1, k2, k2+1);
//                 // lines: left and top
//                 lineIndices.push_back(k1);  // left
//                 lineIndices.push_back(k2);
//                 lineIndices.push_back(k1);  // top
//                 lineIndices.push_back(k1+1);
//             }
//         }
//     }

//     // array size and index for building next face
//     unsigned int start_index;                    // starting index for next face
//     int vertex_size = (int)vertices.size();      // vertex array size of +X face
//     int index_size = (int)indices.size();        // index array size of +X face
//     int lineIndexSize = (int)lineIndices.size(); // line index size of +X face

//     // build -X face by negating x and z
//     start_index = vertices.size() / 3;
//     for(int i = 0, j = 0; i < vertex_size; i += 3, j += 2)
//     {
//         addVertex(-vertices[i], vertices[i+1], -vertices[i+2]);
//         addTexCoord(texCoords[j], texCoords[j+1]);
//         addNormal(-normals[i], normals[i+1], -normals[i+2]);
//     }
//     for(int i = 0; i < index_size; ++i)
//     {
//         indices.push_back(start_index + indices[i]);
//     }
//     for(int i = 0; i < lineIndexSize; i += 4)
//     {
//         // left and bottom lines
//         lineIndices.push_back(start_index + lineIndices[i]);     // left
//         lineIndices.push_back(start_index + lineIndices[i+1]);
//         lineIndices.push_back(start_index + lineIndices[i+1]);  // bottom
//         lineIndices.push_back(start_index + lineIndices[i+1] + 1);
//     }

//     // build +Y face by swapping x=>y, y=>-z, z=>-x
//     start_index = vertices.size() / 3;
//     for(int i = 0, j = 0; i < vertex_size; i += 3, j += 2)
//     {
//         addVertex(-vertices[i+2], vertices[i], -vertices[i+1]);
//         addTexCoord(texCoords[j], texCoords[j+1]);
//         addNormal(-normals[i+2], normals[i], -normals[i+1]);
//     }
//     for(int i = 0; i < index_size; ++i)
//     {
//         indices.push_back(start_index + indices[i]);
//     }
//     for(int i = 0; i < lineIndexSize; ++i)
//     {
//         // top and left lines (same as +X)
//         lineIndices.push_back(start_index + lineIndices[i]);
//     }

//     // build -Y face by swapping x=>-y, y=>z, z=>-x
//     start_index = vertices.size() / 3;
//     for(int i = 0, j = 0; i < vertex_size; i += 3, j += 2)
//     {
//         addVertex(-vertices[i+2], -vertices[i], vertices[i+1]);
//         addTexCoord(texCoords[j], texCoords[j+1]);
//         addNormal(-normals[i+2], -normals[i], normals[i+1]);
//     }
//     for(int i = 0; i < index_size; ++i)
//     {
//         indices.push_back(start_index + indices[i]);
//     }
//     for(int i = 0; i < lineIndexSize; i += 4)
//     {
//         // top and right lines
//         lineIndices.push_back(start_index + lineIndices[i]); // top
//         lineIndices.push_back(start_index + lineIndices[i+3]);
//         lineIndices.push_back(start_index + lineIndices[i] + 1); // right
//         lineIndices.push_back(start_index + lineIndices[i+1] + 1);
//     }

//     // build +Z face by swapping x=>z, z=>-x
//     start_index = vertices.size() / 3;
//     for(int i = 0, j = 0; i < vertex_size; i += 3, j += 2)
//     {
//         addVertex(-vertices[i+2], vertices[i+1], vertices[i]);
//         addTexCoord(texCoords[j], texCoords[j+1]);
//         addNormal(-normals[i+2], normals[i+1], normals[i]);
//     }
//     for(int i = 0; i < index_size; ++i)
//     {
//         indices.push_back(start_index + indices[i]);
//     }
//     for(int i = 0; i < lineIndexSize; ++i)
//     {
//         // top and left lines (same as +X)
//         lineIndices.push_back(start_index + lineIndices[i]);
//     }

//     // build -Z face by swapping x=>-z, z=>x
//     start_index = vertices.size() / 3;
//     for(int i = 0, j = 0; i < vertex_size; i += 3, j += 2)
//     {
//         addVertex(vertices[i+2], vertices[i+1], -vertices[i]);
//         addTexCoord(texCoords[j], texCoords[j+1]);
//         addNormal(normals[i+2], normals[i+1], -normals[i]);
//     }
//     for(int i = 0; i < index_size; ++i)
//     {
//         indices.push_back(start_index + indices[i]);
//     }
//     for(int i = 0; i < lineIndexSize; i += 4)
//     {
//         // left and bottom lines
//         lineIndices.push_back(start_index + lineIndices[i]);     // left
//         lineIndices.push_back(start_index + lineIndices[i+1]);
//         lineIndices.push_back(start_index + lineIndices[i+1]);   // bottom
//         lineIndices.push_back(start_index + lineIndices[i+1] + 1);
//     }

//     // generate interleaved vertex array
//     buildInterleavedVertices();
// }

comp_scale_for_length :: (v : [3] float, length : float) -> float{
    return length / sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
}

get_unit_positive_x :: (pointsPerRow : u32) -> [..] float {
    DEG2RAD := acos(-1.0) / 180.0;

    vertices : [..] float;
    n1 : [3] float;
    n2 : [3] float;
    v : [3] float;
    a1 : float;
    a2 : float;
    scale : float;

    // rotate latitudinal plane from 45 to -45 degrees along Z-axis
    for i : 0..pointsPerRow-1 {
        a2 = DEG2RAD * (45.0 - 90.0 * i / (pointsPerRow - 1));
        n2[0] = -sin(a2);
        n2[1] = cos(a2);
        n2[2] = 0;
        for j : 0..pointsPerRow-1 {
            a1 = DEG2RAD * (-45.0 + 90.0 * j / (pointsPerRow - 1));
            n1[0] = -sin(a1);
            n1[1] = 0;
            n1[2] = -cos(a1);

            // find direction vector of intersected line, n1 x n2
            v[0] = n1[1] * n2[2] - n1[2] * n2[1];
            v[1] = n1[2] * n2[0] - n1[0] * n2[2];
            v[2] = n1[0] * n2[1] - n1[1] * n2[0];

            // normalize direction vector
            scale = comp_scale_for_length(v, 1);
            v[0] *= scale;
            v[1] *= scale;
            v[2] *= scale;

            array_add(*vertices,v[0]);
            array_add(*vertices,v[1]);
            array_add(*vertices,v[2]);
        }
    }

    return vertices;
}

generate_cube_sphere :: (radius : float = 1.0, only_front : bool = true) -> [..] gVertex, [..] u32 {
    indices : [..] u32;
    vertices : [..] gVec3;
    normals : [..] gVec3;
    tex_coords : [..] gVec2;
    defer array_free(vertices);
    defer array_free(normals);
    defer array_free(tex_coords);

    vertex_count_per_row : int = 10; // TODO -- changeme!!!

    x, y, z, xy : float;
    s, t : float;

    unit_vertices : [..] float = get_unit_positive_x(xx vertex_count_per_row);

    k, k1, k2 : int;
    for i : 0..vertex_count_per_row-1 {
        k1 = i * vertex_count_per_row;
        k2 = k1 + vertex_count_per_row;
        t = cast(float)i / (vertex_count_per_row - 1);

        for j : 0..vertex_count_per_row-1 {
            x = unit_vertices[k];
            y = unit_vertices[k+1];
            z = unit_vertices[k+2];
            s = cast(float)j / (vertex_count_per_row - 1);
            array_add(*vertices,.{x*radius, y*radius, z*radius});
            array_add(*normals, .{x, y, z});
            array_add(*tex_coords, .{s, t});

            if i < (vertex_count_per_row-1) && j < (vertex_count_per_row-1) {
                array_add(*indices, cast(u32)k1);
                array_add(*indices, cast(u32)k2);
                array_add(*indices, cast(u32)k1+1);
                array_add(*indices, cast(u32)k1+1);
                array_add(*indices, cast(u32)k2);
                array_add(*indices, cast(u32)k2+1);
            }
            k += 3;
            k1+=1;
            k2+=1;
        }
    }


    start_index : u32;
    vertex_size : u32 = cast(u32)(vertices.count*3);
    index_size : u32 = cast(u32)indices.count;

    start_index = cast(u32)(vertices.count);
    j : u32 = 0;
    for i : 0..vertex_size-1 {
        verts : *float = cast(*float)vertices.data;
        tc : *float = cast(*float)tex_coords.data;
        norm : *float = cast(*float)normals.data;
        array_add(*vertices, .{-verts[i], verts[i+1], -verts[i+2]});
        array_add(*tex_coords, .{tc[j], tc[j+1]});
        array_add(*normals, .{-norm[i], norm[i+1], -norm[i+2]});
        i+=2;
        j+=2;
    }
    for i : 0..index_size-1 {
        array_add(*indices, start_index + indices[i]);
    }

    start_index = cast(u32)(vertices.count);
    j = 0;
    for i : 0..vertex_size-1 {
        verts : *float = cast(*float)vertices.data;
        tc : *float = cast(*float)tex_coords.data;
        norm : *float = cast(*float)normals.data;
        array_add(*vertices, .{-verts[i+2], verts[i], -verts[i+1]});
        array_add(*tex_coords, .{tc[j], tc[j+1]});
        array_add(*normals, .{-norm[i+2], norm[i], -norm[i+1]});
        i+=2;
        j+=2;
    }
    for i : 0..index_size-1 {
        array_add(*indices, start_index + indices[i]);
    }

    start_index = cast(u32)(vertices.count);
    j = 0;
    for i : 0..vertex_size-1 {
        verts : *float = cast(*float)vertices.data;
        tc : *float = cast(*float)tex_coords.data;
        norm : *float = cast(*float)normals.data;
        array_add(*vertices, .{-verts[i+2], -verts[i], verts[i+1]});
        array_add(*tex_coords, .{tc[j], tc[j+1]});
        array_add(*normals, .{-norm[i+2], -norm[i], norm[i+1]});
        i+=2;
        j+=2;
    }
    for i : 0..index_size-1 {
        array_add(*indices, start_index + indices[i]);
    }

    start_index = cast(u32)(vertices.count);
    j = 0;
    for i : 0..vertex_size-1 { //THE FRONT FACE
        verts : *float = cast(*float)vertices.data;
        tc : *float = cast(*float)tex_coords.data;
        norm : *float = cast(*float)normals.data;
        array_add(*vertices, .{-verts[i+2], verts[i+1], verts[i]});
        array_add(*tex_coords, .{tc[j], tc[j+1]});
        array_add(*normals, .{-norm[i+2], norm[i+1], norm[i]});
        i+=2;
        j+=2;
    }
    for i : 0..index_size-1 {
        array_add(*indices, start_index + indices[i]);
    }
 
    start_index = cast(u32)(vertices.count);
    j = 0;
    for i : 0..vertex_size-1 { //THE FRONT FACE
        verts : *float = cast(*float)vertices.data;
        tc : *float = cast(*float)tex_coords.data;
        norm : *float = cast(*float)normals.data;
        array_add(*vertices, .{verts[i+2], verts[i+1], -verts[i]});
        array_add(*tex_coords, .{tc[j], tc[j+1]});
        //if only_front then array_add(*tex_coords, .{0,0}); else array_add(*tex_coords, .{tc[j], tc[j+1]});
        array_add(*normals, .{norm[i+2], norm[i+1], -norm[i]});
        i+=2;
        j+=2;
    }
    for i : 0..index_size-1 {
        array_add(*indices, start_index + indices[i]);
    }

    if only_front {
        start_index = 0;
        j = 0;
        for i : 0..(vertex_size*4)-1 {
            tc : *float = cast(*float)tex_coords.data;
            tc[j] = 0.0;
            tc[j+1] = 0.0;
            i+=2;
            j+=2;
        }
    }
      
    sphere : [..] gVertex;
    for i : 0..vertices.count-1 {
        array_add(*sphere, .{ vertices[i], normals[i], tex_coords[i]});
    }
    return sphere, indices; 
}

cube_verts_float : [36*8] float = float.[ 
    // back face
    -1.0, -1.0, -1.0,  0.0,  0.0, -1.0, 0.0, 0.0, // bottom-left
    1.0,  1.0, -1.0,  0.0,  0.0, -1.0, 1.0, 1.0, // top-right
    1.0, -1.0, -1.0,  0.0,  0.0, -1.0, 1.0, 0.0, // bottom-right         
    1.0,  1.0, -1.0,  0.0,  0.0, -1.0, 1.0, 1.0, // top-right
    -1.0, -1.0, -1.0,  0.0,  0.0, -1.0, 0.0, 0.0, // bottom-left
    -1.0,  1.0, -1.0,  0.0,  0.0, -1.0, 0.0, 1.0, // top-left
    // front face
    -1.0, -1.0,  1.0,  0.0,  0.0,  1.0, 0.0, 0.0, // bottom-left
    1.0, -1.0,  1.0,  0.0,  0.0,  1.0, 1.0, 0.0, // bottom-right
    1.0,  1.0,  1.0,  0.0,  0.0,  1.0, 1.0, 1.0, // top-right
    1.0,  1.0,  1.0,  0.0,  0.0,  1.0, 1.0, 1.0, // top-right
    -1.0,  1.0,  1.0,  0.0,  0.0,  1.0, 0.0, 1.0, // top-left
    -1.0, -1.0,  1.0,  0.0,  0.0,  1.0, 0.0, 0.0, // bottom-left
    // left face
    -1.0,  1.0,  1.0, -1.0,  0.0,  0.0, 1.0, 0.0, // top-right
    -1.0,  1.0, -1.0, -1.0,  0.0,  0.0, 1.0, 1.0, // top-left
    -1.0, -1.0, -1.0, -1.0,  0.0,  0.0, 0.0, 1.0, // bottom-left
    -1.0, -1.0, -1.0, -1.0,  0.0,  0.0, 0.0, 1.0, // bottom-left
    -1.0, -1.0,  1.0, -1.0,  0.0,  0.0, 0.0, 0.0, // bottom-right
    -1.0,  1.0,  1.0, -1.0,  0.0,  0.0, 1.0, 0.0, // top-right
    // right face
    1.0,  1.0,  1.0,  1.0,  0.0,  0.0, 1.0, 0.0, // top-left
    1.0, -1.0, -1.0,  1.0,  0.0,  0.0, 0.0, 1.0, // bottom-right
    1.0,  1.0, -1.0,  1.0,  0.0,  0.0, 1.0, 1.0, // top-right         
    1.0, -1.0, -1.0,  1.0,  0.0,  0.0, 0.0, 1.0, // bottom-right
    1.0,  1.0,  1.0,  1.0,  0.0,  0.0, 1.0, 0.0, // top-left
    1.0, -1.0,  1.0,  1.0,  0.0,  0.0, 0.0, 0.0, // bottom-left     
    // bottom face
    -1.0, -1.0, -1.0,  0.0, -1.0,  0.0, 0.0, 1.0, // top-right
    1.0, -1.0, -1.0,  0.0, -1.0,  0.0, 1.0, 1.0, // top-left
    1.0, -1.0,  1.0,  0.0, -1.0,  0.0, 1.0, 0.0, // bottom-left
    1.0, -1.0,  1.0,  0.0, -1.0,  0.0, 1.0, 0.0, // bottom-left
    -1.0, -1.0,  1.0,  0.0, -1.0,  0.0, 0.0, 0.0, // bottom-right
    -1.0, -1.0, -1.0,  0.0, -1.0,  0.0, 0.0, 1.0, // top-right
    // top face
    -1.0,  1.0, -1.0,  0.0,  1.0,  0.0, 0.0, 1.0, // top-left
    1.0,  1.0 , 1.0,  0.0,  1.0,  0.0, 1.0, 0.0, // bottom-right
    1.0,  1.0, -1.0,  0.0,  1.0,  0.0, 1.0, 1.0, // top-right     
    1.0,  1.0,  1.0,  0.0,  1.0,  0.0, 1.0, 0.0, // bottom-right
    -1.0,  1.0, -1.0,  0.0,  1.0,  0.0, 0.0, 1.0, // top-left
    -1.0,  1.0,  1.0,  0.0,  1.0,  0.0, 0.0, 0.0  // bottom-left        
];

generate_cube :: (indexed : bool = false) -> [..] gVertex, [..] u32 {
    //vert_count = 36
    verts : [..] gVertex;
    indices : [..] u32;
    vert_basep := cast(*gVertex) cube_verts_float.data;
    for i : 0..35 {
        array_add(*verts, vert_basep[i]);
    } 
    if (indexed){
        for i : 0..35 {
            array_add(*indices, cast(u32)i);
        }
    }
    return verts,indices;
}

