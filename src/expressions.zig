const std = @import("std");
const Token = @import("scan.zig").Token;
const LiteralStorage = @import("scan.zig").LiteralStorage;

pub const Operator = enum(u4) {
    bang,
    minus,
    plus,
    slash,
    star,
    greater,
    greater_equal,
    less,
    less_equal,

    pub fn format(self: Operator, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        const str = switch (self) {
            .bang => "!",
            .minus => "-",
            .plus => "+",
            .slash => "/",
            .star => "*",
            .greater => ">",
            .greater_equal => ">=",
            .less => "<",
            .less_equal => "<=",
        };

        try writer.print("{s}", .{str});
    }
};

pub const Tag = enum(u2) { binary, grouping, literal, unary };

pub const Expr = union(Tag) {
    binary: *Binary,
    grouping: *Grouping,
    literal: *Literal,
    unary: *Unary,

    pub fn destroy(self: Expr, allocator: std.mem.Allocator) void {
        switch (self) {
            .binary => |ptr| {
                ptr.left.destroy(allocator);
                ptr.right.destroy(allocator);
                allocator.destroy(ptr);
            },
            .grouping => |ptr| {
                ptr.expr.destroy(allocator);
                allocator.destroy(ptr);
            },
            .literal => |ptr| allocator.destroy(ptr),
            .unary => |ptr| {
                ptr.right.destroy(allocator);
                allocator.destroy(ptr);
            },
        }
    }

    pub fn format(self: Expr, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self) {
            .binary => |ptr| try ptr.*.format(fmt, options, writer),
            .grouping => |ptr| try ptr.*.format(fmt, options, writer),
            .literal => |ptr| try ptr.*.format(fmt, options, writer),
            .unary => |ptr| try ptr.*.format(fmt, options, writer),
        }
    }
};

pub const Binary = struct {
    left: Expr,
    operator: Operator,
    right: Expr,

    pub fn create(allocator: std.mem.Allocator, left: Expr, op: Operator, right: Expr) !*Binary {
        const binary = try allocator.create(Binary);
        binary.left = left;
        binary.operator = op;
        binary.right = right;
        return binary;
    }

    pub fn format(self: Binary, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("({} {} {})", .{ self.operator, self.left, self.right });
    }
};

pub const Grouping = struct {
    expr: Expr,

    pub fn create(allocator: std.mem.Allocator, expr: Expr) !*Grouping {
        const grouping = try allocator.create(Grouping);
        grouping.expr = expr;
        return grouping;
    }

    pub fn format(self: Grouping, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("(group {})", .{self.expr});
    }
};

const LiteralType = enum { number, string, true, false, nil };

pub const Literal = struct {
    type: LiteralType,
    value: ?LiteralStorage,

    pub fn create(allocator: std.mem.Allocator, literalType: LiteralType, value: ?LiteralStorage) !*Literal {
        const literalPtr = try allocator.create(Literal);
        literalPtr.type = literalType;
        literalPtr.value = value;
        return literalPtr;
    }

    pub fn format(self: Literal, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        switch (self.type) {
            .string => try writer.print("{s}", .{self.value.?.string}),
            .number => {
                const number: f64 = self.value.?.number;
                const number_int: i64 = @intFromFloat(number);
                const number_recast: f64 = @floatFromInt(number_int);

                if (number == number_recast) {
                    try writer.print("{d:.1}", .{number});
                } else {
                    try writer.print("{d}", .{number});
                }
            },
            .true => try writer.writeAll("true"),
            .false => try writer.writeAll("false"),
            .nil => try writer.writeAll("nil"),
        }
    }
};

pub const Unary = struct {
    operator: Operator,
    right: Expr,

    pub fn create(allocator: std.mem.Allocator, op: Operator, right: Expr) !*Unary {
        const unary = try allocator.create(Unary);
        unary.operator = op;
        unary.right = right;
        return unary;
    }

    pub fn format(self: Unary, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;

        try writer.print("({} {})", .{ self.operator, self.right });
    }
};

test "print -123 * ( 45.67 )" {
    const allocator = std.testing.allocator;
    var out = std.ArrayList(u8).init(std.testing.allocator);
    defer out.deinit();

    const expr = Expr{
        .binary = try Binary.create(allocator, .{
            .unary = try Unary.create(allocator, .minus, .{
                .literal = try Literal.create(allocator, .number, .{ .number = 123 }),
            }),
        }, .star, .{
            .grouping = try Grouping.create(allocator, .{
                .literal = try Literal.create(allocator, .number, .{ .number = 45.67 }),
            }),
        }),
    };
    defer expr.destroy(allocator);

    try out.writer().print("{}", .{expr});
    try std.testing.expect(std.mem.eql(u8, "(* (- 123.0) (group 45.67))", out.items[0..]));
}
