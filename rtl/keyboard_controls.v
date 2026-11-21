`timescale 1ns / 1ps

module keyboard_controls (
    input wire clk,
    input wire reset,
    input wire ms_tick,
    input wire [7:0] byte_data,
    input wire byte_valid,
    output reg [7:0] color_press,
    output reg seed_valid,
    output reg [2:0] seed_value,
    output reg start_press,
    output reg restart_press,
    output reg keyboard_seen
);
    reg [17:0] held;
    reg release_key, extended;
    reg [2:0] prefix_age;
    reg [2:0] pause_bytes;
    reg [4:0] key_index;
    localparam [4:0] START_KEY = 16, RESTART_KEY = 17, UNMAPPED = 31;

    // PS/2 scan set 2. Index 0-7 is a color and 8-15 selects a seed.
    always @* begin
        case (byte_data)
            8'h16: key_index = 0;  8'h1e: key_index = 1;
            8'h26: key_index = 2;  8'h25: key_index = 3;
            8'h2e: key_index = 4;  8'h36: key_index = 5;
            8'h3d: key_index = 6;  8'h3e: key_index = 7;
            8'h05: key_index = 8;  8'h06: key_index = 9;
            8'h04: key_index = 10; 8'h0c: key_index = 11;
            8'h03: key_index = 12; 8'h0b: key_index = 13;
            8'h83: key_index = 14; 8'h0a: key_index = 15;
            8'h5a: key_index = START_KEY;
            8'h2d: key_index = RESTART_KEY;
            default: key_index = UNMAPPED;
        endcase
    end

    always @(posedge clk) begin
        if (reset) begin
            held <= 0;
            release_key <= 0;
            extended <= 0;
            prefix_age <= 0;
            pause_bytes <= 0;
            color_press <= 0;
            seed_valid <= 0;
            seed_value <= 0;
            start_press <= 0;
            restart_press <= 0;
            keyboard_seen <= 0;
        end else begin
            color_press <= 0;
            seed_valid <= 0;
            start_press <= 0;
            restart_press <= 0;

            if (byte_valid) begin
                prefix_age <= 0;
                if (byte_data == 8'haa) begin
                    // Device self-test. Clear stale key holds after reconnect.
                    held <= 0;
                    release_key <= 0;
                    extended <= 0;
                    pause_bytes <= 0;
                    keyboard_seen <= 0;
                end else if (pause_bytes != 0) begin
                    pause_bytes <= pause_bytes - 1'b1;
                end else if (byte_data == 8'he1) begin
                    pause_bytes <= 7;
                    release_key <= 0;
                    extended <= 0;
                end else if (byte_data == 8'he0) begin
                    extended <= 1;
                end else if (byte_data == 8'hf0) begin
                    release_key <= 1;
                end else begin
                    if ((!extended || key_index == START_KEY) && key_index != UNMAPPED) begin
                        keyboard_seen <= 1;
                        if (release_key) begin
                            held[key_index] <= 0;
                        end else if (!held[key_index]) begin
                            held[key_index] <= 1;
                            if (key_index < 8)
                                color_press[key_index[2:0]] <= 1;
                            else if (key_index < 16) begin
                                seed_valid <= 1;
                                seed_value <= key_index[2:0];
                            end else if (key_index == START_KEY)
                                start_press <= 1;
                            else
                                restart_press <= 1;
                        end
                    end
                    release_key <= 0;
                    extended <= 0;
                end
            end else if (ms_tick && (release_key || extended || pause_bytes != 0)) begin
                prefix_age <= prefix_age + 1'b1;
                if (&prefix_age) begin
                    release_key <= 0;
                    extended <= 0;
                    pause_bytes <= 0;
                end
            end
        end
    end
endmodule
