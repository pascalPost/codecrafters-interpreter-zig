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