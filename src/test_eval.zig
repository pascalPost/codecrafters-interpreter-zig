const std = @import("std");
const eval = @import("eval.zig").eval;
const ast = @import("expressions.zig");
const Expr = ast.Expr;
const Literal = ast.Literal;
const Grouping = ast.Grouping;
const Unary = ast.Unary;
const Operator = ast.Operator;
const Binary = ast.Binary;
const expect = std.testing.expect;

test "literals: false" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .literal = try Literal.create(allocator, .false, null) };
    defer expr.destroy(allocator);
    const res = try eval(allocator, expr);
    try expect(res.?.bool == false);
}

test "literals: true" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .literal = try Literal.create(allocator, .true, null) };
    defer expr.destroy(allocator);
    const res = try eval(allocator, expr);
    try expect(res.?.bool == true);
}

test "literals: nil" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .literal = try Literal.create(allocator, .nil, null) };
    defer expr.destroy(allocator);
    const res = try eval(allocator, expr);
    try expect(res == null);
}

test "literals: number" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .literal = try Literal.create(allocator, .number, .{ .number = 42 }) };
    defer expr.destroy(allocator);
    const res = try eval(allocator, expr);
    try expect(res.?.number == 42);
}

test "literals: string" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .literal = try Literal.create(allocator, .string, .{ .string = "test" }) };
    defer expr.destroy(allocator);
    const res = try eval(allocator, expr);
    try expect(std.mem.eql(u8, res.?.string.value, "test"));
}

test "parentheses" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .grouping = try Grouping.create(allocator, Expr{ .literal = try Literal.create(allocator, .number, .{ .number = 42 }) }) };
    defer expr.destroy(allocator);
    const res = try eval(allocator, expr);
    try expect(res.?.number == 42);
}

test "unary operators: negation" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .unary = try Unary.create(allocator, .minus, Expr{ .literal = try Literal.create(allocator, .number, .{ .number = 42 }) }) };
    defer expr.destroy(allocator);
    const res = try eval(allocator, expr);
    try expect(res.?.number == -42);
}

test "unary operators: logical not" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .unary = try Unary.create(allocator, .bang, Expr{ .literal = try Literal.create(allocator, .true, null) }) };
    defer expr.destroy(allocator);
    const res = try eval(allocator, expr);
    try expect(res.?.bool == false);
}

test "arithmetic operators" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .binary = try Binary.create(allocator, Expr{ .literal = try Literal.create(allocator, .number, .{ .number = 42 }) }, .slash, Expr{ .literal = try Literal.create(allocator, .number, .{ .number = 5 }) }) };
    defer expr.destroy(allocator);
    const res = try eval(allocator, expr);
    try expect(res.?.number == 42.0 / 5.0);
}

test "string concatenation" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .binary = try Binary.create(allocator, Expr{ .literal = try Literal.create(allocator, .string, .{ .string = "foo" }) }, .plus, Expr{ .literal = try Literal.create(allocator, .string, .{ .string = "bar" }) }) };
    defer expr.destroy(allocator);
    const res = try eval(allocator, expr);
    defer res.?.deinit(allocator);
    try expect(std.mem.eql(u8, res.?.string.value, "foobar"));
}

test "relational operators" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .binary = try Binary.create(allocator, Expr{ .literal = try Literal.create(allocator, .number, .{ .number = 42 }) }, .greater, Expr{ .literal = try Literal.create(allocator, .number, .{ .number = 5 }) }) };
    defer expr.destroy(allocator);
    const res = try eval(allocator, expr);
    try expect(res.?.bool == true);
}
