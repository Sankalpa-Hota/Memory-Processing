// chacha_quarterround.v
// ChaCha quarter round
module chacha_quarterround(
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    input  wire [31:0] c_in,
    input  wire [31:0] d_in,
    output wire [31:0] a_out,
    output wire [31:0] b_out,
    output wire [31:0] c_out,
    output wire [31:0] d_out
);

    wire [31:0] t1, t2, t3, t4;

    assign t1 = a_in + b_in;
    assign d_out = { (d_in ^ t1) << 16 } | { (d_in ^ t1) >> (32-16) }; // ROTL 16

    assign t2 = c_in + d_out;
    assign b_out = { (b_in ^ t2) << 12 } | { (b_in ^ t2) >> (32-12) }; // ROTL 12

    assign t3 = a_in + b_out;
    assign d_out = { (d_out ^ t3) << 8 } | { (d_out ^ t3) >> (32-8) };   // ROTL 8

    assign t4 = c_in + d_out;
    assign b_out = { (b_out ^ t4) << 7 } | { (b_out ^ t4) >> (32-7) };   // ROTL 7

    assign a_out = t3;
    assign c_out = t4;

endmodule
