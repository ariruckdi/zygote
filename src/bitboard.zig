const std = @import("std");

const U64_1: u64 = 1; //ok this is kinda dumb

pub const Bitboard = struct {
    this: u64,

    pub fn init(value: u64) Bitboard {
        return Bitboard{ .this = value };
    }

    pub fn init_single(square: u6) Bitboard {
        return Bitboard{ .this = (U64_1 << square) };
    }

    pub fn set(self: *Bitboard, square: u6) void {
        self.this = self.this | (U64_1 << square);
    }

    pub fn get(self: *const Bitboard, square: u6) bool {
        return (self.this & (U64_1 << square)) != 0;
    }

    pub fn rm(self: *Bitboard, square: u6) void {
        self.this = self.this & ~(U64_1 << square);
    }

    pub fn flip(self: *Bitboard) void {
        self.this = ~self.this;
    }

    pub fn add(self: *Bitboard, other: *Bitboard) void {
        self.this = self.this | other.this;
    }

    pub fn sub(self: *Bitboard, other: *Bitboard) void {
        self.this = self.this & ~other.this;
    }

    pub fn combine_add(lhs: *Bitboard, rhs: *Bitboard) Bitboard {
        return Bitboard.init(rhs.this | lhs.this);
    }

    pub fn combine_sub(lhs: *Bitboard, rhs: *Bitboard) Bitboard {
        return Bitboard.init(rhs.this & ~lhs.this);
    }

    pub fn combine_overlap(lhs: *Bitboard, rhs: *Bitboard) Bitboard {
        return Bitboard.init(rhs.this & lhs.this);
    }

    pub fn to_string(self: *const Bitboard) [72]u8 {
        var result = [_]u8{' '} ** 72;
        var idx: usize = 0;
        for (0..8) |row| {
            for (0..8) |col| {
                const square = (7 - row) * 8 + col;
                result[idx] = if (self.get(@intCast(square))) '1' else '0';
                std.debug.print("\nidx: {d}, result[idx]: {c}, square: {d}", .{ idx, result[idx], square });
                idx += 1;
            }
            result[idx] = '-';
            std.debug.print("\nidx: {d}, result[idx]: {c}", .{ idx, result[idx] });
            idx += 1;
        }
        return result;
    }
};

test "bitboard basics" {
    var bb_test = Bitboard.init(0);
    bb_test.set(4);
    try std.testing.expectEqual(bb_test, Bitboard.init(0b10000));
    try std.testing.expect(bb_test.get(4));
    std.debug.print("\n{s}", .{bb_test.to_string()});
}
