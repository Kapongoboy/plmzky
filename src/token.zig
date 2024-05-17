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
    COMMA,
    SEMICOLON,
    LPAREN,
    RPAREN,
    LBRACE,
    RBRACE,
    FUNCTION,
    LET,
};

pub const Literal = []const u8;

pub const Token = struct {
    ttype: TokenKind,
    literal: Literal,

    pub fn init(token_type: TokenKind, ch: u8) Token {
        return Token{ .ttype = token_type, .literal = &[_]u8{ch} };
    }

    /// The caller owns the argument string
    pub fn initWithString(token_type: TokenKind, ch: []const u8) Token {
        return Token{ .ttype = token_type, .literal = ch };
    }
};

pub const KeyWords = struct {
    map: Map(TokenKind),
    pub fn tryInit(a: Allocator) !KeyWords {
        var map = Map(TokenKind).init(a);

        try map.put("fn", TokenKind.FUNCTION);
        try map.put("let", TokenKind.LET);

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
