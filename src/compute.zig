const std = @import("std");
const Point = @import("./points_from_json.zig").Point;
const formula = @import("./formula.zig");

pub fn compute(allocator: std.mem.Allocator, points: []Point) ![]const f64 {
    const result_array: []f64 = try allocator.alloc(f64, points.len + 1);
    var sum: f64 = 0;
    const sum_coef = formula.sumCoef(points.len);

    for (points, 0..) |point, i| {
        const result = formula.referenceHaversine(point.x0, point.y0, point.x1, point.y1, formula.EARTH_RADIUS);

        result_array[i] = result;
        sum += sum_coef * result;
    }
    result_array[points.len] = sum;

    return result_array;
}
