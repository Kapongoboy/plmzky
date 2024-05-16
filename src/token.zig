const std = @import("std");

pub const TokenType = []const u8;

pub const Token = struct {
    ttype: TokenType,
    literal: TokenType,

    pub fn new(token_type: TokenType, ch: u8) Token {
        return Token{ .ttype = token_type, .literal = &[_]u8{ch} };
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
