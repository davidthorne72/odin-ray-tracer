package main

import "core:fmt"
import "core:math"

HitRecord :: struct {
	hit_point:  Point30,
	normal:     Vec30,
	t:          f64,
	front_face: bool,
	material:   ^Material,
}

Vec30 :: distinct [4]f64
Point30 :: Vec30
Colour30 :: Vec30
Pixel :: distinct [3]int

Ray :: struct {
	origin:    Point30,
	direction: Vec30,
}

at :: proc(ray: ^Ray, t: f64) -> Point30 {
	return ray.origin + t * ray.direction
}

dotv30 :: proc(vector_a: Vec30, vector_b: Vec30) -> f64 {
	return vector_a[0] * vector_b[0] + vector_a[1] * vector_b[1] + vector_a[2] * vector_b[2]
}

length :: proc(vector: Vec30) -> f64 {
	return math.sqrt(dotv30(vector, vector))
}

unit_vector :: proc(vector: Vec30) -> Vec30 {
	return vector / length(vector)
}

cross :: proc(v: Vec30, u: Vec30) -> Vec30 {
	cross: Vec30 = Vec30{0, 0, 0, 0}
	cross[0] = v[1] * u[2] - v[2] * u[1]
	cross[1] = v[2] * u[0] - v[0] * u[2]
	cross[2] = v[0] * u[1] - v[1] * u[0]
	return cross
}

set_face_normal :: proc(ray: ^Ray, outward_normal: ^Vec30, hit_record: ^HitRecord) {
	hit_record.front_face = dotv30(ray.direction, outward_normal^) < 0
	hit_record.normal = hit_record.front_face ? outward_normal^ : -outward_normal^
}

write_colour :: proc(pixel_colour: Colour30) {
	r: f64 = linear_to_gamma(pixel_colour[0])
	g: f64 = linear_to_gamma(pixel_colour[1])
	b: f64 = linear_to_gamma(pixel_colour[2])
	interval: Interval = Interval{0.000, 0.999}


	rbyte: int = int(256 * clamp_double(interval, r))
	gbyte: int = int(256 * clamp_double(interval, g))
	bbyte: int = int(256 * clamp_double(interval, b))

	fmt.printf("%d %d %d\n", rbyte, gbyte, bbyte)
}
