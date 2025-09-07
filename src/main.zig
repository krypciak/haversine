const std = @import("std");
const ArrayList = std.ArrayList;

const generator = @import("./generator.zig");
const points_from_json = @import("./points_from_json.zig");
const compute = @import("./compute.zig");

const json_module = @import("./json/json.zig");
const Json = json_module.Json;
const JsonNode = json_module.JsonNode;

comptime {
    _ = @import("./json/json.zig");
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    if (argv.len <= 1) return error.NoArgument;

    const action = argv[1];
    if (std.mem.eql(u8, action, "generate")) {
        if (argv.len <= 2) return error.PointCountMissing;
        const point_count_str = argv[2];

        if (argv.len <= 3) return error.SeedMissing;
        const seed_str = argv[3];

        const point_count = try std.fmt.parseInt(u64, point_count_str, 10);
        const seed = try std.fmt.parseInt(u64, seed_str, 10);
        try generator.writeRandomPoints(point_count, seed);
    } else if (std.mem.eql(u8, action, "compute")) {
        if (argv.len <= 2) return error.InputFileArgumentMissing;
        const input_file_path = argv[2];

        const compare_to_path = if (argv.len <= 3) null else argv[3];

        try handleCompute(allocator, input_file_path, compare_to_path);
    }
}

fn handleCompute(allocator: std.mem.Allocator, input_file_path: []const u8, compare_to_path: ?[]const u8) !void {
    const input_file = try std.fs.cwd().openFile(input_file_path, .{});
    const input_data = try input_file.readToEndAlloc(allocator, 10000000);
    defer allocator.free(input_data);
    input_file.close();

    const json = try Json.parse(allocator, input_data);
    defer json.deinit();

    if (json.node) |*node| {
        const points = try points_from_json.getPointsFromJson(allocator, node);

        const result_data = try compute.compute(allocator, points);
        defer allocator.free(result_data);

        if (compare_to_path) |*path| {
            const compare_to_file = try std.fs.cwd().openFile(path.*, .{});
            defer compare_to_file.close();

            const expected_data_buf = try allocator.alignedAlloc(u8, @alignOf(f64), 100 * 1024 * 1024);
            const bytes_read = try compare_to_file.readAll(expected_data_buf);
            const expected_data_u8 = expected_data_buf[0..bytes_read];
            const expected_data = std.mem.bytesAsSlice(f64, expected_data_u8);

            try compareData(result_data, expected_data);
        } else {
            const stdout = std.io.getStdOut().writer();

            try stdout.writeAll(std.mem.bytesAsSlice(u8, result_data));
        }
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
