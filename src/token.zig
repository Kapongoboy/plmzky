const std = @import("std");
const Map = std.StringHashMap;
const Allocator = std.mem.Allocator;

pub const TokenKind = enum {
    ILLEGAL,
    EOF,

    IDENT,
    INT,

    ASSIGN,
    PLUS,
    MINUS,
    BANG,
    ASTERISK,
    SLASH,

    LT,
    GT,

    EQ,
    NEQ,

    COMMA,
    SEMICOLON,

    LPAREN,
    RPAREN,
    LBRACE,
    RBRACE,

    FUNCTION,
    LET,
    TRUE,
    FALSE,
    IF,
    ELSE,
    RETURN,
};

pub const Location = struct {
    _row: usize,
    _col: usize,
    _file: *[]const u8,

    pub fn init(row: usize, col: usize, file: *[]const u8) Location {
        return Location{ ._row = row, ._col = col, ._file = file };
    }

    pub fn get(self: *Location) .{ *usize, *usize, *[]const u8 } {
        return .{ &self._row, &self._col, self._file };
    }
};

pub const Literal = []const u8;

pub const Token = struct {
    ttype: TokenKind,
    literal: Literal,
    _local: ?Location = null,

    pub fn init(token_type: TokenKind, ch: u8) Token {
        return Token{ .ttype = token_type, .literal = &[_]u8{ch} };
    }

    /// The caller owns the argument string
    pub fn initWithString(token_type: TokenKind, ch: []const u8) Token {
        return Token{ .ttype = token_type, .literal = ch };
    }

    /// The caller owns the argument string here as well
    pub fn initWithLocation(token_type: TokenKind, ch: u8, loc: ?Location) Token {
        return Token{ .ttype = token_type, .literal = &[_]u8{ch}, ._local = loc };
    }

    pub fn initWithStringAndLocation(token_type: TokenKind, ch: []const u8, loc: ?Location) Token {
        return Token{ .ttype = token_type, .literal = ch, ._local = loc };
    }

    pub fn local(self: *Token) ?Location {
        return if (self._local) |i| i else null;
    }
};

pub const KeyWords = struct {
    map: Map(TokenKind),
    pub fn tryInit(a: Allocator) !KeyWords {
        var map = Map(TokenKind).init(a);

        try map.put("fn", TokenKind.FUNCTION);
        try map.put("let", TokenKind.LET);
        try map.put("true", TokenKind.TRUE);
        try map.put("false", TokenKind.FALSE);
        try map.put("if", TokenKind.IF);
        try map.put("else", TokenKind.ELSE);
        try map.put("return", TokenKind.RETURN);

        return KeyWords{ .map = map };
    }

    pub fn lookUpIdent(self: *KeyWords, ident: []const u8) TokenKind {
        if (self.map.get(ident)) |tok| {
            return tok;
        } else {
            return TokenKind.IDENT;
        }
    }

    pub fn deinit(self: *KeyWords) void {
        self.map.deinit();
    }
};
