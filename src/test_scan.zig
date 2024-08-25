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
    try expect(eql(scanner.tokens.items[0], Token.init(.EOF, 0, 0)));
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
    try expect(eql(scanner.tokens.items[0], Token.init(.LEFT_PAREN, 0, 1)));
    try expect(eql(scanner.tokens.items[1], Token.init(.LEFT_PAREN, 1, 1)));
    try expect(eql(scanner.tokens.items[2], Token.init(.RIGHT_PAREN, 2, 1)));
    try expect(eql(scanner.tokens.items[3], Token.init(.EOF, 3, 0)));
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
    try expect(eql(scanner.tokens.items[0], Token.init(.LEFT_BRACE, 0, 1)));
    try expect(eql(scanner.tokens.items[1], Token.init(.LEFT_BRACE, 1, 1)));
    try expect(eql(scanner.tokens.items[2], Token.init(.RIGHT_BRACE, 2, 1)));
    try expect(eql(scanner.tokens.items[3], Token.init(.RIGHT_BRACE, 3, 1)));
    try expect(eql(scanner.tokens.items[4], Token.init(.EOF, 4, 0)));
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
    try expect(eql(scanner.tokens.items[0], Token.init(.LEFT_PAREN, 0, 1)));
    try expect(eql(scanner.tokens.items[1], Token.init(.LEFT_BRACE, 1, 1)));
    try expect(eql(scanner.tokens.items[2], Token.init(.STAR, 2, 1)));
    try expect(eql(scanner.tokens.items[3], Token.init(.DOT, 3, 1)));
    try expect(eql(scanner.tokens.items[4], Token.init(.COMMA, 4, 1)));
    try expect(eql(scanner.tokens.items[5], Token.init(.PLUS, 5, 1)));
    try expect(eql(scanner.tokens.items[6], Token.init(.MINUS, 6, 1)));
    try expect(eql(scanner.tokens.items[7], Token.init(.SEMICOLON, 7, 1)));
    try expect(eql(scanner.tokens.items[8], Token.init(.RIGHT_BRACE, 8, 1)));
    try expect(eql(scanner.tokens.items[9], Token.init(.RIGHT_PAREN, 9, 1)));
    try expect(eql(scanner.tokens.items[10], Token.init(.EOF, 10, 0)));
}

test "lexical errors" {
    const content = ",.$(#";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(scanner.tokens.items.len == 4);
    try expect(eql(scanner.tokens.items[0], Token.init(.COMMA, 0, 1)));
    try expect(eql(scanner.tokens.items[1], Token.init(.DOT, 1, 1)));
    try expect(eql(scanner.tokens.items[2], Token.init(.LEFT_PAREN, 3, 1)));
    try expect(eql(scanner.tokens.items[3], Token.init(.EOF, 5, 0)));

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
    try expect(eql(scanner.tokens.items[0], Token.init(.EQUAL, 0, 1)));
    try expect(eql(scanner.tokens.items[1], Token.init(.LEFT_BRACE, 1, 1)));
    try expect(eql(scanner.tokens.items[2], Token.init(.EQUAL_EQUAL, 2, 2)));
    try expect(eql(scanner.tokens.items[3], Token.init(.EQUAL, 4, 1)));
    try expect(eql(scanner.tokens.items[4], Token.init(.RIGHT_BRACE, 5, 1)));
    try expect(eql(scanner.tokens.items[5], Token.init(.EOF, 6, 0)));
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
    try expect(eql(scanner.tokens.items[0], Token.init(.BANG, 0, 1)));
    try expect(eql(scanner.tokens.items[1], Token.init(.BANG_EQUAL, 1, 2)));
    try expect(eql(scanner.tokens.items[2], Token.init(.EQUAL_EQUAL, 3, 2)));
    try expect(eql(scanner.tokens.items[3], Token.init(.EOF, 5, 0)));
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
    try expect(eql(scanner.tokens.items[0], Token.init(.LESS, 0, 1)));
    try expect(eql(scanner.tokens.items[1], Token.init(.LESS_EQUAL, 1, 2)));
    try expect(eql(scanner.tokens.items[2], Token.init(.GREATER, 3, 1)));
    try expect(eql(scanner.tokens.items[3], Token.init(.GREATER_EQUAL, 4, 2)));
    try expect(eql(scanner.tokens.items[4], Token.init(.EOF, 6, 0)));
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
    try expect(eql(scanner.tokens.items[0], Token.init(.EOF, 10, 0)));
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
    try expect(eql(scanner.tokens.items[0], Token.init(.SLASH, 12, 1)));
    try expect(eql(scanner.tokens.items[1], Token.init(.EOF, 13, 0)));
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
    try expect(eql(scanner.tokens.items[0], Token.init(.LEFT_PAREN, 0, 1)));
    try expect(eql(scanner.tokens.items[1], Token.init(.RIGHT_PAREN, 4, 1)));
    try expect(eql(scanner.tokens.items[2], Token.init(.EOF, 5, 0)));
}

test "multi-line errors" {
    const content = "# (\n)\t@";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(scanner.tokens.items.len == 3);
    try expect(eql(scanner.tokens.items[0], Token.init(.LEFT_PAREN, 2, 1)));
    try expect(eql(scanner.tokens.items[1], Token.init(.RIGHT_PAREN, 4, 1)));
    try expect(eql(scanner.tokens.items[2], Token.init(.EOF, 7, 0)));

    try expect(scanner.errors == 2);
    const errorMsg = "[line 1] Error: Unexpected character: #\n[line 2] Error: Unexpected character: @\n";
    try expect(std.mem.eql(u8, errorMsg, errOut.items[0..]));
}

test "string literals" {
    const content = "\"foo baz\"";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 2);

    try expect(eql(scanner.tokens.items[0], Token.init(.STRING, 0, 8)));
    try expect(std.mem.eql(u8, scanner.tokens.items[0].literal.?.string, "foo baz"));

    try expect(eql(scanner.tokens.items[1], Token.init(.EOF, 9, 0)));
}

test "unterminated string" {
    const content = "\"bar";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(std.testing.allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(scanner.tokens.items.len == 1);
    try expect(eql(scanner.tokens.items[0], Token.init(.EOF, 4, 0)));

    try expect(scanner.errors == 1);
    const errorMsg = "[line 1] Error: Unterminated string.\n";
    try expect(std.mem.eql(u8, errorMsg, errOut.items[0..]));
}
