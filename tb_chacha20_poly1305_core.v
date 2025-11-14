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

    initial clk=0;
    always #5 clk=~clk;

    chacha20_poly1305_core dut(
        .clk(clk), .reset_n(rst),
        .init(init), .next(next), .done(done), .encdec(encdec),
        .key(key), .nonce(nonce), .data_in(data_in),
        .ready(ready), .valid(valid), .tag_ok(tag_ok),
        .data_out(data_out), .tag(tag)
    );

    // VCD dump
    initial begin
        $dumpfile("tb_chacha20_poly1305_core.vcd");
        $dumpvars(0, tb_chacha20_poly1305_core);
    end

    // Global cycle counter
    initial cycle_count = 0;
    always @(posedge clk) cycle_count = cycle_count + 1;

    initial begin
        rst=0; init=0; next=0; done=0; encdec=1;
        key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        nonce = {32'h11111111,32'h22222222,32'h33333333};
        data_in = {16{32'hcafebabedeadbeef}};

        #20 rst=1;
        $display("[Cycle %0d] RESET released", cycle_count);

        #10 init=1; @(posedge clk); init=0;
        $display("[Cycle %0d] INIT asserted", cycle_count);

        #10 next=1; @(posedge clk); next=0;
        $display("[Cycle %0d] NEXT asserted", cycle_count);

        wait(valid);
        $display("[Cycle %0d] VALID output received, data_out=%h", cycle_count, data_out);

        wait(tag_ok);
        $display("[Cycle %0d] TAG computed, tag=%h", cycle_count, tag);

        $display("[Cycle %0d] Total simulation cycles = %0d", cycle_count, cycle_count);
        #20 $finish;
    end
endmodule
