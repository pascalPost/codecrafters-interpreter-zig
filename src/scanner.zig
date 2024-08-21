const std = @import("std");

const TokenType = enum {
    // Single-character tokens.
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SEMICOLON,
    SLASH,
    STAR,

    // One or two character tokens.
    BANG,
    BANG_EQUAL,
    EQUAL,
    EQUAL_EQUAL,
    GREATER,
    GREATER_EQUAL,
    LESS,
    LESS_EQUAL,

    // Literals.
    IDENTIFIER,
    STRING,
    NUMBER,

    // Keywords.
    AND,
    CLASS,
    ELSE,
    FALSE,
    FUN,
    FOR,
    IF,
    NIL,
    OR,
    PRINT,
    RETURN,
    SUPER,
    THIS,
    TRUE,
    VAR,
    WHILE,

    EOF,
};

pub const Token = struct {
    type: TokenType,
    start: usize,
    length: usize,

    // literal: anytype,
};

pub fn eql(a: Token, b: Token) bool {
    return a.type == b.type and a.start == b.start and a.length == b.length;
}

fn lexeme(token: Token, content: []const u8) []const u8 {
    return content[token.start .. token.start + token.length];
}

pub fn tokenize(allocator: std.mem.Allocator, content: []const u8) !std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(allocator);

    // var start: usize = 0;
    // var current: usize = 0;

    var i: usize = 0;
    const len = content.len;
    while (i < len) {
        const token: ?Token = switch (content[i]) {
            '(' => Token{ .type = .LEFT_PAREN, .start = i, .length = 1 },
            ')' => Token{ .type = .RIGHT_PAREN, .start = i, .length = 1 },
            else => null,
        };

        if (token) |t| try tokens.append(t);

        i += 1;
    }

    try tokens.append(Token{ .type = TokenType.EOF, .start = i, .length = 0 });

    return tokens;
}

pub fn format(tokens: []Token, content: []const u8,writer: anytype) !void {
    for (tokens) |token| {
        const tokenType = std.enums.tagName(TokenType, token.type) orelse unreachable;
        const lexemeStr = lexeme(token, content);
        try writer.print("{s} {s} null\n", .{ tokenType , lexemeStr });
    }
}
