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
    try expect(eql(tokens.items[0], Token{ .type = .EOF, .start = 0, .length = 0 }));
}

test "Parentheses" {
    const content = "(()";
    var tokens = try tokenize(std.testing.allocator, content[0..]);
    defer tokens.deinit();

    try expect(tokens.items.len == 4);
    try expect(eql(tokens.items[0], Token{ .type = .LEFT_PAREN, .start = 0, .length = 1 }));
    try expect(eql(tokens.items[1], Token{ .type = .LEFT_PAREN, .start = 1, .length = 1 }));
    try expect(eql(tokens.items[2], Token{ .type = .RIGHT_PAREN, .start = 2, .length = 1 }));
    try expect(eql(tokens.items[3], Token{ .type = .EOF, .start = 3, .length = 0 }));
}

test "Braces" {
    const content = "{{}}";
    var tokens = try tokenize(std.testing.allocator, content[0..]);
    defer tokens.deinit();

    try expect(tokens.items.len == 5);
    try expect(eql(tokens.items[0], Token{ .type = .LEFT_BRACE, .start = 0, .length = 1 }));
    try expect(eql(tokens.items[1], Token{ .type = .LEFT_BRACE, .start = 1, .length = 1 }));
    try expect(eql(tokens.items[2], Token{ .type = .RIGHT_BRACE, .start = 2, .length = 1 }));
    try expect(eql(tokens.items[3], Token{ .type = .RIGHT_BRACE, .start = 3, .length = 1 }));
    try expect(eql(tokens.items[4], Token{ .type = .EOF, .start = 4, .length = 0 }));
}

test "single-character tokens" {
    const content = "({*.,+-;})";
    var tokens = try tokenize(std.testing.allocator, content[0..]);
    defer tokens.deinit();

    try expect(tokens.items.len == 11);
    try expect(eql(tokens.items[0], Token{ .type = .LEFT_PAREN, .start = 0, .length = 1 }));
    try expect(eql(tokens.items[1], Token{ .type = .LEFT_BRACE, .start = 1, .length = 1 }));
    try expect(eql(tokens.items[2], Token{ .type = .STAR, .start = 2, .length = 1 }));
    try expect(eql(tokens.items[3], Token{ .type = .DOT, .start = 3, .length = 1 }));
    try expect(eql(tokens.items[4], Token{ .type = .COMMA, .start = 4, .length = 1 }));
    try expect(eql(tokens.items[5], Token{ .type = .PLUS, .start = 5, .length = 1 }));
    try expect(eql(tokens.items[6], Token{ .type = .MINUS, .start = 6, .length = 1 }));
    try expect(eql(tokens.items[7], Token{ .type = .SEMICOLON, .start = 7, .length = 1 }));
    try expect(eql(tokens.items[8], Token{ .type = .RIGHT_BRACE, .start = 8, .length = 1 }));
    try expect(eql(tokens.items[9], Token{ .type = .RIGHT_PAREN, .start = 9, .length = 1 }));
    try expect(eql(tokens.items[10], Token{ .type = .EOF, .start = 10, .length = 0 }));
}
