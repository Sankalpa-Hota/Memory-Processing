`timescale 1ns/1ps
module tb_chacha20_poly1305_bus;
    reg clk, rst, cs, we;
    reg [7:0] addr;
    reg [511:0] wdata;
    wire [511:0] rdata;

    integer cycle_count;
    integer block_cycle_count;
    integer blk;

    reg [511:0] data_input0, data_input1;

    initial clk = 0;
    always #5 clk = ~clk;

    chacha20_poly1305_bus dut(
        .clk(clk),
        .reset_n(rst),
        .cs(cs),
        .we(we),
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
        $display("[Cycle %0d] WRITE addr=%02h, data size=%0d bits, cycles=%0d",
                 cycle_count, a, $bits(v), cycle_count - block_cycle_count);
    end
    endtask

    task bus_read(input [7:0] a);
    begin
        block_cycle_count = cycle_count;
        @(posedge clk); cs=1; we=0; addr=a;
        @(posedge clk); cs=0;
        $display("[Cycle %0d] READ addr=%02h, data size=%0d bits, cycles=%0d, data=%h",
                 cycle_count, a, $bits(rdata), cycle_count - block_cycle_count, rdata);
    end
    endtask

    initial begin
        rst = 0; cs = 0; we = 0; addr = 0; wdata = 0;

        // Example data
        data_input0 = {16{32'hdeadbeef}};
        data_input1 = {16{32'hcafebabe}};

        #20 rst = 1;
        $display("[Cycle %0d] RESET released", cycle_count);

        // Write key
        bus_write(8'h10, 32'h00112233);
        bus_write(8'h11, 32'h44556677);
        bus_write(8'h12, 32'h8899aabb);
        bus_write(8'h13, 32'hccddeeff);
        bus_write(8'h14, 32'h01234567);
        bus_write(8'h15, 32'h89abcdef);
        bus_write(8'h16, 32'hfedcba98);
        bus_write(8'h17, 32'h76543210);

        // Write nonce
        bus_write(8'h20, 32'h11111111);
        bus_write(8'h21, 32'h22222222);
        bus_write(8'h22, 32'h33333333);

        // -------------------------
        // Process two different data inputs
        // -------------------------
        for (blk = 0; blk < 2; blk = blk + 1) begin
            if(blk==0) bus_write(8'h30, data_input0);
            else      bus_write(8'h30, data_input1);

            // INIT
            bus_write(8'h08, 512'h1);
            $display("[Cycle %0d] INIT asserted for block %0d", cycle_count, blk);

            // NEXT
            bus_write(8'h08, 512'h2);
            $display("[Cycle %0d] NEXT asserted for block %0d", cycle_count, blk);

            // Wait for valid output
            while(1) begin
                bus_read(8'h09); // read status
                if(rdata[1]) begin
                    bus_read(8'h30); // read data_out
                    $display("[Cycle %0d] VALID output for block %0d", cycle_count, blk);
                    disable while;
                end
                @(posedge clk);
            end

            // Wait for tag
            while(1) begin
                bus_read(8'h09);
                if(rdata[2]) begin
                    bus_read(8'h40); // read tag
                    $display("[Cycle %0d] TAG computed for block %0d", cycle_count, blk);
                    disable while;
                end
                @(posedge clk);
            end

            // Done
            bus_write(8'h08, 512'h4);

            $display("Block %0d processing done. Total cycles so far: %0d\n", blk, cycle_count);
        end

        $display("Total simulation cycles for 2 data blocks = %0d", cycle_count);
        #20 $finish;
    end
endmodule
