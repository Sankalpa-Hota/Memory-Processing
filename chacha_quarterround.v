// ChaCha20 Quarter Round - fully synthesizable, pure Verilog
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
    wire [31:0] t1 = a_in + b_in;
    wire [31:0] t2 = c_in + d_in;

    wire [31:0] d1 = { (d_in ^ t1) << 16 } | { (d_in ^ t1) >> 16 };
    wire [31:0] b1 = { (b_in ^ t2) << 12 } | { (b_in ^ t2) >> 20 };

    wire [31:0] t3 = a_in + b1;
    wire [31:0] d2 = { (d1 ^ t3) << 8 } | { (d1 ^ t3) >> 24 };

    wire [31:0] t4 = c_in + d2;
    wire [31:0] b2 = { (b1 ^ t4) << 7 } | { (b1 ^ t4) >> 25 };

    assign a_out = t3;
    assign b_out = b2;
    assign c_out = t4;
    assign d_out = d2;
endmodule
