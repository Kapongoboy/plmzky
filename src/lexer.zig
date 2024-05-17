const std = @import("std");
const testing = std.testing;
const token = @import("token.zig");

pub const Lexer = struct {
    input: []const u8,
    position: usize, // current position in input (points to current char)
    read_position: usize, // current reading position in input (after current char)
    ch: u8, // current char under examination

    pub fn init(input: []const u8) Lexer {
        var l = Lexer{
            .input = input,
            .position = 0,
            .read_position = 0,
            .ch = 0x00,
        };
        l.readChar();
        return l;
    }

    fn readChar(l: *Lexer) void {
        if (l.read_position >= l.input.len) {
            l.ch = 0x00;
        } else {
            l.ch = l.input[l.read_position];
        }
        l.position = l.read_position;
        l.read_position += 1;
    }

    pub fn nextToken(l: *Lexer) token.Token {
        var tok: token.Token = undefined;

        switch (l.ch) {
            '=' => tok = token.Token.new(token.ASSIGN, l.ch),
            ';' => tok = token.Token.new(token.SEMICOLON, l.ch),
            '(' => tok = token.Token.new(token.LPAREN, l.ch),
            ')' => tok = token.Token.new(token.RPAREN, l.ch),
            ',' => tok = token.Token.new(token.COMMA, l.ch),
            '+' => tok = token.Token.new(token.PLUS, l.ch),
            '{' => tok = token.Token.new(token.LBRACE, l.ch),
            '}' => tok = token.Token.new(token.RBRACE, l.ch),
            else => {
                if (std.ascii.isAlphabetic(l.ch)) {}
            },
        }

        l.readChar();
        return tok;
    }
};

test "text next token" {
    const input = "=+(){},;";
    const expected = [_]struct { expected_type: token.TokenType, expected_literal: []const u8 }{
        .{ .expected_type = token.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = token.PLUS, .expected_literal = "+" },
        .{ .expected_type = token.LPAREN, .expected_literal = "(" },
        .{ .expected_type = token.RPAREN, .expected_literal = ")" },
        .{ .expected_type = token.LBRACE, .expected_literal = "{" },
        .{ .expected_type = token.RBRACE, .expected_literal = "}" },
        .{ .expected_type = token.COMMA, .expected_literal = "," },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.EOF, .expected_literal = "" },
    };

    var l = Lexer.init(input);

    for (expected) |tt| {
        const tok = l.nextToken();
        try testing.expectEqual(tt.expected_type, tok.ttype);
        try testing.expectEqual(tt.expected_literal, tok.literal);
    }
}

test "text next token long form" {
    const input =
        \\let five = 5;
        \\let ten = 10;
        \\
        \\let add = fn(x, y) {
        \\    x + y;
        \\};
        \\
        \\let result = add(five, ten);
    ;

    const expected = [_]struct { expected_type: token.TokenType, expected_literal: []const u8 }{
        .{ .expected_type = token.LET, .expected_literal = "let" },
        .{ .expected_type = token.IDENT, .expected_literal = "five" },
        .{ .expected_type = token.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = token.INT, .expected_literal = "5" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.LET, .expected_literal = "let" },
        .{ .expected_type = token.IDENT, .expected_literal = "ten" },
        .{ .expected_type = token.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = token.INT, .expected_literal = "10" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.LET, .expected_literal = "let" },
        .{ .expected_type = token.IDENT, .expected_literal = "add" },
        .{ .expected_type = token.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = token.FUNCTION, .expected_literal = "fn" },
        .{ .expected_type = token.LPAREN, .expected_literal = "(" },
        .{ .expected_type = token.IDENT, .expected_literal = "x" },
        .{ .expected_type = token.COMMA, .expected_literal = "," },
        .{ .expected_type = token.IDENT, .expected_literal = "y" },
        .{ .expected_type = token.RPAREN, .expected_literal = ")" },
        .{ .expected_type = token.LBRACE, .expected_literal = "{" },
        .{ .expected_type = token.IDENT, .expected_literal = "x" },
        .{ .expected_type = token.PLUS, .expected_literal = "+" },
        .{ .expected_type = token.IDENT, .expected_literal = "y" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.RBRACE, .expected_literal = "}" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.LET, .expected_literal = "let" },
        .{ .expected_type = token.IDENT, .expected_literal = "result" },
        .{ .expected_type = token.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = token.IDENT, .expected_literal = "add" },
        .{ .expected_type = token.LPAREN, .expected_literal = "(" },
        .{ .expected_type = token.IDENT, .expected_literal = "five" },
        .{ .expected_type = token.COMMA, .expected_literal = "," },
        .{ .expected_type = token.IDENT, .expected_literal = "ten" },
        .{ .expected_type = token.RPAREN, .expected_literal = ")" },
        .{ .expected_type = token.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = token.EOF, .expected_literal = "" },
    };

    var l = Lexer.init(input);

    for (expected) |tt| {
        const tok = l.nextToken();
        try testing.expectEqual(tt.expected_type, tok.ttype);
        try testing.expectEqual(tt.expected_literal, tok.literal);
    }
}
