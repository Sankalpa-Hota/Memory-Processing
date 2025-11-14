`timescale 1ns/1ps
module tb_chacha20_poly1305_bus;
    reg clk, rst, cs, we;
    reg [7:0] addr;
    reg [511:0] wdata;
    wire [511:0] rdata;

    integer cycle_count;

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // DUT
    chacha20_poly1305_bus top(
        .clk(clk), .reset_n(rst),
        .cs(cs), .we(we),
        .address(addr),
        .write_data(wdata),
        .read_data(rdata)
    );

    // VCD
    initial begin
        $dumpfile("tb_chacha20_poly1305_bus.vcd");
        $dumpvars(0, tb_chacha20_poly1305_bus);
    end

    // Global cycle counter
    initial cycle_count = 0;
    always @(posedge clk) cycle_count = cycle_count + 1;

    // Bus write
    task bus_write(input [7:0] a, input [511:0] v);
    begin
        @(posedge clk); cs=1; we=1; addr=a; wdata=v;
        @(posedge clk); cs=0; we=0;
        $display("[Cycle %0d] WRITE: addr=%02h, data=%h", cycle_count, a, v);
    end
    endtask

    // Bus read
    task bus_read(input [7:0] a);
    begin
        @(posedge clk); cs=1; we=0; addr=a;
        @(posedge clk); cs=0;
        $display("[Cycle %0d] READ: addr=%02h, data=%h", cycle_count, a, rdata);
    end
    endtask

    // Test procedure
    initial begin
        rst=0; cs=0; we=0; addr=0; wdata=0;
        #20 rst=1;
        $display("[Cycle %0d] RESET released", cycle_count);

        // Key write
        bus_write(8'h10, {16{32'h00112233}});
        // Nonce write
        bus_write(8'h20, {16{32'h01020304}});
        // Data write
        bus_write(8'h30, {16{32'hdeadbeef}});
        // Init
        bus_write(8'h08, 512'h1);
        #20
        // Next
        bus_write(8'h08, 512'h2);
        #50
        // Done
        bus_write(8'h08, 512'h4);
        #20 bus_read(8'h09); // status

        $display("[Cycle %0d] Total cycles = %0d", cycle_count, cycle_count);
        #20 $finish;
    end
endmodule
