const Chess = @import("chess.zig");
const Bitboard = @import("bitboard.zig").Bitboard;

const KNIGHT_DIRECTIONS = []u6{ 15, 17, 10, 6 };

//TODO write test for this

comptime precomputed_knight_moves: []Bitboard = precompute: {
    const result = [64]Bitboard{Bitboard.init()} ** 64;
    for (0..64) |square| {
        for (KNIGHT_DIRECTIONS) |dir| {
            const target_add = square + dir;
            const target_sub = square - dir;
            if (target_add < 64) result[square].set(target_add);
            if (target_sub >= 0) result[square].set(target_sub);
        }
    }
    break :precompute result;
}
