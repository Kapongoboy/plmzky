const std = @import("std");
const testing = std.testing;
const token = @import("token.zig");
const KeyWords = token.KeyWords;
const TokenKind = token.TokenKind;
const Token = token.Token;
const Allocator = std.mem.Allocator;

pub const StringManager = struct {
    const Self = @This();

    allocator: Allocator,
    buf: []u8,
    ptr: usize = 0,
    size: usize = 4096,

    pub fn init(a: Allocator) !StringManager {
        return StringManager{
            .allocator = a,
            .buf = try a.alloc(u8, 4096),
        };
    }

    pub fn make_string(self: *Self, letters: []const u8) !*const []u8 {
        const end = self.ptr + letters.len;
        defer self.ptr = end;

        if (self.ptr >= 4096) {
            const old_buf = self.buf;
            defer self.allocator.free(old_buf);

            const old_size = self.size;
            self.size *= 2;
            const new_buf = try self.allocator.alloc(u8, self.size);
            std.mem.copyForwards(u8, new_buf[0..old_size], old_buf);
            self.buf = new_buf;
        }

        std.mem.copyForwards(u8, self.buf[self.ptr..end], letters);

        return &self.buf[self.ptr..end];
    }

    pub fn deinit(self: *Self) void {
        self.allocator.free(self.buf);
    }
};

pub const Lexer = struct {
    keywords: *KeyWords,
    input: []const u8,
    position: usize, // current position in input (points to current char)
    read_position: usize, // current reading position in input (after current char)
    ch: u8, // current char under examination
    curr_line: usize,
    curr_col: usize,
    repl: bool,
    sm: *StringManager,
    path: ?*[]const u8,

    pub fn init(input: []const u8, repl: bool, path: ?*[]const u8, kw: *KeyWords, sm: *StringManager) Lexer {
        var l = Lexer{
            .keywords = kw,
            .input = input,
            .position = 0,
            .read_position = 0,
            .ch = 0x00,
            .curr_line = 1,
            .curr_col = 1,
            .repl = repl,
            .sm = sm,
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

    fn readIdentifier(l: *Lexer) !Token {
        const position = l.position;

        while (std.ascii.isAlphabetic(l.ch) or (l.ch == '_')) {
            l.readChar();
        }

        const loc = if (l.repl) null else token.Location.init(l.curr_line, l.curr_col, l.path.?);

        return Token.init(l.keywords.lookUpIdent(l.input[position..l.position]), try l.sm.make_string(l.input[position..l.position]), loc);
    }

    fn skipWhiteSpace(l: *Lexer) void {
        while (std.ascii.isWhitespace(l.ch)) {
            l.readChar();
        }
    }

    fn readNumber(l: *Lexer) !Token {
        const position = l.position;

        while (std.ascii.isDigit(l.ch)) {
            l.readChar();
        }

        const loc = if (l.repl) null else token.Location.init(l.curr_line, l.curr_col, l.path.?);

        return Token.init(TokenKind.INT, try l.sm.make_string(l.input[position..l.position]), loc);
    }

    pub fn nextToken(l: *Lexer) !token.Token {
        var tok: token.Token = undefined;

        l.skipWhiteSpace();

        const loc = if (l.repl) null else token.Location.init(l.curr_line, l.curr_col, l.path.?);

        switch (l.ch) {
            '=' => {
                if (l.peekChar() == '=') {
                    l.readChar();
                    tok = Token.init(TokenKind.EQ, try l.sm.make_string("=="), loc);
                } else {
                    tok = Token.init(TokenKind.ASSIGN, try l.sm.make_string("="), loc);
                }
            },
            ';' => tok = Token.init(TokenKind.SEMICOLON, try l.sm.make_string(";"), loc),
            '(' => tok = Token.init(TokenKind.LPAREN, try l.sm.make_string("("), loc),
            ')' => tok = Token.init(TokenKind.RPAREN, try l.sm.make_string(")"), loc),
            ',' => tok = Token.init(TokenKind.COMMA, try l.sm.make_string(","), loc),
            '+' => tok = Token.init(TokenKind.PLUS, try l.sm.make_string("+"), loc),
            '{' => tok = Token.init(TokenKind.LBRACE, try l.sm.make_string("{"), loc),
            '}' => tok = Token.init(TokenKind.RBRACE, try l.sm.make_string("}"), loc),
            '!' => {
                if (l.peekChar() == '=') {
                    l.readChar();
                    tok = Token.init(TokenKind.NEQ, try l.sm.make_string("!="), loc);
                } else {
                    tok = Token.init(TokenKind.BANG, try l.sm.make_string("!"), loc);
                }
            },
            '-' => tok = Token.init(TokenKind.MINUS, try l.sm.make_string("-"), loc),
            '*' => tok = Token.init(TokenKind.ASTERISK, try l.sm.make_string("*"), loc),
            '/' => tok = Token.init(TokenKind.SLASH, try l.sm.make_string("/"), loc),
            '<' => tok = Token.init(TokenKind.LT, try l.sm.make_string("<"), loc),
            '>' => tok = Token.init(TokenKind.GT, try l.sm.make_string(">"), loc),
            0x00 => tok = Token.init(TokenKind.EOF, try l.sm.make_string(""), loc),
            else => {
                if ((std.ascii.isAlphabetic(l.ch)) or (l.ch == '_')) {
                    return try l.readIdentifier();
                } else if (std.ascii.isDigit(l.ch)) {
                    return try l.readNumber();
                } else {
                    std.debug.print("Illegal character: {X}\n", .{l.ch});
                    tok = Token.init(TokenKind.ILLEGAL, try l.sm.make_string(""), loc);
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
    var SM = try StringManager.init(testing.allocator);
    defer {
        KW.deinit();
        SM.deinit();
    }

    var l = Lexer.init(input, true, null, &KW, &SM);

    for (expected) |tt| {
        const tok = try l.nextToken();
        try testing.expectEqual(tt.expected_type, tok.ttype);

        const result = std.mem.eql(u8, tt.expected_literal, tok.literal);

        try testing.expect(result);
    }
}

test "test next token complete" {
    const input =
        \\let five = 5; 
        \\let ten = 10;
        \\let add = fn(x, y) {
        \\x + y;
        \\};
        \\let result = add(five, ten);
        \\!-/*5;
        \\5 < 10 > 5;
        \\if (5 < 10) {
        \\return true;
        \\} else {
        \\return false;
        \\}
        \\10 == 10;
        \\10 != 9;
    ;

    const expected = [_]struct {
        expected_type: TokenKind,
        expected_literal: []const u8,
    }{
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
        .{ .expected_type = TokenKind.BANG, .expected_literal = "!" },
        .{ .expected_type = TokenKind.MINUS, .expected_literal = "-" },
        .{ .expected_type = TokenKind.SLASH, .expected_literal = "/" },
        .{ .expected_type = TokenKind.ASTERISK, .expected_literal = "*" },
        .{ .expected_type = TokenKind.INT, .expected_literal = "5" },
        .{ .expected_type = TokenKind.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = TokenKind.INT, .expected_literal = "5" },
        .{ .expected_type = TokenKind.LT, .expected_literal = "<" },
        .{ .expected_type = TokenKind.INT, .expected_literal = "10" },
        .{ .expected_type = TokenKind.GT, .expected_literal = ">" },
        .{ .expected_type = TokenKind.INT, .expected_literal = "5" },
        .{ .expected_type = TokenKind.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = TokenKind.IF, .expected_literal = "if" },
        .{ .expected_type = TokenKind.LPAREN, .expected_literal = "(" },
        .{ .expected_type = TokenKind.INT, .expected_literal = "5" },
        .{ .expected_type = TokenKind.LT, .expected_literal = "<" },
        .{ .expected_type = TokenKind.INT, .expected_literal = "10" },
        .{ .expected_type = TokenKind.RPAREN, .expected_literal = ")" },
        .{ .expected_type = TokenKind.LBRACE, .expected_literal = "{" },
        .{ .expected_type = TokenKind.RETURN, .expected_literal = "return" },
        .{ .expected_type = TokenKind.TRUE, .expected_literal = "true" },
        .{ .expected_type = TokenKind.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = TokenKind.RBRACE, .expected_literal = "}" },
        .{ .expected_type = TokenKind.ELSE, .expected_literal = "else" },
        .{ .expected_type = TokenKind.LBRACE, .expected_literal = "{" },
        .{ .expected_type = TokenKind.RETURN, .expected_literal = "return" },
        .{ .expected_type = TokenKind.FALSE, .expected_literal = "false" },
        .{ .expected_type = TokenKind.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = TokenKind.RBRACE, .expected_literal = "}" },
        .{ .expected_type = TokenKind.INT, .expected_literal = "10" },
        .{ .expected_type = TokenKind.EQ, .expected_literal = "==" },
        .{ .expected_type = TokenKind.INT, .expected_literal = "10" },
        .{ .expected_type = TokenKind.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = TokenKind.INT, .expected_literal = "10" },
        .{ .expected_type = TokenKind.NEQ, .expected_literal = "!=" },
        .{ .expected_type = TokenKind.INT, .expected_literal = "9" },
        .{ .expected_type = TokenKind.SEMICOLON, .expected_literal = ";" },
        .{ .expected_type = TokenKind.EOF, .expected_literal = "" },
    };

    var KW = try KeyWords.tryInit(testing.allocator);
    var SM = try StringManager.init(testing.allocator);

    defer {
        KW.deinit();
        SM.deinit();
    }

    var l = Lexer.init(input, true, null, &KW, &SM);

    for (expected) |tt| {
        const tok = try l.nextToken();
        try testing.expectEqual(tt.expected_type, tok.ttype);
        const result = std.mem.eql(u8, tt.expected_literal, tok.literal);
        try testing.expect(result);
    }
}
