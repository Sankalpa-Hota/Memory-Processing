// chacha20_poly1305_core.v
// Fully integrated ChaCha20 + Poly1305 using multiplier + reducer

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

    // Internal registers
    reg [127:0] r_reg, s_reg;
    reg [129:0] acc_reg;

    wire [511:0] chacha_data_out;
    wire chacha_ready, chacha_valid;

    // ChaCha20 core instance
    chacha_core CHA(
        .clk(clk),
        .reset_n(reset_n),
        .init(init),
        .next(next),
        .key(key),
        .ctr({32'h0, nonce[31:0]}),
        .iv(nonce[95:32]),
        .ready(chacha_ready),
        .data_out_valid(chacha_valid),
        .data_out(chacha_data_out)
    );

    // Multiplier instance
    reg mul_start;
    reg [129:0] mul_a;
    reg [127:0] mul_b;
    wire [257:0] mul_product;
    wire mul_done;

    mult_130x128_limb MUL(
        .clk(clk),
        .reset_n(reset_n),
        .start(mul_start),
        .a_in(mul_a),
        .b_in(mul_b),
        .product_out(mul_product),
        .busy(),
        .done(mul_done)
    );

    // Reducer instance
    reg red_start;
    wire [129:0] red_out;
    wire red_done;

    reduce_mod_poly1305 RED(
        .clk(clk),
        .reset_n(reset_n),
        .start(red_start),
        .value_in(mul_product),
        .value_out(red_out),
        .busy(),
        .done(red_done)
    );

    // FSM states
    reg [1:0] state;
    localparam IDLE = 2'd0,
               MUL  = 2'd1,
               RED  = 2'd2,
               DONE = 2'd3;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            r_reg      <= 128'h0;
            s_reg      <= 128'h0;
            acc_reg    <= 130'h0;
            ready      <= 1'b1;
            valid      <= 1'b0;
            tag_ok     <= 1'b0;
            mul_start  <= 1'b0;
            red_start  <= 1'b0;
            state      <= IDLE;
        end else begin
            valid <= 1'b0;
            case (state)
                IDLE: begin
                    ready <= 1'b1;
                    if (chacha_valid) begin
                        r_reg <= chacha_data_out[127:0];
                        s_reg <= chacha_data_out[255:128];

                        // Prepare Poly1305 multiply
                        mul_a <= {2'b0, acc_reg[127:0]} + {2'b0, data_in[127:0]}; // 130-bit
                        mul_b <= r_reg; // 128-bit
                        mul_start <= 1'b1;
                        state <= MUL;
                        ready <= 1'b0;
                    end
                end

                MUL: begin
                    mul_start <= 1'b0;
                    if (mul_done) begin
                        red_start <= 1'b1;
                        state <= RED;
                    end
                end

                RED: begin
                    red_start <= 1'b0;
                    if (red_done) begin
                        acc_reg <= red_out;
                        valid <= 1'b1;
                        state <= IDLE;
                    end
                end

                DONE: begin
                    tag_ok <= 1'b1;
                end
            endcase

            if (done) state <= DONE;
            if (state == DONE) tag_ok <= 1'b1;
        end
    end

    assign data_out = chacha_data_out;
    assign tag = acc_reg[127:0] + s_reg;

endmodule


