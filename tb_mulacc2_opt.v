`timescale 1ns/1ps
module tb_mulacc2_opt;
  reg clk, rst;
  reg clear, next;
  reg [31:0] a, b;
  wire [64:0] psum;

  initial begin clk=0; forever #5 clk=~clk; end

  mulacc2_opt u(.clk(clk), .reset_n(rst), .clear(clear), .next(next), .a(a), .b(b), .psum(psum));

  initial begin
    rst=0; clear=0; next=0; a=0; b=0;
    #20 rst = 1;
    #10 clear = 1; @(posedge clk); clear = 0;
    a = 32'd3; b = 32'd5; @(posedge clk);
    next = 1; @(posedge clk); next = 0; // accumulate 3*5
    @(posedge clk);
    a = 32'd7; b = 32'd11; @(posedge clk);
    next = 1; @(posedge clk); next = 0; // accumulate 7*11
    #20 $display("psum = %d (expected 3*5 + 7*11 = 15 + 77 = 92)", psum);
    #20 $finish;
  end
endmodule
