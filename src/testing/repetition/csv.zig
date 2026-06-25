const std = @import("std");

pub fn Csv(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        headers: std.ArrayList([]const u8),
        data: std.ArrayList(std.ArrayList(T)),

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .headers = .empty,
                .data = .empty,
            };
        }

        pub fn deinit(self: *Self) void {
            self.headers.deinit(self.allocator);

            for (self.data.items) |*entry| {
                entry.deinit(self.allocator);
            }
            self.data.deinit(self.allocator);
        }

        fn getIndexOrAppend(self: *Self, header: []const u8) !usize {
            for (self.headers.items, 0..) |h, i| {
                if (std.mem.eql(u8, h, header)) return i;
            }
            try self.headers.append(self.allocator, header);
            try self.data.append(self.allocator, .empty);
            return self.headers.items.len - 1;
        }

        pub fn append(self: *Self, header: []const u8, value: T) !void {
            const index: usize = try self.getIndexOrAppend(header);
            try self.data.items[index].append(self.allocator, value);
        }

        pub fn print(self: *const Self) void {
            const delimiter = "\t";
            for (self.headers.items, 0..) |header, i| {
                if (i > 0) std.debug.print("{s}", .{delimiter});
                std.debug.print("{s}", .{header});
            }
            std.debug.print("\n", .{});

            var max_len: u64 = 0;
            for (self.data.items) |arr| {
                max_len = @max(max_len, arr.items.len);
            }
            for (0..max_len) |i| {
                for (self.data.items, 0..) |*arr, j| {
                    if (j > 0) std.debug.print("{s}", .{delimiter});
                    const item = arr.items[i];
                    std.debug.print("{}", .{item});
                }
                std.debug.print("\n", .{});
            }
        }
    };
}
