package main

import "core:fmt"
import "core:log"
import "core:math"

HitRecord :: struct {
  hit_point : Point30,
  normal : Vec30,
  t: f32,
  front_face: bool
}

Vec30 :: distinct [4] f32
Point30 :: Vec30
Colour30 :: Vec30
Pixel :: distinct [3] int
Ray :: struct { origin : Point30, direction : Vec30 }
Sphere :: struct { center : Point30, radius : f32 }
Interval :: struct { min: f32, max: f32 }

size :: proc(interval: ^Interval) -> f32 {
  return interval.max - interval.min;
}

contains :: proc(interval: ^Interval, x: f32) -> bool {
  return interval.min <= x && x <= interval.max;
}

surrounds :: proc(interval: ^Interval, x: f32) -> bool {
  return interval.min < x && x < interval.max;  
}

create_interval :: proc() -> Interval {
  interval : Interval = Interval{math.F32_MIN, math.F32_MAX};
  return interval;
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

hit_sphere :: proc(sphere: ^Sphere, ray: ^Ray, ray_t: ^Interval, hit_record: ^HitRecord) -> bool {
  oc: Vec30 = sphere.center - ray.origin;
  a: f32 = dotv30(ray.direction, ray.direction);
  h: f32 = dotv30(ray.direction, oc);
  c: f32 = dotv30(oc, oc) - sphere.radius * sphere.radius;
  
  discriminant: f32 = h * h - a * c;
  if (discriminant < 0) {
    return false;
  }
  sqrt_discriminant: f32 = math.sqrt(discriminant);
  root: f32 = (h - sqrt_discriminant) / a;
  if !surrounds(ray_t, root) {
    root = (h + sqrt_discriminant) / a;
    if !surrounds(ray_t, root) {
      return false;
    }
  }
  hit_record.t = root;
  hit_record.hit_point = at(ray, hit_record.t);
  outward_normal: Vec30 = (hit_record.hit_point - sphere.center) / sphere.radius;
  set_face_normal(ray, &outward_normal, hit_record);
  return true;
}

compute_hits :: proc(spheres: [dynamic]^Sphere, ray: ^Ray, ray_t: ^Interval, hit_record: ^HitRecord) ->bool {
  temp_hit_record: HitRecord;
  hit_anything: bool = false;
  closest_so_far: f32 = ray_t.max;
  for sphere in spheres {
    
    if hit_sphere(sphere, ray, &Interval{ray_t.min, closest_so_far}, &temp_hit_record) {
      hit_anything = true;
      closest_so_far = temp_hit_record.t;
      hit_record^ = temp_hit_record;
    }
  }
  return hit_anything;
}

ray_colour :: proc(spheres: [dynamic]^Sphere, ray: ^Ray) -> Colour30 {
  hit_record: HitRecord;
  if compute_hits(spheres, ray, &Interval{0, math.F32_MAX}, &hit_record) {
    return 0.5 * (hit_record.normal + Colour30{1, 1, 1, 0});
  }
  unit_direction: Vec30 = unit_vector(ray.direction);
  a: f32 = 0.5*(unit_direction[1] + 1.0);
  return (1.0 - a) * Colour30{1.0, 1.0, 1.0, 0} + a * Colour30{0.5, 0.7, 1.0, 0}; 
}

main :: proc() {
  aspect_ratio: f32 = 16.0 / 9.0;
  
  image_width: int = 400;
  image_height: int = int(f32(image_width) / aspect_ratio);
  image_height = (image_height < 1) ? 1.0 : image_height;
  camera_center: Point30 = Point30{0, 0, 0, 0};
  
  focal_length: f32 = 1.0;
  viewport_height: f32 = 2.0;
  viewport_width: f32 = viewport_height * f32(image_width) / f32(image_height);
  
  viewport_u: Vec30 = Vec30{viewport_width, 0, 0, 0};
  viewport_v: Vec30 = Vec30{0, -viewport_height, 0, 0};
  
  pixel_delta_u: Vec30 = viewport_u / f32(image_width);
  pixel_delta_v: Vec30 = viewport_v / f32(image_height);
  
  viewport_upper_left: Point30 = camera_center - Vec30{0, 0, focal_length, 0} - (viewport_u / 2) - (viewport_v / 2);
  
  pixel00_loc: Point30 = viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v);
  sphere_two: Sphere = Sphere{Point30{0, 0, -1, 0}, 0.5};
  sphere_one: Sphere = Sphere{Point30{0, -100.5, -1, 0}, 100};
  spheres: [dynamic]^Sphere;
  append(&spheres, &sphere_two);
  append(&spheres, &sphere_one);
  
  fmt.printf("P3\n");
  fmt.printf("%d %d\n255\n", image_width, image_height);
  for j := 0; j < image_height; j += 1 {
    for i := 0; i < image_width; i += 1 {
      pixel_center: Point30 = pixel00_loc + (f32(i) * pixel_delta_u) + (f32(j) * pixel_delta_v);
      ray_direction: Vec30 = pixel_center - camera_center;
      ray: Ray = Ray{camera_center, ray_direction};
      pixel_color : Colour30 = ray_colour(spheres, &ray);
      write_colour(pixel_color);
    } 
  }
}

write_colour :: proc(pixel_colour: Colour30) {
  r : f32 = pixel_colour[0];
  g: f32 = pixel_colour[1];
  b: f32 = pixel_colour[2];

  rbyte : int = int(255.999 * r);
  gbyte : int = int(255.999 * g);
  bbyte : int = int(255.999 * b);

  fmt.printf("%d %d %d\n", rbyte, gbyte, bbyte);
}