`timescale 1ns / 1ps
`include "game_states.vh"

module tb_video;
    reg clk = 0;
    always #5 clk = ~clk;
    reg reset = 1;
    wire pixel_tick, ms_tick;
    wire [9:0] x, y;
    wire active_video, hsync, vsync, frame_end;

    clock_timer timer (.clk(clk), .reset(reset), .ms_tick(ms_tick), .pixel_tick(pixel_tick));
    vga_sync sync (
        .clk(clk), .reset(reset), .pixel_tick(pixel_tick), .x(x), .y(y),
        .active_video(active_video), .hsync(hsync), .vsync(vsync), .frame_end(frame_end)
    );

    reg [9:0] render_x = 0, render_y = 0;
    reg render_capture = 0;
    reg [3:0] state = `CM_MENU;
    reg [2:0] color_id = 0;
    wire [11:0] rgb;
    game_renderer renderer (
        .clk(clk), .reset(reset), .frame_end(render_capture), .x(render_x), .y(render_y),
        .state(state), .seed(3'd2), .level(3'd7), .countdown(2'd3),
        .color_id(color_id), .show_index(3'd2), .answer_count(4'd3),
        .used(8'h07), .failed_at(4'd3), .streak(4'd2),
        .total_wins(12'h089), .keyboard_seen(1'b1), .rgb(rgb)
    );

    task capture;
        input [3:0] new_state;
        input [2:0] color;
        begin
            state = new_state;
            color_id = color;
            render_capture = 1;
            @(negedge clk);
            render_capture = 0;
        end
    endtask

    task expect_pixel;
        input [9:0] at_x, at_y;
        input [11:0] expected_rgb;
        begin
            render_x = at_x;
            render_y = at_y;
            repeat (4) @(negedge clk);
            if (rgb !== expected_rgb)
                $fatal(1, "Pixel (%0d, %0d): expected %h, got %h", at_x, at_y, expected_rgb, rgb);
        end
    endtask

    reg scan_tick = 0;
    wire [6:0] seg_n;
    wire [7:0] an_n;
    wire dp_n;
    sevenseg_driver sevenseg (
        .clk(clk), .reset(reset), .ms_tick(scan_tick), .digits(32'h76543210),
        .seg_n(seg_n), .an_n(an_n), .dp_n(dp_n)
    );

    integer i, line, column, vga_ticks, active_pixels, low_hsync, low_vsync;
    reg [6:0] seg_ref [0:7];
    localparam PRINT_WIDTH = 640;
    localparam PRINT_HEIGHT = 480;
    initial begin
        seg_ref[0] = 7'h40; seg_ref[1] = 7'h79; seg_ref[2] = 7'h24; seg_ref[3] = 7'h30;
        seg_ref[4] = 7'h19; seg_ref[5] = 7'h12; seg_ref[6] = 7'h02; seg_ref[7] = 7'h78;
        repeat (4) @(negedge clk);
        reset = 0;
        fork
            begin
                vga_ticks = 0;
                active_pixels = 0;
                low_hsync = 0;
                low_vsync = 0;
                for (line = 0; line < 525; line = line + 1) begin
                    for (column = 0; column < 800; column = column + 1) begin
                        repeat (3) begin
                            if (pixel_tick !== 0) $fatal(1, "Pixel enable asserted too early");
                            @(negedge clk);
                        end
                        if (!pixel_tick || x !== column[9:0] || y !== line[9:0])
                            $fatal(1, "Raster position failed at (%0d, %0d)", column, line);
                        if (frame_end !== (column == 799 && line == 524))
                            $fatal(1, "Unexpected frame end");
                        if (active_video !== (column < PRINT_WIDTH && line < PRINT_HEIGHT) ||
                            hsync !== !(column >= 656 && column < 752) ||
                            vsync !== !(line >= 490 && line < 492))
                            $fatal(1, "Invalid VGA timing at (%0d, %0d)", column, line);
                        vga_ticks = vga_ticks + 1;
                        if (active_video) active_pixels = active_pixels + 1;
                        if (!hsync) low_hsync = low_hsync + 1;
                        if (!vsync) low_vsync = low_vsync + 1;
                        @(negedge clk);
                    end
                end
                if (vga_ticks != 420000 || active_pixels != 307200 ||
                    low_hsync != 50400 || low_vsync != 1600 || x !== 0 || y !== 0)
                    $fatal(1, "Invalid full-frame totals");
            end
            begin
                capture(`CM_SHOW, 3'd2);
                expect_pixel(300, 200, 12'hfe3);
                expect_pixel(32, 128, 12'heef);
                expect_pixel(68, 402, 12'hf43);
                expect_pixel(132, 402, 12'h47f);
                expect_pixel(196, 402, 12'hfe3);
                expect_pixel(260, 402, 12'h3d5);
                expect_pixel(324, 402, 12'ha5e);
                expect_pixel(388, 402, 12'hf83);
                expect_pixel(452, 402, 12'h3dc);
                expect_pixel(516, 402, 12'hf8c);
                expect_pixel(68, 418, 12'heef);
                expect_pixel(516, 418, 12'h112);
                // Inputs change now, but the renderer must keep the current frame.
                state = `CM_INPUT;
                expect_pixel(300, 200, 12'hfe3);
                capture(`CM_INPUT, 3'd2);
                expect_pixel(300, 200, 12'h223);
                expect_pixel(68, 294, 12'h6e8);
                capture(`CM_COUNTDOWN, 0);
                expect_pixel(304, 192, 12'h5ed);
                capture(`CM_WRONG, 0);
                expect_pixel(32, 128, 12'hf76);
                capture(`CM_COMPLETE, 0);
                expect_pixel(34, 128, 12'h6e8);

                for (i = 1; i <= 8; i = i + 1) begin
                    scan_tick = 1;
                    @(negedge clk);
                    if (an_n !== 8'hff) $fatal(1, "Digits were not blanked before switching");
                    scan_tick = 0;
                    @(negedge clk);
                    if (an_n !== ~(8'b1 << (i % 8)) || seg_n !== seg_ref[i % 8] || !dp_n)
                        $fatal(1, "Incorrect seven-segment output");
                end
            end
        join
        $display("PASS: full VGA frame, renderer/palette, frame snapshot, seven-segment outputs");
        $finish;
    end
endmodule
