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

fn run(allocator: std.mem.Allocator, program: []const u8, outWriter: anytype, errWriter: anytype) !void {
    const scanner = try scan.Scanner.init(allocator, program, errWriter);
    defer scanner.deinit();

    var tokens: []const scan.Token = scanner.tokens.items[0..];

    const statements = try parse(allocator, &tokens, errWriter);
    defer {
        for (statements) |stmt| {
            switch (stmt) {
                .expr, .print => |e| e.destroy(allocator),
            }
        }
        allocator.free(statements);
    }

    for (statements) |stmt| {
        switch (stmt) {
            .print => |e| {
                const res = eval.eval(allocator, e) catch {
                    std.process.exit(70);
                };

                if (res) |val| {
                    defer val.deinit(allocator);
                    try outWriter.print("{}\n", .{val});
                } else {
                    try outWriter.writeAll("nil\n");
                }
            },
            else => {},
        }
    }
}

test "print: generate output" {
    const program =
        \\ print "Hello, World!";
    ;

    const allocator = std.testing.allocator;

    var stdOut = std.ArrayList(u8).init(std.testing.allocator);
    defer stdOut.deinit();

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    try run(allocator, program, stdOut.writer(), errOut.writer());
    try std.testing.expect(errOut.items.len == 0);
    try std.testing.expect(std.mem.eql(u8, "Hello, World!\n", stdOut.items[0..]));
}

test "print: multiple outputs" {
    const program =
    \\ print "Hello, World!";
    \\ print 42;
;

    const allocator = std.testing.allocator;

    var stdOut = std.ArrayList(u8).init(std.testing.allocator);
    defer stdOut.deinit();

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    try run(allocator, program, stdOut.writer(), errOut.writer());
    try std.testing.expect(errOut.items.len == 0);
    try std.testing.expect(std.mem.eql(u8, "Hello, World!\n42\n", stdOut.items[0..]));
}
