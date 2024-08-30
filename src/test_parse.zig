const std = @import("std");
const expect = std.testing.expect;
const parse = @import("parse.zig");
const scan = @import("scan.zig");

test "parse booleans & nil" {
    const allocator = std.testing.allocator;
    const content = "true";

    var errOut = std.ArrayList(u8).init(allocator);
    defer errOut.deinit();

    const scanner = try scan.Scanner.init(allocator, content, errOut.writer());
    defer scanner.deinit();

    try expect(errOut.items.len == 0); // no error output
    try expect(scanner.errors == 0);
    try expect(scanner.tokens.items.len == 2);
    try expect(scan.eql(scanner.tokens.items[0], scan.Token.init(.TRUE, 0, 4, null)));
    try expect(scan.eql(scanner.tokens.items[1], scan.Token.init(.EOF, 4, 0, null)));

    const expr = try parse.parse(allocator, scanner.tokens.items);
    defer expr.destroy(allocator);
    try expect(expr.literal.type == .true);
}
