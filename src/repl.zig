const std = @import("std");
const lexer = @import("lexer.zig");
const Lexer = lexer.Lexer;
const SM = lexer.StringManager;
const stdout = std.io.getStdOut();
const stdin = std.io.getStdIn();
const TokenKind = @import("token.zig").TokenKind;
const Allocator = std.mem.Allocator;

const PROMPT = ">> ";

pub fn start(a: Allocator) !void {
    var sm = try SM.init(a);

    defer sm.deinit();

    while (true) {
        try stdout.writer().print("{s}", .{PROMPT});

        var buffer: [1024]u8 = undefined;

        const input = try stdin.reader().readUntilDelimiter(&buffer, '\n');

        if (std.mem.eql(u8, std.mem.trim(u8, input, &std.ascii.whitespace), "exit()")) {
            break;
        }

        var l = Lexer.init(input, true, null, &sm);

        var tok = try l.nextToken();

        while (tok.ttype != TokenKind.EOF) {
            try stdout.writer().print("{any}\n", .{tok});
            tok = try l.nextToken();
        }
    }
}
