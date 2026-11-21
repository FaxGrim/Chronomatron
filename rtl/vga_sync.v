`timescale 1ns / 1ps

module vga_sync (
    input wire clk,
    input wire reset,
    input wire pixel_tick,
    output reg [9:0] x,
    output reg [9:0] y,
    output wire active_video,
    output wire hsync,
    output wire vsync,
    output wire frame_end
);
    assign active_video = x < 640 && y < 480;
    assign hsync = !(x >= 656 && x < 752);
    assign vsync = !(y >= 490 && y < 492);
    assign frame_end = pixel_tick && x == 799 && y == 524;

    always @(posedge clk) begin
        if (reset) begin
            x <= 0;
            y <= 0;
        end else if (pixel_tick) begin
            if (x == 799) begin
                x <= 0;
                y <= y == 524 ? 10'd0 : y + 1'b1;
            end else begin
                x <= x + 1'b1;
            end
        end
    end
endmodule
