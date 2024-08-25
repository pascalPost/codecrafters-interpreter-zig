const std = @import("std");
const scanner = @import("scanner.zig");
const expect = std.testing.expect;
const eql = scanner.eql;
const Token = scanner.Token;
const tokenize = scanner.tokenize;

test "empty file" {
    const content = "";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const res = try tokenize(std.testing.allocator, content[0..], errOut.writer());
    const tokens = res.tokens;
    const errors = res.errors;
    defer tokens.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(errors == 0);
    try expect(tokens.items.len == 1);
    try expect(eql(tokens.items[0], Token.init(.EOF, 0, 0)));
}

test "parentheses" {
    const content = "(()";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const res = try tokenize(std.testing.allocator, content[0..], errOut.writer());
    const tokens = res.tokens;
    const errors = res.errors;
    defer tokens.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(errors == 0);
    try expect(tokens.items.len == 4);
    try expect(eql(tokens.items[0], Token.init(.LEFT_PAREN, 0, 1)));
    try expect(eql(tokens.items[1], Token.init(.LEFT_PAREN, 1, 1)));
    try expect(eql(tokens.items[2], Token.init(.RIGHT_PAREN, 2, 1)));
    try expect(eql(tokens.items[3], Token.init(.EOF, 3, 0)));
}

test "braces" {
    const content = "{{}}";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const res = try tokenize(std.testing.allocator, content[0..], errOut.writer());
    const tokens = res.tokens;
    const errors = res.errors;
    defer tokens.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(errors == 0);
    try expect(tokens.items.len == 5);
    try expect(eql(tokens.items[0], Token.init(.LEFT_BRACE, 0, 1)));
    try expect(eql(tokens.items[1], Token.init(.LEFT_BRACE, 1, 1)));
    try expect(eql(tokens.items[2], Token.init(.RIGHT_BRACE, 2, 1)));
    try expect(eql(tokens.items[3], Token.init(.RIGHT_BRACE, 3, 1)));
    try expect(eql(tokens.items[4], Token.init(.EOF, 4, 0)));
}

test "single-character tokens" {
    const content = "({*.,+-;})";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const res = try tokenize(std.testing.allocator, content[0..], errOut.writer());
    const tokens = res.tokens;
    const errors = res.errors;
    defer tokens.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(errors == 0);
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

test "lexical errors" {
    const content = ",.$(#";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const res = try tokenize(std.testing.allocator, content[0..], errOut.writer());
    const tokens = res.tokens;
    const errors = res.errors;
    defer tokens.deinit();

    try expect(tokens.items.len == 4);
    try expect(eql(tokens.items[0], Token.init(.COMMA, 0, 1)));
    try expect(eql(tokens.items[1], Token.init(.DOT, 1, 1)));
    try expect(eql(tokens.items[2], Token.init(.LEFT_PAREN, 3, 1)));
    try expect(eql(tokens.items[3], Token.init(.EOF, 5, 0)));

    try expect(errors == 2);
    const errorMsg = "[line 1] Error: Unexpected character: $\n[line 1] Error: Unexpected character: #\n";
    try expect(std.mem.eql(u8, errorMsg, errOut.items[0..]));
}

test "assignment & equality operators" {
    const content = "={===}";

    const res = try tokenize(std.testing.allocator, content[0..], std.io.getStdErr().writer());
    const tokens = res.tokens;
    defer tokens.deinit();
    const errors = res.errors;

    try expect(errors == 0);
    try expect(tokens.items.len == 6);
    try expect(eql(tokens.items[0], Token.init(.EQUAL, 0, 1)));
    try expect(eql(tokens.items[1], Token.init(.LEFT_BRACE, 1, 1)));
    try expect(eql(tokens.items[2], Token.init(.EQUAL_EQUAL, 2, 2)));
    try expect(eql(tokens.items[3], Token.init(.EQUAL, 4, 1)));
    try expect(eql(tokens.items[4], Token.init(.RIGHT_BRACE, 5, 1)));
    try expect(eql(tokens.items[5], Token.init(.EOF, 6, 0)));
}

test "negation & inequality operators" {
    const content = "!!===";

    const res = try tokenize(std.testing.allocator, content[0..], std.io.getStdErr().writer());
    const tokens = res.tokens;
    defer tokens.deinit();
    const errors = res.errors;

    try expect(errors == 0);
    try expect(tokens.items.len == 4);
    try expect(eql(tokens.items[0], Token.init(.BANG, 0, 1)));
    try expect(eql(tokens.items[1], Token.init(.BANG_EQUAL, 1, 2)));
    try expect(eql(tokens.items[2], Token.init(.EQUAL_EQUAL, 3, 2)));
    try expect(eql(tokens.items[3], Token.init(.EOF, 5, 0)));
}

test "relational operators" {
    const content = "<<=>>=";

    const res = try tokenize(std.testing.allocator, content[0..], std.io.getStdErr().writer());
    const tokens = res.tokens;
    defer tokens.deinit();
    const errors = res.errors;

    try expect(errors == 0);
    try expect(tokens.items.len == 5);
    try expect(eql(tokens.items[0], Token.init(.LESS, 0, 1)));
    try expect(eql(tokens.items[1], Token.init(.LESS_EQUAL, 1, 2)));
    try expect(eql(tokens.items[2], Token.init(.GREATER, 3, 1)));
    try expect(eql(tokens.items[3], Token.init(.GREATER_EQUAL, 4, 2)));
    try expect(eql(tokens.items[4], Token.init(.EOF, 6, 0)));
}

test "comment" {
    const content = "// Comment";

    const res = try tokenize(std.testing.allocator, content[0..], std.io.getStdErr().writer());
    const tokens = res.tokens;
    defer tokens.deinit();
    const errors = res.errors;

    try expect(errors == 0);
    try expect(tokens.items.len == 1);
    try expect(eql(tokens.items[0], Token.init(.EOF, 10, 0)));
}

test "division operator & comments" {
    const content = "/// comment\n/";

    const res = try tokenize(std.testing.allocator, content[0..], std.io.getStdErr().writer());
    const tokens = res.tokens;
    defer tokens.deinit();
    const errors = res.errors;

    try expect(errors == 0);
    try expect(tokens.items.len == 2);
    try expect(eql(tokens.items[0], Token.init(.SLASH, 12, 1)));
    try expect(eql(tokens.items[1], Token.init(.EOF, 13, 0)));
}

test "whitespace" {
    const content = "( \t\n)";

    const res = try tokenize(std.testing.allocator, content[0..], std.io.getStdErr().writer());
    const tokens = res.tokens;
    defer tokens.deinit();
    const errors = res.errors;

    try expect(errors == 0);
    try expect(tokens.items.len == 3);
    try expect(eql(tokens.items[0], Token.init(.LEFT_PAREN, 0, 1)));
    try expect(eql(tokens.items[1], Token.init(.RIGHT_PAREN, 4, 1)));
    try expect(eql(tokens.items[2], Token.init(.EOF, 5, 0)));
}

test "multi-line errors" {
    const content = "# (\n)\t@";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const res = try tokenize(std.testing.allocator, content[0..], errOut.writer());
    const tokens = res.tokens;
    defer tokens.deinit();
    const errors = res.errors;

    try expect(tokens.items.len == 3);
    try expect(eql(tokens.items[0], Token.init(.LEFT_PAREN, 2, 1)));
    try expect(eql(tokens.items[1], Token.init(.RIGHT_PAREN, 4, 1)));
    try expect(eql(tokens.items[2], Token.init(.EOF, 7, 0)));

    try expect(errors == 2);
    const errorMsg = "[line 1] Error: Unexpected character: #\n[line 2] Error: Unexpected character: @\n";
    try expect(std.mem.eql(u8, errorMsg, errOut.items[0..]));
}

test "string literals" {
    const allocator = std.testing.allocator;
    const content = "\"foo baz\"";

    const res = try tokenize(allocator, content[0..], std.io.getStdErr().writer());
    const tokens = res.tokens;

    // add this to a deinit own class
    defer {
        for (tokens.items) |*item| {
            if (item.type == .STRING) {
                allocator.free(item.literal.?.string);
            }
        }
        tokens.deinit();
    }

    const errors = res.errors;

    try expect(errors == 0);
    try expect(tokens.items.len == 2);

    try expect(eql(tokens.items[0], Token.init(.STRING, 0, 8)));
    try expect(std.mem.eql(u8, tokens.items[0].literal.?.string, "foo baz"));

    try expect(eql(tokens.items[1], Token.init(.EOF, 9, 0)));
}

test "unterminated string" {
    const content = "\"bar";

    var errOut = std.ArrayList(u8).init(std.testing.allocator);
    defer errOut.deinit();

    const res = try tokenize(std.testing.allocator, content[0..], errOut.writer());
    const tokens = res.tokens;

    defer tokens.deinit();

    const errors = res.errors;

    try expect(tokens.items.len == 1);
    try expect(eql(tokens.items[0], Token.init(.EOF, 4, 0)));

    try expect(errors == 1);
    const errorMsg = "[line 1] Error: Unterminated string.\n";
    try expect(std.mem.eql(u8, errorMsg, errOut.items[0..]));
}
