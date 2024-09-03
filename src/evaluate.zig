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

fn to_bool(val: ?Result) bool {
    if (val) |v| {
        switch (v) {
            .bool => return v.bool,
            else => return true,
        }
    }

    return false;
}

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
        .unary => |u| {
            switch (u.operator) {
                .minus => return .{ .number = -eval(u.right).?.number },
                .bang => return .{ .bool = !to_bool(eval(u.right)) },
                else => unreachable,
            }
        },
        .binary => |b| {
            switch (b.operator) {
                .slash => return .{ .number = eval(b.left).?.number / eval(b.right).?.number },
                .star => return .{ .number = eval(b.left).?.number * eval(b.right).?.number },
                .plus => return .{ .number = eval(b.left).?.number + eval(b.right).?.number },
                .minus => return .{ .number = eval(b.left).?.number - eval(b.right).?.number },
                else => unreachable,
            }
        },
    }
}
