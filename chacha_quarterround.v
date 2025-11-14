module chacha_quarterround(
    input  wire [31:0] a_in,
    input  wire [31:0] b_in,
    input  wire [31:0] c_in,
    input  wire [31:0] d_in,
    output [31:0] a_out,
    output [31:0] b_out,
    output [31:0] c_out,
    output [31:0] d_out
);

    function [31:0] rotl;
        input [31:0] x;
        input [4:0] n;
        begin
            rotl = (x << n) | (x >> (32-n));
        end
    endfunction

    wire [31:0] t1 = a_in + b_in;
    wire [31:0] t2 = c_in + d_in;

    wire [31:0] d1 = rotl(d_in ^ t1, 16);
    wire [31:0] b1 = rotl(b_in ^ t2, 12);

    wire [31:0] t3 = a_in + b1;
    wire [31:0] d2 = rotl(d1 ^ t3, 8);
    wire [31:0] t4 = c_in + d2;
    wire [31:0] b2 = rotl(b1 ^ t4, 7);

    assign a_out = t3;
    assign b_out = b2;
    assign c_out = t4;
    assign d_out = d2;

endmodule

