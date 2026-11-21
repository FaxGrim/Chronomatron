`timescale 1ns / 1ps

module sevenseg_driver (
    input wire clk,
    input wire reset,
    input wire ms_tick,
    input wire [31:0] digits,
    output reg [6:0] seg_n,
    output reg [7:0] an_n,
    output wire dp_n
);
    reg [2:0] digit_index;
    reg [3:0] digit;
    reg [6:0] decoded;
    reg drive_digit;
    assign dp_n = 1'b1;

    always @* begin
        digit = digits[digit_index*4 +: 4];
        case (digit) // {g,f,e,d,c,b,a}, active low
            4'd0: decoded = 7'b1000000;
            4'd1: decoded = 7'b1111001;
            4'd2: decoded = 7'b0100100;
            4'd3: decoded = 7'b0110000;
            4'd4: decoded = 7'b0011001;
            4'd5: decoded = 7'b0010010;
            4'd6: decoded = 7'b0000010;
            4'd7: decoded = 7'b1111000;
            4'd8: decoded = 7'b0000000;
            4'd9: decoded = 7'b0010000;
            4'ha: decoded = 7'b0000110; // E
            4'hb: decoded = 7'b1000111; // L
            4'hc: decoded = 7'b0010010; // S
            default: decoded = 7'b1111111;
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            digit_index <= 0;
            seg_n <= 7'h7f;
            an_n <= 8'hff;
            drive_digit <= 0;
        end else if (ms_tick) begin
            an_n <= 8'hff;
            digit_index <= digit_index + 1'b1;
            drive_digit <= 1;
        end else if (drive_digit) begin
            seg_n <= decoded;
            an_n <= ~(8'b1 << digit_index);
            drive_digit <= 0;
        end
    end
endmodule
