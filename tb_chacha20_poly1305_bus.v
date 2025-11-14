//top wrapper bus test
`timescale 1ns/1ps
module tb_chacha20_poly1305_bus;
  reg clk, rst;
  reg cs, we;
  reg [7:0] addr;
  reg [31:0] wdata;
  wire [31:0] rdata;

  integer cycle_count;

  // clock
  initial clk = 0; forever #5 clk = ~clk; end

  // DUT
  chacha20_poly1305_bus top (
    .clk(clk), .reset_n(rst),
    .cs(cs), .we(we),
    .address(addr), .write_data(wdata),
    .read_data(rdata)
  );

  // VCD dump
  initial begin
    $dumpfile("tb_chacha20_poly1305_bus.vcd");
    $dumpvars(0, tb_chacha20_poly1305_bus);
  end

  // global cycle counter
  always @(posedge clk) begin
    if (!rst) cycle_count <= 0;
    else cycle_count <= cycle_count + 1;
  end

  // bus tasks
  task bus_write(input [7:0] a, input [31:0] v);
  begin
    @(posedge clk);
    cs = 1; we = 1; addr = a; wdata = v;
    @(posedge clk);
    cs = 0; we = 0;
    $display("WRITE: addr=%02h, data=%08h at cycle %0d", a, v, cycle_count);
  end
  endtask

  task bus_read(input [7:0] a);
  begin
    @(posedge clk);
    cs = 1; we = 0; addr = a;
    @(negedge clk);
    $display("READ: addr=%02h, data=%08h at cycle %0d", a, rdata, cycle_count);
    @(posedge clk); cs = 0;
  end
  endtask

  initial begin
    rst = 0; cs = 0; we = 0; addr = 0; wdata = 0;
    #20 rst = 1;

    // Write key
    bus_write(8'h10, 32'h00112233);
    bus_write(8'h11, 32'h44556677);
    bus_write(8'h12, 32'h8899aabb);
    bus_write(8'h13, 32'hccddeeff);
    bus_write(8'h14, 32'h01234567);
    bus_write(8'h15, 32'h89abcdef);
    bus_write(8'h16, 32'hdeadbeef);
    bus_write(8'h17, 32'hfeedface);

    // Write nonce
    bus_write(8'h20, 32'h01010101);
    bus_write(8'h21, 32'h02020202);
    bus_write(8'h22, 32'h03030303);

    // Write data
    bus_write(8'h30, 32'haaaaaaaa);
    bus_write(8'h31, 32'hbbbbbbbb);

    // Trigger init
    bus_write(8'h08, 32'h1);
    #20
    // Trigger next
    bus_write(8'h08, 32'h2);
    #200
    // Trigger done
    bus_write(8'h08, 32'h4);
    #20
    bus_read(8'h09); // status
    $display("Total cycles = %0d", cycle_count);

    #20 $finish;
  end
endmodule
