const std = @import("std");
const scanner = @import("scanner.zig");
const expect = std.testing.expect;
const eql = scanner.eql;
const Token = scanner.Token;
const tokenize = scanner.tokenize;

test "Empty file" {
    const content = "";
    var tokens = try tokenize(std.testing.allocator, content[0..]);
    defer tokens.deinit();

    try expect(tokens.items.len == 1);
    try expect(eql(tokens.items[0], Token.init(.EOF, 0, 0)));
}

test "Parentheses" {
    const content = "(()";
    var tokens = try tokenize(std.testing.allocator, content[0..]);
    defer tokens.deinit();

    try expect(tokens.items.len == 4);
    try expect(eql(tokens.items[0], Token.init(.LEFT_PAREN, 0, 1)));
    try expect(eql(tokens.items[1], Token.init(.LEFT_PAREN, 1, 1)));
    try expect(eql(tokens.items[2], Token.init(.RIGHT_PAREN, 2, 1)));
    try expect(eql(tokens.items[3], Token.init(.EOF, 3, 0)));
}

test "Braces" {
    const content = "{{}}";
    var tokens = try tokenize(std.testing.allocator, content[0..]);
    defer tokens.deinit();

    try expect(tokens.items.len == 5);
    try expect(eql(tokens.items[0], Token.init(.LEFT_BRACE, 0, 1)));
    try expect(eql(tokens.items[1], Token.init(.LEFT_BRACE, 1, 1)));
    try expect(eql(tokens.items[2], Token.init(.RIGHT_BRACE, 2, 1)));
    try expect(eql(tokens.items[3], Token.init(.RIGHT_BRACE, 3, 1)));
    try expect(eql(tokens.items[4], Token.init(.EOF, 4, 0)));
}

test "single-character tokens" {
    const content = "({*.,+-;})";
    var tokens = try tokenize(std.testing.allocator, content[0..]);
    defer tokens.deinit();

    try expect(tokens.items.len == 11);
    try expect(eql(tokens.items[0], Token.init(.LEFT_PAREN, 0, 1)));
    try expect(eql(tokens.items[1], Token.init(.LEFT_BRACE, 1, 1)));
    try expect(eql(tokens.items[2], Token.init(.STAR, 2, 1)));
    try expect(eql(tokens.items[3], Token.init(.DOT, 3, 1)));
    try expect(eql(tokens.items[4], Token.init(.COMMA, 4, 1)));
    try expect(eql(tokens.items[5], Token.init(.PLUS, 5, 1)));
    try expect(eql(tokens.items[6], Token.init(.MINUS, 6, 1)));
    try expect(eql(tokens.items[7], Token.init(.SEMICOLON, 7, 1)));
    try expect(eql(tokens.items[8], Token.init(.RIGHT_BRACE, 8, 1)));
    try expect(eql(tokens.items[9], Token.init(.RIGHT_PAREN, 9, 1)));
    try expect(eql(tokens.items[10], Token.init(.EOF, 10, 0)));
}
