const std = @import("std");
const ArrayList = std.ArrayList;
const Token = @import("token.zig").Token;

const Node = union(enum) {
    fn tokenLiteral() []const u8 {
        @compileError("not yet implemented");
    }
};

const Statement = union(enum) {
    fn statementNode() Node {
        @compileError("not yet implemented");
    }
};

const Expression = union(enum) {
    fn expressionNode() Node {
        @compileError("not yet implemented");
    }
};

const Program = struct {
    statements: ArrayList(Statement),

    pub fn tokenLiteral(p: *Program) []const u8 {
        if (p.statements.items.len > 0) {
            return p.statements.items[0].statementNode().tokenLiteral();
        }
    }
};
