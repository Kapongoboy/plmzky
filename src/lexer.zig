const std = @import("std");
const testing = std.testing;
const token = @import("token.zig");
const KeyWords = token.KeyWords;

pub const Lexer = struct {
    keywords: *KeyWords,
    input: []const u8,
    position: usize, // current position in input (points to current char)
    read_position: usize, // current reading position in input (after current char)
    ch: u8, // current char under examination

    pub fn init(input: []const u8, kw: *KeyWords) Lexer {
        var l = Lexer{
            .keywords = kw,
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

    fn readIdentifier(l: *Lexer) []const u8 {
        const position = l.position;

        while (std.ascii.isAlphabetic(l.ch)) {
            l.readChar();
        }

        return l.input[position..l.position];
    }

    fn skipWhiteSpace(l: *Lexer) void {
        while (std.ascii.isWhitespace(l.ch)) {
            l.readChar();
        }
    }

    fn readNumber(l: *Lexer) []const u8 {
        const position = l.position;

        while (std.ascii.isDigit(l.ch)) {
            l.readChar();
        }

        return l.input[position..l.position];
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
                if (std.ascii.isAlphabetic(l.ch)) {
                    const literal = l.readIdentifier();
                    return token.Token.initWithString(literal, l.keywords.lookUpIdent(literal));
                } else if (std.ascii.isDigit(l.ch)) {
                    return token.Token.initWithString(token.INT, l.readNumber());
                } else {
                    tok = token.Token.new(token.ILLEGAL, l.ch);
                }
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

    var KW = try KeyWords.tryInit(testing.allocator);
    defer KW.deinit();

    var l = Lexer.init(input, &KW);

    for (expected) |tt| {
        const tok = l.nextToken();
        std.debug.print("tok: {s}\ntt: {s}\n", .{ tok.ttype, tt.expected_type });
        try testing.expect(std.mem.eql(u8, tt.expected_type, tok.ttype));
        try testing.expect(std.mem.eql(u8, tt.expected_literal, tok.literal));
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

    var KW = try KeyWords.tryInit(testing.allocator);
    defer KW.deinit();

    var l = Lexer.init(input, &KW);

    for (expected) |tt| {
        const tok = l.nextToken();
        try testing.expect(std.mem.eql(u8, tt.expected_type, tok.ttype));
        try testing.expect(std.mem.eql(u8, tt.expected_literal, tok.literal));
    }
}
