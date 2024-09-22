const std = @import("std");
const scan = @import("scan.zig");
const parser = @import("parse.zig");
const eval = @import("eval.zig");
const statements = @import("statements.zig");

pub fn main() !void {
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: ./your_program.sh tokenize <filename>\n", .{});
        std.process.exit(1);
    }

    const command = args[1];
    const filename = args[2];

    const tokenize = std.mem.eql(u8, command, "tokenize");
    const parse = std.mem.eql(u8, command, "parse");
    const evaluate = std.mem.eql(u8, command, "evaluate");
    const run = std.mem.eql(u8, command, "run");

    if (!(tokenize or parse or evaluate or run)) {
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

    if (tokenize) {
        try scan.format(scanner.tokens.items, file_contents, std.io.getStdOut().writer());
    }

    if (scanner.errors > 0) {
        std.process.exit(std.process.exit(65)); // EX_DATAERR (65) from sysexits.h
    }

    if (tokenize) return;

    if (parse) {
        const parseRes = parser.parse(allocator, scanner.tokens.items, std.io.getStdErr().writer()) catch {
            std.process.exit(std.process.exit(65));
        };
        defer parseRes.expr.destroy(allocator);

        try std.io.getStdOut().writer().print("{}", .{parseRes.expr});
        return;
    }

    if (evaluate) {
        const parseRes = parser.parse(allocator, scanner.tokens.items, std.io.getStdErr().writer()) catch {
            std.process.exit(std.process.exit(65));
        };
        defer parseRes.expr.destroy(allocator);

        const res = eval.eval(allocator, parseRes.expr) catch {
            std.process.exit(70);
        };

        if (res) |val| {
            defer val.deinit(allocator);
            try std.io.getStdOut().writer().print("{}\n", .{val});
        } else {
            try std.io.getStdOut().writer().writeAll("nil\n");
        }
    }

    if (run) {
        var tokens: []const scan.Token = scanner.tokens.items[0..];

        const stmts = statements.parse(allocator, &tokens, std.io.getStdErr().writer()) catch {
            std.process.exit(std.process.exit(65));
        };
        defer {
            for (stmts) |stmt| {
                switch (stmt) {
                    .expr, .print => |e| e.destroy(allocator),
                }
            }
            allocator.free(stmts);
        }

        for (stmts) |stmt| {
            switch (stmt) {
                .print => |e| {
                    const res = eval.eval(allocator, e) catch {
                        std.process.exit(70);
                    };

                    if (res) |val| {
                        defer val.deinit(allocator);
                        try std.io.getStdOut().writer().print("{}\n", .{val});
                    } else {
                        try std.io.getStdOut().writer().writeAll("nil\n");
                    }
                },
                else => {},
            }
        }
    }
}
