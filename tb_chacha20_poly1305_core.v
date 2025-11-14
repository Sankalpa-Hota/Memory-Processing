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

  // cycle counters for instrumentation
  integer global_cycles;
  integer t_start, t_mul_done, t_red_done, t_final;

  initial begin clk=0; forever #5 clk=~clk; end

  chacha20_poly1305_core dut (
    .clk(clk), .reset_n(rst),
    .init(init), .next(next), .done(done), .encdec(encdec),
    .key(key), .nonce(nonce), .data_in(data_in),
    .ready(ready), .valid(valid), .tag_ok(tag_ok),
    .data_out(data_out), .tag(tag)
  );

  // count cycles
  always @(posedge clk) begin
    if (!rst) global_cycles = 0;
    else global_cycles = global_cycles + 1;
  end

  initial begin
    // default inputs
    rst = 0; init = 0; next = 0; done = 0; encdec = 1;
    key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
    nonce = {32'h11111111, 32'h22222222, 32'h33333333};
    // some 512-bit data (4 identical 128-bit chunks for simplicity)
    data_in = {4{128'hcafebabedeadbeefcafebabedeadbeef}};

    #20 rst = 1;
    #20 init = 1;
    @(posedge clk); init = 0;
    $display("init asserted at cycle %0d", global_cycles);
    // wait for chacha keystream to be captured and keygen latched
    #200;

    // start processing: perform next to request keystream and process the four 128-bit chunks
    t_start = global_cycles;
    next = 1;
    @(posedge clk); next = 0;
    $display("next asserted at cycle %0d", t_start);

    // wait for multiplier to start/finish: poll internal mul_done via debug probe? Not accessible here.
    // Instead we watch for 'valid' toggles which indicate processing progress.
    // We also sample tag later when done.
    // We will wait up to a timeout and print events when valid/tag_ok asserted.
    integer timeout;
    timeout = 5000;
    while (timeout > 0) begin
      @(posedge clk);
      timeout = timeout - 1;
      // detect the first valid after start -> indicates block processed
      if (valid) begin
        t_mul_done = global_cycles;
        $display("valid asserted at %0d cycles (approx mul+red done for a block)", t_mul_done);
      end
      if (tag_ok) begin
        t_final = global_cycles;
        $display("tag_ok asserted at %0d cycles", t_final);
        $display("Total cycles from next to tag_ok: %0d", t_final - t_start);
        $display("Tag = %h", tag);
        disable wait_loop;
      end
    end
wait_loop: ;

    #20 $finish;
  end
endmodule
