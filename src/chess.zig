const std = @import("std");
const Bitboard = @import("bitboard.zig").Bitboard;

pub const PAWN: u3 = 0b001;
pub const KNIGHT: u3 = 0b010;
pub const BISHOP: u3 = 0b011;
pub const QUEEN: u3 = 0b100;
pub const ROOK: u3 = 0b101;
pub const KING: u3 = 0b110;

pub const Move = struct { start: u6, target: u6, ep: u6, castling: u4, piece: u3, white: bool };

pub const Board = struct {
    white_pieces: Bitboard = Bitboard.init(0),
    black_pieces: Bitboard = Bitboard.init(0),
    ortho_sliders: Bitboard = Bitboard.init(0),
    dia_sliders: Bitboard = Bitboard.init(0),
    pawns: Bitboard = Bitboard.init(0),
    white_king: u6 = 0,
    black_king: u6 = 63,
    ep: u6 = 0,
    castling: u4 = 0b1111,
    whites_turn: bool = true,

    pub fn init() Board {
        return Board{};
    }

    fn set(self: *Board, square: u6, piece: u3, white: bool) void {
        if (white) {
            self.white_pieces.set(square);
            self.black_pieces.rm(square);
        } else {
            self.black_pieces.set(square);
            self.white_pieces.rm(square);
        }
        switch (piece) {
            BISHOP, QUEEN => {
                self.dia_sliders.set(square);
            },
            ROOK, QUEEN => {
                self.ortho_sliders.set(square);
            },
            PAWN => {
                self.pawns.set(square);
            },
            KING => {
                if (white) self.white_king = square else self.black_king = square;
            },
            else => {
                unreachable;
            },
        }
    }

    pub fn init_fen(fen: *const []u8) Board {
        _ = fen;
        unreachable;
    }

    pub fn domove(self: *Board, move: Move) void {
        _ = self;
        _ = move;
        unreachable;
    }

    pub fn unmove(self: *Board, move: Move) void {
        _ = self;
        _ = move;
        unreachable;
    }
};

test "board basics" {
    const board = Board.init();
    try std.testing.expectEqual(board, Board.init());
}
