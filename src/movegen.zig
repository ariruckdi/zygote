const std = @import("std");
const Chess = @import("chess.zig");
const Bitboard = @import("bitboard.zig").Bitboard;

const KNIGHT_DIRECTIONS = [_]u6{ 15, 17, 10, 6 };
const NEAREST_SQUARES = [_]i8{ 1, 8, -1, -8, 9, 7, -9, -7 };

fn dx(square1: i8, square2: i8) i8 {
    return (square2 % 8) - (square1 % 8);
}

fn dy(square1: i8, square2: i8) i8 {
    return (square2 / 8) - (square1 / 8);
}

fn valid_knight_deltas(square: i8, target: i8) bool {
    if (@abs(dx(square, target)) == 1 and @abs(dy(square, target) == 2)) return true;
    if (@abs(dx(square, target)) == 2 and @abs(dy(square, target) == 1)) return true;
    return false;
}

const precomputed_knight_moves: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    var result: [64]Bitboard = [_]Bitboard{Bitboard.init(0)} ** 64;

    for (0..64) |_square| {
        const square = @as(i8, _square);
        var next_bb = Bitboard.init(0);
        for (KNIGHT_DIRECTIONS) |dir| {
            const target_add = square + dir;
            const target_sub = square - dir;
            if (target_add < 64 and valid_knight_deltas(square, target_add)) next_bb.set(target_add);
            if (target_sub >= 0 and valid_knight_deltas(square, target_sub)) next_bb.set(target_sub);
        }
        result[square] = next_bb;
    }
    break :precompute result;
};

const precomputed_king_moves: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    var result: [64]Bitboard = [_]Bitboard{Bitboard.init(0)} ** 64;

    for (0..64) |_square| {
        const square = @as(i8, _square);
        var next_bb = Bitboard.init(0);
        for (NEAREST_SQUARES) |dir| {
            const target = square + dir;
            if (target < 64 and target >= 0) {
                next_bb.set(square);
            }
        }
        result[square] = next_bb;
    }
    break :precompute result;
};

test "knight" {
    var compare: Bitboard = Bitboard.init_single(10);
    compare.set(17);
    try std.testing.expectEqual(compare, precomputed_knight_moves[0]);
    std.debug.print("{s}", .{precomputed_knight_moves[45].to_string()});
}
