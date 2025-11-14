`timescale 1ns/1ps
`include "chacha_functions.v"

module chacha_block(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [511:0] state_in,
    output reg  [511:0] state_out
);
    reg [31:0] w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15;
    reg [31:0] t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15;
    integer r;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_out <= 512'h0;
            w0<=0;w1<=0;w2<=0;w3<=0;w4<=0;w5<=0;w6<=0;w7<=0;
            w8<=0;w9<=0;w10<=0;w11<=0;w12<=0;w13<=0;w14<=0;w15<=0;
            t0<=0;t1<=0;t2<=0;t3<=0;t4<=0;t5<=0;t6<=0;t7<=0;
            t8<=0;t9<=0;t10<=0;t11<=0;t12<=0;t13<=0;t14<=0;t15<=0;
        end else begin
            // load state_in
            w0  = state_in[511:480]; w1  = state_in[479:448]; w2  = state_in[447:416]; w3  = state_in[415:384];
            w4  = state_in[383:352]; w5  = state_in[351:320]; w6  = state_in[319:288]; w7  = state_in[287:256];
            w8  = state_in[255:224]; w9  = state_in[223:192]; w10 = state_in[191:160]; w11 = state_in[159:128];
            w12 = state_in[127:96];  w13 = state_in[95:64];   w14 = state_in[63:32];   w15 = state_in[31:0];

            // copy to t
            t0=w0; t1=w1; t2=w2; t3=w3; t4=w4; t5=w5; t6=w6; t7=w7;
            t8=w8; t9=w9; t10=w10; t11=w11; t12=w12; t13=w13; t14=w14; t15=w15;

            // 10 double rounds
            for(r=0;r<10;r=r+1) begin
                {t0,t4,t8,t12}   = chacha_functions.quarterround(t0,t4,t8,t12);
                {t1,t5,t9,t13}   = chacha_functions.quarterround(t1,t5,t9,t13);
                {t2,t6,t10,t14}  = chacha_functions.quarterround(t2,t6,t10,t14);
                {t3,t7,t11,t15}  = chacha_functions.quarterround(t3,t7,t11,t15);

                {t0,t5,t10,t15}  = chacha_functions.quarterround(t0,t5,t10,t15);
                {t1,t6,t11,t12}  = chacha_functions.quarterround(t1,t6,t11,t12);
                {t2,t7,t8,t13}   = chacha_functions.quarterround(t2,t7,t8,t13);
                {t3,t4,t9,t14}   = chacha_functions.quarterround(t3,t4,t9,t14);
            end

            // feed-forward
            state_out[511:480] <= t0 + w0;   state_out[479:448] <= t1 + w1;
            state_out[447:416] <= t2 + w2;   state_out[415:384] <= t3 + w3;
            state_out[383:352] <= t4 + w4;   state_out[351:320] <= t5 + w5;
            state_out[319:288] <= t6 + w6;   state_out[287:256] <= t7 + w7;
            state_out[255:224] <= t8 + w8;   state_out[223:192] <= t9 + w9;
            state_out[191:160] <= t10 + w10; state_out[159:128] <= t11 + w11;
            state_out[127:96]  <= t12 + w12; state_out[95:64]  <= t13 + w13;
            state_out[63:32]   <= t14 + w14; state_out[31:0]   <= t15 + w15;
        end
    end
endmodule
