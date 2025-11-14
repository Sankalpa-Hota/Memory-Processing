`timescale 1ns/1ps
module tb_chacha_core;
  reg clk, rst;
  reg init, next;
  reg [255:0] key;
  reg [63:0] iv, ctr;
  wire ready;
  wire [511:0] data_out;
  wire data_out_valid;

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  chacha_core u (
    .clk(clk), .reset_n(rst),
    .init(init), .next(next),
    .keylen(1'b1), .key(key),
    .iv(iv), .ctr(ctr),
    .rounds(5'h14), .data_in(512'h0),
    .ready(ready), .data_out(data_out), .data_out_valid(data_out_valid)
  );

  initial begin
    rst = 0; init = 0; next = 0;
    key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
    iv = 64'hdeadbeefcafebabe;
    ctr = 64'h0;
    #20 rst = 1;
    #20 init = 1;
    #10 init = 0;
    #50 $display("keystream_valid=%b", data_out_valid);
    #20 $finish;
  end
endmodule
