const std = @import("std");
const scan = @import("scanner.zig");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: ./your_program.sh tokenize <filename>\n", .{});
        std.process.exit(1);
    }

    const command = args[1];
    const filename = args[2];

    if (!std.mem.eql(u8, command, "tokenize")) {
        std.debug.print("Unknown command: {s}\n", .{command});
        std.process.exit(1);
    }

    const file_contents = try std.fs.cwd().readFileAlloc(std.heap.page_allocator, filename, std.math.maxInt(usize));
    defer std.heap.page_allocator.free(file_contents);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("leak detected in allocator");
    }

    const scanner = try scan.Scanner.init(allocator, file_contents, std.io.getStdErr().writer());
    defer scanner.deinit();

    try scan.format(scanner.tokens.items, file_contents, std.io.getStdOut().writer());

    if (scanner.errors > 0) {
        std.process.exit(std.process.exit(65)); // EX_DATAERR (65) from sysexits.h
    }
}
