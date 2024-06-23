const std = @import("std");
pub const Chess = @import("chess.zig");
pub const Bitboard = @import("bitboard.zig").Bitboard;
pub const Movegen = @import("movegen.zig");

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)

    const index64 = [64]u6{ 63, 30, 3, 32, 59, 14, 11, 33, 60, 24, 50, 9, 55, 19, 21, 34, 61, 29, 2, 53, 51, 23, 41, 18, 56, 28, 1, 43, 46, 27, 0, 35, 62, 31, 58, 4, 5, 49, 54, 6, 15, 52, 12, 40, 7, 42, 45, 16, 25, 57, 48, 13, 10, 39, 8, 44, 20, 47, 38, 22, 17, 37, 36, 26 };

    const blubb: u64 = 0b100000000000000;
    const xor_lsb = (blubb ^ (blubb - 1));

    const folded: u32 = @as(u32, xor_lsb) ^ (xor_lsb >> 32);

    const lookup_index: usize = (@mulWithOverflow(folded, 0x78291ACF)[0]) >> 26;

    std.debug.print("\n{b}, (blubb ^ (blubb - 1)): {b}", .{ blubb, xor_lsb });
    std.debug.print("\nfolded: {b}", .{folded});
    std.debug.print("\nindex: {b}", .{lookup_index});
    std.debug.print("\nArray lookup: {d}", .{index64[lookup_index]});

    std.debug.print("\nAll your {s} are belong to us.\n", .{"pawns"});

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
