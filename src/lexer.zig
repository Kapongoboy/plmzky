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
    curr_line: usize,
    curr_col: usize,
    repl: bool,
    path: ?*[]const u8,

    pub fn init(input: []const u8, repl: bool, path: ?*[]const u8, kw: *KeyWords) Lexer {
        var l = Lexer{
            .keywords = kw,
            .input = input,
            .position = 0,
            .read_position = 0,
            .ch = 0x00,
            .curr_line = 1,
            .curr_col = 1,
            .repl = repl,
            .path = path,
        };
        l.readChar();
        return l;
    }

    fn peekChar(l: *Lexer) u8 {
        if (l.read_position >= l.input.len) {
            return 0x00;
        } else {
            return l.input[l.read_position];
        }
    }

    fn readChar(l: *Lexer) void {
        if (l.read_position >= l.input.len) {
            l.ch = 0x00;
        } else {
            l.ch = l.input[l.read_position];
        }

        if (l.ch == '\n') {
            l.curr_line += 1;
            l.curr_col = 1;
        } else {
            l.curr_col += 1;
        }

        l.position = l.read_position;
        l.read_position += 1;
    }

    fn readIdentifier(l: *Lexer) Token {
        const position = l.position;

        while (std.ascii.isAlphabetic(l.ch) or (l.ch == '_')) {
            l.readChar();
        }

        const loc = if (l.repl) null else token.Location.init(l.curr_line, l.curr_col, l.path.?);

        return Token.initWithStringAndLocation(l.keywords.lookUpIdent(l.input[position..l.position]), l.input[position..l.position], loc);
    }

    fn skipWhiteSpace(l: *Lexer) void {
        while (std.ascii.isWhitespace(l.ch)) {
            l.readChar();
        }
    }

    fn readNumber(l: *Lexer) Token {
        const position = l.position;

        while (std.ascii.isDigit(l.ch)) {
            l.readChar();
        }

        const loc = if (l.repl) null else token.Location.init(l.curr_line, l.curr_col, l.path.?);

        return Token.initWithStringAndLocation(TokenKind.INT, l.input[position..l.position], loc);
    }

    pub fn nextToken(l: *Lexer) token.Token {
        var tok: token.Token = undefined;

        l.skipWhiteSpace();

        const loc = if (l.repl) null else token.Location.init(l.curr_line, l.curr_col, l.path.?);

        switch (l.ch) {
            '=' => {
                if (l.peekChar() == '=') {
                    l.readChar();
                    tok = Token.initWithStringAndLocation(TokenKind.EQ, "==", loc);
                } else {
                    tok = Token.initWithLocation(TokenKind.ASSIGN, l.ch, loc);
                }
            },
            ';' => tok = Token.initWithLocation(TokenKind.SEMICOLON, l.ch, loc),
            '(' => tok = Token.initWithLocation(TokenKind.LPAREN, l.ch, loc),
            ')' => tok = Token.initWithLocation(TokenKind.RPAREN, l.ch, loc),
            ',' => tok = Token.initWithLocation(TokenKind.COMMA, l.ch, loc),
            '+' => tok = Token.initWithLocation(TokenKind.PLUS, l.ch, loc),
            '{' => tok = Token.initWithLocation(TokenKind.LBRACE, l.ch, loc),
            '}' => tok = Token.initWithLocation(TokenKind.RBRACE, l.ch, loc),
            '!' => {
                if (l.peekChar() == '=') {
                    l.readChar();
                    tok = Token.initWithStringAndLocation(TokenKind.NEQ, "!=", loc);
                } else {
                    tok = Token.initWithStringAndLocation(TokenKind.BANG, "!", loc);
                }
            },
            '-' => tok = Token.initWithLocation(TokenKind.MINUS, l.ch, loc),
            '*' => tok = Token.initWithLocation(TokenKind.ASTERISK, l.ch, loc),
            '/' => tok = Token.initWithLocation(TokenKind.SLASH, l.ch, loc),
            '<' => tok = Token.initWithLocation(TokenKind.LT, l.ch, loc),
            '>' => tok = Token.initWithLocation(TokenKind.GT, l.ch, loc),
            0x00 => tok = Token.initWithLocation(TokenKind.EOF, l.ch, loc),
            else => {
                if ((std.ascii.isAlphabetic(l.ch)) or (l.ch == '_')) {
                    return l.readIdentifier();
                } else if (std.ascii.isDigit(l.ch)) {
                    return l.readNumber();
                } else {
                    std.debug.print("Illegal character: {X}\n", .{l.ch});
                    tok = Token.initWithLocation(TokenKind.ILLEGAL, l.ch, loc);
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

    var l = Lexer.init(input, true, null, &KW);

    for (expected) |tt| {
        const tok = l.nextToken();
        try testing.expectEqual(tt.expected_type, tok.ttype);

        const result = std.mem.eql(u8, tt.expected_literal, tok.literal);

        std.debug.print("\nthe result was {}\nexpected {any}, actual {any}\n", .{ result, tt.expected_literal, tok.literal });
        try testing.expect(result);
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

    var l = Lexer.init(input, true, null, &KW);

    for (expected) |tt| {
        const tok = l.nextToken();
        try testing.expectEqual(tt.expected_type, tok.ttype);
        // const result = std.mem.eql(u8, tt.expected_literal, tok.literal);
        // try testing.expect(result);
    }
}
