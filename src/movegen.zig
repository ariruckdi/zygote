const std = @import("std");
const Chess = @import("chess.zig");
const Bitboard = @import("bitboard.zig").Bitboard;

const KNIGHT_DIRECTIONS = [_]u6{ 15, 17, 10, 6 };
const NEAREST_SQUARES = [_]i8{ 1, 8, -1, -8, 9, 7, -9, -7 };
const WHITE_PAWN_ATTACKS = [_]i8{ 7, 9 };
const BLACK_PAWN_ATTACKS = [_]i8{ -9, -7 };

//helpers
fn dx(square1: u6, square2: u6) i8 {
    return @as(i8, (square2 % 8)) - @as(i8, (square1 % 8));
}

fn dy(square1: u6, square2: u6) i8 {
    return @as(i8, (square2 / 8)) - @as(i8, (square1 / 8));
}

fn valid_knight_deltas(square: u6, target: u6) bool {
    if (@abs(dx(square, target)) == 1 and @abs(dy(square, target)) == 2) return true;
    if (@abs(dx(square, target)) == 2 and @abs(dy(square, target)) == 1) return true;
    return false;
}

fn valid_neighbor(square: u6, target: u6) bool {
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
const positive_rays = [4][64]Bitboard{ precomp_ray_N, precomp_ray_E, precomp_ray_NE, precomp_ray_NW };
const negative_rays = [4][64]Bitboard{ precomp_ray_S, precomp_ray_W, precomp_ray_SE, precomp_ray_SW };
const precomp_rays = [8][64]Bitboard{ precomp_ray_N, precomp_ray_E, precomp_ray_S, precomp_ray_W, precomp_ray_NE, precomp_ray_SE, precomp_ray_SW, precomp_ray_NW };

fn dump_precomp_data(data: *const [64]Bitboard) void {
    std.debug.print("\n", .{});
    for (data) |bb| {
        std.debug.print("\n{s}", .{bb.to_string()});
    }
}

//pseudo legal movegen
fn knight_moves(square: u6, board: *const Chess.Board, white: bool, quiets: bool) Bitboard {
    const captures = Bitboard.combine_overlap(precomp_knight[square], board.them(white));
    if (!quiets) return captures;

    const quiet = Bitboard.combine_sub(precomp_knight[square], board.occupied());
    return Bitboard.combine_add(quiet, captures);
}

fn pawn_captures(square: u6, board: *const Chess.Board, white: bool) Bitboard {
    const precomp_to_use = if (white) precomp_pawn_attack_white[square] else precomp_pawn_attack_black[square];
    return Bitboard.combine_overlap(precomp_to_use, board.them(white));
}

fn pawn_pushes(square: u6, board: *const Chess.Board, white: bool) Bitboard {
    const precomp_to_use = if (white) precomp_pawn_push_white[square] else precomp_pawn_push_black[square];
    const result = Bitboard.combine_sub(precomp_to_use, board.occupied());
    if (result.bitscan_trailing() == result.bitscan_leading()) { //result is single, might be invalid
        if (@abs(dy(result.bitscan_trailing(), @intCast(square))) == 2) { //we jumped one, discard result
            return Bitboard.init(0);
        }
    }
    return result;
}

fn pawn_moves(square: u6, board: *const Chess.Board, white: bool) Bitboard {
    var captures = pawn_captures(square, board, white);
    const pushes = pawn_pushes(square, board, white);
    const ep = Bitboard.init_single(board.ep);
    if (board.ep != 0) captures.add(ep);
    return Bitboard.combine_add(captures, pushes);
}

fn king_moves(square: u6, board: *const Chess.Board, white: bool, quiets: bool) Bitboard {
    const captures = Bitboard.combine_overlap(precomp_king[square], board.them(white));
    const all_moves = Bitboard.combine_sub(precomp_king[square], board.us(white));
    if (!quiets) {
        return captures;
    } else {
        return all_moves;
    }
}

//dir is between 0 and 3, 0 and 1 are ortho, 2 and 3 dia
fn _positive_ray_moves(square: u6, board: *const Chess.Board, dir: usize, white: bool) Bitboard {
    var result = positive_rays[dir][square];
    const blocker = Bitboard.combine_overlap(result, board.occupied());
    if (blocker.not_empty()) {
        const blocker_square = blocker.bitscan_trailing();
        result.xor(positive_rays[dir][blocker_square]);
        result.sub(board.us(white));
    }
    return result;
}

fn _negative_ray_moves(square: u6, board: *const Chess.Board, dir: usize, white: bool) Bitboard {
    var result = negative_rays[dir][square];
    const blocker = Bitboard.combine_overlap(result, board.occupied());
    if (blocker.not_empty()) {
        const blocker_square = blocker.bitscan_leading();
        result.xor(negative_rays[dir][blocker_square]);
        result.sub(board.us(white));
    }
    return result;
}

fn _positive_ray_captures(square: u6, board: *const Chess.Board, dir: usize, white: bool) Bitboard {
    const ray = positive_rays[dir][square];
    const blocker = Bitboard.combine_overlap(ray, board.occupied());
    if (blocker.is_empty()) {
        return Bitboard.init(0);
    } else {
        const blocker_square = blocker.bitscan_trailing();
        return Bitboard.combine_overlap(board.them(white), Bitboard.init_single(blocker_square));
    }
}

fn _negative_ray_captures(square: u6, board: *const Chess.Board, dir: usize, white: bool) Bitboard {
    const ray = negative_rays[dir][square];
    const blocker = Bitboard.combine_overlap(ray, board.occupied());
    if (blocker.is_empty()) {
        return Bitboard.init(0);
    } else {
        const blocker_square = blocker.bitscan_leading();
        return Bitboard.combine_overlap(board.them(white), Bitboard.init_single(blocker_square));
    }
}

fn slider_moves_ortho(square: u6, board: *const Chess.Board, white: bool) Bitboard {
    //north-south
    const north = _positive_ray_moves(square, board, 0, white);
    const south = _negative_ray_moves(square, board, 0, white);
    const ns = Bitboard.combine_add(north, south);
    //east-west
    const east = _positive_ray_moves(square, board, 1, white);
    const west = _negative_ray_moves(square, board, 1, white);
    const ew = Bitboard.combine_add(east, west);

    return Bitboard.combine_add(ns, ew);
}

fn slider_moves_dia(square: u6, board: *const Chess.Board, white: bool) Bitboard {
    //ne-se
    const ne = _positive_ray_moves(square, board, 2, white);
    const se = _negative_ray_moves(square, board, 2, white);
    const nese = Bitboard.combine_add(ne, se);
    //nw-sw
    const nw = _positive_ray_moves(square, board, 3, white);
    const sw = _negative_ray_moves(square, board, 3, white);
    const nwsw = Bitboard.combine_add(nw, sw);

    return Bitboard.combine_add(nese, nwsw);
}

fn slider_captures_ortho(square: u6, board: *const Chess.Board, white: bool) Bitboard {
    //north-south
    const north = _positive_ray_captures(square, board, 0, white);
    const south = _negative_ray_captures(square, board, 0, white);
    const ns = Bitboard.combine_add(north, south);
    //east-west
    const east = _positive_ray_captures(square, board, 1, white);
    const west = _negative_ray_captures(square, board, 1, white);
    const ew = Bitboard.combine_add(east, west);

    return Bitboard.combine_add(ns, ew);
}

fn slider_captures_dia(square: u6, board: *const Chess.Board, white: bool) Bitboard {
    //ne-se
    const ne = _positive_ray_captures(square, board, 2, white);
    const se = _negative_ray_captures(square, board, 2, white);
    const nese = Bitboard.combine_add(ne, se);
    //nw-sw
    const nw = _positive_ray_captures(square, board, 3, white);
    const sw = _negative_ray_captures(square, board, 3, white);
    const nwsw = Bitboard.combine_add(nw, sw);

    return Bitboard.combine_add(nese, nwsw);
}

//legal movegen

//BUG this is slow and should not be called in final
fn pseudo_moves_at_square(square: u6, board: *const Chess.Board) Bitboard {
    const piece = board.get_piece(square);
    const white = board.white_piece_on_sqare(square);
    switch (piece) {
        Chess.PAWN => {
            return pawn_moves(square, board, white);
        },
        Chess.KNIGHT => {
            return knight_moves(square, board, white, true);
        },
        Chess.BISHOP => {
            return slider_moves_dia(square, board, white);
        },
        Chess.ROOK => {
            return slider_moves_ortho(square, board, white);
        },
        Chess.QUEEN => {
            const dia = slider_moves_dia(square, board, white);
            const ortho = slider_moves_ortho(square, board, white);
            return Bitboard.combine_add(dia, ortho);
        },
        Chess.KING => {
            return king_moves(square, board, white, true);
        },
        else => {
            unreachable;
        },
    }
}

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
    var pawn_push = [_]u6{ 40, 32 };
    compare.set_group(&pawn_push);
    try std.testing.expectEqual(compare, precomp_pawn_push_black[48]);

    var compare_caps = Bitboard.init(0);
    var pawn_caps = [_]u6{ 0, 2 };
    compare_caps.set_group(&pawn_caps);
    try std.testing.expectEqual(compare_caps, precomp_pawn_attack_black[9]);
}

test "knight in start pos" {
    var board = Chess.Board.init_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
    try std.testing.expectEqual(Chess.KNIGHT, board.get_piece(1));
    try std.testing.expectEqual(true, board.white_piece_on_sqare(1));
    std.debug.print("\n{s}", .{knight_moves(1, &board, true, true).to_string()});
}

test "initial possible movecount" {
    const board = Chess.Board.init_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
    var count: u8 = 0;
    for (0..17) |square| {
        if (board.no_piece(@truncate(square))) {
            continue;
        }
        count += pseudo_moves_at_square(@truncate(square), &board).popcount();
    }
    try std.testing.expectEqual(20, count);
}
