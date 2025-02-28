package main

import "core:fmt"
import "core:math"

Camera :: struct {
	image_width:         int,
	image_height:        int,
	aspect_ratio:        f64,
	center:              Point30,
	pixel00_loc:         Point30,
	pixel_delta_u:       Vec30,
	pixel_delta_v:       Vec30,
	samples_per_pixel:   int,
	pixel_samples_scale: f64,
	max_depth:           int,
	vfov:                f64,
	look_from:           Point30,
	look_at:             Point30,
	vup:                 Vec30,
	u:                   Vec30,
	v:                   Vec30,
	w:                   Vec30,
}

main :: proc() {
	aspect_ratio: f64 = 16.0 / 9.0
	material_left: Material = Material{MaterialType.Metal, Colour30{0.0, 0.0, 1.0, 0.0}, 0.0}
	material_right: Material = Material{MaterialType.Glass, Colour30{1.0, 1.0, 1.0, 0.0}, 0.0}
	R: f64 = math.cos_f64(math.PI / 4)
	sphere_one: Sphere = Sphere{Point30{-R, 0.0, -1.0, 0}, R, &material_right}
	sphere_two: Sphere = Sphere{Point30{R, 0.0, -1.0, 0}, R, &material_left}

	spheres: [dynamic]^Sphere

	append(&spheres, &sphere_two)
	append(&spheres, &sphere_one)

	camera: Camera = Camera{}
	initialize_camera(&camera, 400, 16.0 / 9.0, 100)
	render(spheres, &camera)
}

render :: proc(spheres: [dynamic]^Sphere, camera: ^Camera) {
	fmt.printf("P3\n")
	fmt.printf("%d %d\n255\n", camera.image_width, camera.image_height)
	for j := 0; j < camera.image_height; j += 1 {
		for i := 0; i < camera.image_width; i += 1 {
			colour: Colour30 = Colour30{0, 0, 0, 0}
			for k := 0; k < camera.samples_per_pixel; k += 1 {
				ray: Ray = get_ray(camera, i, j)
				colour += ray_colour(spheres, &ray, camera.max_depth)
			}
			write_colour(camera.pixel_samples_scale * colour)
		}
	}
}

get_ray :: proc(camera: ^Camera, i: int, j: int) -> Ray {
	offset: Point30 = sample_square()
	pixel_sample: Point30 =
		camera.pixel00_loc +
		((f64(i) + offset[0]) * camera.pixel_delta_u) +
		((f64(j) + offset[1]) * camera.pixel_delta_v)
	ray_origin: Point30 = camera.center
	ray_direction: Vec30 = pixel_sample - ray_origin
	return Ray{ray_origin, ray_direction}
}

initialize_camera :: proc(
	camera: ^Camera,
	image_width: int = 100,
	aspect_ratio: f64 = 1.0,
	samples_per_pixel: int = 100,
	vfov: int = 90,
	look_from: Vec30 = Vec30{0, 0, 0, 0},
	look_at: Vec30 = Vec30{0, 0, -1, 0},
	vup: Vec30 = Vec30{0, 1, 0, 0},
) {
	camera.image_width = image_width
	camera.aspect_ratio = aspect_ratio
	camera.samples_per_pixel = samples_per_pixel
	camera.pixel_samples_scale = 1.0 / f64(camera.samples_per_pixel)
	camera.max_depth = 50

	image_height: int = int(f64(image_width) / aspect_ratio)
	camera.image_height = (image_height < 1) ? 1.0 : image_height
	camera.center = look_from

	dot_op: Vec30 = look_from - look_at
	focal_length: f64 = math.sqrt(dotv30(dot_op, dot_op))
	theta: f64 = f64(math.DEG_PER_RAD) * f64(vfov)
	h: f64 = math.tan_f64(theta / 2.0)
	viewport_height: f64 = 2 * h * focal_length
	viewport_width: f64 = viewport_height * f64(camera.image_width) / f64(camera.image_height)

	w: Vec30 = unit_vector(look_from - look_at)
	u: Vec30 = unit_vector(cross(vup, w))
	v: Vec30 = cross(w, u)

	viewport_u: Vec30 = viewport_width * u
	viewport_v: Vec30 = viewport_height * -v

	camera.pixel_delta_u = viewport_u / f64(image_width)
	camera.pixel_delta_v = viewport_v / f64(image_height)

	viewport_upper_left: Point30 =
		camera.center - (focal_length * w) - (viewport_u / 2) - (viewport_v / 2)
	camera.pixel00_loc = viewport_upper_left + 0.5 * (camera.pixel_delta_u + camera.pixel_delta_v)
}
