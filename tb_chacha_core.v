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

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // DUT
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

    initial cycle_count = 0;
    always @(posedge clk) cycle_count = cycle_count + 1;

    initial begin
        rst = 0; init = 0; next = 0;
        key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        iv  = 64'hdeadbeefcafebabe;
        ctr = 64'h0;
        data_in = 512'h0;

        #20 rst = 1;
        $display("[Cycle %0d] RESET released", cycle_count);

        // Process 10 blocks
        for (blk = 0; blk < 10; blk = blk + 1) begin
            data_in = {16{32'hdeadbeef ^ blk}};
            ctr = ctr + 1;

            @(posedge clk);
            init = 1; @(posedge clk); init = 0;

            @(posedge clk);
            next = 1; @(posedge clk); next = 0;

            // Wait for valid output with timeout
            integer timeout;
            timeout = 0;
            while(!data_out_valid && timeout < 50000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if(timeout == 50000) begin
                $display("ERROR: data_out_valid timeout!");
                $finish;
            end

            $display("[Cycle %0d] Block %0d encrypted: %h", cycle_count, blk, data_out);
        end

        $display("Total cycles: %0d", cycle_count);
        #20 $finish;
    end
endmodule
