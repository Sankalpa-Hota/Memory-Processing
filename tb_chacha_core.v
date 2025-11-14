`timescale 1ns/1ps
module tb_chacha_core;
    reg clk, rst, init, next;
    reg [255:0] key;
    reg [63:0] iv, ctr;
    wire ready;
    wire [511:0] data_out;
    wire data_out_valid;

    integer cycle_count;

    initial clk=0;
    always #5 clk=~clk;

    chacha_core dut(
        .clk(clk), .reset_n(rst),
        .init(init), .next(next),
        .key(key), .ctr(ctr), .iv(iv),
        .data_in(512'h0),
        .ready(ready), .data_out(data_out), .data_out_valid(data_out_valid)
    );

    initial begin
        $dumpfile("tb_chacha_core.vcd");
        $dumpvars(0, tb_chacha_core);
    end

    // Cycle counter
    initial cycle_count=0;
    always @(posedge clk) cycle_count = cycle_count + 1;

    initial begin
        rst=0; init=0; next=0;
        key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        iv = 64'hdeadbeefcafebabe;
        ctr = 64'h0;

        #20 rst=1;
        $display("[Cycle %0d] RESET released", cycle_count);

        #20 init=1; @(posedge clk); init=0;
        $display("[Cycle %0d] INIT asserted", cycle_count);

        #50 next=1; @(posedge clk); next=0;
        $display("[Cycle %0d] NEXT asserted", cycle_count);

        wait(data_out_valid);
        $display("[Cycle %0d] Data out ready: %h", cycle_count, data_out);

        $display("[Cycle %0d] Total cycles = %0d", cycle_count, cycle_count);
        #20 $finish;
    end
endmodule
