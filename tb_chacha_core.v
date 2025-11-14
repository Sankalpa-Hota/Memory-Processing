`timescale 1ns/1ps
module tb_chacha_core;
  reg clk, rst;
  reg init, next;
  reg [255:0] key;
  reg [63:0] iv, ctr;
  wire ready;
  wire [511:0] data_out;
  wire data_out_valid;

  integer cycle_count;

  // clock generation
  initial clk = 0; forever #5 clk = ~clk; end

  // DUT
  chacha_core u (
    .clk(clk), .reset_n(rst),
    .init(init), .next(next),
    .key(key),
    .iv(iv), .ctr(ctr),
    .ready(ready),
    .data_out(data_out),
    .data_out_valid(data_out_valid)
  );

  // VCD dump
  initial begin
    $dumpfile("tb_chacha_core.vcd");
    $dumpvars(0, tb_chacha_core);
  end

  // cycle counter
  always @(posedge clk) begin
    if (!rst) cycle_count <= 0;
    else cycle_count <= cycle_count + 1;
  end

  initial begin
    rst = 0; init = 0; next = 0;
    key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
    iv  = 64'hdeadbeefcafebabe;
    ctr = 64'h0;

    #20 rst = 1;
    #10 init = 1;
    @(posedge clk); init = 0;
    $display("Init asserted at cycle %0d", cycle_count);

    #20 next = 1;
    @(posedge clk); next = 0;
    $display("Next asserted at cycle %0d", cycle_count);

    wait (data_out_valid == 1);
    $display("Keystream valid at cycle %0d", cycle_count);
    $display("Keystream[511:0] = %h", data_out);
    $display("Total cycles for keystream generation = %0d", cycle_count);

    #20 $finish;
  end
endmodule
