const std = @import("std");

const U64_1: u64 = 1; //ok this is kinda dumb
const BITSCAN_FW_TABLE = [64]u6{ 63, 30, 3, 32, 59, 14, 11, 33, 60, 24, 50, 9, 55, 19, 21, 34, 61, 29, 2, 53, 51, 23, 41, 18, 56, 28, 1, 43, 46, 27, 0, 35, 62, 31, 58, 4, 5, 49, 54, 6, 15, 52, 12, 40, 7, 42, 45, 16, 25, 57, 48, 13, 10, 39, 8, 44, 20, 47, 38, 22, 17, 37, 36, 26 };
const BITSCAN_BW_TABLE = [64]u6{ 0, 47, 1, 56, 48, 27, 2, 60, 57, 49, 41, 37, 28, 16, 3, 61, 54, 58, 35, 52, 50, 42, 21, 44, 38, 32, 29, 23, 17, 11, 4, 62, 46, 55, 26, 59, 40, 36, 15, 53, 34, 51, 20, 43, 31, 22, 10, 45, 25, 39, 14, 33, 19, 30, 9, 24, 13, 18, 8, 12, 7, 6, 5, 63 };

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

    pub fn set_group(self: *Bitboard, group: []u6) void {
        for (group) |square| {
            self.set(square);
        }
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

    pub fn add(self: *Bitboard, other: Bitboard) void {
        self.this = self.this | other.this;
    }

    pub fn sub(self: *Bitboard, other: Bitboard) void {
        self.this = self.this & ~other.this;
    }

    pub fn combine_add(lhs: Bitboard, rhs: Bitboard) Bitboard {
        return Bitboard.init(rhs.this | lhs.this);
    }

    pub fn combine_sub(lhs: Bitboard, rhs: Bitboard) Bitboard {
        return Bitboard.init(lhs.this & ~rhs.this);
    }

    pub fn combine_overlap(lhs: Bitboard, rhs: Bitboard) Bitboard {
        return Bitboard.init(rhs.this & lhs.this);
    }

    pub fn to_string(self: *const Bitboard) [72]u8 {
        var result = [_]u8{' '} ** 72;
        var idx: usize = 0;
        for (0..8) |row| {
            for (0..8) |col| {
                const square = (7 - row) * 8 + col;
                result[idx] = if (self.get(@intCast(square))) '+' else '-';
                //std.debug.print("\nidx: {d}, result[idx]: {c}, square: {d}", .{ idx, result[idx], square });
                idx += 1;
            }
            result[idx] = '\n';
            //std.debug.print("\nidx: {d}, result[idx]: {c}", .{ idx, result[idx] });
            idx += 1;
        }
        return result;
    }

    pub fn bitscan_fw(self: *const Bitboard) u6 { //returns index of least significant bit of bitboard
        const xor_lsb_fill: u64 = (self.this ^ (self.this - 1));
        const lower_half: u32 = @truncate(xor_lsb_fill);
        const upper_half: u32 = @truncate(xor_lsb_fill >> 32);
        const folded: u32 = lower_half ^ upper_half;
        const lookup_index: usize = (@mulWithOverflow(folded, 0x78291ACF)[0]) >> 26;
        return BITSCAN_FW_TABLE[lookup_index];
    }

    pub fn bitscan_bw(self: *const Bitboard) u6 { //returns index of most significant bit of bitboard
        const debruijn: u64 = 0x03f79d71b4cb0a89;
        var bb = self.this;
        bb |= bb >> 1;
        bb |= bb >> 2;
        bb |= bb >> 4;
        bb |= bb >> 8;
        bb |= bb >> 16;
        bb |= bb >> 32;
        const deb_product = @mulWithOverflow(bb, debruijn)[0];
        const index: usize = @truncate(deb_product >> 58);
        return BITSCAN_BW_TABLE[index];
    }
};

test "bitboard basics" {
    var bb_test = Bitboard.init(0);
    bb_test.set(4);
    try std.testing.expectEqual(bb_test, Bitboard.init(0b10000));
    try std.testing.expect(bb_test.get(4));
}

test "bitscan" {
    for (0..64) |index| {
        try std.testing.expectEqual(index, Bitboard.init_single(@intCast(index)).bitscan_fw());
        try std.testing.expectEqual(index, Bitboard.init_single(@intCast(index)).bitscan_bw());
    }
    std.debug.print("\n\nint: {b}, scan_fw: {d}, scan_bw: {d}\n", .{ 0b001000100, Bitboard.init(0b001000100).bitscan_fw(), Bitboard.init(0b001000100).bitscan_bw() });
}
