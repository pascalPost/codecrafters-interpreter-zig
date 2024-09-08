const std = @import("std");
const ast = @import("expressions.zig");
const Expr = ast.Expr;
const Literal = ast.Literal;
const Grouping = ast.Grouping;
const Unary = ast.Unary;
const Operator = ast.Operator;
const Binary = ast.Binary;

const Tag = enum(u2) { bool, number, string };

pub const Result = union(Tag) {
    bool: bool,
    number: f64,
    string: []const u8,

    pub fn deinit(self: Result, allocator: std.mem.Allocator) void {
        if (self == .string) {
            allocator.free(self.string);
        }
    }

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

fn concat(allocator: std.mem.Allocator, a: []const u8, b: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, a.len + b.len);
    @memcpy(result[0..a.len], a);
    @memcpy(result[a.len..], b);
    return result;
}

pub fn eval(allocator: std.mem.Allocator, expr: Expr) std.mem.Allocator.Error!?Result {
    switch (expr) {
        .literal => |l| {
            switch (l.type) {
                .false => return .{ .bool = false },
                .true => return .{ .bool = true },
                .nil => return null,
                .number => return .{ .number = l.value.?.number },
                .string => {

                    // TODO this is an unnecessary copy; perhaps we can enhance by differentiating between an string literal and a string
                    const store = try allocator.dupe(u8, l.value.?.string);

                    return .{ .string = store };
                },
            }
        },
        .grouping => |c| return try eval(allocator, c.expr),
        .unary => |u| {
            switch (u.operator) {
                .minus => return .{ .number = -(try eval(allocator, u.right)).?.number },
                .bang => return .{ .bool = !to_bool(try eval(allocator, u.right)) },
                else => unreachable,
            }
        },
        .binary => |b| {
            switch (b.operator) {
                .slash => return .{ .number = (try eval(allocator, b.left)).?.number / (try eval(allocator, b.right)).?.number },
                .star => return .{ .number = (try eval(allocator, b.left)).?.number * (try eval(allocator, b.right)).?.number },
                .minus => return .{ .number = (try eval(allocator, b.left)).?.number - (try eval(allocator, b.right)).?.number },
                .plus => {
                    const left = (try eval(allocator, b.left)).?;
                    const right = (try eval(allocator, b.right)).?;

                    if (left == .string) {
                        std.debug.assert(right == .string);

                        // TODO this is probably not the most efficient way to do this
                        defer allocator.free(left.string);
                        defer allocator.free(right.string);

                        return .{ .string = try concat(allocator, left.string, right.string) };
                    }

                    return .{ .number = (try eval(allocator, b.left)).?.number + (try eval(allocator, b.right)).?.number };
                },
                else => unreachable,
            }
        },
    }
}
