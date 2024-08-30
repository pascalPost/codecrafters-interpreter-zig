const std = @import("std");
const assert = std.debug.assert;

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

const keyword_slice = [_]struct { []const u8, TokenType }{
    .{ "and", .AND },
    .{ "class", .CLASS },
    .{ "else", .ELSE },
    .{ "false", .FALSE },
    .{ "for", .FOR },
    .{ "fun", .FUN },
    .{ "if", .IF },
    .{ "nil", .NIL },
    .{ "or", .OR },
    .{ "print", .PRINT },
    .{ "return", .RETURN },
    .{ "super", .SUPER },
    .{ "this", .THIS },
    .{ "true", .TRUE },
    .{ "var", .VAR },
    .{ "while", .WHILE },
};

const keyword_type_map = std.StaticStringMap(TokenType).initComptime(keyword_slice);

// const LiteralTag = enum { string, number };

pub const LiteralStorage = union {
    // a small string optimization could be implemented here
    // another possibility would be to use a string oobject pool that only needs to be deallocated once
    string: []const u8,
    number: f64,

    // pub fn format(self: LiteralStorage, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    //     _ = fmt;
    //     _ = options;
    //
    //     switch (self) {
    //         .string => try writer.print("{s}", .{self.string}),
    //         .number => {
    //             const number: f64 = self.number;
    //             const number_int: i64 = @intFromFloat(number);
    //             const number_recast: f64 = @floatFromInt(number_int);
    //
    //             if (number == number_recast) {
    //                 try writer.print("{d:.1}", .{number});
    //             } else {
    //                 try writer.print("{d}", .{number});
    //             }
    //         },
    //     }
    // }
};

pub const Token = struct {
    type: TokenType,
    start: usize,
    length: usize,
    literal: ?LiteralStorage,

    pub fn init(tokenType: TokenType, start: usize, length: usize, literal: ?LiteralStorage) Token {
        return Token{ .type = tokenType, .start = start, .length = length, .literal = literal };
    }
};

pub fn eql(a: Token, b: Token) bool {
    const type_and_literal: bool = switch (a.type) {
        .STRING => b.type == .STRING and std.mem.eql(u8, a.literal.?.string, b.literal.?.string),
        .NUMBER => b.type == .NUMBER and a.literal.?.number == b.literal.?.number,
        else => a.type == b.type and a.literal == null and b.literal == null,
    };
    return type_and_literal and a.start == b.start and a.length == b.length;
}

fn lexeme(token: Token, content: []const u8) []const u8 {
    return content[token.start .. token.start + token.length];
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
            '(' => Token.init(.LEFT_PAREN, i, 1, null),
            ')' => Token.init(.RIGHT_PAREN, i, 1, null),
            '{' => Token.init(.LEFT_BRACE, i, 1, null),
            '}' => Token.init(.RIGHT_BRACE, i, 1, null),
            ',' => Token.init(.COMMA, i, 1, null),
            '.' => Token.init(.DOT, i, 1, null),
            '-' => Token.init(.MINUS, i, 1, null),
            '+' => Token.init(.PLUS, i, 1, null),
            ';' => Token.init(.SEMICOLON, i, 1, null),
            '*' => Token.init(.STAR, i, 1, null),
            '!' => blk: {
                if (i + 1 < len and content[i + 1] == '=') {
                    const token = Token.init(.BANG_EQUAL, i, 2, null);
                    i += 1;
                    break :blk token;
                }
                break :blk Token.init(.BANG, i, 1, null);
            },
            '=' => blk: {
                if (i + 1 < len and content[i + 1] == '=') {
                    const token = Token.init(.EQUAL_EQUAL, i, 2, null);
                    i += 1;
                    break :blk token;
                }
                break :blk Token.init(.EQUAL, i, 1, null);
            },
            '<' => blk: {
                if (i + 1 < len and content[i + 1] == '=') {
                    const token = Token.init(.LESS_EQUAL, i, 2, null);
                    i += 1;
                    break :blk token;
                }
                break :blk Token.init(.LESS, i, 1, null);
            },
            '>' => blk: {
                if (i + 1 < len and content[i + 1] == '=') {
                    const token = Token.init(.GREATER_EQUAL, i, 2, null);
                    i += 1;
                    break :blk token;
                }
                break :blk Token.init(.GREATER, i, 1, null);
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
                break :blk Token.init(.SLASH, i, 1, null);
            },
            '"' => blk: {
                // string literal
                const strStart = i;
                i += 1;
                while (i < len - 1 and content[i] != '"') {
                    i += 1;
                    assert(i < len);
                    if (content[i] == '\n') {
                        line += 1;
                    }
                }

                assert(i < len);
                if (content[i] != '"') {
                    // unterminated string
                    try errorWriter.print("[line {d}] Error: Unterminated string.\n", .{line});
                    errors += 1;
                    break :blk null;
                }

                const store = try allocator.dupe(u8, content[strStart + 1 .. i]);
                break :blk Token.init(.STRING, strStart, i - strStart + 1, .{ .string = store });
            },
            '0'...'9' => blk: {
                // number literal
                const numStart = i;
                while (i + 1 < len and content[i + 1] >= '0' and content[i + 1] <= '9') i += 1;
                if (i + 1 < len and content[i + 1] == '.') i += 1;

                // this option would disallow trailing dots
                // if (i + 2 < len and content[i + 1] == '.' and content[i + 2] >= 48 and content[i + 2] <= 57) i += 1;

                while (i + 1 < len and content[i + 1] >= '0' and content[i + 1] <= '9') i += 1;

                const numEnd = i + 1;
                const num = try std.fmt.parseFloat(f64, content[numStart..numEnd]);
                break :blk Token.init(.NUMBER, numStart, numEnd - numStart, .{ .number = num });
            },
            'A'...'Z', 'a'...'z', '_' => blk: {
                // keyword or identifier
                const numStart = i;
                while (i + 1 < len) : (i += 1) {
                    const c = content[i + 1];
                    if (!((c >= '0' and c <= '9') or (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z') or c == '_')) {
                        break;
                    }
                }
                const numEnd = i + 1;

                const potential_keyword = content[numStart..numEnd];
                if (keyword_type_map.get(potential_keyword)) |tokenType| {
                    break :blk Token.init(tokenType, numStart, numEnd - numStart, null);
                }

                break :blk Token.init(.IDENTIFIER, numStart, numEnd - numStart, null);
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

    try tokens.append(Token{ .type = TokenType.EOF, .start = i, .length = 0, .literal = null });

    return .{ .tokens = tokens, .errors = errors, .allocator = allocator };
}

pub fn format(tokens: []Token, content: []const u8, writer: anytype) !void {
    for (tokens) |token| {
        const tokenType = std.enums.tagName(TokenType, token.type) orelse unreachable;
        const lexemeStr = lexeme(token, content);
        try writer.print("{s} {s} ", .{ tokenType, lexemeStr });

        switch (token.type) {
            .STRING => try writer.print("{s}\n", .{token.literal.?.string}),
            .NUMBER => {
                const number: f64 = token.literal.?.number;
                const number_int: i64 = @intFromFloat(number);
                const number_recast: f64 = @floatFromInt(number_int);

                if (number == number_recast) {
                    try writer.print("{d:.1}\n", .{number});
                } else {
                    try writer.print("{d}\n", .{number});
                }
            },
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
