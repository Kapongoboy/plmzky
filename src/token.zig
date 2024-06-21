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

    pub fn init(token_type: TokenKind, ch: *const []u8, loc: ?Location) Token {
        return Token{ .ttype = token_type, .literal = ch.*, ._local = loc };
    }

    pub fn local(self: *Token) ?Location {
        return if (self._local) |i| i else null;
    }
};

pub const KeyWordsStatic = std.static_string_map.StaticStringMap(TokenKind).initComptime(.{
    .{ "fn", TokenKind.FUNCTION },
    .{ "let", TokenKind.LET },
    .{ "true", TokenKind.TRUE },
    .{ "false", TokenKind.FALSE },
    .{ "if", TokenKind.IF },
    .{ "else", TokenKind.ELSE },
    .{ "return", TokenKind.RETURN },
});

pub fn lookUpIdent(ident: []const u8) TokenKind {
    if (KeyWordsStatic.get(ident)) |tok| {
        return tok;
    } else {
        return TokenKind.IDENT;
    }
}
