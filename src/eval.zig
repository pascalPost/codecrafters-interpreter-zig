const std = @import("std");
const ast = @import("expressions.zig");
const Expr = ast.Expr;
const Literal = ast.Literal;
const Grouping = ast.Grouping;
const Unary = ast.Unary;
const Operator = ast.Operator;
const Binary = ast.Binary;

pub const Error = error{OperandNoNumber} || std.mem.Allocator.Error || std.posix.WriteError;

const Tag = enum(u2) { bool, number, string };

pub const Result = union(Tag) {
    bool: bool,
    number: f64,
    string: struct { value: []const u8, owning: bool = false },

    pub fn deinit(self: Result, allocator: std.mem.Allocator) void {
        if (self == .string and self.string.owning) {
            allocator.free(self.string.value);
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
            .string => |s| try writer.print("{s}", .{s.value}),
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

fn equality_operator(allocator: std.mem.Allocator, left_expr: Expr, right_expr: Expr) Error!?Result {
    const left = (try eval(allocator, left_expr)).?;
    const right = (try eval(allocator, right_expr)).?;

    switch (left) {
        .string => return .{ .bool = right == .string and std.mem.eql(u8, left.string.value, right.string.value) },
        .number => return .{ .bool = right == .number and left.number == right.number },
        .bool => return .{ .bool = right == .bool and left.bool == right.bool },
    }

    return .{ .bool = false };
}

pub fn eval(allocator: std.mem.Allocator, expr: Expr) Error!?Result {
    switch (expr) {
        .literal => |l| {
            switch (l.type) {
                .false => return .{ .bool = false },
                .true => return .{ .bool = true },
                .nil => return null,
                .number => return .{ .number = l.value.?.number },

                // TODO perhaps ownership can be transferred here; has to be reviewed once all is working to know for sure
                .string => return .{ .string = .{ .value = l.value.?.string, .owning = false } },
            }
        },
        .grouping => |c| return try eval(allocator, c.expr),
        .unary => |u| {
            switch (u.operator.type) {
                .minus => {
                    const right = try eval(allocator, u.right);
                    if (right == null or right.? != .number) {
                        try std.io.getStdErr().writer().print("[line {d}] Error: Operands must be numbers.\n", .{u.operator.line});
                        return error.OperandNoNumber;
                    }
                    return .{ .number = -(try eval(allocator, u.right)).?.number };
                },
                .bang => return .{ .bool = !to_bool(try eval(allocator, u.right)) },
                else => unreachable,
            }
        },
        .binary => |b| {
            switch (b.operator.type) {
                .slash => return .{ .number = (try eval(allocator, b.left)).?.number / (try eval(allocator, b.right)).?.number },
                .star => return .{ .number = (try eval(allocator, b.left)).?.number * (try eval(allocator, b.right)).?.number },
                .minus => return .{ .number = (try eval(allocator, b.left)).?.number - (try eval(allocator, b.right)).?.number },
                .plus => {
                    const left = (try eval(allocator, b.left)).?;
                    const right = (try eval(allocator, b.right)).?;

                    if (left == .string) {
                        std.debug.assert(right == .string);

                        defer left.deinit(allocator);
                        defer right.deinit(allocator);

                        return .{ .string = .{ .value = try concat(allocator, left.string.value, right.string.value), .owning = true } };
                    }

                    return .{ .number = (try eval(allocator, b.left)).?.number + (try eval(allocator, b.right)).?.number };
                },
                .less => return .{ .bool = (try eval(allocator, b.left)).?.number < (try eval(allocator, b.right)).?.number },
                .less_equal => return .{ .bool = (try eval(allocator, b.left)).?.number <= (try eval(allocator, b.right)).?.number },
                .greater => return .{ .bool = (try eval(allocator, b.left)).?.number > (try eval(allocator, b.right)).?.number },
                .greater_equal => return .{ .bool = (try eval(allocator, b.left)).?.number >= (try eval(allocator, b.right)).?.number },
                .equal_equal => return equality_operator(allocator, b.left, b.right),
                .bang_equal => {
                    var result = try equality_operator(allocator, b.left, b.right);
                    result.?.bool = !result.?.bool;
                    return result;
                },
                else => unreachable,
            }
        },
    }
}
