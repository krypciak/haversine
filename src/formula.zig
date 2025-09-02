const std = @import("std");
const sin = std.math.sin;
const cos = std.math.cos;
const asin = std.math.asin;
const sqrt = std.math.sqrt;
const degreesToRadians = std.math.degreesToRadians;

fn square(x: f64) f64 {
    return x * x;
}

pub fn sumCoef(len: anytype) f64 {
    return 1.0 / @as(f64, @floatFromInt(len));
}

// NOTE(casey): EarthRadius is generally expected to be 6372.8
pub const EARTH_RADIUS = 6372.8;

pub fn referenceHaversine(X0: f64, Y0: f64, X1: f64, Y1: f64, comptime EarthRadius: f64) f64 {
    //  NOTE(casey): This is not meant to be a "good" way to calculate the Haversine distance.
    //    Instead, it attempts to follow, as closely as possible, the formula used in the real-world
    //    question on which these homework exercises are loosely based.

    var lat1: f64 = Y0;
    var lat2: f64 = Y1;
    const lon1: f64 = X0;
    const lon2: f64 = X1;

    const dLat: f64 = degreesToRadians(lat2 - lat1);
    const dLon: f64 = degreesToRadians(lon2 - lon1);
    lat1 = degreesToRadians(lat1);
    lat2 = degreesToRadians(lat2);

    const a: f64 = square(sin(dLat / 2.0)) + cos(lat1) * cos(lat2) * square(sin(dLon / 2));
    const c: f64 = 2.0 * asin(sqrt(a));

    const result: f64 = EarthRadius * c;

    return result;
}
