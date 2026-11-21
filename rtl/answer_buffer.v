`timescale 1ns / 1ps

module answer_buffer (
    input wire clk,
    input wire reset,
    input wire clear,
    input wire accept,
    input wire [7:0] candidates,
    output wire multiple,
    output reg [23:0] answer,
    output reg [3:0] count,
    output reg [7:0] used
);
    wire [7:0] new_colors = candidates & ~used;
    reg [2:0] color_id;
    integer i;

    assign multiple = (new_colors & (new_colors - 8'd1)) != 8'd0;

    integer bit_index;

    always @* begin
        color_id = 0;
        for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1)
            if (new_colors[bit_index])
                color_id = bit_index[2:0];
    end

    always @(posedge clk) begin
        if (reset || clear) begin
            used <= 0;
            count <= 0;
            answer <= 0;
        end else if (accept && new_colors != 0 && !multiple && count < 8) begin
            for (i = 0; i < 8; i = i + 1)
                if (count == i[3:0])
                    answer[i*3 +: 3] <= color_id;
            used <= used | new_colors;
            count <= count + 1'b1;
        end
    end
endmodule
