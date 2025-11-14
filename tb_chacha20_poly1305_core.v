`timescale 1ns/1ps
module tb_chacha20_poly1305_core;
    reg clk, rst, init, next, done, encdec;
    reg [255:0] key;
    reg [95:0] nonce;
    reg [511:0] data_in;
    wire ready, valid, tag_ok;
    wire [511:0] data_out;
    wire [127:0] tag;

    integer cycle_count;
    integer block_cycle_count;
    integer blk;

    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    chacha20_poly1305_core dut(
        .clk(clk),
        .reset_n(rst),
        .init(init),
        .next(next),
        .done(done),
        .encdec(encdec),
        .key(key),
        .nonce(nonce),
        .data_in(data_in),
        .ready(ready),
        .valid(valid),
        .tag_ok(tag_ok),
        .data_out(data_out),
        .tag(tag)
    );

    initial begin
        $dumpfile("tb_chacha20_poly1305_core.vcd");
        $dumpvars(0, tb_chacha20_poly1305_core);
    end

    initial begin
        cycle_count = 0;
        block_cycle_count = 0;
    end

    always @(posedge clk) cycle_count = cycle_count + 1;

    initial begin
        rst = 0; init = 0; next = 0; done = 0; encdec = 1;
        key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        nonce = {32'h11111111, 32'h22222222, 32'h33333333};

        #20 rst = 1;
        $display("[Cycle %0d] RESET released", cycle_count);

        // -------------------------
        // Send 10 data blocks
        // -------------------------
        for (blk = 0; blk < 10; blk = blk + 1) begin
            data_in = {16{32'hcafebabedeadbeef + blk}}; // unique per block
            $display("[Cycle %0d] Block %0d data_in = %h", cycle_count, blk, data_in);

            // INIT
            block_cycle_count = cycle_count;
            init = 1; @(posedge clk); init = 0;
            $display("[Cycle %0d] INIT asserted for block %0d", cycle_count, blk);

            // NEXT
            block_cycle_count = cycle_count;
            next = 1; @(posedge clk); next = 0;
            $display("[Cycle %0d] NEXT asserted for block %0d", cycle_count, blk);

            // Wait for valid data_out
            block_cycle_count = cycle_count;
            while(!valid) @(posedge clk);
            $display("[Cycle %0d] VALID data_out for block %0d: %h", cycle_count, blk, data_out);
            $display("Block %0d cycles taken: %0d", blk, cycle_count - block_cycle_count);

            // Wait for tag
            block_cycle_count = cycle_count;
            while(!tag_ok) @(posedge clk);
            $display("[Cycle %0d] TAG computed for block %0d: %h", cycle_count, blk, tag);
            $display("Tag cycles taken: %0d", cycle_count - block_cycle_count);

            // Small delay between blocks for visibility in waveform
            #20;
        end

        $display("Total simulation cycles for 10 blocks: %0d", cycle_count);
        #20 $finish;
    end
endmodule
