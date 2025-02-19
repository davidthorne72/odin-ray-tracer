package main

import "core:math"
import "core:fmt"

HitRecord :: struct {
    hit_point : Point30,
    normal : Vec30,
    t: f32,
    front_face: bool,
    material: ^Material
}

Vec30 :: distinct [4] f32
Point30 :: Vec30
Colour30 :: Vec30
Pixel :: distinct [3] int

Ray :: struct {
    origin : Point30,
    direction : Vec30
}

at :: proc(ray: ^Ray, t: f32) -> Point30 {
    return ray.origin + t * ray.direction;
}

dotv30 :: proc(vector_a: Vec30, vector_b: Vec30) -> f32 {
    return vector_a[0]*vector_b[0] + vector_a[1]*vector_b[1] + vector_a[2]*vector_b[2];
}

length :: proc(vector: Vec30) -> f32 {
    return math.sqrt(dotv30(vector, vector));
}

unit_vector :: proc(vector: Vec30) -> Vec30 {
    return vector / length(vector);
}

set_face_normal :: proc(ray: ^Ray, outward_normal: ^Vec30, hit_record: ^HitRecord) {
    hit_record.front_face = dotv30(ray.direction, outward_normal^) < 0;
    hit_record.normal = hit_record.front_face ? outward_normal^: -outward_normal^;
}

write_colour :: proc(pixel_colour: Colour30) {
    r : f32 = linear_to_gamma(pixel_colour[0]);
    g: f32 = linear_to_gamma(pixel_colour[1]);
    b: f32 = linear_to_gamma(pixel_colour[2]);
    interval: Interval = Interval{0.000, 0.999};


    rbyte : int = int(256 * clamp_double(interval, r));
    gbyte : int = int(256 * clamp_double(interval, g));
    bbyte : int = int(256 * clamp_double(interval, b));

    fmt.printf("%d %d %d\n", rbyte, gbyte, bbyte);
}