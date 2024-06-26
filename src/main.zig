const std = @import("std");
const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();
const Allocator = std.mem.Allocator;
const plmzky = @import("plmzky");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);

    const ally = arena.allocator();

    defer arena.deinit();

    const user = std.process.getEnvVarOwned(ally, "USER") catch |e| {
        try stderr.print("Error getting user name: err = {}\n", .{e});
        return;
    };

    if (!try givenFileArg(ally)) {
        try stdout.print("Hello {s}! This is the Monkey programming language\n", .{user});
        try plmzky.repl.start(ally);
    } else {
        try stderr.print("File argument not yet supported, functionality coming soon\n", .{});
    }
}

fn givenFileArg(a: Allocator) !bool {
    var iter = try std.process.ArgIterator.initWithAllocator(a);
    defer iter.deinit();

    var count: u16 = 0;

    while (iter.next()) |_| : (count += 1) {}

    return count > 1;
}
