package main

import "core:fmt"
import "core:math"

Camera :: struct { 
  image_width: int,
  image_height: int,
  aspect_ratio: f32,
  center: Point30,
  pixel00_loc: Point30,
  pixel_delta_u: Vec30,
  pixel_delta_v: Vec30,
  samples_per_pixel: int,
  pixel_samples_scale: f32,
  max_depth: int
 }

main :: proc() {
  aspect_ratio: f32 = 16.0 / 9.0;
  material_ground: Material = Material{MaterialType.Lambertian, Colour30{0.8, 0.8, 0.0, 0.0}, 0.0};
  material_center: Material = Material{MaterialType.Lambertian, Colour30{0.1, 0.2, 0.5, 0.0}, 0.0};
  material_left: Material = Material{MaterialType.Glass, Colour30{1.0, 1.0, 1.0 , 0.0}, 1.0/1.33};
  material_right: Material = Material{MaterialType.Metal, Colour30{0.8, 0.6, 0.2, 0.0}, 1.0};
  
  sphere_one: Sphere = Sphere{Point30{0.0, -100.5, -1.0, 0}, 100.0, &material_ground};
  sphere_two: Sphere = Sphere{Point30{0.0, 0.0, -1.2, 0}, 0.5, &material_center};
  sphere_three: Sphere = Sphere{Point30{-1.0, 0.0, -1.0, 0}, 0.5, &material_left};
  sphere_four: Sphere = Sphere{Point30{1.0, 0.0, -1.0, 0}, 0.5, &material_right};
  
  spheres: [dynamic]^Sphere;

  append(&spheres, &sphere_one);
  append(&spheres, &sphere_two);
  append(&spheres, &sphere_three);
  append(&spheres, &sphere_four);
  
  camera: Camera = Camera{};
  initialize_camera(&camera, 1920, 16.0/9.0, 100);
  render(spheres, &camera);
}

render :: proc(spheres: [dynamic]^Sphere, camera: ^Camera) {
  fmt.printf("P3\n");
  fmt.printf("%d %d\n255\n", camera.image_width, camera.image_height);
  for j := 0; j < camera.image_height; j += 1 {
    for i := 0; i < camera.image_width; i += 1 {
      colour : Colour30 = Colour30{0, 0, 0, 0};
      for k := 0; k < camera.samples_per_pixel; k += 1 {
        ray: Ray = get_ray(camera, i, j);
        colour += ray_colour(spheres, &ray, camera.max_depth);
      }
      write_colour(camera.pixel_samples_scale * colour);
    }
  }
}

get_ray :: proc(camera: ^Camera, i: int, j: int) -> Ray {
  offset : Point30 = sample_square();
  pixel_sample: Point30 = camera.pixel00_loc + ((f32(i) + offset[0]) * camera.pixel_delta_u) + ((f32(j) + offset[1]) * camera.pixel_delta_v);
  ray_origin: Point30 = camera.center;
  ray_direction: Vec30 = pixel_sample - ray_origin;
  return Ray{ray_origin, ray_direction};
}

initialize_camera :: proc(camera: ^Camera, image_width: int = 100, aspect_ratio: f32 = 1.0, samples_per_pixel: int = 100) {
  camera.image_width = image_width;
  camera.aspect_ratio = aspect_ratio;
  camera.samples_per_pixel = samples_per_pixel;
  camera.pixel_samples_scale = 1.0 / f32(camera.samples_per_pixel);
  camera.max_depth = 50;

  image_height: int = int(f32(image_width) / aspect_ratio);
  camera.image_height = (image_height < 1) ? 1.0 : image_height;
  camera.center = Point30{0, 0, 0, 0};

  focal_length: f32 = 1.0;
  viewport_height: f32 = 2.0;
  viewport_width: f32 = viewport_height * f32(camera.image_width) / f32(camera.image_height);

  viewport_u: Vec30 = Vec30{viewport_width, 0, 0, 0};
  viewport_v: Vec30 = Vec30{0, -viewport_height, 0, 0};

  camera.pixel_delta_u = viewport_u / f32(image_width);
  camera.pixel_delta_v = viewport_v / f32(image_height);

  viewport_upper_left: Point30 = camera.center - Vec30{0, 0, focal_length, 0} - (viewport_u / 2) - (viewport_v / 2);

  camera.pixel00_loc = viewport_upper_left + 0.5 * (camera.pixel_delta_u + camera.pixel_delta_v);
}
