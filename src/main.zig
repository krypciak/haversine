const std = @import("std");
const ArrayList = std.ArrayList;

const generator = @import("./generator.zig");

comptime {
    _ = @import("json/json.zig");
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

        if (argv.len <= 3) return error.PointCountMissing;
        const seed_str = argv[3];

        const point_count = try std.fmt.parseInt(u64, point_count_str, 10);
        const seed = try std.fmt.parseInt(u64, seed_str, 10);
        try generator.writeRandomPoints(point_count, seed);
    }
}
