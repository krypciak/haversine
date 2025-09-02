const std = @import("std");
const formula = @import("./formula.zig");

pub fn writeRandomPoints(point_pair_count: u64, seed: u64) !void {
    var prng = std.Random.DefaultPrng.init(seed);
    const rand = prng.random();

    const json_file = try std.fs.cwd().createFile(
        "output.json",
        .{ .read = false },
    );
    defer json_file.close();
    const json_writer = json_file.writer();

    const binary_file = try std.fs.cwd().createFile(
        "output.f64",
        .{ .read = false },
    );
    defer binary_file.close();
    const binary_writer = binary_file.writer();

    _ = try json_writer.write(
        \\{
        \\  "pairs": [
        \\
    );

    var sum: f64 = 0;
    const sum_coef = formula.sumCoef(point_pair_count);
    var i: usize = 0;
    while (i < point_pair_count) : (i += 1) {
        const x0 = 360 * rand.float(f64) - 180;
        const y0 = 360 * rand.float(f64) - 180;
        const x1 = 360 * rand.float(f64) - 180;
        const y1 = 360 * rand.float(f64) - 180;

        const result = formula.referenceHaversine(x0, y0, x1, y1, formula.EARTH_RADIUS);
        sum += sum_coef * result;

        try binary_writer.writeInt(u64, @bitCast(result), .little);

        try json_writer.print("    {{ \"x0\": {d}, \"y0\": {d}, \"x1\": {d}, \"y1\": {d} }}", .{ x0, y0, x1, y1 });
        if (i != point_pair_count - 1) try json_writer.print(",", .{});
        try json_writer.print("\n", .{});
    }

    std.debug.print("sum: {d}\n", .{sum});
    try binary_writer.writeInt(u64, @bitCast(sum), .little);

    _ = try json_writer.write(
        \\  ]
        \\}
    );

    std.debug.print("output in\n./output.json\n./output.f64\n", .{});
}
