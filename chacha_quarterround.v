// Quarter-round operation for ChaCha20
module chacha_quarterround(
    input  wire [31:0] a_in, b_in, c_in, d_in,
    output wire [31:0] a_out, b_out, c_out, d_out
);
    wire [31:0] a1, b1, c1, d1;
    // a += b; d ^= a; d <<<=16
    assign a1 = a_in + b_in;
    assign d1 = { (d_in ^ a1) [15:0], (d_in ^ a1) [31:16] }; // rotate left 16
    // c += d; b ^= c; b <<<=12
    assign c1 = c_in + d1;
    assign b1 = { (b_in ^ c1) [19:0], (b_in ^ c1) [31:20] }; // rotate left 12
    // a += b; d ^= a; d <<<=8
    assign a_out = a1 + b1;
    assign d_out = { (d1 ^ a_out)[23:0], (d1 ^ a_out)[31:24] }; // rotate left 8
    // c += d; b ^= c; b <<<=7
    assign c_out = c1 + d_out;
    assign b_out = { (b1 ^ c_out)[24:0], (b1 ^ c_out)[31:25] }; // rotate left 7
endmodule
