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
    integer block_cycle_count;
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
    initial begin
        cycle_count = 0;
        block_cycle_count = 0;
    end
    always @(posedge clk) cycle_count = cycle_count + 1;

    initial begin
        // Reset and initial signals
        rst = 0; init = 0; next = 0;
        key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        iv  = 64'hdeadbeefcafebabe;
        ctr = 64'h0;
        data_in = 512'h0;

        #20 rst = 1;
        $display("[Cycle %0d] RESET released", cycle_count);

        // Send 10 sequential blocks with delay
        for (blk = 0; blk < 10; blk = blk + 1) begin
            // Prepare unique data_in for each block
            data_in = {16{32'hdeadbeef ^ blk}};

            // Optional: small delay between changing data_in
            @(posedge clk); @(posedge clk);

            // Capture start cycle for this block
            block_cycle_count = cycle_count;

            // INIT pulse
            init = 1; @(posedge clk); init = 0;
            $display("[Cycle %0d] INIT asserted for block %0d", cycle_count, blk);

            // NEXT pulse
            next = 1; @(posedge clk); next = 0;
            $display("[Cycle %0d] NEXT asserted for block %0d", cycle_count, blk);

            // Wait for valid output
            while(!data_out_valid) @(posedge clk);
            $display("[Cycle %0d] Data out ready for block %0d: %h", cycle_count, blk, data_out);

            // Show cycles taken per block
            $display("Block %0d cycles taken: %0d", blk, cycle_count - block_cycle_count);

            // Increment counter for next block
            ctr = ctr + 1;
        end

        $display("Total simulation cycles for 10 blocks: %0d", cycle_count);
        #20 $finish;
    end
endmodule
