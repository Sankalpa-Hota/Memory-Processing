`timescale 1ns/1ps
module tb_chacha_core;
    reg clk, rst, init, next;
    reg [255:0] key;
    reg [63:0] iv, ctr;
    reg [511:0] data_in;
    wire ready;
    wire [511:0] data_out;
    wire data_out_valid;

    integer cycle_count;
    integer blk;

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    chacha_core dut(
        .clk(clk),
        .reset_n(rst),
        .init(init),
        .next(next),
        .key(key),
        .ctr(ctr),
        .iv(iv),
        .data_in(data_in),
        .ready(ready),
        .data_out(data_out),
        .data_out_valid(data_out_valid)
    );

    // VCD dump
    initial begin
        $dumpfile("tb_chacha_core.vcd");
        $dumpvars(0, tb_chacha_core);
    end

    // Cycle counter
    initial cycle_count = 0;
    always @(posedge clk) cycle_count = cycle_count + 1;

    // Block loop variables
    reg [511:0] block_data;
    reg waiting;

    initial begin
        // Reset and init
        rst = 0; init = 0; next = 0;
        key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        iv  = 64'hdeadbeefcafebabe;
        ctr = 64'h0;
        data_in = 512'h0;

        #20 rst = 1;
        $display("[Cycle %0d] RESET released", cycle_count);

        for (blk = 0; blk < 10; blk = blk + 1) begin
            // Prepare unique data block
            block_data = {16{32'hdeadbeef ^ blk}};
            data_in = block_data;

            // INIT pulse
            init = 1; @(posedge clk); init = 0;
            $display("[Cycle %0d] INIT asserted for bloc
