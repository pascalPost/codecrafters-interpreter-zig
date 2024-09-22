//! This module contains the statments AST. The rules are:
//! program → statement* EOF ;
//! statement → exprStmt | printStmt ;
//! exprStmt → expression ";" ;
//! printStmt → "print" expression ";" ;

const std = @import("std");
const scan = @import("scan.zig");
const parser = @import("parse.zig");
const expressions = @import("expressions.zig");
const eval = @import("eval.zig");

pub const Tag = enum(u1) { print, expr };

pub const Stmt = union(Tag) { print: expressions.Expr, expr: expressions.Expr };

fn create_statement(allocator: std.mem.Allocator, tokens: *[]const scan.Token, errorWriter: anytype) !Stmt {
    std.debug.assert(tokens.len > 0);
    switch (tokens.*[0].type) {
        .PRINT => {
            const res = try parser.parse(allocator, tokens.*[1..], errorWriter);
            tokens.* = res.tokens;
            errdefer res.expr.destroy(allocator);

            // account for semicolon
            std.debug.assert(tokens.len > 0 and tokens.*[0].type == .SEMICOLON);
            tokens.* = res.tokens[1..];

            return .{ .print = res.expr };
        },
        else => {
            const res = try parser.parse(allocator, tokens.*, errorWriter);
            tokens.* = res.tokens;
            errdefer res.expr.destroy(allocator);

            // account for semicolon
            std.debug.assert(tokens.len > 0 and tokens.*[0].type == .SEMICOLON);
            tokens.* = res.tokens[1..];

            return .{ .expr = res.expr };
        },
    }
}

pub fn parse(allocator: std.mem.Allocator, tokens: *[]const scan.Token, errorWriter: anytype) ![]const Stmt {
    var statements = std.ArrayList(Stmt).init(allocator);

    while (tokens.len > 0 and tokens.*[0].type != .EOF) {
        const statement = try create_statement(allocator, tokens, errorWriter);
        try statements.append(statement);
    }

    return statements.toOwnedSlice();
}

test "print: generate output" {
    const program =
        \\ print "Hello, World!";
    ;

    const allocator = std.testing.allocator;

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(allocator, program, errOut.writer());
    defer scanner.deinit();

    var tokens: []const scan.Token = scanner.tokens.items[0..];

    const statements = try parse(allocator, &tokens, errOut.writer());
    defer {
        for (statements) |stmt| {
            switch (stmt) {
                .expr, .print => |e| e.destroy(allocator),
            }
        }
        allocator.free(statements);
    }

    // for(statements) |stmt| {
    //     if(stmt == .print){
    //         const res = try eval.eval(allocator, stmt.expr);
    //         if(res)|r| {}
    //     }
    // }

    try std.testing.expect(statements.len > 0);
    try std.testing.expect(statements[0] == .print);
    try std.testing.expect(statements[0].print == .literal);
}
