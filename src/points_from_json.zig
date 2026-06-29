const std = @import("std");

const json_module = @import("./json.zig");
const Json = json_module.Json;
const JsonNode = json_module.JsonNode;

pub const Point = struct {
    x0: f64,
    y0: f64,
    x1: f64,
    y1: f64,
};

fn get_number_from_map(map: *const std.StringHashMap(JsonNode), comptime name: []const u8) !f64 {
    const node = map.get(name) orelse return error.InvalidJson;
    const num = switch (node) {
        .Number => |n| n,
        else => return error.InvalidJson,
    };
    return num;
}

pub fn getPointsFromJson(allocator: std.mem.Allocator, json: *const JsonNode) ![]Point {
    const root = switch (json.*) {
        .Record => |*r| r,
        else => return error.InvalidJson,
    };
    const pairs = root.get("pairs") orelse return error.InvalidJson;

    const cord_array = switch (pairs) {
        .Array => |*a| a,
        else => return error.InvalidJson,
    };
    const points_array: []Point = try allocator.alloc(Point, cord_array.len);

    for (cord_array.*, 0..) |*cord_element, i| {
        const cord_record = switch (cord_element.*) {
            .Record => |*r| r,
            else => return error.InvalidJson,
        };
        const x0 = try get_number_from_map(cord_record, "x0");
        const y0 = try get_number_from_map(cord_record, "y0");
        const x1 = try get_number_from_map(cord_record, "x1");
        const y1 = try get_number_from_map(cord_record, "y1");

        points_array[i] = .{ .x0 = x0, .y0 = y0, .x1 = x1, .y1 = y1 };
    }

    return points_array;
}
