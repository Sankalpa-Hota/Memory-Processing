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

  // cycle counters
  integer global_cycles;
  integer start_cycle, block_idx;
  integer block_start_cycle[0:3];
  integer block_end_cycle[0:3];

  // clock
  initial clk=0; forever #5 clk=~clk; end

  // DUT
  chacha20_poly1305_core dut (
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

  // global cycle counter
  always @(posedge clk) begin
    if (!rst) global_cycles = 0;
    else global_cycles = global_cycles + 1;
  end

  initial begin
    rst = 0; init=0; next=0; done=0; encdec=1;
    key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
    nonce = {32'h11111111, 32'h22222222, 32'h33333333};
    data_in = {4{128'hcafebabedeadbeefcafebabedeadbeef}};

    #20 rst = 1;
    #20 init = 1;
    @(posedge clk); init = 0;
    start_cycle = global_cycles;
    $display("Init asserted at cycle %0d", start_cycle);

    #50 next = 1;
    @(posedge clk); next = 0;
    $display("Next asserted at cycle %0d", global_cycles);

    // wait for tag_ok
    integer timeout; timeout = 5000;
    while (!tag_ok && timeout > 0) begin
      @(posedge clk);
      timeout = timeout - 1;
    end

    $display("Tag_ok asserted at cycle %0d", global_cycles);
    $display("Total cycles from next to tag_ok: %0d", global_cycles - start_cycle);
    $display("Final tag = %h", tag);

    #20 $finish;
  end
endmodule
