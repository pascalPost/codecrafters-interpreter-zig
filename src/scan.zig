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

const LiteralStorage = union {
    // a small string optimization could be implemented here
    // another possibility would be to use a string oobject pool that only needs to be deallocated once
    string: []const u8,
    number: f64,
};

pub const Token = struct {
    type: TokenType,
    start: usize,
    length: usize,
    literal: ?LiteralStorage = null,

    pub fn init(tokenType: TokenType, start: usize, length: usize) Token {
        return Token{ .type = tokenType, .start = start, .length = length };
    }
};

pub fn eql(a: Token, b: Token) bool {
    return a.type == b.type and a.start == b.start and a.length == b.length;
}

fn lexeme(token: Token, content: []const u8) []const u8 {
    if (token.length == 0) {
        return "";
    }

    return content[token.start .. token.start + token.length + 1];
}

fn tokenize(allocator: std.mem.Allocator, content: []const u8, errorWriter: anytype) !Scanner {
    var tokens = std.ArrayList(Token).init(allocator);

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
            '"' => blk: {
                const strStart = i;
                // string literal
                i += 1;
                while (i < len - 1 and content[i] != '"') {
                    i += 1;
                    if (content[i] == '\n') {
                        line += 1;
                    }
                }

                if (content[i] != '"') {
                    // unterminated string
                    try errorWriter.print("[line {d}] Error: Unterminated string.\n", .{line});
                    errors += 1;
                    break :blk null;
                }

                var token = Token.init(.STRING, strStart, i - strStart);

                // allocate string content
                const store = try allocator.dupe(u8, content[strStart + 1 .. i]);

                token.literal = .{ .string = store };

                break :blk token;
            },
            else => blk: {
                const unexpected_char = content[i .. i + 1];
                try errorWriter.print("[line {d}] Error: Unexpected character: {s}\n", .{ line, unexpected_char });
                errors += 1;
                break :blk null;
            },
        };

        if (token) |t| try tokens.append(t);

        i += 1;
    }

    try tokens.append(Token{ .type = TokenType.EOF, .start = i, .length = 0 });

    return .{ .tokens = tokens, .errors = errors, .allocator = allocator };
}

pub fn format(tokens: []Token, content: []const u8, writer: anytype) !void {
    for (tokens) |token| {
        const tokenType = std.enums.tagName(TokenType, token.type) orelse unreachable;
        const lexemeStr = lexeme(token, content);
        try writer.print("{s} {s} ", .{ tokenType, lexemeStr });

        switch (token.type) {
            .STRING => try writer.print("{s}\n", .{token.literal.?.string}),
            else => try writer.print("{s}\n", .{"null"}),
        }
    }
}

pub const Scanner = struct {
    tokens: std.ArrayList(Token),
    errors: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, content: []const u8, errorWriter: anytype) !Scanner {
        return tokenize(allocator, content, errorWriter);
    }

    pub fn deinit(self: *const Scanner) void {
        for (self.tokens.items) |*item| {
            if (item.type == .STRING) {
                self.allocator.free(item.literal.?.string);
            }
        }
        self.tokens.deinit();
    }
};
