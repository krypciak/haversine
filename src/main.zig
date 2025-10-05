const std = @import("std");
const ArrayList = std.ArrayList;

const generator = @import("./generator.zig");
const compute = @import("./compute.zig");

const points_from_json = @import("./points_from_json.zig");
const Point = points_from_json.Point;

const json_module = @import("./json.zig");
const Json = json_module.Json;
const JsonNode = json_module.JsonNode;

const timer = @import("./timer.zig");

const repetition_tester = @import("./repetition_tester.zig");

comptime {
    _ = @import("./json.zig");
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
        try generator.writeRandomPoints(allocator, point_count, seed);
    } else if (std.mem.eql(u8, action, "compute")) {
        if (argv.len <= 2) return error.InputFileArgumentMissing;
        const input_file_path = argv[2];

        const compare_to_path = if (argv.len <= 3) null else argv[3];

        try handleCompute(allocator, input_file_path, compare_to_path);
    } else if (std.mem.eql(u8, action, "repetitionTest")) {
        try repetition_tester.repetitionTest();
    }
}

fn handleCompute(allocator: std.mem.Allocator, input_file_path: []const u8, compare_to_path: ?[]const u8) !void {
    try timer.initTimer(allocator);

    const input_file = try std.fs.cwd().openFile(input_file_path, .{});
    const input_file_size = (try input_file.stat()).size;
    try timer.start("input read", input_file_size);
    const input_data = try input_file.readToEndAlloc(allocator, input_file_size);
    defer allocator.free(input_data);
    input_file.close();
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
            const compare_to_file = try std.fs.cwd().openFile(path.*, .{});
            defer compare_to_file.close();
            const compare_to_file_size = (try compare_to_file.stat()).size;
            try timer.start("compare read", compare_to_file_size);

            const expected_data_buf = try allocator.alignedAlloc(u8, std.mem.Alignment.@"64", compare_to_file_size);
            const bytes_read = try compare_to_file.readAll(expected_data_buf);
            const expected_data_u8 = expected_data_buf[0..bytes_read];
            const expected_data = std.mem.bytesAsSlice(f64, expected_data_u8);

            timer.stop();

            try compareData(result_data, expected_data);
        } else {
            var stdout_writer = std.fs.File.stdout().writer(&.{});
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
