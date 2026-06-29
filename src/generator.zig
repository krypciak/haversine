const std = @import("std");
const formula = @import("./formula.zig");

fn writeF64(writer: *std.Io.Writer, value: f64) !void {
    try writer.writeInt(u64, @bitCast(value), .little);
}

pub fn writeRandomPoints(allocator: std.mem.Allocator, io: std.Io, point_pair_count: u64, seed: u64) !void {
    var prng = std.Random.DefaultPrng.init(seed);
    const rand = prng.random();

    const json_output_filename = try std.fmt.allocPrint(allocator, "data/data_{d}_flex.json", .{point_pair_count});
    const binary_output_filename = try std.fmt.allocPrint(allocator, "data/data_{d}_haveranswer.f64", .{point_pair_count});

    const json_file = try std.Io.Dir.cwd().createFile(
        io,
        json_output_filename,
        .{ .read = false },
    );
    const json_file_data_buffer = try allocator.alloc(u8, point_pair_count * 600);
    var json_file_writer = json_file.writer(io, json_file_data_buffer);

    const binary_file = try std.Io.Dir.cwd().createFile(
        io,
        binary_output_filename,
        .{ .read = false },
    );
    const binary_file_data_buffer = try allocator.alloc(u8, (point_pair_count + 1) * @sizeOf(f64));
    var binary_file_writer = binary_file.writer(io, binary_file_data_buffer);

    try json_file_writer.interface.writeAll(
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

        try writeF64(&binary_file_writer.interface, result);

        try json_file_writer.interface.print("    {{ \"x0\": {d}, \"y0\": {d}, \"x1\": {d}, \"y1\": {d} }}", .{ x0, y0, x1, y1 });

        if (i != point_pair_count - 1) try json_file_writer.interface.writeAll(",");
        try json_file_writer.interface.writeAll("\n");
    }

    std.debug.print("sum: {d}\n", .{sum});

    try json_file_writer.interface.writeAll(
        \\  ]
        \\}
    );
    try json_file_writer.interface.flush();
    json_file.close(io);

    try writeF64(&binary_file_writer.interface, sum);
    try binary_file_writer.interface.flush();
    binary_file.close(io);

    std.debug.print("output in\n./{s}\n./{s}\n", .{ json_output_filename, binary_output_filename });
}
