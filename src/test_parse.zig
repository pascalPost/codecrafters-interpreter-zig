const std = @import("std");
const expect = std.testing.expect;
const parse = @import("parse.zig");
const scan = @import("scan.zig");
const Token = scan.Token;

test "booleans & nil" {
    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    {
        const res = try parse.parse(allocator, &[_]scan.Token{scan.Token.init(.TRUE, 0, 1, 1, null)}, errOut.writer());
        defer res.expr.destroy(allocator);

        try expect(errOut.items.len == 0); // no error output
        try expect(res.expr == .literal);
        try expect(res.expr.literal.type == .true);
        try expect(res.expr.literal.value == null);
    }
    {
        const res = try parse.parse(allocator, &[_]scan.Token{scan.Token.init(.FALSE, 0, 1, 1, null)}, errOut.writer());
        defer res.expr.destroy(allocator);

        try expect(errOut.items.len == 0); // no error output
        try expect(res.expr == .literal);
        try expect(res.expr.literal.type == .false);
        try expect(res.expr.literal.value == null);
    }
    {
        const res = try parse.parse(allocator, &[_]scan.Token{scan.Token.init(.NIL, 0, 1, 1, null)}, errOut.writer());
        defer res.expr.destroy(allocator);

        try expect(errOut.items.len == 0); // no error output
        try expect(res.expr == .literal);
        try expect(res.expr.literal.type == .nil);
        try expect(res.expr.literal.value == null);
    }
}

test "number literals" {
    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const res = try parse.parse(allocator, &[_]scan.Token{scan.Token.init(.NUMBER, 0, 1, 1, .{ .number = 35 })}, errOut.writer());
    defer res.expr.destroy(allocator);

    try expect(errOut.items.len == 0); // no error output
    try expect(res.expr == .literal);
    try expect(res.expr.literal.type == .number);
    try expect(res.expr.literal.value.?.number == 35);
}

test "string literals" {
    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const res = try parse.parse(allocator, &[_]scan.Token{Token.init(.STRING, 0, 1, 1, .{ .string = "test" })}, errOut.writer());
    defer res.expr.destroy(allocator);

    try expect(errOut.items.len == 0); // no error output
    try expect(res.expr == .literal);
    try expect(res.expr.literal.type == .string);
    try expect(std.mem.eql(u8, res.expr.literal.value.?.string, "test"));
}

test "parentheses" {
    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const tokens = [_]Token{
        Token.init(.LEFT_PAREN, 0, 1, 1, null),
        Token.init(.STRING, 0, 1, 1, .{ .string = "test" }),
        Token.init(.RIGHT_PAREN, 0, 1, 1, null),
    };

    const res = try parse.parse(allocator, &tokens, errOut.writer());
    defer res.expr.destroy(allocator);

    try expect(errOut.items.len == 0); // no error output
    try expect(res.expr == .grouping);
    try expect(res.expr.grouping.expr == .literal);
    try expect(res.expr.grouping.expr.literal.type == .string);
    try expect(std.mem.eql(u8, res.expr.grouping.expr.literal.value.?.string, "test"));
}

test "parentheses (double)" {
    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const tokens = [_]Token{
        Token.init(.LEFT_PAREN, 0, 1, 1, null),
        Token.init(.LEFT_PAREN, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 26.13 }),
        Token.init(.RIGHT_PAREN, 0, 1, 1, null),
        Token.init(.RIGHT_PAREN, 0, 1, 1, null),
    };

    const res = try parse.parse(allocator, &tokens, errOut.writer());
    defer res.expr.destroy(allocator);

    try expect(errOut.items.len == 0); // no error output
    try expect(res.expr == .grouping);
    try expect(res.expr.grouping.expr == .grouping);
    try expect(res.expr.grouping.expr.grouping.expr == .literal);
    try expect(res.expr.grouping.expr.grouping.expr.literal.type == .number);
    try expect(res.expr.grouping.expr.grouping.expr.literal.value.?.number == 26.13);
}

test "unary operators (negation operator)" {
    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const tokens = [_]Token{
        Token.init(.BANG, 0, 1, 1, null),
        Token.init(.TRUE, 0, 1, 1, null),
    };

    const res = try parse.parse(allocator, &tokens, errOut.writer());
    defer res.expr.destroy(allocator);

    try expect(errOut.items.len == 0); // no error output
    try expect(res.expr == .unary);
    try expect(res.expr.unary.operator.type == .bang);
    try expect(res.expr.unary.operator.line == 1);
    try expect(res.expr.unary.right == .literal);
    try expect(res.expr.unary.right.literal.type == .true);
}

test "unary operators (negative number)" {
    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const tokens = [_]Token{
        Token.init(.MINUS, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 26.13 }),
    };

    const res = try parse.parse(allocator, tokens[0..], errOut.writer());
    defer res.expr.destroy(allocator);

    try expect(errOut.items.len == 0); // no error output
    try expect(res.expr == .unary);
    try expect(res.expr.unary.operator.type == .minus);
    try expect(res.expr.unary.right == .literal);
    try expect(res.expr.unary.right.literal.type == .number);
    try expect(res.expr.unary.right.literal.value.?.number == 26.13);
}

test "arithmetic operators (factor - multiplication & division)" {
    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const tokens = [_]Token{
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 16 }),
        Token.init(.STAR, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 38 }),
        Token.init(.SLASH, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 58 }),
    };

    const res = try parse.parse(allocator, tokens[0..], errOut.writer());
    defer res.expr.destroy(allocator);

    try expect(errOut.items.len == 0); // no error output
    try expect(res.expr == .binary);
    try expect(res.expr.binary.operator.type == .slash);
    try expect(res.expr.binary.left == .binary);
    try expect(res.expr.binary.left.binary.operator.type == .star);
    try expect(res.expr.binary.left.binary.left == .literal);
    try expect(res.expr.binary.left.binary.left.literal.type == .number);
    try expect(res.expr.binary.left.binary.left.literal.value.?.number == 16);
    try expect(res.expr.binary.left.binary.right == .literal);
    try expect(res.expr.binary.left.binary.right.literal.type == .number);
    try expect(res.expr.binary.left.binary.right.literal.value.?.number == 38);
    try expect(res.expr.binary.right == .literal);
    try expect(res.expr.binary.right.literal.type == .number);
    try expect(res.expr.binary.right.literal.value.?.number == 58);
}

test "arithmetic operators (complex factor)" {
    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    // (86 * -97 / (12 * 93))
    const tokens = [_]Token{
        Token.init(.LEFT_PAREN, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 86 }),
        Token.init(.STAR, 0, 1, 1, null),
        Token.init(.MINUS, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 97 }),
        Token.init(.SLASH, 0, 1, 1, null),
        Token.init(.LEFT_PAREN, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 12 }),
        Token.init(.STAR, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 93 }),
        Token.init(.RIGHT_PAREN, 0, 1, 1, null),
        Token.init(.RIGHT_PAREN, 0, 1, 1, null),
    };

    const res = try parse.parse(allocator, tokens[0..], errOut.writer());
    defer res.expr.destroy(allocator);

    try expect(errOut.items.len == 0); // no error output
    try expect(res.expr == .grouping);
    try expect(res.expr.grouping.expr == .binary);
    try expect(res.expr.grouping.expr.binary.operator.type == .slash);
    try expect(res.expr.grouping.expr.binary.left == .binary);
    try expect(res.expr.grouping.expr.binary.left.binary.operator.type == .star);
    try expect(res.expr.grouping.expr.binary.left.binary.left == .literal);
    try expect(res.expr.grouping.expr.binary.left.binary.left.literal.type == .number);
    try expect(res.expr.grouping.expr.binary.left.binary.left.literal.value.?.number == 86);
    try expect(res.expr.grouping.expr.binary.left.binary.right == .unary);
    try expect(res.expr.grouping.expr.binary.left.binary.right.unary.operator.type == .minus);
    try expect(res.expr.grouping.expr.binary.left.binary.right.unary.right == .literal);
    try expect(res.expr.grouping.expr.binary.left.binary.right.unary.right.literal.type == .number);
    try expect(res.expr.grouping.expr.binary.left.binary.right.unary.right.literal.value.?.number == 97);
    try expect(res.expr.grouping.expr.binary.right == .grouping);
    try expect(res.expr.grouping.expr.binary.right.grouping.expr == .binary);
    try expect(res.expr.grouping.expr.binary.right.grouping.expr.binary.operator.type == .star);
    try expect(res.expr.grouping.expr.binary.right.grouping.expr.binary.left == .literal);
    try expect(res.expr.grouping.expr.binary.right.grouping.expr.binary.left.literal.type == .number);
    try expect(res.expr.grouping.expr.binary.right.grouping.expr.binary.left.literal.value.?.number == 12);
    try expect(res.expr.grouping.expr.binary.right.grouping.expr.binary.right == .literal);
    try expect(res.expr.grouping.expr.binary.right.grouping.expr.binary.right.literal.type == .number);
    try expect(res.expr.grouping.expr.binary.right.grouping.expr.binary.right.literal.value.?.number == 93);
}

test "arithmetic operators (plus & minus)" {
    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const tokens = [_]Token{
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 16 }),
        Token.init(.PLUS, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 38 }),
        Token.init(.MINUS, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 58 }),
    };

    const res = try parse.parse(allocator, tokens[0..], errOut.writer());
    defer res.expr.destroy(allocator);

    try expect(errOut.items.len == 0); // no error output
    try expect(res.expr == .binary);
    try expect(res.expr.binary.operator.type == .minus);
    try expect(res.expr.binary.left == .binary);
    try expect(res.expr.binary.left.binary.operator.type == .plus);
    try expect(res.expr.binary.left.binary.left == .literal);
    try expect(res.expr.binary.left.binary.left.literal.type == .number);
    try expect(res.expr.binary.left.binary.left.literal.value.?.number == 16);
    try expect(res.expr.binary.left.binary.right == .literal);
    try expect(res.expr.binary.left.binary.right.literal.type == .number);
    try expect(res.expr.binary.left.binary.right.literal.value.?.number == 38);
    try expect(res.expr.binary.right == .literal);
    try expect(res.expr.binary.right.literal.type == .number);
    try expect(res.expr.binary.right.literal.value.?.number == 58);
}

test "comparison operators" {
    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const tokens = [_]Token{
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 16 }),
        Token.init(.GREATER, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 38 }),
        Token.init(.LESS, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 58 }),
    };

    const res = try parse.parse(allocator, tokens[0..], errOut.writer());
    defer res.expr.destroy(allocator);

    try expect(errOut.items.len == 0); // no error output
    try expect(res.expr == .binary);
    try expect(res.expr.binary.operator.type == .less);
    try expect(res.expr.binary.left == .binary);
    try expect(res.expr.binary.left.binary.operator.type == .greater);
    try expect(res.expr.binary.left.binary.left == .literal);
    try expect(res.expr.binary.left.binary.left.literal.type == .number);
    try expect(res.expr.binary.left.binary.left.literal.value.?.number == 16);
    try expect(res.expr.binary.left.binary.right == .literal);
    try expect(res.expr.binary.left.binary.right.literal.type == .number);
    try expect(res.expr.binary.left.binary.right.literal.value.?.number == 38);
    try expect(res.expr.binary.right == .literal);
    try expect(res.expr.binary.right.literal.type == .number);
    try expect(res.expr.binary.right.literal.value.?.number == 58);
}

test "equality" {
    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const tokens = [_]Token{
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 16 }),
        Token.init(.EQUAL_EQUAL, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 16 }),
    };

    const res = try parse.parse(allocator, tokens[0..], errOut.writer());
    defer res.expr.destroy(allocator);

    try expect(errOut.items.len == 0); // no error output
    try expect(res.expr == .binary);
    try expect(res.expr.binary.operator.type == .equal_equal);
    try expect(res.expr.binary.left == .literal);
    try expect(res.expr.binary.left.literal.type == .number);
    try expect(res.expr.binary.left.literal.value.?.number == 16);
    try expect(res.expr.binary.right == .literal);
    try expect(res.expr.binary.right.literal.type == .number);
    try expect(res.expr.binary.right.literal.value.?.number == 16);
}

test "syntactic errors" {
    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const tokens = [_]Token{
        Token.init(.LEFT_PAREN, 0, 1, 1, null),
        Token.init(.NUMBER, 0, 1, 1, .{ .number = 16 }),
        Token.init(.PLUS, 0, 1, 1, null),
        Token.init(.RIGHT_PAREN, 0, 1, 1, null),
        Token.init(.EOF, 0, 1, 1, null),
    };

    _= parse.parse(allocator, tokens[0..], errOut.writer()) catch |err| {
        try expect(err == parse.Error.ParseError);
        // try expect(std.mem.eql(u8, "[line 1] Expect expression.\n", errOut.items[0..]));
        return;
    };


}
