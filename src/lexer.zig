const std = @import("std");
const testing = std.testing;
const token = @import("token.zig");

pub const Lexer = struct {
    input: []const u8,
    position: usize, // current position in input (points to current char)
    read_position: usize, // current reading position in input (after current char)
    ch: u8, // current char under examination

    pub fn new(input: []u8) Lexer {
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
            _ => tok = token.Token.new(token.EOF, 0x00),
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

    var l = Lexer.new(input);

    for (expected) |tt| {
        const tok = l.nextToken();
        try testing.expectEqual(tt.expected_type, tok.ttype);
        try testing.expectEqual(tt.expected_literal, tok.literal);
    }
}
