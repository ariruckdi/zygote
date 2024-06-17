const std = @import("std");
pub const Chess = @import("chess.zig");
pub const Bitboard = @import("bitboard.zig").Bitboard;
pub const Movegen = @import("movegen.zig");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)

    std.debug.print("All your {s} are belong to us.\n", .{"pawns"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "main" {
    std.testing.refAllDecls(@This());
}
