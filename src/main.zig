const std = @import("std");

const U64_1: u64 = 1; //ok this is kinda dumb

const PAWN: u3 = 0b001;
const KNIGHT: u3 = 0b010;
const BISHOP: u3 = 0b011;
const QUEEN: u3 = 0b100;
const ROOK: u3 = 0b101;
const KING: u3 = 0b110;

const Bitboard = struct {
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

    pub fn get(self: *Bitboard, square: u6) bool {
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
};

const Move = struct { start: u6, target: u6, ep: u6, castling: u4, piece: u3, white: bool };

const Board = struct {
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

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)

    std.debug.print("All your {s} are belong to us.\n", .{"pawns"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "board basics" {
    const board = Board.init();
    try std.testing.expectEqual(board, Board.init());
}

test "bitboard basics" {
    var bb = Bitboard.init(0);
    bb.set(4);
    try std.testing.expectEqual(bb, Bitboard.init(0b10000));
    try std.testing.expect(bb.get(4));
}
