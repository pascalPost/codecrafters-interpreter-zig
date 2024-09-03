const std = @import("std");
const ast = @import("expressions.zig");
const Expr = ast.Expr;
const Literal = ast.Literal;
const Grouping = ast.Grouping;
const Unary = ast.Unary;
const Operator = ast.Operator;
const Binary = ast.Binary;

const Tag = enum(u2) { bool, number, string };

const Result = union(Tag) {
    bool: bool,
    number: f64,
    string: []const u8,

    pub fn format(self: Result, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        switch (self) {
            .bool => try writer.print("{}", .{self.bool}),
            .number => {
                const number: f64 = self.number;
                const number_int: i64 = @intFromFloat(number);
                const number_recast: f64 = @floatFromInt(number_int);

                if (number == number_recast) {
                    try writer.print("{d:.0}", .{number});
                } else {
                    try writer.print("{d}", .{number});
                }
            },
            .string => try writer.print("{s}", .{self.string}),
        }
    }
};

const expect = std.testing.expect;

pub fn eval(expr: Expr) ?Result {
    switch (expr) {
        .literal => |l| {
            switch (l.type) {
                .false => return .{ .bool = false },
                .true => return .{ .bool = true },
                .nil => return null,
                .number => return .{ .number = expr.literal.value.?.number },
                .string => return .{ .string = expr.literal.value.?.string },
            }
        },
        .grouping => |c| return eval(c.expr),
        else => unreachable,
    }
}

test "literals: false" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .literal = try Literal.create(allocator, .false, null) };
    defer expr.destroy(allocator);
    const res = eval(expr);
    try expect(res.?.bool == false);
}

test "literals: true" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .literal = try Literal.create(allocator, .true, null) };
    defer expr.destroy(allocator);
    const res = eval(expr);
    try expect(res.?.bool == true);
}

test "literals: nil" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .literal = try Literal.create(allocator, .nil, null) };
    defer expr.destroy(allocator);
    const res = eval(expr);
    try expect(res == null);
}

test "literals: number" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .literal = try Literal.create(allocator, .number, .{ .number = 42 }) };
    defer expr.destroy(allocator);
    const res = eval(expr);
    try expect(res.?.number == 42);

    try std.io.getStdOut().writer().print("{}\n", .{res.?});
}

test "literals: string" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .literal = try Literal.create(allocator, .string, .{ .string = "test" }) };
    defer expr.destroy(allocator);
    const res = eval(expr);
    try expect(std.mem.eql(u8, res.?.string, "test"));
}

test "parentheses" {
    const allocator = std.testing.allocator;
    const expr = Expr{ .grouping = try Grouping.create(allocator, Expr{ .literal = try Literal.create(allocator, .number, .{ .number = 42 }) }) };
    defer expr.destroy(allocator);
    const res = eval(expr);
    try expect(res.?.number == 42);
}
