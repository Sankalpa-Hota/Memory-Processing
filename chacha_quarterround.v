// ChaCha20 32-bit quarter round
`timescale 1ns/1ps

module chacha_quarterround(
    input  wire [31:0] a_in, b_in, c_in, d_in,
    output wire [31:0] a_out, b_out, c_out, d_out
);
    wire [31:0] a1 = a_in + b_in;
    wire [31:0] d1 = { (d_in ^ a1) << 16 } | { (d_in ^ a1) >> (32-16) };
    wire [31:0] c1 = c_in + d1;
    wire [31:0] b1 = { (b_in ^ c1) << 12 } | { (b_in ^ c1) >> (32-12) };
    wire [31:0] a2 = a1 + b1;
    wire [31:0] d2 = { (d1 ^ a2) << 8 } | { (d1 ^ a2) >> (32-8) };
    wire [31:0] c2 = c1 + d2;
    wire [31:0] b2 = { (b1 ^ c2) << 7 } | { (b1 ^ c2) >> (32-7) };

    assign a_out = a2;
    assign b_out = b2;
    assign c_out = c2;
    assign d_out = d2;
endmodule

