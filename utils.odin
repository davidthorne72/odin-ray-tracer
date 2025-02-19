package main

import "core:math/rand"
import "base:builtin"
import "core:math"

Interval :: struct {
    min: f32,
    max: f32
}

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

random_double :: proc() -> f32 {
    return rand.float32();
}

sample_square :: proc() -> Vec30 {
    return Vec30{random_double() - 0.5, random_double() - 0.5, 0, 0};
}

random_double_in_interval :: proc(interval: Interval, ) -> f32 {
    return rand.float32_range(interval.min, interval.max);
}

clamp_double :: proc(interval: Interval, x: f32) -> f32 {
    return builtin.clamp(x, interval.min, interval.max);
}

random_vector :: proc() -> Vec30 {
    return Vec30{random_double(), random_double(), random_double(), 0};
}

random_clamped_vector :: proc(min: f32, max: f32) -> Vec30 {
    return Vec30{rand.float32_range(min, max), rand.float32_range(min, max), rand.float32_range(min, max), 0};
}

random_unit_vector :: proc() -> Vec30 {
    for {
        p: Vec30 = random_clamped_vector(-1.0, 1.0);
        lensq: f32 = dotv30(p, p);
        if 1e-45 < lensq && lensq <= 1 {
            return p / math.sqrt(lensq);
        }
    }
}

random_on_hemisphere :: proc(normal: ^Vec30) -> Vec30 {
    on_unit_sphere: Vec30 = random_unit_vector();
    if dotv30(on_unit_sphere, normal^) > 0.0 {
        return on_unit_sphere;
    }
    return -on_unit_sphere;
}

linear_to_gamma :: proc(linear_component: f32) -> f32 {
    if (linear_component > 0) {
        return math.sqrt(linear_component)
    }
    return 0;
}

near_zero :: proc(vec: Vec30) -> bool {
    s: f32 = 1e-8;
    return (math.abs(vec[0]) < s && math.abs(vec[1]) < s && math.abs(vec[2]) < s);
}

reflect :: proc(v: ^Vec30, n: ^Vec30) -> Vec30 {
    return v^ - 2 * dotv30(v^, n^) * n^;
}