`timescale 1ns/1ps
module tb_chacha20_poly1305_core;
    reg clk, rst;
    reg init, next, done, encdec;
    reg [255:0] key;
    reg [95:0] nonce;
    reg [511:0] data_in;
    wire ready, valid, tag_ok;
    wire [511:0] data_out;
    wire [127:0] tag;

    integer global_cycles;
    integer start_cycle, block_cycles;

    // clock
    initial clk = 0; forever #5 clk = ~clk; end

    // cycle counter
    initial global_cycles = 0;
    always @(posedge clk)
        if (rst) global_cycles = global_cycles + 1;

    // DUT
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

    // waveform dump
    initial begin
        $dumpfile("tb_chacha20_poly1305_core.vcd");
        $dumpvars(0, tb_chacha20_poly1305_core);
    end

    initial begin
        rst = 0; init = 0; next = 0; done = 0; encdec = 1;
        key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        nonce = {32'h11111111, 32'h22222222, 32'h33333333};
        data_in = {4{128'hcafebabedeadbeefcafebabedeadbeef}};

        #20 rst = 1;
        #10 init = 1;
        @(posedge clk); init = 0;
        start_cycle = global_cycles;
        $display("Init asserted at cycle %0d", start_cycle);

        #20 next = 1;
        @(posedge clk); next = 0;
        $display("Next asserted at cycle %0d", global_cycles);

        // process 4 blocks
        integer i;
        for (i = 0; i < 4; i = i + 1) begin
            block_cycles = global_cycles;
            wait(valid == 1);
            $display("Block %0d processed, cycles = %0d, data_out = %h", i, global_cycles - block_cycles, data_out[127 + i*128 -:128]);
            @(posedge clk);
        end

        // wait for final tag
        wait(tag_ok == 1);
        $display("Tag computed at cycle %0d, total cycles = %0d", global_cycles, global_cycles - start_cycle);
        $display("Tag = %h", tag);

        #20 $finish;
    end
endmodule

