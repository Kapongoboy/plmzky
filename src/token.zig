const std = @import("std");
const Map = std.StringHashMap;
const Allocator = std.mem.Allocator;

pub const TokenType = []const u8;

pub const Token = struct {
    ttype: TokenType,
    literal: TokenType,

    pub fn new(token_type: TokenType, ch: u8) Token {
        return Token{ .ttype = token_type, .literal = &[_]u8{ch} };
    }

    /// The caller owns the argument string
    pub fn initWithString(token_type: TokenType, ch: []const u8) Token {
        return Token{ .ttype = token_type, .literal = ch };
    }
};

pub const ILLEGAL = "ILLEGAL";
pub const EOF = "EOF";
pub const IDENT = "IDENT";
pub const INT = "INT";
pub const ASSIGN = "=";
pub const PLUS = "+";
pub const COMMA = ".";
pub const SEMICOLON = ";";
pub const LPAREN = "(";
pub const RPAREN = ")";
pub const LBRACE = "{";
pub const RBRACE = "}";
pub const FUNCTION = "FUNCTION";
pub const LET = "LET";

pub const KeyWords = struct {
    map: Map(TokenType),
    pub fn tryInit(a: Allocator) !KeyWords {
        var map = Map(TokenType).init(a);

        try map.put("fn", FUNCTION);
        try map.put("let", LET);

        return KeyWords{ .map = map };
    }

    pub fn lookUpIdent(self: *KeyWords, ident: []const u8) TokenType {
        if (self.map.get(ident)) |tok| {
            return tok;
        } else {
            return IDENT;
        }
    }

    pub fn deinit(self: *KeyWords) void {
        self.map.deinit();
    }
};
