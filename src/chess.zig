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

    fn occupied(self: *Board) Bitboard {
        return Bitboard.combine_add(&self.white_pieces, &self.black_pieces);
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
            BISHOP => {
                self.dia_sliders.set(square);
            },
            ROOK => {
                self.ortho_sliders.set(square);
            },
            QUEEN => {
                self.dia_sliders.set(square);
                self.ortho_sliders.set(square);
            },
            PAWN => {
                self.pawns.set(square);
            },
            KING => {
                if (white) self.white_king = square else self.black_king = square;
            },
            KNIGHT => {},
            else => {
                unreachable;
            },
        }
    }

    fn has_piece(self: *Board, square: u6) bool {
        return self.occupied().get(square);
    }

    fn get_piece(self: *Board, square: u6) u3 {
        if (self.pawns.get(square)) return PAWN;
        if (self.black_king == square or self.white_king == square) return KING;
        const dia_slider = self.dia_sliders.get(square);
        const ortho_slider = self.ortho_sliders.get(square);
        if (dia_slider and ortho_slider) return QUEEN;
        if (dia_slider) return BISHOP;
        if (ortho_slider) return ROOK;
        if (self.occupied().get(square)) return KNIGHT;
        return 0;
    }

    //be very careful about not calling this for an empty space,
    //the occupied check will be removed for speed at some point
    fn get_color(self: *Board, square: u6) bool {
        if (!self.occupied().get(square)) unreachable;
        return self.white_pieces.get(square);
    }

    fn piece_from_char(c: u8) u3 {
        return switch (c) {
            'p', 'P' => PAWN,
            'n', 'N' => KNIGHT,
            'b', 'B' => BISHOP,
            'r', 'R' => ROOK,
            'q', 'Q' => QUEEN,
            'k', 'K' => KING,
            else => 0,
        };
    }

    fn color_from_char(c: u8) bool {
        return switch (c) {
            'p', 'n', 'b', 'r', 'q', 'k' => false,
            'P', 'N', 'B', 'R', 'Q', 'K' => true,
            else => unreachable,
        };
    }

    pub fn init_fen(fen: []const u8) Board {
        var result = Board.init();
        var row: u6 = 0;
        var col: u6 = 0;

        var fen_index: usize = 0;

        while (fen_index < fen.len and row < 8) : (fen_index += 1) {
            const char = fen[fen_index];
            switch (char) {
                '1'...'8' => {
                    col += @intCast(char - '0');
                },
                '/' => {
                    row += 1;
                    col = 0;
                },
                'p', 'n', 'b', 'r', 'q', 'k', 'P', 'N', 'B', 'R', 'Q', 'K' => {
                    const square = (7 - row) * 8 + col;
                    result.set(square, piece_from_char(char), color_from_char(char));
                    std.debug.print("\n{c} at {d}", .{ char, square });

                    col += 1;
                },
                else => {
                    std.debug.print("{--c--}", .{char});
                    break;
                },
            }
        }
        return result;
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
    var board2 = Board.init_fen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1");
    try std.testing.expectEqual(board2.get_piece(0), ROOK);
    try std.testing.expectEqual(board2.get_color(0), true);
}
