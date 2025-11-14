// chacha_quarterround.v
// Corrected ChaCha quarter round
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

    // intermediate wires
    wire [31:0] a1, b1, c1, d1;
    wire [31:0] a2, b2, c2, d2;
    wire [31:0] a3, b3, c3, d3;
    wire [31:0] a4, b4, c4, d4;

    // Step 1
    assign a1 = a_in + b_in;
    assign d1 = { (d_in ^ a1) << 16 } | { (d_in ^ a1) >> (32-16) };
    assign c1 = c_in + d1;
    assign b1 = { (b_in ^ c1) << 12 } | { (b_in ^ c1) >> (32-12) };

    // Step 2
    assign a2 = a1 + b1;
    assign d2 = { (d1 ^ a2) << 8 } | { (d1 ^ a2) >> (32-8) };
    assign c2 = c1 + d2;
    assign b2 = { (b1 ^ c2) << 7 } | { (b1 ^ c2) >> (32-7) };

    // outputs
    assign a_out = a2;
    assign b_out = b2;
    assign c_out = c2;
    assign d_out = d2;

endmodule
