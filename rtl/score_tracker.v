`timescale 1ns / 1ps

module score_tracker (
    input wire clk,
    input wire reset,
    input wire level_passed,
    input wire reset_streak,
    output reg [3:0] streak,
    output reg [11:0] total_wins
);
    always @(posedge clk) begin
        if (reset) begin
            streak <= 0;
            total_wins <= 0;
        end else begin
            if (reset_streak)
                streak <= 0;
            else if (level_passed && streak < 8)
                streak <= streak + 1'b1;

            // BCD keeps the two displays simple. Saturate at 999.
            if (level_passed && total_wins != 12'h999) begin
                if (total_wins[3:0] == 9) begin
                    total_wins[3:0] <= 0;
                    if (total_wins[7:4] == 9) begin
                        total_wins[7:4] <= 0;
                        total_wins[11:8] <= total_wins[11:8] + 1'b1;
                    end else begin
                        total_wins[7:4] <= total_wins[7:4] + 1'b1;
                    end
                end else begin
                    total_wins[3:0] <= total_wins[3:0] + 1'b1;
                end
            end
        end
    end
endmodule
