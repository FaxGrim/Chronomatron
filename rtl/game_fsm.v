`timescale 1ns / 1ps
`include "game_states.vh"

module game_fsm #(
    parameter [15:0] COUNTDOWN_MS = 1000,
    parameter [15:0] FIRST_COLOR_MS = 1500,
    parameter [15:0] COLOR_STEP_MS = 100,
    parameter [15:0] GAP_MS = 180
) (
    input wire clk,
    input wire reset,
    input wire ms_tick,
    input wire start,
    input wire restart,
    input wire switches_clear,
    input wire [2:0] requested_seed,
    input wire [3:0] answer_count,
    input wire multiple_inputs,
    input wire correct,
    input wire [3:0] wrong_position,
    output reg [3:0] state,
    output reg [2:0] seed,
    output reg [2:0] level,
    output reg [2:0] show_index,
    output reg [1:0] countdown,
    output reg [3:0] failed_at,
    output wire accept_answer,
    output wire clear_answer,
    output wire level_passed,
    output wire reset_streak
);
    reg [15:0] remaining_ms;
    reg [15:0] color_ms;
    localparam [15:0] LATE_COLOR_STEP_MS = COLOR_STEP_MS << 1;
    wire time_up = ms_tick && remaining_ms == 1;

    assign accept_answer = state == `CM_INPUT && !restart;
    assign clear_answer = restart || state == `CM_MENU || state == `CM_PREPARE ||
                          state == `CM_ARM_INPUT;
    assign level_passed = state == `CM_CHECK && correct && !restart;
    assign reset_streak = restart || (state == `CM_CHECK && !correct) ||
                          (start && (state == `CM_MENU || state == `CM_COMPLETE));

    always @(posedge clk) begin
        if (reset || restart) begin
            state <= `CM_MENU;
            seed <= 0;
            level <= 0;
            show_index <= 0;
            countdown <= 0;
            failed_at <= 0;
            remaining_ms <= 0;
            color_ms <= FIRST_COLOR_MS;
        end else begin
            if (ms_tick && remaining_ms != 0)
                remaining_ms <= remaining_ms - 1'b1;

            case (state)
                `CM_MENU, `CM_COMPLETE, `CM_WRONG: if (start) begin
                    if (state == `CM_MENU)
                        seed <= requested_seed;
                    level <= 0;
                    color_ms <= FIRST_COLOR_MS;
                    failed_at <= 0;
                    state <= `CM_PREPARE;
                end

                `CM_PREPARE: if (switches_clear) begin
                    remaining_ms <= COUNTDOWN_MS;
                    countdown <= 3;
                    show_index <= 0;
                    state <= `CM_COUNTDOWN;
                end

                `CM_COUNTDOWN: if (time_up) begin
                    if (countdown == 1) begin
                        remaining_ms <= color_ms;
                        state <= `CM_SHOW;
                    end else begin
                        countdown <= countdown - 1'b1;
                        remaining_ms <= COUNTDOWN_MS;
                    end
                end

                `CM_SHOW: if (time_up) begin
                    if (show_index == 7) begin
                        state <= `CM_ARM_INPUT;
                    end else begin
                        remaining_ms <= GAP_MS;
                        state <= `CM_GAP;
                    end
                end

                `CM_GAP: if (time_up) begin
                    show_index <= show_index + 1'b1;
                    remaining_ms <= color_ms;
                    state <= `CM_SHOW;
                end

                `CM_ARM_INPUT: if (switches_clear)
                    state <= `CM_INPUT;

                `CM_INPUT: begin
                    if (answer_count == 8)
                        state <= `CM_CHECK;
                    else if (multiple_inputs)
                        state <= `CM_RETRY_INPUT;
                end

                `CM_CHECK: begin
                    failed_at <= wrong_position;
                    if (!correct)
                        state <= `CM_WRONG;
                    else if (level == 7)
                        state <= `CM_COMPLETE;
                    else
                        state <= `CM_LEVEL_CLEAR;
                end

                `CM_LEVEL_CLEAR: if (start) begin
                    level <= level + 1'b1;
                    // Entering level 7 or 8 takes a double step in difficulty.
                    if (level >= 3'd5)
                        color_ms <= color_ms - LATE_COLOR_STEP_MS;
                    else
                        color_ms <= color_ms - COLOR_STEP_MS;
                    state <= `CM_PREPARE;
                end

                `CM_RETRY_INPUT: if (start)
                    state <= `CM_PREPARE;

                default: state <= `CM_MENU;
            endcase
        end
    end
endmodule
