`timescale 1ns / 1ps

module clock_timer #(
    parameter integer CLOCKS_PER_MS = 100_000
) (
    input wire clk,
    input wire reset,
    output wire ms_tick,
    output wire pixel_tick
);
    localparam integer MS_WIDTH = CLOCKS_PER_MS > 1 ? $clog2(CLOCKS_PER_MS) : 1;
    localparam integer MS_LAST = CLOCKS_PER_MS - 1;
    reg [MS_WIDTH-1:0] ms_count;
    reg [1:0] pixel_count;

    assign ms_tick = ms_count == MS_LAST[MS_WIDTH-1:0];
    assign pixel_tick = pixel_count == 2'd3;

    always @(posedge clk) begin
        if (reset) begin
            ms_count <= 0;
            pixel_count <= 0;
        end else begin
            ms_count <= ms_tick ? {MS_WIDTH{1'b0}} : ms_count + 1'b1;
            pixel_count <= pixel_count + 1'b1;
        end
    end
endmodule
