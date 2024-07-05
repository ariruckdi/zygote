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

    pub fn xor(self: *Bitboard, other: Bitboard) void {
        self.this = self.this ^ other.this;
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

    pub fn combine_xor(lhs: Bitboard, rhs: Bitboard) Bitboard {
        return Bitboard.init(rhs.this ^ lhs.this);
    }

    pub fn not_empty(self: *const Bitboard) bool {
        return !(self.this == 0);
    }

    pub fn is_empty(self: *const Bitboard) bool {
        return (self.this == 0);
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

    //TODO remove checks when done with movegen
    pub fn bitscan_trailing(self: *const Bitboard) u6 { //returns index of least significant bit of bitboard
        if (self.is_empty()) {
            unreachable;
        }
        return @truncate(@ctz(self.this));
    }

    //TODO remove checks when done with movegen
    pub fn bitscan_leading(self: *const Bitboard) u6 { //returns index of most significant bit of bitboard
        if (self.is_empty()) {
            unreachable;
        }
        return 63 ^ @as(u6, @truncate(@clz(self.this)));
    }

    //BUG returns 0 on completely full Bitboard, but why should there ever be one of those and why should we popcount it
    // #famous last words
    pub fn popcount(self: *const Bitboard) u6 {
        return @truncate(@popCount(self.this));
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
        try std.testing.expectEqual(index, Bitboard.init_single(@intCast(index)).bitscan_trailing());
        try std.testing.expectEqual(index, Bitboard.init_single(@intCast(index)).bitscan_leading());
    }
    std.debug.print("\n\nint: {b}, scan_fw: {d}, scan_bw: {d}\n", .{ 0b001000100, Bitboard.init(0b001000100).bitscan_trailing(), Bitboard.init(0b001000100).bitscan_leading() });
}

test "popcount" {
    try std.testing.expectEqual(3, Bitboard.init(0b001001001).popcount());
}
