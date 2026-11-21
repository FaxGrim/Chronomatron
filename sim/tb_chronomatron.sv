`timescale 1ns / 1ps
`include "game_states.vh"

module tb_chronomatron;
    localparam integer MS_CLOCKS = 100;
    localparam integer SETTLE = 4 * MS_CLOCKS + 8;
    reg clk = 0;
    always #5 clk = ~clk;

    reg reset_n = 0;
    reg [10:0] sw = 0;
    reg btnd = 0, btnc = 0;
    reg ps2_clk = 1, ps2_data = 1;
    wire [15:0] led;

    chronomatron_top #(
        .CLOCKS_PER_MS(MS_CLOCKS), .DEBOUNCE_MS(3), .COUNTDOWN_MS(5),
        .FIRST_COLOR_MS(10), .COLOR_STEP_MS(1), .GAP_MS(2)
    ) dut (
        .CLK100MHZ(clk), .CPU_RESETN(reset_n), .SW(sw),
        .BTND(btnd), .BTNC(btnc), .PS2_CLK(ps2_clk), .PS2_DATA(ps2_data),
        .VGA_R(), .VGA_G(), .VGA_B(), .VGA_HS(), .VGA_VS(),
        .SEG_N(), .DP_N(), .AN_N(), .LED(led)
    );

    task ticks;
        input integer cycles;
        begin repeat (cycles) @(negedge clk); end
    endtask

    task wait_for_state;
        input [3:0] target;
        integer tries;
        begin
            tries = 0;
            while (dut.state !== target && tries < 30_000) begin
                ticks(1);
                tries = tries + 1;
            end
            if (dut.state !== target)
                $fatal(1, "Expected state %0d but got %0d", target, dut.state);
        end
    endtask

    task press_button;
        input restart;
        begin
            if (restart) btnc = 1; else btnd = 1;
            ticks(SETTLE);
            if (restart) btnc = 0; else btnd = 0;
            ticks(SETTLE);
        end
    endtask

    task flip_switch;
        input [2:0] id;
        begin
            sw[{1'b0, id}] = 1;
            ticks(SETTLE);
        end
    endtask

    task send_ps2_bit;
        input bit_data;
        begin
            ps2_data = bit_data;
            ticks(14);
            ps2_clk = 0;
            ticks(16);
            ps2_clk = 1;
            ticks(14);
        end
    endtask

    task send_ps2_byte;
        input [7:0] data;
        input bad_parity;
        integer bit_index;
        begin
            send_ps2_bit(0);
            for (bit_index = 0; bit_index < 8; bit_index = bit_index + 1)
                send_ps2_bit(data[bit_index]);
            send_ps2_bit((~^data) ^ bad_parity);
            send_ps2_bit(1);
            ps2_data = 1;
            ticks(18);
        end
    endtask

    task tap_key;
        input [7:0] scan;
        begin
            send_ps2_byte(scan, 0);
            send_ps2_byte(8'hf0, 0);
            send_ps2_byte(scan, 0);
        end
    endtask

    function [7:0] scan_code;
        input [2:0] color;
        begin
            case (color)
                0: scan_code = 8'h16;
                1: scan_code = 8'h1e;
                2: scan_code = 8'h26;
                3: scan_code = 8'h25;
                4: scan_code = 8'h2e;
                5: scan_code = 8'h36;
                6: scan_code = 8'h3d;
                7: scan_code = 8'h3e;
            endcase
        end
    endfunction

    function [11:0] bcd;
        input integer value;
        integer high, mid, low;
        begin
            high = value / 100;
            mid = (value / 10) % 10;
            low = value % 10;
            bcd = {high[3:0], mid[3:0], low[3:0]};
        end
    endfunction

    reg [3:0] previous_state = `CM_MENU;
    integer shown_count = 0;
    always @(negedge clk) begin
        if (dut.state == `CM_COUNTDOWN && previous_state != `CM_COUNTDOWN)
            shown_count = 0;
        if (dut.state == `CM_SHOW && previous_state != `CM_SHOW) begin
            if (dut.show_index !== shown_count[2:0] ||
                dut.show_color !== dut.expected[shown_count*3 +: 3])
                $fatal(1, "Wrong color or display index at step %0d", shown_count);
            shown_count = shown_count + 1;
        end
        if (dut.state == `CM_INPUT && previous_state != `CM_INPUT && shown_count != 8)
            $fatal(1, "Answer phase started after %0d colors", shown_count);
        previous_state = dut.state;
    end

    reg [23:0] rom_rows [0:63];
    reg [15:0] expected_color_ms [0:7];
    reg [7:0] seen_colors;
    integer seed, level, position, row, total_clears;
    reg [2:0] id, duplicate_id;
    reg [23:0] pattern;

    initial begin
        // Scaled equivalent of 1500, 1400, 1300, 1200, 1100, 1000, 800, 600 ms.
        expected_color_ms[0] = 10;
        expected_color_ms[1] = 9;
        expected_color_ms[2] = 8;
        expected_color_ms[3] = 7;
        expected_color_ms[4] = 6;
        expected_color_ms[5] = 5;
        expected_color_ms[6] = 3;
        expected_color_ms[7] = 1;
        ticks(5);
        reset_n = 1;
        ticks(SETTLE * 2);
        total_clears = 0;

        // Full switch-only playthrough for every seed.
        for (seed = 0; seed < 8; seed = seed + 1) begin
            sw[10:8] = seed[2:0];
            ticks(SETTLE);
            for (level = 0; level < 8; level = level + 1) begin
                press_button(0);
                wait_for_state(`CM_INPUT);
                if (dut.run_seed !== seed[2:0] || dut.level !== level[2:0])
                    $fatal(1, "Run seed/level mismatch");
                if (dut.game.color_ms !== expected_color_ms[level])
                    $fatal(1, "Difficulty timer did not follow level");
                pattern = dut.expected;
                if (seed == 0 && level == 0 && pattern !== {3'd4,3'd6,3'd2,3'd7,3'd0,3'd5,3'd1,3'd3})
                    $fatal(1, "Published seed 0 / level 1 example does not match ROM");
                seen_colors = 0;
                for (position = 0; position < 8; position = position + 1) begin
                    id = pattern[position*3 +: 3];
                    if (seen_colors[id]) $fatal(1, "Repeated color in a pattern");
                    seen_colors[id] = 1;
                    flip_switch(id);
                    if (led[11:8] !== (position[3:0] + 1'b1) || !led[{1'b0, id}])
                        $fatal(1, "Switch answer was not stored once");
                end
                for (row = 0; row < seed * 8 + level; row = row + 1)
                    if (rom_rows[row] === pattern)
                        $fatal(1, "Repeated ROM pattern");
                rom_rows[seed * 8 + level] = pattern;

                wait_for_state(level == 7 ? `CM_COMPLETE : `CM_LEVEL_CLEAR);
                total_clears = total_clears + 1;
                if (dut.answer !== pattern || dut.streak !== (level[3:0] + 1'b1) ||
                    dut.total_wins !== bcd(total_clears))
                    $fatal(1, "Incorrect answer storage or score");
                // Moving the seed switches does not change the running session.
                sw[10:8] = seed[2:0] ^ 3'b111;
                ticks(SETTLE);
                sw[7:0] = 0;
                ticks(SETTLE);
            end
            press_button(1);
            wait_for_state(`CM_MENU);
            if (dut.streak !== 0 || dut.total_wins !== bcd(total_clears))
                $fatal(1, "Menu restart unexpectedly changed scores");
        end

        // Select a seed on the keyboard and verify malformed frames and key repeat.
        send_ps2_byte(8'h83, 1);
        if (dut.menu_seed === 3'd6 || led[15])
            $fatal(1, "Bad parity should be ignored");
        tap_key(8'h83); // F7 -> seed 6
        if (dut.menu_seed !== 3'd6 || !led[15]) $fatal(1, "Keyboard seed selection failed");

        sw[0] = 1;
        ticks(SETTLE);
        tap_key(8'h5a); // Enter
        wait_for_state(`CM_PREPARE);
        if (dut.run_seed !== 3'd6 || dut.answer_count !== 0)
            $fatal(1, "Seed was not locked or an old switch was recorded");
        sw[0] = 0;
        wait_for_state(`CM_INPUT);
        pattern = dut.expected;

        // Bounce shorter than the threshold and unrelated keys never become answers.
        sw[7] = 1; ticks(12); sw[7] = 0; ticks(SETTLE);
        tap_key(8'h1c);
        if (dut.answer_count !== 0) $fatal(1, "Bounce or unmapped key accepted");

        // Accept keyboard and switches in one round, deduplicate repeat and same color.
        id = pattern[2:0];
        send_ps2_byte(scan_code(id), 0);
        send_ps2_byte(scan_code(id), 0);
        flip_switch(id);
        if (dut.answer_count !== 1) $fatal(1, "Repeated color was accepted");
        send_ps2_byte(8'hf0, 0);
        send_ps2_byte(scan_code(id), 0);
        flip_switch(pattern[5:3]);
        tap_key(scan_code(pattern[8:6]));
        for (position = 3; position < 8; position = position + 1)
            flip_switch(pattern[position*3 +: 3]);
        wait_for_state(`CM_LEVEL_CLEAR);
        if (dut.total_wins !== 12'h065 || dut.streak !== 1)
            $fatal(1, "Mixed control round failed");

        // Replay the level on ambiguous simultaneous input without losing a streak.
        sw[7:0] = 0; ticks(SETTLE);
        tap_key(8'h5a);
        wait_for_state(`CM_INPUT);
        sw[1:0] = 2'b11; ticks(SETTLE);
        wait_for_state(`CM_RETRY_INPUT);
        if (dut.answer_count !== 0 || dut.streak !== 1)
            $fatal(1, "Ambiguous input changed answer or streak");
        sw[7:0] = 0; ticks(SETTLE);
        press_button(0);
        wait_for_state(`CM_INPUT);

        // Positions 3 and 4 are swapped. Report the first error only.
        pattern = dut.expected;
        for (position = 0; position < 8; position = position + 1) begin
            case (position)
                2: duplicate_id = pattern[11:9];
                3: duplicate_id = pattern[8:6];
                default: duplicate_id = pattern[position*3 +: 3];
            endcase
            flip_switch(duplicate_id);
        end
        wait_for_state(`CM_WRONG);
        if (dut.failed_at !== 3 || dut.streak !== 0 || dut.total_wins !== 12'h065)
            $fatal(1, "Wrong position/score mismatch");
        sw[7:0] = 0; ticks(SETTLE);
        press_button(0);
        wait_for_state(`CM_INPUT);
        if (dut.level !== 0 || dut.run_seed !== 6)
            $fatal(1, "Failure did not restart from level 1 with the same seed");

        tap_key(8'h2d); // R
        wait_for_state(`CM_MENU);
        if (dut.total_wins !== 12'h065) $fatal(1, "Restart must keep cumulative score");
        reset_n = 0;
        ticks(8);
        if (dut.total_wins !== 0 || led[15]) $fatal(1, "CPU reset did not clear all stats/status");
        $display("PASS: 64 switch-only levels, mixed play, debouncing, seed locking, scores, PS/2");
        $finish;
    end
endmodule
