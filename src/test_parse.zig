const std = @import("std");
const expect = std.testing.expect;
const parse = @import("parse.zig");
const scan = @import("scan.zig");
const Token = scan.Token;

test "booleans & nil" {
    const allocator = std.testing.allocator;

    {
        const res = try parse.parse(allocator, &[_]scan.Token{scan.Token.init(.TRUE, 0, 1, null)});
        defer res.expr.destroy(allocator);

        try expect(res.expr == .literal);
        try expect(res.expr.literal.type == .true);
        try expect(res.expr.literal.value == null);
    }
    {
        const res = try parse.parse(allocator, &[_]scan.Token{scan.Token.init(.FALSE, 0, 1, null)});
        defer res.expr.destroy(allocator);

        try expect(res.expr == .literal);
        try expect(res.expr.literal.type == .false);
        try expect(res.expr.literal.value == null);
    }
    {
        const res = try parse.parse(allocator, &[_]scan.Token{scan.Token.init(.NIL, 0, 1, null)});
        defer res.expr.destroy(allocator);

        try expect(res.expr == .literal);
        try expect(res.expr.literal.type == .nil);
        try expect(res.expr.literal.value == null);
    }
}

test "number literals" {
    const allocator = std.testing.allocator;
    const res = try parse.parse(allocator, &[_]scan.Token{scan.Token.init(.NUMBER, 0, 1, .{ .number = 35 })});
    defer res.expr.destroy(allocator);

    try expect(res.expr == .literal);
    try expect(res.expr.literal.type == .number);
    try expect(res.expr.literal.value.?.number == 35);
}

test "string literals" {
    const allocator = std.testing.allocator;
    const res = try parse.parse(allocator, &[_]scan.Token{Token.init(.STRING, 0, 1, .{ .string = "test" })});
    defer res.expr.destroy(allocator);

    try expect(res.expr == .literal);
    try expect(res.expr.literal.type == .string);
    try expect(std.mem.eql(u8, res.expr.literal.value.?.string, "test"));
}

test "parentheses" {
    const allocator = std.testing.allocator;

    const tokens = [_]Token{
        Token.init(.LEFT_PAREN, 0, 1, null),
        Token.init(.STRING, 0, 1, .{ .string = "test" }),
        Token.init(.RIGHT_PAREN, 0, 1, null),
    };

    const res = try parse.parse(allocator, &tokens);
    defer res.expr.destroy(allocator);

    try expect(res.expr == .grouping);
    try expect(res.expr.grouping.expr == .literal);
    try expect(res.expr.grouping.expr.literal.type == .string);
    try expect(std.mem.eql(u8, res.expr.grouping.expr.literal.value.?.string, "test"));
}

test "parentheses (double)" {
    const allocator = std.testing.allocator;

    const tokens = [_]Token{
        Token.init(.LEFT_PAREN, 0, 1, null),
        Token.init(.LEFT_PAREN, 0, 1, null),
        Token.init(.NUMBER, 0, 1, .{ .number = 26.13 }),
        Token.init(.RIGHT_PAREN, 0, 1, null),
        Token.init(.RIGHT_PAREN, 0, 1, null),
    };

    const res = try parse.parse(allocator, &tokens);
    defer res.expr.destroy(allocator);

    try expect(res.expr == .grouping);
    try expect(res.expr.grouping.expr == .grouping);
    try expect(res.expr.grouping.expr.grouping.expr == .literal);
    try expect(res.expr.grouping.expr.grouping.expr.literal.type == .number);
    try expect(res.expr.grouping.expr.grouping.expr.literal.value.?.number == 26.13);
}

test "unary operators" {
    const allocator = std.testing.allocator;

    const tokens = [_]Token{
        Token.init(.BANG, 0, 1, null),
        Token.init(.TRUE, 0, 1, null),
        Token.init(.MINUS, 0, 1, null),
        Token.init(.NUMBER, 0, 1, .{ .number = 26.13 }),
    };

    {
        const res = try parse.parse(allocator, &tokens);
        defer res.expr.destroy(allocator);

        try expect(res.expr == .unary);
        try expect(res.expr.unary.operator == .bang);
        try expect(res.expr.unary.right == .literal);
        try expect(res.expr.unary.right.literal.type == .true);
    }
    {
        const res = try parse.parse(allocator, tokens[2..]);
        defer res.expr.destroy(allocator);

        try expect(res.expr == .unary);
        try expect(res.expr.unary.operator == .minus);
        try expect(res.expr.unary.right == .literal);
        try expect(res.expr.unary.right.literal.type == .number);
        try expect(res.expr.unary.right.literal.value.?.number == 26.13);
    }
}

test "arithmetic operators (factor - multiplication & division)" {
   const allocator = std.testing.allocator;

    const tokens = [_]Token{
        Token.init(.NUMBER, 0, 1, .{ .number = 16 }),
        Token.init(.STAR, 0, 1, null),
        Token.init(.NUMBER, 0, 1, .{ .number = 38 }),
        Token.init(.SLASH, 0, 1, null),
        Token.init(.NUMBER, 0, 1, .{ .number = 58 }),
    };

    const res = try parse.parse(allocator, tokens[2..]);
    defer res.expr.destroy(allocator);

    try expect(res.expr == .binary);
}
