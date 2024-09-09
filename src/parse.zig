//! Parse the tokens into an abstract syntax tree.
//! The parser is a recursive descent parser.
//! The abstract syntax tree is a tree of expressions defined in the expressions module.
//! Used grammer:
//!    factor  = unary ( ( "*" | "/" ) unary )* ;
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
const Binary = ast.Binary;

pub const Error = error{ParseError} || std.mem.Allocator.Error || std.posix.WriteError;

const Result = struct {
    expr: Expr,
    tokens: []const scan.Token,

    fn init(expr: Expr, tokens: []const scan.Token) Result {
        return Result{ .expr = expr, .tokens = tokens };
    }
};

fn create_unary(allocator: std.mem.Allocator, tokens: []const scan.Token, op: Operator, errorWriter: anytype) Error!Result {
    const right = try unary(allocator, tokens[1..], errorWriter);
    return Result.init(.{ .unary = try Unary.create(allocator, op, right.expr) }, right.tokens);
}

fn create_factor(allocator: std.mem.Allocator, tokens: []const scan.Token, left: Expr, op: Operator, errorWriter: anytype) Error!Result {
    // we use tokens[1..] to account for operator (tokens[0])
    std.debug.assert(tokens.len > 1);
    const right = try unary(allocator, tokens[1..], errorWriter);
    return Result.init(.{ .binary = try Binary.create(allocator, left, op, right.expr) }, right.tokens);
}

fn create_term(allocator: std.mem.Allocator, tokens: []const scan.Token, left: Expr, op: Operator, errorWriter: anytype) Error!Result {
    // we use tokens[1..] to account for operator (tokens[0])
    std.debug.assert(tokens.len > 1);
    const right = try factor(allocator, tokens[1..], errorWriter);
    return Result.init(.{ .binary = try Binary.create(allocator, left, op, right.expr) }, right.tokens);
}

fn create_comparison(allocator: std.mem.Allocator, tokens: []const scan.Token, left: Expr, op: Operator, errorWriter: anytype) Error!Result {
    // we use tokens[1..] to account for operator (tokens[0])
    std.debug.assert(tokens.len > 1);
    const right = try term(allocator, tokens[1..], errorWriter);
    return Result.init(.{ .binary = try Binary.create(allocator, left, op, right.expr) }, right.tokens);
}

fn create_equality(allocator: std.mem.Allocator, tokens: []const scan.Token, left: Expr, op: Operator, errorWriter: anytype) Error!Result {
    // we use tokens[1..] to account for operator (tokens[0])
    std.debug.assert(tokens.len > 1);
    const right = try comparison(allocator, tokens[1..], errorWriter);
    return Result.init(.{ .binary = try Binary.create(allocator, left, op, right.expr) }, right.tokens);
}

// merge create_factor, create_term, create_comparison abd create_equality into a single function

fn equality(allocator: std.mem.Allocator, tokens: []const scan.Token, errorWriter: anytype) Error!Result {
    std.debug.assert(tokens.len > 0);
    var res = try comparison(allocator, tokens, errorWriter);
    errdefer res.expr.destroy(allocator);

    while (res.tokens.len > 0) {
        switch (res.tokens[0].type) {
            .BANG_EQUAL => res = try create_term(allocator, res.tokens, res.expr, .{ .type = .bang_equal, .line = res.tokens[0].line }, errorWriter),
            .EQUAL_EQUAL => res = try create_term(allocator, res.tokens, res.expr, .{ .type = .equal_equal, .line = res.tokens[0].line }, errorWriter),
            else => break,
        }
    }

    return res;
}

fn comparison(allocator: std.mem.Allocator, tokens: []const scan.Token, errorWriter: anytype) Error!Result {
    std.debug.assert(tokens.len > 0);
    var res = try term(allocator, tokens, errorWriter);
    errdefer res.expr.destroy(allocator);

    while (res.tokens.len > 0) {
        switch (res.tokens[0].type) {
            .GREATER => res = try create_term(allocator, res.tokens, res.expr, .{ .type = .greater, .line = res.tokens[0].line }, errorWriter),
            .GREATER_EQUAL => res = try create_term(allocator, res.tokens, res.expr, .{ .type = .greater_equal, .line = res.tokens[0].line }, errorWriter),
            .LESS => res = try create_term(allocator, res.tokens, res.expr, .{ .type = .less, .line = res.tokens[0].line }, errorWriter),
            .LESS_EQUAL => res = try create_term(allocator, res.tokens, res.expr, .{ .type = .less_equal, .line = res.tokens[0].line }, errorWriter),
            else => break,
        }
    }

    return res;
}

fn term(allocator: std.mem.Allocator, tokens: []const scan.Token, errorWriter: anytype) Error!Result {
    std.debug.assert(tokens.len > 0);
    var res = try factor(allocator, tokens, errorWriter);
    errdefer res.expr.destroy(allocator);

    while (res.tokens.len > 0) {
        switch (res.tokens[0].type) {
            .MINUS => res = try create_term(allocator, res.tokens, res.expr, .{ .type = .minus, .line = res.tokens[0].line }, errorWriter),
            .PLUS => res = try create_term(allocator, res.tokens, res.expr, .{ .type = .plus, .line = res.tokens[0].line }, errorWriter),
            else => break,
        }
    }

    return res;
}

fn factor(allocator: std.mem.Allocator, tokens: []const scan.Token, errorWriter: anytype) Error!Result {
    std.debug.assert(tokens.len > 0);
    var res = try unary(allocator, tokens, errorWriter);
    errdefer res.expr.destroy(allocator);

    while (res.tokens.len > 0) {
        switch (res.tokens[0].type) {
            .SLASH => res = try create_factor(allocator, res.tokens, res.expr, .{ .type = .slash, .line = res.tokens[0].line }, errorWriter),
            .STAR => res = try create_factor(allocator, res.tokens, res.expr, .{ .type = .star, .line = res.tokens[0].line }, errorWriter),
            else => break,
        }
    }

    return res;
}

/// Parse a unary expression: ( "!" | "-" ) unary | primary ;
fn unary(allocator: std.mem.Allocator, tokens: []const scan.Token, errorWriter: anytype) Error!Result {
    std.debug.assert(tokens.len > 0);
    switch (tokens[0].type) {
        .BANG => return create_unary(allocator, tokens, .{ .type = .bang, .line = tokens[0].line }, errorWriter),
        .MINUS => return create_unary(allocator, tokens, .{ .type = .minus, .line = tokens[0].line }, errorWriter),
        else => return primary(allocator, tokens, errorWriter),
    }
}

/// Parse a primary expression: "false" | "true" | "nil" | NUMBER | STRING | "(" expression ")" ;
fn primary(allocator: std.mem.Allocator, tokens: []const scan.Token, errorWriter: anytype) Error!Result {
    std.debug.assert(tokens.len > 0);
    const token = tokens[0];
    switch (token.type) {
        .FALSE => return Result.init(.{ .literal = try Literal.create(allocator, .false, null) }, tokens[1..]),
        .TRUE => return Result.init(.{ .literal = try Literal.create(allocator, .true, null) }, tokens[1..]),
        .NIL => return Result.init(.{ .literal = try Literal.create(allocator, .nil, null) }, tokens[1..]),
        .NUMBER => return Result.init(.{ .literal = try Literal.create(allocator, .number, .{ .number = token.literal.?.number }) }, tokens[1..]),
        .STRING => return Result.init(.{ .literal = try Literal.create(allocator, .string, .{ .string = token.literal.?.string }) }, tokens[1..]),

        .LEFT_PAREN => {
            const inner = try parse(allocator, tokens[1..], errorWriter);

            std.debug.assert(inner.tokens.len > 0);
            if (inner.tokens[0].type != .RIGHT_PAREN) {
                defer inner.expr.destroy(allocator);
                try errorWriter.print("[line {d}] Expect ')' after expression.", .{inner.tokens[0].line});
                return error.ParseError;
            }

            return Result.init(.{ .grouping = try Grouping.create(allocator, inner.expr) }, inner.tokens[1..]);
        },

        else => {
            std.debug.assert(tokens.len > 0);
            try errorWriter.print("[line {d}] Expect expression.", .{tokens[0].line});
            return error.ParseError;
        },
    }
}

pub fn parse(allocator: std.mem.Allocator, tokens: []const scan.Token, errorWriter: anytype) Error!Result {
    return try equality(allocator, tokens, errorWriter);
}
