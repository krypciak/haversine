const std = @import("std");
const json_module = @import("./json/json.zig");
const Json = json_module.Json;
const JsonNode = json_module.JsonNode;

const formula = @import("./formula.zig");

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

pub fn compute(allocator: std.mem.Allocator, json: JsonNode) ![]const f64 {
    switch (json) {
        .Record => |*root| {
            if (root.get("pairs")) |*pairs| {
                switch (pairs.*) {
                    .Array => |*cord_array| {
                        const result_array: []f64 = try allocator.alloc(f64, cord_array.len + 1);
                        var sum: f64 = 0;
                        const sum_coef = formula.sumCoef(cord_array.len);

                        for (cord_array.*, 0..) |*cord_element, i| {
                            switch (cord_element.*) {
                                .Record => |*cord_record| {
                                    const x0 = try get_number_from_map(cord_record, "x0");
                                    const y0 = try get_number_from_map(cord_record, "y0");
                                    const x1 = try get_number_from_map(cord_record, "x1");
                                    const y1 = try get_number_from_map(cord_record, "y1");

                                    const result = formula.referenceHaversine(x0, y0, x1, y1, formula.EARTH_RADIUS);

                                    result_array[i] = result;
                                    sum += sum_coef * result;
                                },
                                else => return error.InvalidJson,
                            }
                        }
                        result_array[cord_array.len] = sum;

                        return result_array;
                    },
                    else => return error.InvalidJson,
                }
            } else return error.InvalidJson;
        },
        else => return error.InvalidJson,
    }
}
