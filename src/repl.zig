const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const stdout = std.io.getStdOut();
const stdin = std.io.getStdIn();
const KW = @import("token.zig").KeyWords;
const TokenKind = @import("token.zig").TokenKind;

const PROMPT = ">>";

pub fn start(kw: *KW) !void {
    while (true) {
        try stdout.writer().print("{s}", .{PROMPT});

        var buffer: [1024]u8 = undefined;

        const input = try stdin.reader().readUntilDelimiter(&buffer, '\n');

        if (std.mem.eql(u8, std.mem.trim(u8, input, &std.ascii.whitespace), "exit()")) {
            break;
        }

        var l = Lexer.init(input, true, null, kw);

        var tok = l.nextToken();

        while (tok.ttype != TokenKind.EOF) {
            try stdout.writer().print("{any}\n", .{tok});
            tok = l.nextToken();
        }
    }
}
