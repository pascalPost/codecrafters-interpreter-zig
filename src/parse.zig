const std = @import("std");
const scan = @import("scan.zig");
const Expr = @import("expressions.zig").Expr;
const Literal = @import("expressions.zig").Literal;

fn primary(allocator: std.mem.Allocator, tokens: []const scan.Token) !Expr {
    std.debug.assert(tokens.len > 0);

    const token = tokens[0];

    switch (token.type) {
        .FALSE => return Expr{ .literal = try Literal.create(allocator, .false, null) },
        .TRUE => return Expr{ .literal = try Literal.create(allocator, .true, null) },
        .NIL => return Expr{ .literal = try Literal.create(allocator, .nil, null) },
        .NUMBER => return Expr{ .literal = try Literal.create(allocator, .number, .{ .number = token.literal.?.number }) },
        else => unreachable,
    }
}

pub fn parse(allocator: std.mem.Allocator, tokens: []const scan.Token) !Expr {
    return primary(allocator, tokens);
}
