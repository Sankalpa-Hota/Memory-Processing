`timescale 1ns/1ps
module tb_chacha20_poly1305_bus;
    reg clk, rst, cs, we;
    reg [7:0] addr;
    reg [511:0] wdata;
    wire [511:0] rdata;

    integer cycle_count;
    integer block_cycle_count;

    initial clk=0;
    always #5 clk=~clk;

    chacha20_poly1305_bus top(
        .clk(clk), .reset_n(rst),
        .cs(cs), .we(we),
        .address(addr),
        .write_data(wdata),
        .read_data(rdata)
    );

    initial begin
        $dumpfile("tb_chacha20_poly1305_bus.vcd");
        $dumpvars(0, tb_chacha20_poly1305_bus);
    end

    initial cycle_count = 0;
    always @(posedge clk) cycle_count = cycle_count + 1;

    task bus_write(input [7:0] a, input [511:0] v);
    begin
        block_cycle_count = cycle_count;
        @(posedge clk); cs=1; we=1; addr=a; wdata=v;
        @(posedge clk); cs=0; we=0;
        $display("[Cycle %0d] WRITE addr=%02h, data=%h, cycles=%0d",
                 cycle_count, a, v, cycle_count - block_cycle_count);
    end
    endtask

    task bus_read(input [7:0] a);
    begin
        block_cycle_count = cycle_count;
        @(posedge clk); cs=1; we=0; addr=a;
        @(posedge clk); cs=0;
        $display("[Cycle %0d] READ addr=%02h, data=%h, cycles=%0d",
                 cycle_count, a, rdata, cycle_count - block_cycle_count);
    end
    endtask

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
        // Next
        bus_write(8'h08, 512'h2);
        // Done
        bus_write(8'h08, 512'h4);

        #20 bus_read(8'h09); // status
        $display("[Cycle %0d] Total simulation cycles = %0d", cycle_count, cycle_count);
        #20 $finish;
    end
endmodule
