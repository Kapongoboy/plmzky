const std = @import("std");
const StringHashMap = std.StringHashMap;
const Allocator = std.mem.Allocator;

pub const TokenKind = enum {
    ILLEGAL,
    EOF,

    // Identifiers + literals
    IDENT,
    INT,

    // Operators
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

    // Delimiters
    COMMA,
    SEMICOLON,

    LPAREN,
    RPAREN,
    LBRACE,
    RBRACE,

    // Keywords
    FUNCTION,
    LET,
    TRUE,
    FALSE,
    IF,
    ELSE,
    RETURN,
};

pub const KeyWords = struct {
    const Self = @This();

    map: StringHashMap(TokenKind),

    pub fn init(allocator: Allocator) !Self {
        var map = StringHashMap(TokenKind).init(allocator);
        try map.put("let", TokenKind.LET);
        try map.put("fn", TokenKind.FUNCTION);
        try map.put("true", TokenKind.TRUE);
        try map.put("false", TokenKind.FALSE);
        try map.put("if", TokenKind.IF);
        try map.put("else", TokenKind.ELSE);
        try map.put("return", TokenKind.RETURN);

        return KeyWords{ .map = map };
    }

    pub fn loopupIdent(self: *Self, ident: []u8) TokenKind {
        return if (self.map.get(ident)) |token| return token else TokenKind.IDENT;
    }

    pub fn deinit(self: *Self) void {
        self.map.deinit();
    }
};
