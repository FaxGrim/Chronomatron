`timescale 1ns / 1ps
`include "game_states.vh"

module game_renderer (
    input wire clk,
    input wire reset,
    input wire frame_end,
    input wire [9:0] x, y,
    input wire [3:0] state,
    input wire [2:0] seed, level,
    input wire [1:0] countdown,
    input wire [2:0] color_id, show_index,
    input wire [3:0] answer_count,
    input wire [7:0] used,
    input wire [3:0] failed_at, streak,
    input wire [11:0] total_wins,
    input wire keyboard_seen,
    output reg [11:0] rgb
);
    localparam [11:0] BACKGROUND = 12'h112, PANEL = 12'h223, LINE = 12'h345;
    localparam [11:0] WHITE = 12'heef, MUTED = 12'h9ab, ACCENT = 12'h5ed;
    localparam [11:0] GOOD = 12'h6e8, ALERT = 12'hf76;
    localparam [3:0] NO_TEXT = 0, TITLE = 1, METADATA = 2, STATUS = 3;
    localparam [3:0] HINT = 4, HINT_2 = 5, STATS = 6, TILE = 7, BIG_NUMBER = 8;

    reg [3:0] frame_state, frame_answer_count, frame_failed_at, frame_streak;
    reg [2:0] frame_seed, frame_level, frame_color, frame_show_index;
    reg [1:0] frame_countdown;
    reg [7:0] frame_used;
    reg [11:0] frame_wins;
    reg frame_keyboard;

    // A coherent snapshot is taken in vertical blanking.
    always @(posedge clk) begin
        if (reset) begin
            frame_state <= `CM_MENU;
            frame_seed <= 0;
            frame_level <= 0;
            frame_countdown <= 0;
            frame_color <= 0;
            frame_show_index <= 0;
            frame_answer_count <= 0;
            frame_used <= 0;
            frame_failed_at <= 0;
            frame_streak <= 0;
            frame_wins <= 0;
            frame_keyboard <= 0;
        end else if (frame_end) begin
            frame_state <= state;
            frame_seed <= seed;
            frame_level <= level;
            frame_countdown <= countdown;
            frame_color <= color_id;
            frame_show_index <= show_index;
            frame_answer_count <= answer_count;
            frame_used <= used;
            frame_failed_at <= failed_at;
            frame_streak <= streak;
            frame_wins <= total_wins;
            frame_keyboard <= keyboard_seen;
        end
    end

    function [11:0] palette;
        input [2:0] id;
        begin
            case (id)
                3'd0: palette = 12'hf43; // Red
                3'd1: palette = 12'h47f; // Blue
                3'd2: palette = 12'hfe3; // Yellow
                3'd3: palette = 12'h3d5; // Green
                3'd4: palette = 12'ha5e; // Purple
                3'd5: palette = 12'hf83; // Orange
                3'd6: palette = 12'h3dc; // Cyan
                default: palette = 12'hf8c; // Pink
            endcase
        end
    endfunction

    function [7:0] digit;
        input [3:0] number;
        begin digit = 8'h30 + {4'b0, number}; end
    endfunction

    function [127:0] level_name;
        input [2:0] index;
        begin
            case (index)
                0: level_name = "BEGINNER        ";
                1: level_name = "INTERMEDIATE    ";
                2: level_name = "HIGH            ";
                3: level_name = "GRAND           ";
                4: level_name = "SUPREME         ";
                5: level_name = "TRANSCENDENT    ";
                6: level_name = "METAPHYSIC      ";
                default: level_name = "ULTRASEQUENCER  ";
            endcase
        end
    endfunction

    // Stage 1. Locate the pixel inside the panel, a text row, or a color tile.
    reg [3:0] row, s1_row;
    reg [5:0] cell_slot, s1_slot;
    reg [2:0] glyph_x, glyph_y, s1_x, s1_y;
    reg [11:0] base, ink, s1_base, s1_ink;
    wire [2:0] tile = x[8:6] - 3'd1;
    wire [3:0] shown = {1'b0, frame_show_index} + 4'd1;
    wire [3:0] level_digit = {1'b0, frame_level} + 4'd1;
    wire [9:0] big_x = x - 10'd288;
    wire [9:0] big_y = y - 10'd192;
    wire [9:0] tile_glyph_x = {4'd0, x[5:0]} - 10'd27;

    always @* begin
        row = NO_TEXT;
        cell_slot = x[9:4] - 6'd2;
        glyph_x = x[3:1];
        glyph_y = y[3:1];
        base = BACKGROUND;
        ink = WHITE;

        if (x >= 32 && x < 608) begin
            if (y >= 108 && y < 316)
                base = PANEL;
            if ((y >= 96 && y < 98) || (y >= 316 && y < 318) ||
                (y >= 448 && y < 450))
                base = LINE;
            if (y >= 16 && y < 30) begin
                row = TITLE;
                ink = ACCENT;
            end else if (y >= 64 && y < 78) begin
                row = METADATA;
                ink = MUTED;
            end else if (y >= 128 && y < 142) begin
                row = STATUS;
                case (frame_state)
                    `CM_LEVEL_CLEAR, `CM_COMPLETE: ink = GOOD;
                    `CM_WRONG, `CM_RETRY_INPUT: ink = ALERT;
                    default: ink = WHITE;
                endcase
            end else if (y >= 336 && y < 350) begin
                row = HINT;
            end else if (y >= 368 && y < 382) begin
                row = HINT_2;
                ink = MUTED;
            end else if (y >= 464 && y < 478) begin
                row = STATS;
                ink = ACCENT;
            end
        end

        if (x >= 64 && x < 576) begin
            if (frame_state == `CM_SHOW && y >= 168 && y < 284)
                base = palette(frame_color);
            if (y >= 292 && y < 301 && x[5:0] >= 4 && x[5:0] < 60) begin
                base = LINE;
                if ((frame_state == `CM_SHOW || frame_state == `CM_GAP) &&
                    tile <= frame_show_index)
                    base = ACCENT;
                if ((frame_state == `CM_INPUT || frame_state == `CM_CHECK) &&
                    {1'b0, tile} < frame_answer_count)
                    base = GOOD;
            end
            if (x[5:0] >= 4 && x[5:0] < 60 && y >= 396 && y < 418)
                base = palette(tile);
            if (frame_used[tile] && y >= 418 && y < 421 && x[5:0] >= 4 && x[5:0] < 60)
                base = WHITE;
            if (x[5:0] >= 27 && x[5:0] < 37 && y >= 432 && y < 446) begin
                row = TILE;
                cell_slot = {3'd0, tile};
                glyph_x = tile_glyph_x[3:1];
            end
        end
        if (frame_state == `CM_COUNTDOWN && x >= 288 && x < 328 && y >= 192 && y < 248) begin
            row = BIG_NUMBER;
            glyph_x = big_x[5:3];
            glyph_y = big_y[5:3];
            ink = ACCENT;
        end
    end

    always @(posedge clk) begin
        s1_row <= row;
        s1_slot <= cell_slot;
        s1_x <= glyph_x;
        s1_y <= glyph_y;
        s1_base <= base;
        s1_ink <= ink;
    end

    // Stage 2. Convert a column in a fixed-width line to an ASCII character.
    reg [287:0] line;
    reg [7:0] character, s2_character;
    reg [2:0] s2_x, s2_y;
    reg [11:0] s2_base, s2_ink;

    always @* begin
        line = 0;
        case (s1_row)
            TITLE: line = "CHRONOMATRON                        ";
            METADATA: line = {"SEED ", digit({1'b0, frame_seed}), "  LEVEL ", digit(level_digit),
                              "  ", level_name(frame_level), 24'd0};
            STATUS: begin
                case (frame_state)
                    `CM_MENU: line = "SELECT A SEED                       ";
                    `CM_PREPARE, `CM_ARM_INPUT: line = "SET SW0 TO SW7 OFF                  ";
                    `CM_COUNTDOWN: line = "GET READY                           ";
                    `CM_SHOW: line = {"MEMORIZE   COLOR ", digit(shown), "/8", 128'd0};
                    `CM_GAP: line = "MEMORIZE                            ";
                    `CM_INPUT, `CM_CHECK:
                        line = {"YOUR TURN   ", digit(frame_answer_count), "/8", 168'd0};
                    `CM_LEVEL_CLEAR: line = "LEVEL CLEARED                       ";
                    `CM_WRONG: line = {"WRONG AT ", digit(frame_failed_at), 208'd0};
                    `CM_COMPLETE: line = "GAME COMPLETED                      ";
                    `CM_RETRY_INPUT: line = "TWO INPUTS AT ONCE                  ";
                    default: line = 0;
                endcase
            end
            HINT: begin
                case (frame_state)
                    `CM_MENU: line = "SW8 TO SW10 OR F1 TO F8 PICK SEED   ";
                    `CM_PREPARE, `CM_ARM_INPUT: line = "LOWER ALL EIGHT COLOR SWITCHES      ";
                    `CM_COUNTDOWN, `CM_SHOW, `CM_GAP: line = "REMEMBER THE ORDER OF THE COLORS    ";
                    `CM_INPUT, `CM_CHECK: line = "FLIP A SWITCH OR PRESS KEY 1 TO 8   ";
                    `CM_LEVEL_CLEAR: line = "BTND OR ENTER FOR NEXT LEVEL        ";
                    `CM_WRONG: line = "BTND OR ENTER TO RETRY LEVEL 1      ";
                    `CM_COMPLETE: line = "BTND OR ENTER TO PLAY AGAIN         ";
                    `CM_RETRY_INPUT: line = "BTND OR ENTER TO REPLAY THIS LEVEL  ";
                    default: line = 0;
                endcase
            end
            HINT_2: begin
                case (frame_state)
                    `CM_MENU: line = "BTND OR ENTER TO START              ";
                    `CM_INPUT: line = "TILES BELOW MATCH SW0 TO SW7        ";
                    default: line = "BTNC OR R TO RETURN TO SEED MENU    ";
                endcase
            end
            STATS: begin
                if (frame_keyboard)
                    line = {"STREAK ", digit(frame_streak), "  TOTAL WINS ",
                            digit(frame_wins[11:8]), digit(frame_wins[7:4]), digit(frame_wins[3:0]),
                            "  KB USED", 24'd0};
                else
                    line = {"STREAK ", digit(frame_streak), "  TOTAL WINS ",
                            digit(frame_wins[11:8]), digit(frame_wins[7:4]), digit(frame_wins[3:0]),
                            96'd0};
            end
            default: line = 0;
        endcase
        case (s1_row)
            TILE: character = digit({1'b0, s1_slot[2:0]});
            BIG_NUMBER: character = digit({2'b0, frame_countdown});
            default: character = s1_slot < 36 ? line[287 - {s1_slot, 3'b000} -: 8] : 8'h00;
        endcase
    end

    always @(posedge clk) begin
        s2_character <= character;
        s2_x <= s1_x;
        s2_y <= s1_y;
        s2_base <= s1_base;
        s2_ink <= s1_ink;
    end

    // Stage 3. Look up the 5-by-7 glyph and apply its foreground bit.
    wire glyph_on;
    font5x7 font (.character(s2_character), .column(s2_x), .row(s2_y), .pixel(glyph_on));
    always @(posedge clk)
        rgb <= glyph_on ? s2_ink : s2_base;
endmodule
