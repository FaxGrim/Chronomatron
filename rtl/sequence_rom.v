`timescale 1ns / 1ps
// Generated from data/patterns.csv by scripts/generate_patterns.py.
module sequence_rom (
    input wire [2:0] seed, level,
    output reg [23:0] pattern
);
    // ROM address = {seed, zero-based level}. The first color occupies bits [2:0].
    always @* begin
        case ({seed, level})
            6'd0 : pattern = 24'h99714b; // 3 1 5 0 7 2 6 4
            6'd1 : pattern = 24'h1e62ab; // 3 5 2 1 6 4 7 0
            6'd2 : pattern = 24'hd291da; // 2 3 7 0 1 5 4 6
            6'd3 : pattern = 24'hf2e0d1; // 1 2 3 0 6 5 4 7
            6'd4 : pattern = 24'h1a9ea3; // 3 4 2 7 1 5 6 0
            6'd5 : pattern = 24'h1d9d2a; // 2 5 4 6 1 3 7 0
            6'd6 : pattern = 24'ha39d1a; // 2 3 4 6 1 7 0 5
            6'd7 : pattern = 24'hd7831a; // 2 3 4 1 0 7 5 6
            6'd8 : pattern = 24'h8730af; // 7 5 2 0 3 6 1 4
            6'd9 : pattern = 24'h7f0315; // 5 2 4 1 0 6 7 3
            6'd10: pattern = 24'hea6a58; // 0 3 1 5 6 4 2 7
            6'd11: pattern = 24'hef0362; // 2 4 5 1 0 6 3 7
            6'd12: pattern = 24'he630b5; // 5 6 2 0 3 4 1 7
            6'd13: pattern = 24'h1b96ac; // 4 5 2 3 1 7 6 0
            6'd14: pattern = 24'h4f4f48; // 0 1 5 7 4 6 3 2
            6'd15: pattern = 24'he54c1d; // 5 3 0 6 4 2 1 7
            6'd16: pattern = 24'hb390d6; // 6 2 3 0 1 7 4 5
            6'd17: pattern = 24'hbc239c; // 4 3 6 1 2 0 7 5
            6'd18: pattern = 24'h997159; // 1 3 5 0 7 2 6 4
            6'd19: pattern = 24'hab405f; // 7 3 1 0 4 6 2 5
            6'd20: pattern = 24'h85662f; // 7 5 0 3 6 2 1 4
            6'd21: pattern = 24'hd191ea; // 2 5 7 0 1 3 4 6
            6'd22: pattern = 24'h8bdcc1; // 1 0 3 6 5 7 2 4
            6'd23: pattern = 24'h741cbc; // 4 7 2 6 1 0 5 3
            6'd24: pattern = 24'hc6c09f; // 7 3 2 0 4 5 1 6
            6'd25: pattern = 24'hae2c47; // 7 0 1 6 2 4 3 5
            6'd26: pattern = 24'h791e25; // 5 4 0 7 1 2 6 3
            6'd27: pattern = 24'h1a7655; // 5 2 1 3 7 4 6 0
            6'd28: pattern = 24'h63ea62; // 2 4 1 5 6 7 0 3
            6'd29: pattern = 24'h307cd5; // 5 2 3 6 7 0 4 1
            6'd30: pattern = 24'he3435a; // 2 3 5 1 4 6 0 7
            6'd31: pattern = 24'h8a91de; // 6 3 7 0 1 5 2 4
            6'd32: pattern = 24'hd591d4; // 4 2 7 0 1 3 5 6
            6'd33: pattern = 24'hf71423; // 3 4 0 2 1 6 5 7
            6'd34: pattern = 24'hace1d4; // 4 2 7 0 6 1 3 5
            6'd35: pattern = 24'hdd521c; // 4 3 0 1 5 2 7 6
            6'd36: pattern = 24'h328c9f; // 7 3 2 6 0 5 4 1
            6'd37: pattern = 24'he4599a; // 2 3 6 4 5 0 1 7
            6'd38: pattern = 24'hb814fc; // 4 7 3 2 1 0 6 5
            6'd39: pattern = 24'h1e635a; // 2 3 5 1 6 4 7 0
            6'd40: pattern = 24'h2d617c; // 4 7 5 0 6 2 3 1
            6'd41: pattern = 24'h74c0b7; // 7 6 2 0 4 1 5 3
            6'd42: pattern = 24'h8bb370; // 0 6 5 1 3 7 2 4
            6'd43: pattern = 24'h3dad44; // 4 0 5 6 2 3 7 1
            6'd44: pattern = 24'hbb8654; // 4 2 1 3 0 7 6 5
            6'd45: pattern = 24'h9d3075; // 5 6 1 0 3 2 7 4
            6'd46: pattern = 24'h872af8; // 0 7 3 5 2 6 1 4
            6'd47: pattern = 24'h74cdd0; // 0 2 7 6 4 1 5 3
            6'd48: pattern = 24'h744f91; // 1 2 6 7 4 0 5 3
            6'd49: pattern = 24'hb185ce; // 6 1 7 2 0 3 4 5
            6'd50: pattern = 24'he0d7a2; // 2 4 6 3 5 1 0 7
            6'd51: pattern = 24'hde214b; // 3 1 5 0 2 4 7 6
            6'd52: pattern = 24'hd502e7; // 7 4 3 1 0 2 5 6
            6'd53: pattern = 24'h3c38ae; // 6 5 2 4 3 0 7 1
            6'd54: pattern = 24'hde54c1; // 1 0 3 2 5 4 7 6
            6'd55: pattern = 24'h639cac; // 4 5 2 6 1 7 0 3
            6'd56: pattern = 24'hee2c0d; // 5 1 0 6 2 4 3 7
            6'd57: pattern = 24'h7c1ba2; // 2 4 6 5 1 0 7 3
            6'd58: pattern = 24'h65613d; // 5 7 4 0 6 2 1 3
            6'd59: pattern = 24'h811eee; // 6 5 3 7 1 2 0 4
            6'd60: pattern = 24'h5f50e1; // 1 4 3 0 5 6 7 2
            6'd61: pattern = 24'h3f095a; // 2 3 5 4 0 6 7 1
            6'd62: pattern = 24'hfaa10b; // 3 1 4 0 2 5 6 7
            6'd63: pattern = 24'h563387; // 7 0 6 1 3 4 5 2
            default: pattern = 0;
        endcase
    end
endmodule
