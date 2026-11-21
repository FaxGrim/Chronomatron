`timescale 1ns / 1ps

module answer_checker (
    input wire [23:0] expected,
    input wire [23:0] answer,
    output wire correct,
    output reg [3:0] wrong_position
);
    assign correct = wrong_position == 0;

    // Compare slot 0 first in the result. Zero means all slots matched.
    integer i;

    always @* begin
        wrong_position = 0;
        for (i = 7; i >= 0; i = i - 1)
            if (expected[i*3 +: 3] != answer[i*3 +: 3])
                wrong_position = i[3:0] + 1'b1;
    end
endmodule
