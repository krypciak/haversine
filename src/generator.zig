const std = @import("std");
const formula = @import("./formula.zig");

pub fn writeRandomPoints(allocator: std.mem.Allocator, point_pair_count: u64, seed: u64) !void {
    var prng = std.Random.DefaultPrng.init(seed);
    const rand = prng.random();

    const json_output_filename = try std.fmt.allocPrint(allocator, "data/data_{d}_flex.json", .{point_pair_count});
    const binary_output_filename = try std.fmt.allocPrint(allocator, "data/data_{d}_haveranswer.f64", .{point_pair_count});

    var json_string_builder = try std.ArrayList(u8).initCapacity(allocator, point_pair_count * 150);

    try json_string_builder.appendSlice(
        \\{
        \\  "pairs": [
        \\
    );

    var binary_array: []f64 = try allocator.alloc(f64, point_pair_count + 1);

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

        binary_array[i] = result;

        const json_file_str = try std.fmt.allocPrint(allocator, "    {{ \"x0\": {d}, \"y0\": {d}, \"x1\": {d}, \"y1\": {d} }}", .{ x0, y0, x1, y1 });
        defer allocator.free(json_file_str);
        try json_string_builder.appendSlice(json_file_str);

        if (i != point_pair_count - 1) try json_string_builder.appendSlice(",");
        try json_string_builder.appendSlice("\n");
    }

    std.debug.print("sum: {d}\n", .{sum});
    binary_array[point_pair_count] = sum;

    try json_string_builder.appendSlice(
        \\  ]
        \\}
    );

    const json_file = try std.fs.cwd().createFile(
        json_output_filename,
        .{ .read = false },
    );
    const json_writer = json_file.writer();
    try json_writer.writeAll(try json_string_builder.toOwnedSlice());
    json_file.close();

    const binary_file = try std.fs.cwd().createFile(
        binary_output_filename,
        .{ .read = false },
    );
    const binary_writer = binary_file.writer();
    i = 0;
    while (i < binary_array.len) : (i += 1) {
        try binary_writer.writeInt(u64, @bitCast(binary_array[i]), .little);
    }
    binary_file.close();

    std.debug.print("output in\n./{s}\n./{s}\n", .{ json_output_filename, binary_output_filename });
}
