`timescale 1ns / 1ps
`include "game_states.vh"

module chronomatron_top #(
    parameter integer CLOCKS_PER_MS = 100_000,
    parameter integer DEBOUNCE_MS = 12,
    parameter [15:0] COUNTDOWN_MS = 1000,
    parameter [15:0] FIRST_COLOR_MS = 1500,
    parameter [15:0] COLOR_STEP_MS = 100,
    parameter [15:0] GAP_MS = 180
) (
    input wire CLK100MHZ,
    input wire CPU_RESETN,
    input wire [10:0] SW,
    input wire BTND, BTNC,
    input wire PS2_CLK, PS2_DATA,
    output reg [3:0] VGA_R, VGA_G, VGA_B,
    output reg VGA_HS, VGA_VS,
    output wire [6:0] SEG_N,
    output wire DP_N,
    output wire [7:0] AN_N,
    output wire [15:0] LED
);
    wire clk = CLK100MHZ;
    // Assert from the board reset; release on a clock edge. INIT also resets at configuration.
    (* ASYNC_REG = "TRUE" *) reg [2:0] reset_sync = 3'b111;
    always @(posedge clk or negedge CPU_RESETN)
        if (!CPU_RESETN)
            reset_sync <= 3'b111;
        else
            reset_sync <= {reset_sync[1:0], 1'b0};
    wire reset = reset_sync[2];

    wire ms_tick, pixel_tick;
    clock_timer #(.CLOCKS_PER_MS(CLOCKS_PER_MS)) timing (
        .clk(clk), .reset(reset), .ms_tick(ms_tick), .pixel_tick(pixel_tick)
    );

    wire [12:0] stable, rising, settled;
    wire inputs_ready;
    input_debouncer #(.WIDTH(13), .STABLE_MS(DEBOUNCE_MS)) board_inputs (
        .clk(clk), .reset(reset), .ms_tick(ms_tick),
        .async_input({BTNC, BTND, SW}),
        .stable(stable), .rising(rising), .settled(settled), .ready(inputs_ready)
    );
    wire switches_clear = inputs_ready && (&settled[7:0]) && (stable[7:0] == 0);
    wire [2:0] switch_seed = stable[10:8];

    wire [7:0] ps2_byte, key_colors;
    wire ps2_valid, key_seed_valid, key_start, key_restart, keyboard_seen;
    wire [2:0] key_seed;
    ps2_receiver serial_input (
        .clk(clk), .reset(reset), .ps2_clk(PS2_CLK), .ps2_data(PS2_DATA),
        .byte_data(ps2_byte), .byte_valid(ps2_valid)
    );
    keyboard_controls keyboard (
        .clk(clk), .reset(reset), .ms_tick(ms_tick), .byte_data(ps2_byte),
        .byte_valid(ps2_valid), .color_press(key_colors), .seed_valid(key_seed_valid),
        .seed_value(key_seed), .start_press(key_start), .restart_press(key_restart),
        .keyboard_seen(keyboard_seen)
    );

    wire [3:0] state, answer_count, failed_at, wrong_position, streak;
    wire [2:0] run_seed, level, show_index;
    wire [1:0] countdown;
    wire [23:0] expected, answer;
    wire [7:0] used;
    wire [11:0] total_wins;
    wire accept_answer, clear_answer, multiple_inputs, correct, level_passed, reset_streak;
    wire start = rising[11] || key_start;
    wire restart = rising[12] || key_restart;
    reg [2:0] previous_switch_seed, keyboard_seed;
    reg keyboard_seed_selected;
    wire [2:0] menu_seed = keyboard_seed_selected && previous_switch_seed == switch_seed ?
                           keyboard_seed : switch_seed;
    wire [2:0] display_seed = state == `CM_MENU ? menu_seed : run_seed;

    // During the menu, the latest selector wins. The FSM locks it for all eight levels.
    always @(posedge clk) begin
        if (reset) begin
            previous_switch_seed <= 0;
            keyboard_seed <= 0;
            keyboard_seed_selected <= 0;
        end else begin
            previous_switch_seed <= switch_seed;
            if (state != `CM_MENU || restart)
                keyboard_seed_selected <= 0;
            else if (key_seed_valid) begin
                keyboard_seed <= key_seed;
                keyboard_seed_selected <= 1;
            end else if (previous_switch_seed != switch_seed)
                keyboard_seed_selected <= 0;
        end
    end

    game_fsm #(
        .COUNTDOWN_MS(COUNTDOWN_MS), .FIRST_COLOR_MS(FIRST_COLOR_MS),
        .COLOR_STEP_MS(COLOR_STEP_MS), .GAP_MS(GAP_MS)
    ) game (
        .clk(clk), .reset(reset), .ms_tick(ms_tick), .start(start), .restart(restart),
        .switches_clear(switches_clear),
        .requested_seed(key_seed_valid ? key_seed : menu_seed),
        .answer_count(answer_count), .multiple_inputs(multiple_inputs), .correct(correct),
        .wrong_position(wrong_position), .state(state), .seed(run_seed), .level(level),
        .show_index(show_index), .countdown(countdown), .failed_at(failed_at),
        .accept_answer(accept_answer), .clear_answer(clear_answer),
        .level_passed(level_passed), .reset_streak(reset_streak)
    );
    sequence_rom patterns (.seed(run_seed), .level(level), .pattern(expected));
    wire [2:0] show_color = expected[show_index*3 +: 3];
    answer_buffer answers (
        .clk(clk), .reset(reset), .clear(clear_answer), .accept(accept_answer),
        .candidates(rising[7:0] | key_colors), .multiple(multiple_inputs),
        .answer(answer), .count(answer_count), .used(used)
    );
    answer_checker compare_answers (
        .expected(expected), .answer(answer), .correct(correct), .wrong_position(wrong_position)
    );
    score_tracker score (
        .clk(clk), .reset(reset), .level_passed(level_passed), .reset_streak(reset_streak),
        .streak(streak), .total_wins(total_wins)
    );

    wire [3:0] level_number = {1'b0, level} + 4'd1;
    reg [31:0] digits;
    always @* begin
        case (state)
            `CM_WRONG:     digits = {24'hffffff, 4'ha, failed_at};
            `CM_COUNTDOWN: digits = {28'hfffffff, 2'b00, countdown};
            default:       digits = {4'hc, 1'b0, display_seed, 4'hb, level_number, streak, total_wins};
        endcase
    end
    sevenseg_driver sevenseg (
        .clk(clk), .reset(reset), .ms_tick(ms_tick), .digits(digits),
        .seg_n(SEG_N), .an_n(AN_N), .dp_n(DP_N)
    );
    assign LED = {keyboard_seen, state == `CM_LEVEL_CLEAR || state == `CM_COMPLETE,
                  state == `CM_WRONG || state == `CM_RETRY_INPUT,
                  state == `CM_INPUT, answer_count, used};

    wire [9:0] x, y;
    wire active_video, hsync, vsync, frame_end;
    wire [11:0] pixel_rgb;
    vga_sync video_timing (
        .clk(clk), .reset(reset), .pixel_tick(pixel_tick), .x(x), .y(y),
        .active_video(active_video), .hsync(hsync), .vsync(vsync), .frame_end(frame_end)
    );
    game_renderer video (
        .clk(clk), .reset(reset), .frame_end(frame_end), .x(x), .y(y),
        .state(state), .seed(display_seed), .level(level), .countdown(countdown),
        .color_id(show_color), .show_index(show_index), .answer_count(answer_count),
        .used(used), .failed_at(failed_at), .streak(streak), .total_wins(total_wins),
        .keyboard_seen(keyboard_seen), .rgb(pixel_rgb)
    );

    // Latch sync and RGB from the same pixel coordinate.
    always @(posedge clk) begin
        if (reset) begin
            {VGA_R, VGA_G, VGA_B} <= 0;
            {VGA_HS, VGA_VS} <= 2'b11;
        end else if (pixel_tick) begin
            {VGA_R, VGA_G, VGA_B} <= active_video ? pixel_rgb : 12'h000;
            {VGA_HS, VGA_VS} <= {hsync, vsync};
        end
    end
endmodule
