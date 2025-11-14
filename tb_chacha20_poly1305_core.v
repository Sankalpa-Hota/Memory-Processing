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
    integer step_cycle_count;
    integer blk, data_idx;

    reg [511:0] data_blocks [0:1]; // two different data blocks

    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

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
        // Initialize two different 512-bit data blocks
        data_blocks[0] = {8{64'hcafebabedeadbeef}};
        data_blocks[1] = {8{64'h0123456789abcdef}};

        // Reset & configuration
        rst = 0; init = 0; next = 0; done = 0; encdec = 1;
        key = 256'h0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        nonce = {32'h11111111,32'h22222222,32'h33333333};

        #20 rst = 1;
        $display("[Cycle %0d] RESET released", cycle_count);
        $display("Key size = %0d bits", $bits(key));

        // Loop over two data blocks
        for (data_idx = 0; data_idx < 2; data_idx = data_idx + 1) begin
            data_in = data_blocks[data_idx];
            $display("[Cycle %0d] DATA_BLOCK %0d loaded, size = %0d bits, data_in = %h",
                     cycle_count, data_idx, $bits(data_in), data_in);

            // INIT step
            step_cycle_count = cycle_count;
            init = 1; @(posedge clk); init = 0;
            $display("[Cycle %0d] INIT asserted for DATA_BLOCK %0d, cycles = %0d",
                     cycle_count, data_idx, cycle_count - step_cycle_count);

            // NEXT step (start encryption)
            step_cycle_count = cycle_count;
            next = 1; @(posedge clk); next = 0;
            $display("[Cycle %0d] NEXT asserted for DATA_BLOCK %0d, starting encryption",
                     cycle_count, data_idx);

            // Wait for valid output
            step_cycle_count = cycle_count;
            while(!valid) @(posedge clk);
            $display("[Cycle %0d] VALID data_out received for DATA_BLOCK %0d, data_out size = %0d bits, data_out = %h",
                     cycle_count, data_idx, $bits(data_out), data_out);
            $display("Encryption cycles taken = %0d", cycle_count - step_cycle_count);

            // Wait for tag computation
            step_cycle_count = cycle_count;
            while(!tag_ok) @(posedge clk);
            $display("[Cycle %0d] TAG computed for DATA_BLOCK %0d, tag size = %0d bits, tag = %h",
                     cycle_count, data_idx, $bits(tag), tag);
            $display("Tag computation cycles = %0d", cycle_count - step_cycle_count);

            // DONE step
            step_cycle_count = cycle_count;
            done = 1; @(posedge clk); done = 0;
            $display("[Cycle %0d] DONE asserted for DATA_BLOCK %0d, cycles = %0d",
                     cycle_count, data_idx, cycle_count - step_cycle_count);

            $display("------------------------------------------------------");
        end

        $display("Total simulation cycles for all DATA_BLOCKS = %0d", cycle_count);
        #20 $finish;
    end
endmodule
