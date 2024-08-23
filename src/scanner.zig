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

    pub fn init(tokenType: TokenType, start: usize, length: usize) Token {
        return Token{ .type = tokenType, .start = start, .length = length };
    }
};

pub fn eql(a: Token, b: Token) bool {
    return a.type == b.type and a.start == b.start and a.length == b.length;
}

fn lexeme(token: Token, content: []const u8) []const u8 {
    return content[token.start .. token.start + token.length];
}

fn reportError(errorWriter: anytype, content: []const u8, pos: usize, length: usize, line: usize) !void {
    const str = content[pos .. pos + length];
    try errorWriter.print("[line {d}] Error: Unexpected character: {s}\n", .{ line, str });
}

pub const ScannerResult = struct { tokens: std.ArrayList(Token), errors: usize };

pub fn tokenize(allocator: std.mem.Allocator, content: []const u8, errorWriter: anytype) !ScannerResult {
    var tokens = std.ArrayList(Token).init(allocator);

    // var start: usize = 0;
    // var current: usize = 0;
    var line: usize = 1;

    var errors: usize = 0;
    var i: usize = 0;
    const len = content.len;
    while (i < len) {
        const token: ?Token = switch (content[i]) {
            ' ', '\t', '\r' => null,
            '\n' => blk: {
                line += 1;
                break :blk null;
            },
            '(' => Token.init(.LEFT_PAREN, i, 1),
            ')' => Token.init(.RIGHT_PAREN, i, 1),
            '{' => Token.init(.LEFT_BRACE, i, 1),
            '}' => Token.init(.RIGHT_BRACE, i, 1),
            ',' => Token.init(.COMMA, i, 1),
            '.' => Token.init(.DOT, i, 1),
            '-' => Token.init(.MINUS, i, 1),
            '+' => Token.init(.PLUS, i, 1),
            ';' => Token.init(.SEMICOLON, i, 1),
            '*' => Token.init(.STAR, i, 1),
            '!' => blk: {
                if (i + 1 < len and content[i + 1] == '=') {
                    const token = Token.init(.BANG_EQUAL, i, 2);
                    i += 1;
                    break :blk token;
                }
                break :blk Token.init(.BANG, i, 1);
            },
            '=' => blk: {
                if (i + 1 < len and content[i + 1] == '=') {
                    const token = Token.init(.EQUAL_EQUAL, i, 2);
                    i += 1;
                    break :blk token;
                }
                break :blk Token.init(.EQUAL, i, 1);
            },
            else => blk: {
                try reportError(errorWriter, content, i, 1, line);
                errors += 1;
                break :blk null;
            },
            '<' => blk: {
                if (i + 1 < len and content[i + 1] == '=') {
                    const token = Token.init(.LESS_EQUAL, i, 2);
                    i += 1;
                    break :blk token;
                }
                break :blk Token.init(.LESS, i, 1);
            },
            '>' => blk: {
                if (i + 1 < len and content[i + 1] == '=') {
                    const token = Token.init(.GREATER_EQUAL, i, 2);
                    i += 1;
                    break :blk token;
                }
                break :blk Token.init(.GREATER, i, 1);
            },
            '/' => blk: {
                if (i + 1 < len and content[i + 1] == '/') {
                    // comment, discard until newline
                    i += 1;
                    while (i < len - 1 and content[i] != '\n') {
                        i += 1;
                    }
                    line += 1;
                    break :blk null;
                }
                break :blk Token.init(.SLASH, i, 1);
            },
        };

        if (token) |t| try tokens.append(t);

        i += 1;
    }

    try tokens.append(Token{ .type = TokenType.EOF, .start = i, .length = 0 });

    return .{ .tokens = tokens, .errors = errors };
}

pub fn format(tokens: []Token, content: []const u8, writer: anytype) !void {
    for (tokens) |token| {
        const tokenType = std.enums.tagName(TokenType, token.type) orelse unreachable;
        const lexemeStr = lexeme(token, content);
        try writer.print("{s} {s} null\n", .{ tokenType, lexemeStr });
    }
}
