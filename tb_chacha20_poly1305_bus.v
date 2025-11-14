`timescale 1ns/1ps
module tb_chacha20_poly1305_bus;
    reg clk, rst, cs, we;
    reg [7:0] addr;
    reg [511:0] wdata;
    wire [511:0] rdata;

    integer cycle_count, blk, ds;
    reg [511:0] data_inputs[0:9];
    reg waiting;
    reg [511:0] read_val;

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

    // Bus write task
    task bus_write(input [7:0] a, input [511:0] v);
    begin
        @(posedge clk); cs=1; we=1; addr=a; wdata=v;
        @(posedge clk); cs=0; we=0;
    end
    endtask

    // Bus read task
    task bus_read(input [7:0] a, output [511:0] r);
    begin
        @(posedge clk); cs=1; we=0; addr=a;
        @(posedge clk); cs=0;
        r = rdata;
    end
    endtask

    initial begin
        rst = 0; cs=0; we=0; addr=0; wdata=0;

        // Generate 10 datasets
        for(ds=0; ds<10; ds=ds+1)
            data_inputs[ds] = {16{32'h1000 + ds}};

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

        // Process 10 datasets
        for(blk=0; blk<10; blk=blk+1) begin
            bus_write(8'h30, data_inputs[blk]);

            // INIT
            bus_write(8'h08, 512'h1);

            // NEXT
            bus_write(8'h08, 512'h2);

            // wait for valid output
            waiting = 1;
            while(waiting) begin
                bus_read(8'h09, read_val);
                if(read_val[1]) begin
                    bus_read(8'h30, read_val);
                    $display("[Cycle %0d] VALID output block %0d: %h", cycle_count, blk, read_val);
                    waiting = 0;
                end
            end

            // wait for tag
            waiting = 1;
            while(waiting) begin
                bus_read(8'h09, read_val);
                if(read_val[2]) begin
                    bus_read(8'h40, read_val);
                    $display("[Cycle %0d] TAG block %0d: %h", cycle_count, blk, read_val);
                    waiting = 0;
                end
            end

            $display("Block %0d processing done. Total cycles so far: %0d\n", blk, cycle_count);
        end

        $display("Total simulation cycles for 10 blocks = %0d", cycle_count);
        #20 $finish;
    end
endmodule

