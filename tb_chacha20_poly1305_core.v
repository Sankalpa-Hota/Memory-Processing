`timescale 1ns/1ps
module tb_chacha20_poly1305_core;
    reg clk, rst, init, next, done, encdec;
    reg [255:0] key;
    reg [95:0] nonce;
    reg [511:0] data_in;
    wire ready, valid, tag_ok;
    wire [511:0] data_out;
    wire [127:0] tag;

    integer cycle_count;
    integer data_idx;

    reg [511:0] data_blocks [0:1];

    initial clk = 0;
    always #5 clk = ~clk;

    chacha20_poly1305_core dut(
        .clk(clk),
        .reset_n(rst),
        .init(init),
        .next(next),
        .done(done),
        .encdec(encdec),
        .key(key),
        .nonce(nonce),
        .data_in(data_in),
        .ready(ready),
        .valid(valid),
        .tag_ok(tag_ok),
        .data_out(data_out),
        .tag(tag)
    );

    initial begin
        $dumpfile("tb_chacha20_poly1305_core.vcd");
        $dumpvars(0, tb_chacha20_poly1305_core);
    end

    initial cycle_count = 0;
    always @(posedge clk) cycle_count = cycle_count + 1;

    initial begin
        // 512-bit data blocks
        data_blocks[0] = {8{64'hcafebabedeadbeef}};
        data_blocks[1] = {8{64'h0123456789abcdef}};

        // Reset
        rst = 0; init=0; next=0; done=0; encdec=1;
        key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        nonce = {32'h11111111,32'h22222222,32'h33333333};

        #20 rst = 1;

        for(data_idx=0; data_idx<2; data_idx=data_idx+1) begin
            data_in = data_blocks[data_idx];

            @(posedge clk);
            init = 1; @(posedge clk); init = 0;

            @(posedge clk);
            next = 1; @(posedge clk); next = 0;

            // Wait for valid with timeout
            integer timeout;
            timeout = 0;
            while(!valid && timeout < 50000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if(timeout == 50000) begin
                $display("ERROR: VALID timeout!");
                $finish;
            end
            $display("[Cycle %0d] DATA_BLOCK %0d encrypted: %h", cycle_count, data_idx, data_out);

            @(posedge clk);
            done = 1; @(posedge clk); done = 0;

            // Wait for tag
            timeout = 0;
            while(!tag_ok && timeout < 50000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if(timeout == 50000) begin
                $display("ERROR: TAG timeout!");
                $finish;
            end
            $display("[Cycle %0d] DATA_BLOCK %0d tag = %h", cycle_count, data_idx, tag);
        end

        $display("Simulation done. Total cycles = %0d", cycle_count);
        #20 $finish;
    end
endmodule

