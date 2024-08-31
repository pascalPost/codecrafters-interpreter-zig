const std = @import("std");
const scan = @import("scan.zig");
const Expr = @import("expressions.zig").Expr;
const Literal = @import("expressions.zig").Literal;

fn primary(allocator: std.mem.Allocator, tokens: []scan.Token) !Expr {
    std.debug.assert(tokens.len > 0);

    switch (tokens[0].type) {
        .FALSE => return Expr{ .literal = try Literal.create(allocator, .false, null) },
        .TRUE => return Expr{ .literal = try Literal.create(allocator, .true, null) },
        .NIL => return Expr{ .literal = try Literal.create(allocator, .nil, null) },
        else => unreachable,
    }
}

pub fn parse(allocator: std.mem.Allocator, tokens: []scan.Token) !Expr {
    return primary(allocator, tokens);
}
