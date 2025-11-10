
//tests keygen, next, done, tag
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

  initial begin clk=0; forever #5 clk=~clk; end

  chacha20_poly1305_core dut (
    .clk(clk), .reset_n(rst),
    .init(init), .next(next), .done(done), .encdec(encdec),
    .key(key), .nonce(nonce), .data_in(data_in),
    .ready(ready), .valid(valid), .tag_ok(tag_ok),
    .data_out(data_out), .tag(tag)
  );

  initial begin
    rst = 0; init = 0; next = 0; done = 0; encdec = 1;
    key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
    nonce = {32'h11111111, 32'h22222222, 32'h33333333};
    data_in = 512'hcafebabedeadbeefcafebabedeadbeefcafebabedeadbeefcafebabedeadbeef;
    #20 rst = 1;
    #20 init = 1;
    #10 init = 0;
    #50; // wait for keygen capture
    #10 next = 1; // request data block processing
    #10 next = 0;
    #50; // wait for chacha_data_valid and poly1305 update
    #10 done = 1;
    #10 done = 0;
    #20 $display("tag_ok=%b tag=%h", tag_ok, tag);
    #20 $finish;
  end
endmodule
