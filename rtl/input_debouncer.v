`timescale 1ns / 1ps

module input_debouncer #(
    parameter integer WIDTH = 13,
    parameter integer STABLE_MS = 12
) (
    input wire clk,
    input wire reset,
    input wire ms_tick,
    input wire [WIDTH-1:0] async_input,
    output reg [WIDTH-1:0] stable,
    output wire [WIDTH-1:0] rising,
    output wire [WIDTH-1:0] settled,
    output wire ready
);
    localparam integer COUNT_WIDTH = STABLE_MS > 1 ? $clog2(STABLE_MS) : 1;
    localparam integer LAST = STABLE_MS - 1;
    localparam integer READY_WIDTH = $clog2(STABLE_MS + 3);
    localparam integer READY_COUNT = STABLE_MS + 2;

    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync_first, synced;
    reg [WIDTH-1:0] previous;
    reg [READY_WIDTH-1:0] startup_count;

    assign rising = stable & ~previous;
    assign ready = startup_count == READY_COUNT[READY_WIDTH-1:0];

    always @(posedge clk) begin
        if (reset) begin
            sync_first <= 0;
            synced <= 0;
            previous <= 0;
            startup_count <= 0;
        end else begin
            sync_first <= async_input;
            synced <= sync_first;
            previous <= stable;
            if (ms_tick && !ready)
                startup_count <= startup_count + 1'b1;
        end
    end

    genvar i;
    generate for (i = 0; i < WIDTH; i = i + 1) begin : channels
        reg [COUNT_WIDTH-1:0] count;
        assign settled[i] = synced[i] == stable[i];
        always @(posedge clk) begin
            if (reset) begin
                count <= 0;
                stable[i] <= 0;
            end else if (settled[i]) begin
                count <= 0;
            end else if (ms_tick) begin
                if (count == LAST[COUNT_WIDTH-1:0]) begin
                    stable[i] <= synced[i];
                    count <= 0;
                end else begin
                    count <= count + 1'b1;
                end
            end
        end
    end endgenerate
endmodule
