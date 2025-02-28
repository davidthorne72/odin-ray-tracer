package main

import "core:math"

Material :: struct {
    type : MaterialType,
    albedo: Colour30,
    param: f64
}

MaterialType :: enum u8 {
    Lambertian,
    Metal,
    Glass
}

Sphere :: struct {
    center : Point30,
    radius : f64,
    material: ^Material
}

// scattering procs
scatter :: proc(material: ^Material, ray_in: ^Ray, hit_record: ^HitRecord, attenuation: ^Colour30, scattered: ^Ray) -> bool {
    switch material.type {
    case MaterialType.Lambertian:
        return lambertian_scatter(material, ray_in, hit_record, attenuation, scattered);
    case MaterialType.Metal:
        return metal_scatter(material, ray_in, hit_record, attenuation, scattered);
    case MaterialType.Glass:
        return glass_scatter(material, ray_in, hit_record, attenuation, scattered);
    }
    return false;
}

lambertian_scatter :: proc(material: ^Material, ray_in: ^Ray, hit_record: ^HitRecord, attenuation: ^Colour30, scattered: ^Ray) -> bool {
    scatter_direction: Vec30 = hit_record.normal + random_unit_vector();

    if (near_zero(scatter_direction)) {
        scatter_direction = hit_record.normal;
    }
    scattered^ = Ray{hit_record.hit_point, scatter_direction};
    attenuation^ = material.albedo;
    return true
}

metal_scatter :: proc(material: ^Material, ray_in: ^Ray, hit_record: ^HitRecord, attenuation: ^Colour30, scattered: ^Ray) -> bool {
    reflected: Vec30 = reflect(&ray_in.direction, &hit_record.normal);
    reflected = unit_vector(reflected) + (material.param * random_unit_vector());
    scattered^= Ray{hit_record.hit_point, reflected};
    attenuation^ = material.albedo;
    return dotv30(scattered.direction, hit_record.normal) > 0;
}

glass_scatter :: proc(material: ^Material, ray_in: ^Ray, hit_record: ^HitRecord, attenuation: ^Colour30, scattered: ^Ray) -> bool {
    attenuation^ = Colour30{1.0, 1.0, 1.0 , 0};
    ri: f64 = hit_record.front_face ? (1.0 / material.param) : material.param;
    unit_direction: Vec30 = unit_vector(ray_in.direction);
    
    cos_theta: f64 = math.min(dotv30(-unit_direction, hit_record.normal), 1.0);
    sin_theta: f64 = math.sqrt(1.0 - cos_theta * cos_theta);
    cannot_refract: bool = material.param * sin_theta > 1.0;
    direction: Vec30;
    
    if cannot_refract || (reflectance(cos_theta, material.param) > random_double()) {
        direction = reflect(&unit_direction, &hit_record.normal);
    }
    else {
        direction = refract(&unit_direction, &hit_record.normal, material.param)
    }
    scattered^ = Ray{hit_record.hit_point, direction};
    return true;
}

reflectance :: proc(cosine: f64, refraction_index: f64) -> f64 {
    r0: f64 = (1.0 - refraction_index) / (1 + refraction_index);
    r0 = r0 * r0;
    return r0 + (1 - r0) * math.pow((1 - cosine), 5)
}

refract :: proc(uv: ^Vec30, n: ^Vec30, etai_over_etat: f64) -> Vec30 {
    cos_theta: f64 = math.min(dotv30(-uv^, n^), 1.0);
    r_out_perp: Vec30 = etai_over_etat * (uv^ + cos_theta * n^);
    r_out_parallel:  Vec30 = -math.sqrt(math.abs(1.0 - dotv30(r_out_perp, r_out_perp))) * n^;
    return r_out_perp + r_out_parallel;
}

hit_sphere :: proc(sphere: ^Sphere, ray: ^Ray, ray_t: ^Interval, hit_record: ^HitRecord) -> bool {
    oc: Vec30 = sphere.center - ray.origin;
    a: f64 = dotv30(ray.direction, ray.direction);
    h: f64 = dotv30(ray.direction, oc);
    c: f64 = dotv30(oc, oc) - sphere.radius * sphere.radius;

    discriminant: f64 = h * h - a * c;
    if (discriminant < 0) {
        return false;
    }
    sqrt_discriminant: f64 = math.sqrt(discriminant);
    root: f64 = (h - sqrt_discriminant) / a;
    if !surrounds(ray_t, root) {
        root = (h + sqrt_discriminant) / a;
        if !surrounds(ray_t, root) {
            return false;
        }
    }
    hit_record.t = root;
    hit_record.hit_point = at(ray, hit_record.t);
    hit_record.material = sphere.material;
    outward_normal: Vec30 = (hit_record.hit_point - sphere.center) / sphere.radius;
    set_face_normal(ray, &outward_normal, hit_record);
    return true;
}

ray_colour :: proc(spheres: [dynamic]^Sphere, ray: ^Ray, depth: int) -> Colour30 {
    if (depth <= 0) {
        return Colour30{0, 0, 0, 0};
    }
    hit_record: HitRecord;
    if compute_hits(spheres, ray, &Interval{0.001, math.F64_MAX}, &hit_record) {

        scattered: Ray = Ray{};
        attenuation: Colour30 = Colour30{};
        if scatter(hit_record.material, ray, &hit_record, &attenuation, &scattered) {
            return attenuation * ray_colour(spheres, &scattered, depth - 1)
        }
    }
    unit_direction: Vec30 = unit_vector(ray.direction);
    a: f64 = 0.5*(unit_direction[1] + 1.0);
    return (1.0 - a) * Colour30{1.0, 1.0, 1.0, 0} + a * Colour30{0.5, 0.7, 1.0, 0};
}

compute_hits :: proc(spheres: [dynamic]^Sphere, ray: ^Ray, ray_t: ^Interval, hit_record: ^HitRecord) ->bool {
    temp_hit_record: HitRecord;
    hit_anything: bool = false;
    closest_so_far: f64 = ray_t.max;
    for sphere in spheres {

        if hit_sphere(sphere, ray, &Interval{ray_t.min, closest_so_far}, &temp_hit_record) {
            hit_anything = true;
            closest_so_far = temp_hit_record.t;
            hit_record^ = temp_hit_record;
        }
    }
    return hit_anything;
}