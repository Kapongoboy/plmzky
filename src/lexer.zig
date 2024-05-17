const std = @import("std");
const testing = std.testing;
const token = @import("token.zig");
const KeyWords = token.KeyWords;
const TokenKind = token.TokenKind;
const Token = token.Token;

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

        l.skipWhiteSpace();

        switch (l.ch) {
            '=' => tok = Token.init(TokenKind.ASSIGN, l.ch),
            ';' => tok = Token.init(TokenKind.SEMICOLON, l.ch),
            '(' => tok = Token.init(TokenKind.LPAREN, l.ch),
            ')' => tok = Token.init(TokenKind.RPAREN, l.ch),
            ',' => tok = Token.init(TokenKind.COMMA, l.ch),
            '+' => tok = Token.init(TokenKind.PLUS, l.ch),
            '{' => tok = Token.init(TokenKind.LBRACE, l.ch),
            '}' => tok = Token.init(TokenKind.RBRACE, l.ch),
            0x00 => tok = Token.initWithString(TokenKind.EOF, ""),
            else => {
                if ((std.ascii.isAlphabetic(l.ch)) or (l.ch == '_')) {
                    const literal = l.readIdentifier();
                    return Token.initWithString(l.keywords.lookUpIdent(literal), literal);
                } else if (std.ascii.isDigit(l.ch)) {
                    return Token.initWithString(TokenKind.INT, l.readNumber());
                } else {
                    std.debug.print("Illegal character: {X}\n", .{l.ch});
                    tok = Token.init(TokenKind.ILLEGAL, l.ch);
                }
            },
        }

        l.readChar();
        return tok;
    }
};

test "text next token" {
    const input = "=+(){},;";
    const expected = [_]struct { expected_type: TokenKind, expected_literal: []const u8 }{
        .{ .expected_type = TokenKind.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = TokenKind.PLUS, .expected_literal = "+" },
        .{ .expected_type = TokenKind.LPAREN, .expected_literal = "(" },
        .{ .expected_type = TokenKind.RPAREN, .expected_literal = ")" },
        .{ .expected_type = TokenKind.LBRACE, .expected_literal = "{" },
        .{ .expected_type = TokenKind.RBRACE, .expected_literal = "}" },
        .{ .expected_type = TokenKind.COMMA, .expected_literal = "," },
        .{ .expected_type = TokenKind.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = TokenKind.EOF, .expected_literal = "" },
    };

    var KW = try KeyWords.tryInit(testing.allocator);
    defer KW.deinit();

    var l = Lexer.init(input, &KW);

    for (expected) |tt| {
        const tok = l.nextToken();
        try testing.expectEqual(tt.expected_type, tok.ttype);
        // try testing.expect(std.mem.eql(u8, tt.expected_literal, tok.literal));
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

    const expected = [_]struct { expected_type: TokenKind, expected_literal: []const u8 }{
        .{ .expected_type = TokenKind.LET, .expected_literal = "let" },
        .{ .expected_type = TokenKind.IDENT, .expected_literal = "five" },
        .{ .expected_type = TokenKind.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = TokenKind.INT, .expected_literal = "5" },
        .{ .expected_type = TokenKind.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = TokenKind.LET, .expected_literal = "let" },
        .{ .expected_type = TokenKind.IDENT, .expected_literal = "ten" },
        .{ .expected_type = TokenKind.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = TokenKind.INT, .expected_literal = "10" },
        .{ .expected_type = TokenKind.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = TokenKind.LET, .expected_literal = "let" },
        .{ .expected_type = TokenKind.IDENT, .expected_literal = "add" },
        .{ .expected_type = TokenKind.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = TokenKind.FUNCTION, .expected_literal = "fn" },
        .{ .expected_type = TokenKind.LPAREN, .expected_literal = "(" },
        .{ .expected_type = TokenKind.IDENT, .expected_literal = "x" },
        .{ .expected_type = TokenKind.COMMA, .expected_literal = "," },
        .{ .expected_type = TokenKind.IDENT, .expected_literal = "y" },
        .{ .expected_type = TokenKind.RPAREN, .expected_literal = ")" },
        .{ .expected_type = TokenKind.LBRACE, .expected_literal = "{" },
        .{ .expected_type = TokenKind.IDENT, .expected_literal = "x" },
        .{ .expected_type = TokenKind.PLUS, .expected_literal = "+" },
        .{ .expected_type = TokenKind.IDENT, .expected_literal = "y" },
        .{ .expected_type = TokenKind.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = TokenKind.RBRACE, .expected_literal = "}" },
        .{ .expected_type = TokenKind.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = TokenKind.LET, .expected_literal = "let" },
        .{ .expected_type = TokenKind.IDENT, .expected_literal = "result" },
        .{ .expected_type = TokenKind.ASSIGN, .expected_literal = "=" },
        .{ .expected_type = TokenKind.IDENT, .expected_literal = "add" },
        .{ .expected_type = TokenKind.LPAREN, .expected_literal = "(" },
        .{ .expected_type = TokenKind.IDENT, .expected_literal = "five" },
        .{ .expected_type = TokenKind.COMMA, .expected_literal = "," },
        .{ .expected_type = TokenKind.IDENT, .expected_literal = "ten" },
        .{ .expected_type = TokenKind.RPAREN, .expected_literal = ")" },
        .{ .expected_type = TokenKind.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = TokenKind.EOF, .expected_literal = "" },
    };

    var KW = try KeyWords.tryInit(testing.allocator);
    defer KW.deinit();

    var l = Lexer.init(input, &KW);

    for (expected) |tt| {
        const tok = l.nextToken();
        try testing.expectEqual(tt.expected_type, tok.ttype);
        // try testing.expect(std.mem.eql(u8, tt.expected_literal, tok.literal));
    }
}
