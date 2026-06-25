const std = @import("std");
const ArrayList = std.ArrayList;

const generator = @import("./generator.zig");
const compute = @import("./compute.zig");

const points_from_json = @import("./points_from_json.zig");
const Point = points_from_json.Point;

const json_module = @import("./json.zig");
const Json = json_module.Json;
const JsonNode = json_module.JsonNode;

const timer = @import("timer");

const repetition_tester = @import("repetition_tester");

comptime {
    _ = @import("./json.zig");
}

pub fn handleCompute(allocator: std.mem.Allocator, io: std.Io, input_file_path: []const u8, compare_to_path: ?[]const u8) !void {
    try timer.initTimer(allocator);

    const input_file = try std.Io.Dir.cwd().openFile(io, input_file_path, .{});
    const input_file_size = (try input_file.stat(io)).size;
    try timer.start("input read", input_file_size);
    const input_data = try allocator.alloc(u8, input_file_size);
    _ = try input_file.readPositionalAll(io, input_data, 0);
    defer allocator.free(input_data);
    input_file.close(io);
    timer.stop();

    try timer.start("parse", 0);
    try timer.start("Json.parse", 0);
    const json = try Json.parse(allocator, input_data);
    defer json.deinit();
    timer.stop();

    if (json.node) |*node| {
        try timer.start("getPointsFromJson", 0);
        const points = try points_from_json.getPointsFromJson(allocator, node);
        timer.stop();
        timer.stop();

        try timer.start("sum", points.len * @sizeOf(Point));
        const result_data = try compute.compute(allocator, points);
        defer allocator.free(result_data);
        timer.stop();

        if (compare_to_path) |*path| {
            const compare_to_file = try std.Io.Dir.cwd().openFile(io, path.*, .{});
            defer compare_to_file.close(io);
            const compare_to_file_size = (try compare_to_file.stat(io)).size;
            try timer.start("compare read", compare_to_file_size);

            const expected_data_buf = try allocator.alignedAlloc(u8, std.mem.Alignment.@"64", compare_to_file_size);
            const bytes_read = try compare_to_file.readPositionalAll(io, expected_data_buf, 0);
            const expected_data_u8 = expected_data_buf[0..bytes_read];
            const expected_data = std.mem.bytesAsSlice(f64, expected_data_u8);

            timer.stop();

            try compareData(result_data, expected_data);
        } else {
            var stdout_writer = std.Io.File.stdout().writer(io, &.{});
            const stdout = &stdout_writer.interface;

            try stdout.writeAll(std.mem.bytesAsSlice(u8, result_data));
            try stdout.flush();
        }

        try timer.finalize();
    } else return error.JsonNodeNull;
}

fn compareData(computed: []const f64, expected: []align(1) const f64) !void {
    if (computed.len != expected.len) {
        std.debug.print("length mismatch!: computed len: {d}, expected len: {d}\n", .{ computed.len, expected.len });
        return error.LengthMismatch;
    }

    // for (computed, expected, 0..) |computed_num, expected_num, i| {
    //     if (computed_num != expected_num) {
    //         std.debug.print("mismatch at: {d}, computed: {d}, expected: {d}\n", .{ i, computed_num, expected_num });
    //     }
    // }

    const expected_sum = expected[expected.len - 1];
    const computed_sum = computed[computed.len - 1];

    const diff = expected_sum - computed_sum;

    std.debug.print("computed sum: {d}\nexpected sum: {d}\ndiff: {d}\n", .{ computed_sum, expected_sum, diff });
}
