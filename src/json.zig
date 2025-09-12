const std = @import("std");
const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;

pub const JsonNode = union(JsonNode.Type) {
    const Type = enum {
        Number,
        String,
        Bool,
        Null,
        Array,
        Record,
    };

    Number: f64,
    String: []const u8,
    Bool: bool,
    Null: void,
    Array: []JsonNode,
    Record: StringHashMap(JsonNode),

    pub fn print(self: *const JsonNode, allocator: std.mem.Allocator) ![]const u8 {
        var builder = ArrayList(u8).init(allocator);

        switch (self.*) {
            .Number => |*num| {
                const str = try std.fmt.allocPrint(allocator, "{d}", .{num.*});
                defer allocator.free(str);
                try builder.appendSlice(str);
            },
            .String => |*string| {
                const str = try std.fmt.allocPrint(allocator, "\"{s}\"", .{string.*});
                defer allocator.free(str);
                try builder.appendSlice(str);
            },
            .Bool => |*b| {
                if (b.*) {
                    try builder.appendSlice("true");
                } else {
                    try builder.appendSlice("false");
                }
            },
            .Null => {
                try builder.appendSlice("null");
            },
            .Array => |*arr| {
                try builder.append('[');
                for (arr.*, 0..) |*node, i| {
                    if (i != 0) try builder.appendSlice(", ");
                    const str = try node.print(allocator);
                    defer allocator.free(str);
                    try builder.appendSlice(str);
                }
                try builder.append(']');
            },
            .Record => |*rec| {
                try builder.append('{');

                var ite = rec.iterator();
                var i: usize = 0;
                while (ite.next()) |*entry| : (i += 1) {
                    if (i != 0) try builder.appendSlice(", ");
                    try builder.append('"');
                    try builder.appendSlice(entry.key_ptr.*);
                    try builder.append('"');
                    try builder.appendSlice(": ");

                    const value = try entry.value_ptr.print(allocator);
                    defer allocator.free(value);
                    try builder.appendSlice(value);
                }

                try builder.append('}');
            },
        }
        return builder.toOwnedSlice();
    }
};

pub const Json = struct {
    node: ?JsonNode,
    arena: std.heap.ArenaAllocator,

    pub fn deinit(self: *const Json) void {
        self.arena.deinit();
    }

    pub fn parse(allocator: std.mem.Allocator, str: []const u8) !Json {
        var arena = std.heap.ArenaAllocator.init(allocator);
        const arena_allocator = arena.allocator();

        const node = try JsonNodeParser.parse(arena_allocator, str);

        return .{
            .node = node,
            .arena = arena,
        };
    }
};

const JsonNodeParser = struct {
    fn isWhitespace(char: u8) bool {
        return char == ' ' or char == '\t' or char == '\r' or char == '\n';
    }

    fn isControlCharacter(char: u8) bool {
        return char == '"' or char == '\\' or char == '/' or char == 'b' or char == 'f' or char == 'n' or char == 'r' or char == 't' or char == 'u';
    }

    fn readString(allocator: std.mem.Allocator, str: []const u8, start_i: usize) !struct { str: []const u8, i: usize } {
        var string_builder = ArrayList(u8).init(allocator);

        var i = start_i;
        var previous_backslash = false;
        while (i < str.len) : (i += 1) {
            const c = str[i];

            if (previous_backslash) {
                previous_backslash = false;

                const char: u8 = try switch (c) {
                    '\\' => @as(u8, '\\'),
                    '"' => @as(u8, '"'),
                    'b' => @as(u8, '\x08'),
                    'f' => @as(u8, '\x0c'),
                    'n' => @as(u8, '\n'),
                    'r' => @as(u8, '\r'),
                    't' => @as(u8, '\t'),
                    'u' => unreachable,
                    else => error.InvalidEscapeCharacter,
                };
                try string_builder.append(char);
            } else if (c == '\\') {
                previous_backslash = true;
                continue;
            } else if (c == '"') {
                const slice = try string_builder.toOwnedSlice();
                return .{ .str = slice, .i = i };
            } else {
                try string_builder.append(c);
            }
        }

        return error.StringNotEnded;
    }

    fn readNumber(str: []const u8, start_i: usize) !struct { value: f64, i: usize } {
        var i = start_i;
        var has_dot = false;
        var has_minus = false;
        while (i < str.len) : (i += 1) {
            const c = str[i];
            if (c >= '0' and c <= '9') {} else if (c == '.') {
                if (has_dot) return error.InvalidNumber;
                has_dot = true;
            } else if (c == '-') {
                if (has_minus) return error.InvalidNumber;
                has_minus = true;
            } else break;
        }

        const num_str = str[start_i..i];

        const value = std.fmt.parseFloat(f64, num_str) catch std.math.nan(f64);
        return .{ .value = value, .i = i - 1 };
    }

    const BuilderNode = union(BuilderNode.Type) {
        const Type = enum { Root, Array, Record };

        Root: ArrayList(JsonNode),
        Array: ArrayList(JsonNode),
        Record: struct {
            varName: []const u8,
            map: StringHashMap(JsonNode),
        },

        pub fn addNode(self: *BuilderNode, node: JsonNode) !void {
            switch (self.*) {
                .Array, .Root => |*arr| {
                    try arr.append(node);
                },
                .Record => |*rec| {
                    if (rec.*.varName.len == 0) {
                        switch (node) {
                            .String => |*str| {
                                rec.varName = str.*;
                            },
                            else => unreachable,
                        }
                    } else {
                        try rec.*.map.put(rec.*.varName, node);
                        rec.varName = "";
                    }
                },
            }
        }
    };

    pub fn parse(allocator: std.mem.Allocator, str: []const u8) !?JsonNode {
        var i: usize = 0;

        var expect_comma = false;

        var stack = ArrayList(BuilderNode).init(allocator);
        defer stack.deinit();

        try stack.append(.{ .Root = ArrayList(JsonNode).init(allocator) });

        while (i < str.len) : (i += 1) {
            const c = str[i];
            if (isWhitespace(c)) {
                continue;
            }

            var node: ?JsonNode = null;

            if (c == ']') {
                var builder_node_optional = stack.pop();
                if (builder_node_optional) |*builder| {
                    try switch (builder.*) {
                        .Array => |*builder_arr| {
                            const array = try builder_arr.toOwnedSlice();
                            node = .{ .Array = array };
                        },
                        else => error.ExpectedClosingBracket,
                    };
                } else return error.UnexpectedClosingBracket;
            } else if (c == '}') {
                const builder_node_optional = stack.pop();
                if (builder_node_optional) |*builder_node| {
                    try switch (builder_node.*) {
                        .Record => |*builder_rec| {
                            const map = builder_rec.map;
                            node = .{ .Record = map };
                        },
                        else => error.UnexpectedClosingBrace,
                    };
                } else return error.UnexpectedClosingBrace;
            } else if (expect_comma) {
                if (c == ':') {
                    switch (stack.getLast()) {
                        .Record => {},
                        else => return error.UnexpectedColon,
                    }
                } else if (c == ',') {} else return error.ExpectedComma;

                expect_comma = false;
            } else if (c == '{') {
                try stack.append(.{ .Record = .{ .map = StringHashMap(JsonNode).init(allocator), .varName = "" } });
            } else if (c == '[') {
                const list = ArrayList(JsonNode).init(allocator);
                try stack.append(.{ .Array = list });
            } else if (c == '"') {
                i += 1;
                const obj = try readString(allocator, str, i);
                i = obj.i;
                node = .{ .String = obj.str };
            } else if (c == 'n' and i + 4 <= str.len and str[i + 1] == 'u' and str[i + 2] == 'l' and str[i + 3] == 'l') {
                node = .{ .Null = {} };
                i += 3;
            } else if (c == 't' and i + 4 <= str.len and str[i + 1] == 'r' and str[i + 2] == 'u' and str[i + 3] == 'e') {
                node = .{ .Bool = true };
                i += 3;
            } else if (c == 'f' and i + 5 <= str.len and str[i + 1] == 'a' and str[i + 2] == 'l' and str[i + 3] == 's' and str[i + 4] == 'e') {
                node = .{ .Bool = false };
                i += 4;
            } else {
                const obj = try readNumber(str, i);
                i = obj.i;
                const num = obj.value;
                if (std.math.isNan(num)) return error.UnexpectedCharacter;

                node = .{ .Number = num };
            }

            if (node) |*node1| {
                const last = &stack.items[stack.items.len - 1];
                try last.addNode(node1.*);
                expect_comma = true;
            }
        }

        std.debug.assert(stack.items.len > 0);
        if (stack.items.len != 1) return error.BracketNotClosed;

        const root_node = switch (stack.items[0]) {
            .Root => |*root_node| {
                std.debug.assert(root_node.items.len == 1);
                return root_node.items[0];
            },
            else => unreachable,
        };

        return root_node;
    }
};

fn assertJson(input: []const u8) !void {
    const allocator = std.testing.allocator;
    var json = try Json.parse(allocator, input);
    defer json.deinit();

    if (json.node) |*node| {
        const str = try node.print(allocator);
        defer allocator.free(str);

        try std.testing.expectEqualStrings(input, str);
    } else unreachable;
}

test "json empty object" {
    try assertJson("{}");
}
test "json empty array" {
    try assertJson("[]");
}
test "json string" {
    try assertJson("\"hi\"");
}
test "json null" {
    try assertJson("null");
    try assertJson("[null, null]");
}
test "json true" {
    try assertJson("true");
    try assertJson("[true, true]");
}
test "json false" {
    try assertJson("false");
    try assertJson("[false, false]");
}
test "json number integer" {
    try assertJson("123");
    try assertJson("[123, 123]");
}
test "json number float" {
    try assertJson("123.1");
    try assertJson("[123.1, 123.1]");
}
test "json object" {
    try assertJson("{\"hi\": 1, \"test\": 2}");
}
test "json example haversine input" {
    try assertJson("{\"pairs\": [" ++
        "{\"x0\": 71.33250658090708, \"y0\": 14.33765545271811, \"x1\": 57.74392003827924, \"y1\": 144.20042052655367}, " ++
        "{\"x0\": -157.82146249407018, \"y0\": 101.95398371098173, \"x1\": 5.611263262627773, \"y1\": 72.9050823850408}, " ++
        "{\"x0\": 19.773828831748233, \"y0\": 84.97459072411692, \"x1\": 151.30982003446678, \"y1\": 142.34917850014347}" ++
        "]}");
}
