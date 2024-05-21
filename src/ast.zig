const std = @import("std");
const Token = @import("token.zig").Token;

pub const Identifier = struct {
    token: Token,
    value: []const u8,

    pub fn init(t: Token, v: *const []u8) Identifier {
        return Identifier{
            .token = t,
            .value = v.*,
        };
    }

    pub fn token(self: *Identifier) *const Token {
        return &self.token;
    }

    pub fn value(self: *Identifier) *const []const u8 {
        &self.value;
    }
};
