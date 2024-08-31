//! Parse the tokens into an abstract syntax tree.
//! The parser is a recursive descent parser.
//! The abstract syntax tree is a tree of expressions defined in the expressions module.
//! Used grammer:
//!    unary   = ( "!" | "-" ) unary | primary ;
//!    primary = "false" | "true" | "nil" | NUMBER | STRING | "(" expression ")" ;

const std = @import("std");
const scan = @import("scan.zig");
const ast = @import("expressions.zig");
const Expr = ast.Expr;
const Literal = ast.Literal;
const Grouping = ast.Grouping;
const Unary = ast.Unary;
const Operator = ast.Operator;

const Result = struct {
    expr: Expr,
    tokens: []const scan.Token,

    fn init(expr: Expr, tokens: []const scan.Token) Result {
        return Result{ .expr = expr, .tokens = tokens };
    }
};

fn create_unary(allocator: std.mem.Allocator, tokens: []const scan.Token, op: Operator) std.mem.Allocator.Error!Result {
    const right = try parse(allocator, tokens[1..]);
    return Result.init(.{ .unary = try Unary.create(allocator, op, right.expr) }, right.tokens);
}

/// Parse a unary expression: ( "!" | "-" ) unary | primary ;
fn unary(allocator: std.mem.Allocator, tokens: []const scan.Token) std.mem.Allocator.Error!Result {
    std.debug.assert(tokens.len > 0);
    switch (tokens[0].type) {
        .BANG => return create_unary(allocator, tokens, .bang),
        .MINUS => return create_unary(allocator, tokens, .minus),
        else => return primary(allocator, tokens),
    }
}

/// Parse a primary expression: "false" | "true" | "nil" | NUMBER | STRING | "(" expression ")" ;
fn primary(allocator: std.mem.Allocator, tokens: []const scan.Token) std.mem.Allocator.Error!Result {
    std.debug.assert(tokens.len > 0);
    const token = tokens[0];
    switch (token.type) {
        .FALSE => return Result.init(.{ .literal = try Literal.create(allocator, .false, null) }, tokens[1..]),
        .TRUE => return Result.init(.{ .literal = try Literal.create(allocator, .true, null) }, tokens[1..]),
        .NIL => return Result.init(.{ .literal = try Literal.create(allocator, .nil, null) }, tokens[1..]),
        .NUMBER => return Result.init(.{ .literal = try Literal.create(allocator, .number, .{ .number = token.literal.?.number }) }, tokens[1..]),
        .STRING => return Result.init(.{ .literal = try Literal.create(allocator, .string, .{ .string = token.literal.?.string }) }, tokens[1..]),

        .LEFT_PAREN => {
            const inner = try parse(allocator, tokens[1..]);

            std.debug.assert(inner.tokens.len > 0 and inner.tokens[0].type == .RIGHT_PAREN);

            return Result.init(.{ .grouping = try Grouping.create(allocator, inner.expr) }, inner.tokens[1..]);
        },

        else => unreachable,
    }
}

pub fn parse(allocator: std.mem.Allocator, tokens: []const scan.Token) std.mem.Allocator.Error!Result {
    return unary(allocator, tokens);
}
