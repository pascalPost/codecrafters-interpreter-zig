const std = @import("std");
const expect = std.testing.expect;
const parse = @import("parse.zig");
const scan = @import("scan.zig");

test "booleans & nil" {
    const allocator = std.testing.allocator;

    {
        const expr = try parse.parse(allocator, &[_]scan.Token{scan.Token.init(.TRUE, 0, 1, null)});
        defer expr.destroy(allocator);

        try expect(expr == .literal);
        try expect(expr.literal.type == .true);
        try expect(expr.literal.value == null);
    }
    {
        const expr = try parse.parse(allocator, &[_]scan.Token{scan.Token.init(.FALSE, 0, 1, null)});
        defer expr.destroy(allocator);

        try expect(expr == .literal);
        try expect(expr.literal.type == .false);
        try expect(expr.literal.value == null);
    }
    {
        const expr = try parse.parse(allocator, &[_]scan.Token{scan.Token.init(.NIL, 0, 1, null)});
        defer expr.destroy(allocator);

        try expect(expr == .literal);
        try expect(expr.literal.type == .nil);
        try expect(expr.literal.value == null);
    }
}

test "number literals" {
    const allocator = std.testing.allocator;
    const expr = try parse.parse(allocator, &[_]scan.Token{scan.Token.init(.NUMBER, 0, 1, .{ .number = 35 })});
    defer expr.destroy(allocator);

    try expect(expr == .literal);
    try expect(expr.literal.type == .number);
    try expect(expr.literal.value.?.number == 35);
}

test "string literals" {
        const allocator = std.testing.allocator;
    const expr = try parse.parse(allocator, &[_]scan.Token{scan.Token.init(.STRING, 0, 1, .{ .string = "test" })});
    defer expr.destroy(allocator);

    try expect(expr == .literal);
    try expect(expr.literal.type == .string);
    try expect(std.mem.eql(u8, expr.literal.value.?.string, "test"));
}