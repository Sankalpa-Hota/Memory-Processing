`timescale 1ns/1ps
module chacha20_poly1305_core(
    input  wire clk,
    input  wire reset_n,
    input  wire init,
    input  wire next,
    input  wire done,
    input  wire encdec,
    input  wire [255:0] key,
    input  wire [95:0] nonce,
    input  wire [511:0] data_in,
    output reg  ready,
    output reg  valid,
    output reg  tag_ok,
    output wire [511:0] data_out,
    output wire [127:0] tag
);
    reg [127:0] r_reg, s_reg;
    reg [129:0] acc_reg;

    wire [511:0] chacha_data_out;
    wire chacha_ready, chacha_valid;
    wire block_done;
    reg chacha_start;

    // instantiate chacha_core (which uses chacha_block)
    chacha_core cha_inst(
        .clk(clk),
        .reset_n(reset_n),
        .init(chacha_start),
        .next(1'b0),
        .key(key),
        .ctr({32'h0, nonce[31:0]}),
        .iv(nonce[95:32]),
        .data_in(data_in),
        .ready(chacha_ready),
        .data_out_valid(chacha_valid),
        .data_out(chacha_data_out)
    );

    // multiplier and reducer
    reg mul_start, red_start;
    reg [129:0] mul_a;
    reg [127:0] mul_b;
    wire [257:0] mul_product;
    wire mul_done;
    wire [129:0] red_out;
    wire red_done;

    mult_130x128_limb mult_inst(
        .clk(clk),
        .reset_n(reset_n),
        .start(mul_start),
        .a_in(mul_a),
        .b_in(mul_b),
        .product_out(mul_product),
        .busy(),
        .done(mul_done)
    );

    reduce_mod_poly1305 red_inst(
        .clk(clk),
        .reset_n(reset_n),
        .start(red_start),
        .value_in(mul_product),
        .value_out(red_out),
        .busy(),
        .done(red_done)
    );

    // capture rising edge of chacha_valid (one-cycle)
    reg chacha_valid_d;
    wire chacha_valid_rise;
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) chacha_valid_d <= 1'b0;
        else chacha_valid_d <= chacha_valid;
    end
    assign chacha_valid_rise = chacha_valid & ~chacha_valid_d;

    // main control
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            ready <= 1'b1;
            valid <= 1'b0;
            tag_ok <= 1'b0;
            chacha_start <= 1'b0;
            mul_start <= 1'b0;
            red_start <= 1'b0;
            r_reg <= 128'b0;
            s_reg <= 128'b0;
            acc_reg <= 130'b0;
            mul_a <= 130'b0;
            mul_b <= 128'b0;
        end else begin
            // default single-cycle deasserts
            valid <= 1'b0;
            tag_ok <= 1'b0;
            chacha_start <= 1'b0;
            mul_start <= 1'b0;
            red_start <= 1'b0;

            if(init && ready) begin
                // start ChaCha generation for this block
                chacha_start <= 1'b1;
                ready <= 1'b0;
            end

            // when ChaCha data is ready, chacha_valid_rise pulses
            if(chacha_valid_rise) begin
                // capture r and s
                r_reg <= chacha_data_out[127:0];
                s_reg <= chacha_data_out[255:128];
                // prepare multiply: (acc + data_low) * r
                mul_a <= {2'b0, acc_reg} + {2'b0, data_in[127:0]};
                mul_b <= chacha_data_out[127:0];
                mul_start <= 1'b1;
            end

            if(mul_done) begin
                red_start <= 1'b1;
            end

            if(red_done) begin
                acc_reg <= red_out;
                valid <= 1'b1; // accumulator updated
                ready <= 1'b1; // ready for next block
            end

            if(done) begin
                tag_ok <= 1'b1;
            end
        end
    end

    assign data_out = chacha_data_out;
    assign tag = acc_reg[127:0] + s_reg;
endmodule
