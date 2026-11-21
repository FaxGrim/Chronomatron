`timescale 1ns / 1ps

module ps2_receiver #(
    parameter integer FRAME_TIMEOUT = 200_000
) (
    input wire clk,
    input wire reset,
    input wire ps2_clk,
    input wire ps2_data,
    output reg [7:0] byte_data,
    output reg byte_valid
);
    localparam integer TIMEOUT_WIDTH = FRAME_TIMEOUT > 1 ? $clog2(FRAME_TIMEOUT) : 1;
    localparam integer TIMEOUT_LAST = FRAME_TIMEOUT - 1;
    (* ASYNC_REG = "TRUE" *) reg clk_first, clk_sync;
    (* ASYNC_REG = "TRUE" *) reg data_first, data_sync;
    reg [7:0] clock_history;
    reg filtered_clk, previous_clk;
    reg [3:0] bit_number;
    reg [7:0] shift_byte;
    reg parity_ok;
    reg [TIMEOUT_WIDTH-1:0] silence_count;
    wire falling = previous_clk && !filtered_clk;

    always @(posedge clk) begin
        if (reset) begin
            clk_first <= 1;
            clk_sync <= 1;
            data_first <= 1;
            data_sync <= 1;
            clock_history <= 8'hff;
            filtered_clk <= 1;
            previous_clk <= 1;
            bit_number <= 0;
            shift_byte <= 0;
            parity_ok <= 0;
            silence_count <= 0;
            byte_data <= 0;
            byte_valid <= 0;
        end else begin
            clk_first <= ps2_clk;
            clk_sync <= clk_first;
            data_first <= ps2_data;
            data_sync <= data_first;
            clock_history <= {clock_history[6:0], clk_sync};
            if (&clock_history)
                filtered_clk <= 1;
            if (~|clock_history)
                filtered_clk <= 0;
            previous_clk <= filtered_clk;
            byte_valid <= 0;

            if (falling) begin
                silence_count <= 0;
                case (bit_number)
                    4'd0: if (!data_sync) bit_number <= 1;
                    4'd9: begin
                        parity_ok <= (^shift_byte) ^ data_sync;
                        bit_number <= 10;
                    end
                    4'd10: begin
                        if (parity_ok && data_sync) begin
                            byte_data <= shift_byte;
                            byte_valid <= 1;
                        end
                        bit_number <= 0;
                    end
                    default: begin
                        shift_byte <= {data_sync, shift_byte[7:1]};
                        bit_number <= bit_number + 1'b1;
                    end
                endcase
            end else if (bit_number != 0) begin
                if (silence_count == TIMEOUT_LAST[TIMEOUT_WIDTH-1:0]) begin
                    silence_count <= 0;
                    bit_number <= 0;
                end else begin
                    silence_count <= silence_count + 1'b1;
                end
            end
        end
    end
endmodule
