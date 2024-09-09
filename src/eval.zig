const std = @import("std");
const ast = @import("expressions.zig");
const Expr = ast.Expr;
const Literal = ast.Literal;
const Grouping = ast.Grouping;
const Unary = ast.Unary;
const Operator = ast.Operator;
const Binary = ast.Binary;

pub const Error = error{ OperandNoNumber, OperandsNoNumbers } || std.mem.Allocator.Error || std.posix.WriteError;

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

fn equality_operator(left: Result, right: Result) Error!?Result {
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
                    errdefer if (right) |e| e.deinit(allocator);

                    if (right == null or right.? != .number) {
                        try std.io.getStdErr().writer().print("[line {d}] Error: Operand must be a number.\n", .{u.operator.line});
                        return error.OperandNoNumber;
                    }
                    return .{ .number = -(try eval(allocator, u.right)).?.number };
                },
                .bang => return .{ .bool = !to_bool(try eval(allocator, u.right)) },
                else => unreachable,
            }
        },
        .binary => |b| {
            const left = (try eval(allocator, b.left));
            const right = (try eval(allocator, b.right));

            errdefer if (left) |r| r.deinit(allocator);
            errdefer if (right) |r| r.deinit(allocator);

            switch (b.operator.type) {
                .slash, .star, .minus => {
                    if (left == null or left.? != .number or right == null or right.? != .number) {
                        try std.io.getStdErr().writer().print("[line {d}] Error: Operands must be numbers.\n", .{b.operator.line});
                        return error.OperandNoNumber;
                    }
                },
                .plus => {
                    if (left == null or right == null) {
                        try std.io.getStdErr().writer().print("[line {d}] Error: Operands must be numbers.\n", .{b.operator.line});
                        return error.OperandNoNumber;
                    }
                },
                else => {},
            }

            switch (b.operator.type) {
                .slash => return .{ .number = left.?.number / right.?.number },
                .star => return .{ .number = left.?.number * right.?.number },
                .minus => return .{ .number = left.?.number - right.?.number },
                .plus => {
                    if (left.? == .string) {
                        std.debug.assert(right.? == .string);

                        defer left.?.deinit(allocator);
                        defer right.?.deinit(allocator);

                        return .{ .string = .{ .value = try concat(allocator, left.?.string.value, right.?.string.value), .owning = true } };
                    }

                    return .{ .number = left.?.number + right.?.number };
                },
                .less => return .{ .bool = left.?.number < right.?.number },
                .less_equal => return .{ .bool = left.?.number <= right.?.number },
                .greater => return .{ .bool = left.?.number > right.?.number },
                .greater_equal => return .{ .bool = left.?.number >= right.?.number },
                .equal_equal => return try equality_operator(left.?, right.?),
                .bang_equal => {
                    var result = try equality_operator(left.?, right.?);
                    result.?.bool = !result.?.bool;
                    return result;
                },
                else => unreachable,
            }
        },
    }
}
