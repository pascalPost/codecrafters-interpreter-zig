const std = @import("std");
const ast = @import("expressions.zig");
const Expr = ast.Expr;
const Literal = ast.Literal;
const Grouping = ast.Grouping;
const Unary = ast.Unary;
const Operator = ast.Operator;
const Binary = ast.Binary;

const expect = std.testing.expect;

pub fn eval(expr: Expr) ?bool {
    switch (expr) {
        .literal => {
            switch (expr.literal.type) {
                .false => return false,
                .true => return true,
                .nil => return null,
                else => unreachable,
            }

            // return expr.literal.value.?. .?.value;
        },
        else => unreachable,
    }
}

test "literals: booleans & nil (false)" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .literal = try Literal.create(allocator, .false, null) };
    defer expr.destroy(allocator);
    const res = eval(expr);
    try expect(res == false);
}

test "literals: booleans & nil (true)" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .literal = try Literal.create(allocator, .true, null) };
    defer expr.destroy(allocator);
    const res = eval(expr);
    try expect(res == true);
}

test "literals: booleans & nil (nil)" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .literal = try Literal.create(allocator, .nil, null) };
    defer expr.destroy(allocator);
    const res = eval(expr);
    try expect(res == null);
}
