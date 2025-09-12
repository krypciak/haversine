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
    if (map.get(name)) |*node| {
        switch (node.*) {
            .Number => |*num| {
                return num.*;
            },
            else => return error.InvalidJson,
        }
    } else return error.InvalidJson;
}

pub fn getPointsFromJson(allocator: std.mem.Allocator, json: *const JsonNode) ![]Point {
    switch (json.*) {
        .Record => |*root| {
            if (root.get("pairs")) |*pairs| {
                switch (pairs.*) {
                    .Array => |*cord_array| {
                        const points_array: []Point = try allocator.alloc(Point, cord_array.len);

                        for (cord_array.*, 0..) |*cord_element, i| {
                            switch (cord_element.*) {
                                .Record => |*cord_record| {
                                    const x0 = try get_number_from_map(cord_record, "x0");
                                    const y0 = try get_number_from_map(cord_record, "y0");
                                    const x1 = try get_number_from_map(cord_record, "x1");
                                    const y1 = try get_number_from_map(cord_record, "y1");

                                    points_array[i] = .{ .x0 = x0, .y0 = y0, .x1 = x1, .y1 = y1 };
                                },
                                else => return error.InvalidJson,
                            }
                        }

                        return points_array;
                    },
                    else => return error.InvalidJson,
                }
            } else return error.InvalidJson;
        },
        else => return error.InvalidJson,
    }
}
