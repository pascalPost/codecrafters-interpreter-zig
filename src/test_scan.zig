const std = @import("std");
const expect = std.testing.expect;
const scan = @import("scan.zig");
const eql = scan.eql;
const Token = scan.Token;

test "empty file" {
    const content = "";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 1);
    try expect(eql(scanner.tokens.items[0], Token.init(.EOF, 0, 0, null)));
}

test "parentheses" {
    const content = "(()";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 4);
    try expect(eql(scanner.tokens.items[0], Token.init(.LEFT_PAREN, 0, 1, null)));
    try expect(eql(scanner.tokens.items[1], Token.init(.LEFT_PAREN, 1, 1, null)));
    try expect(eql(scanner.tokens.items[2], Token.init(.RIGHT_PAREN, 2, 1, null)));
    try expect(eql(scanner.tokens.items[3], Token.init(.EOF, 3, 0, null)));
}

test "braces" {
    const content = "{{}}";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 5);
    try expect(eql(scanner.tokens.items[0], Token.init(.LEFT_BRACE, 0, 1, null)));
    try expect(eql(scanner.tokens.items[1], Token.init(.LEFT_BRACE, 1, 1, null)));
    try expect(eql(scanner.tokens.items[2], Token.init(.RIGHT_BRACE, 2, 1, null)));
    try expect(eql(scanner.tokens.items[3], Token.init(.RIGHT_BRACE, 3, 1, null)));
    try expect(eql(scanner.tokens.items[4], Token.init(.EOF, 4, 0, null)));
}

test "single-character tokens" {
    const content = "({*.,+-;})";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 11);
    try expect(eql(scanner.tokens.items[0], Token.init(.LEFT_PAREN, 0, 1, null)));
    try expect(eql(scanner.tokens.items[1], Token.init(.LEFT_BRACE, 1, 1, null)));
    try expect(eql(scanner.tokens.items[2], Token.init(.STAR, 2, 1, null)));
    try expect(eql(scanner.tokens.items[3], Token.init(.DOT, 3, 1, null)));
    try expect(eql(scanner.tokens.items[4], Token.init(.COMMA, 4, 1, null)));
    try expect(eql(scanner.tokens.items[5], Token.init(.PLUS, 5, 1, null)));
    try expect(eql(scanner.tokens.items[6], Token.init(.MINUS, 6, 1, null)));
    try expect(eql(scanner.tokens.items[7], Token.init(.SEMICOLON, 7, 1, null)));
    try expect(eql(scanner.tokens.items[8], Token.init(.RIGHT_BRACE, 8, 1, null)));
    try expect(eql(scanner.tokens.items[9], Token.init(.RIGHT_PAREN, 9, 1, null)));
    try expect(eql(scanner.tokens.items[10], Token.init(.EOF, 10, 0, null)));
}

test "lexical errors" {
    const content = ",.$(#";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(scanner.tokens.items.len == 4);
    try expect(eql(scanner.tokens.items[0], Token.init(.COMMA, 0, 1, null)));
    try expect(eql(scanner.tokens.items[1], Token.init(.DOT, 1, 1, null)));
    try expect(eql(scanner.tokens.items[2], Token.init(.LEFT_PAREN, 3, 1, null)));
    try expect(eql(scanner.tokens.items[3], Token.init(.EOF, 5, 0, null)));

    try expect(scanner.errors == 2);
    const errorMsg = "[line 1] Error: Unexpected character: $\n[line 1] Error: Unexpected character: #\n";
    try expect(std.mem.eql(u8, errorMsg, errOut.items[0..]));
}

test "assignment & equality operators" {
    const content = "={===}";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 6);
    try expect(eql(scanner.tokens.items[0], Token.init(.EQUAL, 0, 1, null)));
    try expect(eql(scanner.tokens.items[1], Token.init(.LEFT_BRACE, 1, 1, null)));
    try expect(eql(scanner.tokens.items[2], Token.init(.EQUAL_EQUAL, 2, 2, null)));
    try expect(eql(scanner.tokens.items[3], Token.init(.EQUAL, 4, 1, null)));
    try expect(eql(scanner.tokens.items[4], Token.init(.RIGHT_BRACE, 5, 1, null)));
    try expect(eql(scanner.tokens.items[5], Token.init(.EOF, 6, 0, null)));
}

test "negation & inequality operators" {
    const content = "!!===";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 4);
    try expect(eql(scanner.tokens.items[0], Token.init(.BANG, 0, 1, null)));
    try expect(eql(scanner.tokens.items[1], Token.init(.BANG_EQUAL, 1, 2, null)));
    try expect(eql(scanner.tokens.items[2], Token.init(.EQUAL_EQUAL, 3, 2, null)));
    try expect(eql(scanner.tokens.items[3], Token.init(.EOF, 5, 0, null)));
}

test "relational operators" {
    const content = "<<=>>=";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 5);
    try expect(eql(scanner.tokens.items[0], Token.init(.LESS, 0, 1, null)));
    try expect(eql(scanner.tokens.items[1], Token.init(.LESS_EQUAL, 1, 2, null)));
    try expect(eql(scanner.tokens.items[2], Token.init(.GREATER, 3, 1, null)));
    try expect(eql(scanner.tokens.items[3], Token.init(.GREATER_EQUAL, 4, 2, null)));
    try expect(eql(scanner.tokens.items[4], Token.init(.EOF, 6, 0, null)));
}

test "comment" {
    const content = "// Comment";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 1);
    try expect(eql(scanner.tokens.items[0], Token.init(.EOF, 10, 0, null)));
}

test "division operator & comments" {
    const content = "/// comment\n/";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 2);
    try expect(eql(scanner.tokens.items[0], Token.init(.SLASH, 12, 1, null)));
    try expect(eql(scanner.tokens.items[1], Token.init(.EOF, 13, 0, null)));
}

test "whitespace" {
    const content = "( \t\n)";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 3);
    try expect(eql(scanner.tokens.items[0], Token.init(.LEFT_PAREN, 0, 1, null)));
    try expect(eql(scanner.tokens.items[1], Token.init(.RIGHT_PAREN, 4, 1, null)));
    try expect(eql(scanner.tokens.items[2], Token.init(.EOF, 5, 0, null)));
}

test "multi-line errors" {
    const content = "# (\n)\t@";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(scanner.tokens.items.len == 3);
    try expect(eql(scanner.tokens.items[0], Token.init(.LEFT_PAREN, 2, 1, null)));
    try expect(eql(scanner.tokens.items[1], Token.init(.RIGHT_PAREN, 4, 1, null)));
    try expect(eql(scanner.tokens.items[2], Token.init(.EOF, 7, 0, null)));

    try expect(scanner.errors == 2);
    const errorMsg = "[line 1] Error: Unexpected character: #\n[line 2] Error: Unexpected character: @\n";
    try expect(std.mem.eql(u8, errorMsg, errOut.items[0..]));
}

test "string literal" {
    const content = "\"foo baz\"";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 2);
    try expect(eql(scanner.tokens.items[0], Token.init(.STRING, 0, 9, .{ .string = "foo baz" })));
    try expect(eql(scanner.tokens.items[1], Token.init(.EOF, 9, 0, null)));
}

test "string literal (empty string)" {
    const content = "\"\"";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 2);
    try expect(eql(scanner.tokens.items[0], Token.init(.STRING, 0, 2, .{ .string = "" })));
    try expect(eql(scanner.tokens.items[1], Token.init(.EOF, 2, 0, null)));
}

test "unterminated string" {
    const content = "\"bar";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(scanner.tokens.items.len == 1);
    try expect(eql(scanner.tokens.items[0], Token.init(.EOF, 4, 0, null)));

    try expect(scanner.errors == 1);
    const errorMsg = "[line 1] Error: Unterminated string.\n";
    try expect(std.mem.eql(u8, errorMsg, errOut.items[0..]));
}

test "number literal (single digit)" {
    const content = "4";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 2);
    try expect(eql(scanner.tokens.items[0], Token.init(.NUMBER, 0, 1, .{ .number = 4 })));
    try expect(eql(scanner.tokens.items[1], Token.init(.EOF, 1, 0, null)));
}

test "number literal (two digits)" {
    const content = "42";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 2);
    try expect(eql(scanner.tokens.items[0], Token.init(.NUMBER, 0, 2, .{ .number = 42 })));
    try expect(eql(scanner.tokens.items[1], Token.init(.EOF, 2, 0, null)));
}

test "number literal (float)" {
    const content = "42.0";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 2);
    try expect(eql(scanner.tokens.items[0], Token.init(.NUMBER, 0, 4, .{ .number = 42.0 })));
    try expect(eql(scanner.tokens.items[1], Token.init(.EOF, 4, 0, null)));
}

test "number literal (float with trailing dot)" {
    const content = "42.";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 2);
    try expect(eql(scanner.tokens.items[0], Token.init(.NUMBER, 0, 3, .{ .number = 42.0 })));
    try expect(eql(scanner.tokens.items[1], Token.init(.EOF, 3, 0, null)));
}

test "number literals" {
    const content = "42 43.0 44.";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 4);
    try expect(eql(scanner.tokens.items[0], Token.init(.NUMBER, 0, 2, .{ .number = 42 })));
    try expect(eql(scanner.tokens.items[1], Token.init(.NUMBER, 3, 4, .{ .number = 43.0 })));
    try expect(eql(scanner.tokens.items[2], Token.init(.NUMBER, 8, 3, .{ .number = 44.0 })));
    try expect(eql(scanner.tokens.items[3], Token.init(.EOF, 11, 0, null)));
}

test "identifiers" {
    const content = "foo bar _hello";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 4);
    try expect(eql(scanner.tokens.items[0], Token.init(.IDENTIFIER, 0, 3, null)));
    try expect(eql(scanner.tokens.items[1], Token.init(.IDENTIFIER, 4, 3, null)));
    try expect(eql(scanner.tokens.items[2], Token.init(.IDENTIFIER, 8, 6, null)));
    try expect(eql(scanner.tokens.items[3], Token.init(.EOF, 14, 0, null)));
}

test "reserved words" {
    const content = "and";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 2);
    try expect(eql(scanner.tokens.items[0], Token.init(.AND, 0, 3, null)));
    try expect(eql(scanner.tokens.items[1], Token.init(.EOF, 3, 0, null)));
}
