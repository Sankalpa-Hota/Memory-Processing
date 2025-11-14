`timescale 1ns/1ps
module tb_chacha20_poly1305_bus;
    reg clk, rst, cs, we;
    reg [7:0] addr;
    reg [511:0] wdata;
    wire [511:0] rdata;

    integer cycle_count;
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

    // 32-bit write task
    task bus_write32(input [7:0] a, input [31:0] v);
    begin
        @(posedge clk); cs=1; we=1; addr=a; wdata={480'h0,v};
        @(posedge clk); cs=0; we=0;
    end
    endtask

    // 512-bit write task
    task bus_write512(input [7:0] a, input [511:0] v);
    begin
        @(posedge clk); cs=1; we=1; addr=a; wdata=v;
        @(posedge clk); cs=0; we=0;
    end
    endtask

    // 32-bit read task
    task bus_read32(input [7:0] a, output [31:0] val);
    begin
        @(posedge clk); cs=1; we=0; addr=a;
        @(posedge clk); cs=0;
        val = rdata[31:0];
    end
    endtask

    initial begin
        rst = 0; cs=0; we=0; addr=0; wdata=0;

        data_input0 = {16{32'hdeadbeef}};
        data_input1 = {16{32'hcafebabe}};

        #20 rst = 1;

        // Write key
        bus_write32(8'h10, 32'h00112233);
        bus_write32(8'h11, 32'h44556677);
        bus_write32(8'h12, 32'h8899aabb);
        bus_write32(8'h13, 32'hccddeeff);
        bus_write32(8'h14, 32'h01234567);
        bus_write32(8'h15, 32'h89abcdef);
        bus_write32(8'h16, 32'hfedcba98);
        bus_write32(8'h17, 32'h76543210);

        // Write nonce
        bus_write32(8'h20, 32'h11111111);
        bus_write32(8'h21, 32'h22222222);
        bus_write32(8'h22, 32'h33333333);

        for(blk=0; blk<2; blk=blk+1) begin
            if(blk==0) bus_write512(8'h30, data_input0);
            else      bus_write512(8'h30, data_input1);

            // INIT
            bus_write32(8'h08, 32'h1);

            // NEXT
            bus_write32(8'h08, 32'h2);

            // Wait for valid
            integer timeout; timeout=0;
            while(1) begin
                bus_read32(8'h09, wdata[31:0]);
                if(wdata[1]) break;
                @(posedge clk);
                timeout = timeout + 1;
                if(timeout>50000) begin $display("ERROR: VALID timeout"); $finish; end
            end

            // Read data
            bus_read32(8'h30, wdata[31:0]);
            $display("[Cycle %0d] VALID output block %0d", cycle_count, blk);

            // Wait for tag
            timeout=0;
            while(1) begin
                bus_read32(8'h09, wdata[31:0]);
                if(wdata[2]) break;
                @(posedge clk);
                timeout = timeout + 1;
                if(timeout>50000) begin $display("ERROR: TAG timeout"); $finish; end
            end

            bus_read32(8'h40, wdata[31:0]);
            $display("[Cycle %0d] TAG computed block %0d", cycle_count, blk);

            // DONE
            bus_write32(8'h08, 32'h4);
        end

        $display("Simulation complete. Total cycles = %0d", cycle_count);
        #20 $finish;
    end
endmodule

