`timescale 1ns/1ps
module tb_chacha20_poly1305_core;
    reg clk, rst, init, next, encdec;
    reg [255:0] key;
    reg [95:0] nonce;
    reg [511:0] data_in;
    wire ready, valid, tag_ok;
    wire [511:0] data_out;
    wire [127:0] tag;

    integer cycle_count;
    integer data_idx;

    reg [511:0] data_blocks [0:1];
    reg waiting_valid, waiting_tag;

    // Clock generation: 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Instantiate DUT
    chacha20_poly1305_core dut(
        .clk(clk),
        .reset_n(rst),
        .init(init),
        .next(next),
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

    // Dump waveforms
    initial begin
        $dumpfile("tb_chacha20_poly1305_core.vcd");
        $dumpvars(0, tb_chacha20_poly1305_core);
    end

    initial cycle_count = 0;
    always @(posedge clk) cycle_count = cycle_count + 1;

    initial begin
        // Initialize two 512-bit blocks
        data_blocks[0] = {8{64'hcafebabedeadbeef}};
        data_blocks[1] = {8{64'h0123456789abcdef}};

        // Reset & config
        rst = 0; init = 0; next = 0; encdec = 1;
        key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        nonce = {32'h11111111,32'h22222222,32'h33333333};

        #20 rst = 1;
        $display("[Cycle %0d] RESET released", cycle_count);

        // Process each data block
        for (data_idx = 0; data_idx < 2; data_idx = data_idx + 1) begin
            data_in = data_blocks[data_idx];
            $display("[Cycle %0d] DATA_BLOCK %0d loaded, data_in = %h", cycle_count, data_idx, data_in);

            // Start encryption
            init = 1; @(posedge clk); init = 0;
            $display("[Cycle %0d] INIT asserted for DATA_BLOCK %0d", cycle_count, data_idx);

            // Wait for valid output
            waiting_valid = 1;
            while (waiting_valid) begin
                @(posedge clk);
                if (valid) begin
                    $display("[Cycle %0d] VALID data_out for DATA_BLOCK %0d: %h", cycle_count, data_idx, data_out);
                    waiting_valid = 0;
                end
            end

            // Wait for tag
            waiting_tag = 1;
            while (waiting_tag) begin
                @(posedge clk);
                if (tag_ok) begin
                    $display("[Cycle %0d] TAG for DATA_BLOCK %0d: %h", cycle_count, data_idx, tag);
                    waiting_tag = 0;
                end
            end

            $display("------------------------------------------------------");
        end

        $display("Total simulation cycles for all DATA_BLOCKS = %0d", cycle_count);
        #20 $finish;
    end
endmodule
