const std = @import("std");

pub fn writeRandomPoints(point_pair_count: u64, seed: u64) !void {
    var prng = std.Random.DefaultPrng.init(seed);
    const rand = prng.random();

    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // defer bw.flush() catch unreachable;
    // const writer = bw.writer();

    const file = try std.fs.cwd().createFile(
        "output.json",
        .{ .read = false },
    );
    defer file.close();
    const writer = file.writer();

    _ = try writer.write(
        \\{
        \\  "pairs": [
        \\
    );

    var i: usize = 0;
    while (i < point_pair_count) : (i += 1) {
        const x0 = 360 * rand.float(f64) - 180;
        const y0 = 360 * rand.float(f64) - 180;
        const x1 = 360 * rand.float(f64) - 180;
        const y1 = 360 * rand.float(f64) - 180;

        try writer.print("    {{ \"x0\": {d}, \"y0\": {d}, \"x1\": {d}, \"y1\": {d} }}", .{ x0, y0, x1, y1 });
        if (i != point_pair_count - 1) try writer.print(",", .{});
        try writer.print("\n", .{});
    }

    _ = try writer.write(
        \\  ]
        \\}
    );

    std.debug.print("output in ./output.json\n", .{});
}
