const std = @import("std");
const Chess = @import("chess.zig");
const Bitboard = @import("bitboard.zig").Bitboard;

const KNIGHT_DIRECTIONS = [_]u6{ 15, 17, 10, 6 };
const NEAREST_SQUARES = [_]i8{ 1, 8, -1, -8, 9, 7, -9, -7 };
const WHITE_PAWN_ATTACKS = [_]i8{ 7, 9 };
const BLACK_PAWN_ATTACKS = [_]i8{ -9, -7 };

//helpers
fn dx(square1: i8, square2: i8) i8 {
    return (square2 % 8) - (square1 % 8);
}

fn dy(square1: i8, square2: i8) i8 {
    return (square2 / 8) - (square1 / 8);
}

fn valid_knight_deltas(square: i8, target: i8) bool {
    if (@abs(dx(square, target)) == 1 and @abs(dy(square, target)) == 2) return true;
    if (@abs(dx(square, target)) == 2 and @abs(dy(square, target)) == 1) return true;
    return false;
}

fn valid_neighbor(square: i8, target: i8) bool {
    if (@abs(dx(square, target)) == 1 and @abs(dy(square, target)) == 1) return true;
    if (@abs(dx(square, target)) == 0 and @abs(dy(square, target)) == 1) return true;
    if (@abs(dx(square, target)) == 1 and @abs(dy(square, target)) == 0) return true;
    return false;
}

//comptime precomputing movegen data
const precomp_knight: [64]Bitboard = precompute: {
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

const precomp_king: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    var result: [64]Bitboard = [_]Bitboard{Bitboard.init(0)} ** 64;

    for (0..64) |_square| {
        const square = @as(i8, _square);
        var next_bb = Bitboard.init(0);
        for (NEAREST_SQUARES) |dir| {
            const target = square + dir;
            if (target < 64 and target >= 0 and valid_neighbor(square, target)) {
                next_bb.set(target);
            }
        }
        result[square] = next_bb;
    }
    break :precompute result;
};

const precomp_pawn_push_white: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    var result: [64]Bitboard = [_]Bitboard{Bitboard.init(0)} ** 64;

    for (0..64) |_square| {
        const square = @as(i8, _square);
        var next_bb = Bitboard.init(0);
        const target = square + 8;
        const double_push_target = square + 16;
        if (target < 64) next_bb.set(target);
        if (Chess.Board.y(square) == 1) next_bb.set(double_push_target);
        result[square] = next_bb;
    }
    break :precompute result;
};

const precomp_pawn_push_black: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    var result: [64]Bitboard = [_]Bitboard{Bitboard.init(0)} ** 64;

    for (0..64) |_square| {
        const square = @as(i8, _square);
        var next_bb = Bitboard.init(0);
        const target = square - 8;
        const double_push_target = square - 16;
        if (target >= 0) next_bb.set(target);
        if (Chess.Board.y(square) == 6) next_bb.set(double_push_target);
        result[square] = next_bb;
    }
    break :precompute result;
};

const precomp_pawn_attack_white: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    var result: [64]Bitboard = [_]Bitboard{Bitboard.init(0)} ** 64;

    for (0..64) |_square| {
        const square = @as(i8, _square);
        var next_bb = Bitboard.init(0);
        for (WHITE_PAWN_ATTACKS) |delta| {
            const target = square + delta;
            if (target < 64 and target >= 0 and valid_neighbor(square, target)) {
                next_bb.set(target);
            }
        }
        result[square] = next_bb;
    }
    break :precompute result;
};

const precomp_pawn_attack_black: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    var result: [64]Bitboard = [_]Bitboard{Bitboard.init(0)} ** 64;

    for (0..64) |_square| {
        const square = @as(i8, _square);
        var next_bb = Bitboard.init(0);
        for (BLACK_PAWN_ATTACKS) |delta| {
            const target = square + delta;
            if (target < 64 and target >= 0 and valid_neighbor(square, target)) {
                next_bb.set(target);
            }
        }
        result[square] = next_bb;
    }
    break :precompute result;
};

fn precomp_ray(dir: i8) [64]Bitboard {
    var result: [64]Bitboard = [_]Bitboard{Bitboard.init(0)} ** 64;
    for (0..64) |_square| {
        const square = @as(i8, _square);
        var next_bb = Bitboard.init(0);
        var prev = square;
        var target = square + dir;
        while (target < 64 and target >= 0 and valid_neighbor(prev, target)) {
            next_bb.set(target);
            prev = target;
            target += dir;
        }
        result[square] = next_bb;
    }
    return result;
}

const precomp_ray_NW: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    break :precompute precomp_ray(7);
};
const precomp_ray_N: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    break :precompute precomp_ray(8);
};
const precomp_ray_NE: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    break :precompute precomp_ray(9);
};
const precomp_ray_E: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    break :precompute precomp_ray(1);
};
const precomp_ray_SE: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    break :precompute precomp_ray(-7);
};
const precomp_ray_S: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    break :precompute precomp_ray(-8);
};
const precomp_ray_SW: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    break :precompute precomp_ray(-9);
};
const precomp_ray_W: [64]Bitboard = precompute: {
    @setEvalBranchQuota(4096);
    break :precompute precomp_ray(-1);
};

const precomp_rays = [8][64]Bitboard{ precomp_ray_N, precomp_ray_E, precomp_ray_S, precomp_ray_W, precomp_ray_NE, precomp_ray_SE, precomp_ray_SW, precomp_ray_NW };

fn dump_precomp_data(data: *const [64]Bitboard) void {
    std.debug.print("\n", .{});
    for (data) |bb| {
        std.debug.print("\n{s}", .{bb.to_string()});
    }
}

//pseudo legal movegen
fn knight_moves(square: u6, board: *Chess.Board, white: bool, quiets: bool) Bitboard {
    const opponent = if (white) {
        &board.black_pieces;
    } else {
        &board.white_pieces;
    };
    const quiet = Bitboard.combine_sub(precomp_knight[square], board.occupied());
    const captures = Bitboard.combine_overlap(precomp_knight[square], opponent);
    if (!quiets) return captures;
    return Bitboard.combine_add(quiet, captures);
}

//legal movegen

//tests
test "knight" {
    var compare: Bitboard = Bitboard.init_single(10);
    compare.set(17);
    try std.testing.expectEqual(compare, precomp_knight[0]);
}

test "king" {
    var compare = Bitboard.init(0);
    compare.set(8);
    compare.set(10);
    compare.set(0);
    compare.set(1);
    compare.set(2);
    compare.set(16);
    compare.set(17);
    compare.set(18);
    try std.testing.expectEqual(compare, precomp_king[9]);
}

test "black pawn" {
    var compare = Bitboard.init(0);
    var pawn_pushes = [_]u6{ 40, 32 };
    compare.set_group(&pawn_pushes);
    try std.testing.expectEqual(compare, precomp_pawn_push_black[48]);

    var compare_caps = Bitboard.init(0);
    var pawn_captures = [_]u6{ 0, 2 };
    compare_caps.set_group(&pawn_captures);
    try std.testing.expectEqual(compare_caps, precomp_pawn_attack_black[9]);
}
