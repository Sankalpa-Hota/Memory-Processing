`timescale 1ns/1ps
module tb_chacha_core;
  reg clk, rst;
  reg init, next;
  reg [255:0] key;
  reg [63:0] iv, ctr;
  wire ready;
  wire [511:0] data_out;
  wire data_out_valid;

  integer cycle;
  initial cycle = 0;

  // clock
  initial begin clk = 0; forever #5 clk = ~clk; end

  // DUT
  chacha_core u (
    .clk(clk), .reset_n(rst),
    .init(init), .next(next),
    .keylen(1'b1), .key(key),
    .iv(iv), .ctr(ctr),
    .rounds(5'h14), .data_in(512'h0),
    .ready(ready), .data_out(data_out), .data_out_valid(data_out_valid)
  );

  // VCD dump
  initial begin
    $dumpfile("tb_chacha_core.vcd");
    $dumpvars(0, tb_chacha_core);
  end

  // cycle counter
  always @(posedge clk) cycle = cycle + 1;

  initial begin
    rst = 0; init = 0; next = 0;
    key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
    iv = 64'hdeadbeefcafebabe;
    ctr = 64'h0;
    #20 rst = 1;

    #20 init = 1;
    @(posedge clk); init = 0;
    $display("[tb_chacha_core] Init at cycle %0d", cycle);

    #50 next = 1;
    @(posedge clk); next = 0;
    $display("[tb_chacha_core] Next at cycle %0d", cycle);

    // wait for data_out_valid
    while (!data_out_valid) @(posedge clk);
    $display("[tb_chacha_core] Keystream ready at cycle %0d", cycle);
    $display("[tb_chacha_core] Keystream = %h", data_out);

    $display("[tb_chacha_core] Total cycles: %0d", cycle);
    #20 $finish;
  end
endmodule
