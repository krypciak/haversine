const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = std.heap.page_allocator;
    const argv = try init.minimal.args.toSlice(allocator);

    if (argv.len <= 1) return error.MissingAction;

    const io = init.io;

    const arg1 = argv[1];
    const arg2 = if (argv.len <= 2) null else argv[2];
    const arg3 = if (argv.len <= 3) null else argv[3];

    if (std.mem.eql(u8, arg1, "generate")) {
        const point_count_str = arg2 orelse return error.PointCountMissing;
        const seed_str = arg3 orelse return error.SeedMissing;

        const point_count = try std.fmt.parseInt(u64, point_count_str, 10);
        const seed = try std.fmt.parseInt(u64, seed_str, 10);
        try @import("./generator.zig").writeRandomPoints(allocator, io, point_count, seed);
    } else if (std.mem.eql(u8, arg1, "compute")) {
        const input_file_path = arg2 orelse return error.InputFileArguemntMissing;
        const compare_to_path = arg3;

        try @import("./haversine_main.zig").handleCompute(allocator, io, input_file_path, compare_to_path);
    } else if (std.mem.eql(u8, arg1, "repetitionTest")) {
        const testType = arg2 orelse return error.MissingTestType;
        try @import("./testing/repetition/repetition_tester.zig").run(allocator, io, testType);
    } else return error.UnknownAction;
}
