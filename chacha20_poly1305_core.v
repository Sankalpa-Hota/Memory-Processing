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

    chacha_core cha_inst(
        .clk(clk),
        .reset_n(reset_n),
        .init(init),
        .next(next),
        .key(key),
        .ctr({32'h0, nonce[31:0]}),
        .iv(nonce[95:32]),
        .data_in(data_in),
        .ready(chacha_ready),
        .data_out_valid(chacha_valid),
        .data_out(chacha_data_out)
    );

    reg mul_start;
    reg [129:0] mul_a;
    reg [127:0] mul_b;
    wire [257:0] mul_product;
    wire mul_done;

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

    reg red_start;
    wire [129:0] red_out;
    wire red_done;

    reduce_mod_poly1305 red_inst(
        .clk(clk),
        .reset_n(reset_n),
        .start(red_start),
        .value_in(mul_product),
        .value_out(red_out),
        .busy(),
        .done(red_done)
    );

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            r_reg <= 128'h0;
            s_reg <= 128'h0;
            acc_reg <= 130'h0;
            ready <= 1'b1;
            valid <= 0;
            tag_ok <= 0;
            mul_start <= 0;
            red_start <= 0;
        end else begin
            valid <= 0;
            tag_ok <= 0;

            if(chacha_valid) begin
                r_reg <= chacha_data_out[127:0];
                s_reg <= chacha_data_out[255:128];
                mul_a <= {2'b0, acc_reg} + {2'b0, data_in[127:0]};
                mul_b <= r_reg;
                mul_start <= 1'b1;
            end

            if(mul_done) begin
                mul_start <= 0;
                red_start <= 1'b1;
            end

            if(red_done) begin
                acc_reg <= red_out;
                red_start <= 0;
                valid <= 1'b1;
            end

            if(done) tag_ok <= 1'b1;
        end
    end

    assign data_out = chacha_data_out;
    assign tag = acc_reg[127:0] + s_reg;
endmodule
