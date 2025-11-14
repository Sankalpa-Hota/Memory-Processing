// Quarter-round operation for ChaCha20
module chacha_quarterround(
    input  wire [31:0] a_in, b_in, c_in, d_in,
    output wire [31:0] a_out, b_out, c_out, d_out
);
    wire [31:0] a1, b1, c1, d1;

    // ChaCha quarter-round operations
    assign a1 = a_in + b_in;                       // a += b
    assign d1 = { (d_in ^ a1)[15:0], (d_in ^ a1)[31:16] }; // d ^= a; ROTL16
    assign c1 = c_in + d1;                         // c += d
    assign b1 = { (b_in ^ c1)[19:0], (b_in ^ c1)[31:20] }; // b ^= c; ROTL12
    assign a_out = a1 + b1;                        // a += b
    assign d_out = { (d1 ^ a_out)[23:0], (d1 ^ a_out)[31:24] }; // d ^= a; ROTL8
    assign c_out = c1 + d_out;                     // c += d
    assign b_out = { (b1 ^ c_out)[24:0], (b1 ^ c_out)[31:25] }; // b ^= c; ROTL7
endmodule
