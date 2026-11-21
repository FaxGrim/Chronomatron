`timescale 1ns / 1ps

module font5x7 (
    input wire [7:0] character,
    input wire [2:0] column, row,
    output wire pixel
);
    reg [34:0] glyph;
    wire [5:0] address = 6'd34 - ({row, 2'b00} + {3'b000, row} + {3'b000, column});
    assign pixel = column < 5 && row < 7 ? glyph[address] : 1'b0;

    // Seven rows, with the top-left pixel stored in bit 34.
    always @* begin
        case (character)
            "0": glyph = {5'h0e, 5'h11, 5'h13, 5'h15, 5'h19, 5'h11, 5'h0e};
            "1": glyph = {5'h04, 5'h0c, 5'h04, 5'h04, 5'h04, 5'h04, 5'h0e};
            "2": glyph = {5'h0e, 5'h11, 5'h01, 5'h02, 5'h04, 5'h08, 5'h1f};
            "3": glyph = {5'h1e, 5'h01, 5'h01, 5'h0e, 5'h01, 5'h01, 5'h1e};
            "4": glyph = {5'h02, 5'h06, 5'h0a, 5'h12, 5'h1f, 5'h02, 5'h02};
            "5": glyph = {5'h1f, 5'h10, 5'h10, 5'h1e, 5'h01, 5'h01, 5'h1e};
            "6": glyph = {5'h06, 5'h08, 5'h10, 5'h1e, 5'h11, 5'h11, 5'h0e};
            "7": glyph = {5'h1f, 5'h01, 5'h02, 5'h04, 5'h08, 5'h08, 5'h08};
            "8": glyph = {5'h0e, 5'h11, 5'h11, 5'h0e, 5'h11, 5'h11, 5'h0e};
            "9": glyph = {5'h0e, 5'h11, 5'h11, 5'h0f, 5'h01, 5'h02, 5'h0c};
            "A": glyph = {5'h0e, 5'h11, 5'h11, 5'h1f, 5'h11, 5'h11, 5'h11};
            "B": glyph = {5'h1e, 5'h11, 5'h11, 5'h1e, 5'h11, 5'h11, 5'h1e};
            "C": glyph = {5'h0e, 5'h11, 5'h10, 5'h10, 5'h10, 5'h11, 5'h0e};
            "D": glyph = {5'h1e, 5'h11, 5'h11, 5'h11, 5'h11, 5'h11, 5'h1e};
            "E": glyph = {5'h1f, 5'h10, 5'h10, 5'h1e, 5'h10, 5'h10, 5'h1f};
            "F": glyph = {5'h1f, 5'h10, 5'h10, 5'h1e, 5'h10, 5'h10, 5'h10};
            "G": glyph = {5'h0e, 5'h11, 5'h10, 5'h17, 5'h11, 5'h11, 5'h0f};
            "H": glyph = {5'h11, 5'h11, 5'h11, 5'h1f, 5'h11, 5'h11, 5'h11};
            "I": glyph = {5'h0e, 5'h04, 5'h04, 5'h04, 5'h04, 5'h04, 5'h0e};
            "J": glyph = {5'h07, 5'h02, 5'h02, 5'h02, 5'h02, 5'h12, 5'h0c};
            "K": glyph = {5'h11, 5'h12, 5'h14, 5'h18, 5'h14, 5'h12, 5'h11};
            "L": glyph = {5'h10, 5'h10, 5'h10, 5'h10, 5'h10, 5'h10, 5'h1f};
            "M": glyph = {5'h11, 5'h1b, 5'h15, 5'h15, 5'h11, 5'h11, 5'h11};
            "N": glyph = {5'h11, 5'h19, 5'h15, 5'h13, 5'h11, 5'h11, 5'h11};
            "O": glyph = {5'h0e, 5'h11, 5'h11, 5'h11, 5'h11, 5'h11, 5'h0e};
            "P": glyph = {5'h1e, 5'h11, 5'h11, 5'h1e, 5'h10, 5'h10, 5'h10};
            "Q": glyph = {5'h0e, 5'h11, 5'h11, 5'h11, 5'h15, 5'h12, 5'h0d};
            "R": glyph = {5'h1e, 5'h11, 5'h11, 5'h1e, 5'h14, 5'h12, 5'h11};
            "S": glyph = {5'h0f, 5'h10, 5'h10, 5'h0e, 5'h01, 5'h01, 5'h1e};
            "T": glyph = {5'h1f, 5'h04, 5'h04, 5'h04, 5'h04, 5'h04, 5'h04};
            "U": glyph = {5'h11, 5'h11, 5'h11, 5'h11, 5'h11, 5'h11, 5'h0e};
            "V": glyph = {5'h11, 5'h11, 5'h11, 5'h11, 5'h11, 5'h0a, 5'h04};
            "W": glyph = {5'h11, 5'h11, 5'h11, 5'h15, 5'h15, 5'h15, 5'h0a};
            "X": glyph = {5'h11, 5'h11, 5'h0a, 5'h04, 5'h0a, 5'h11, 5'h11};
            "Y": glyph = {5'h11, 5'h11, 5'h0a, 5'h04, 5'h04, 5'h04, 5'h04};
            "Z": glyph = {5'h1f, 5'h01, 5'h02, 5'h04, 5'h08, 5'h10, 5'h1f};
            "/": glyph = {5'h01, 5'h01, 5'h02, 5'h04, 5'h08, 5'h10, 5'h10};
            default: glyph = 0;
        endcase
    end
endmodule
