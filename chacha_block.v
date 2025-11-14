// ChaCha20 512-bit block using quarter rounds
module chacha_block(
    input  wire [511:0] state_in,
    output wire [511:0] state_out
);

    reg [31:0] w0,w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13,w14,w15;
    reg [31:0] t0,t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15;
    integer i;

    // Initialize words from input
    always @(*) begin
        w0  = state_in[511:480]; w1  = state_in[479:448];
        w2  = state_in[447:416]; w3  = state_in[415:384];
        w4  = state_in[383:352]; w5  = state_in[351:320];
        w6  = state_in[319:288]; w7  = state_in[287:256];
        w8  = state_in[255:224]; w9  = state_in[223:192];
        w10 = state_in[191:160]; w11 = state_in[159:128];
        w12 = state_in[127:96];  w13 = state_in[95:64];
        w14 = state_in[63:32];   w15 = state_in[31:0];
    end

    // 20 rounds: 10 column + 10 diagonal
    always @(*) begin
        // temporary working variables
        t0=w0; t1=w1; t2=w2; t3=w3; t4=w4; t5=w5; t6=w6; t7=w7;
        t8=w8; t9=w9; t10=w10; t11=w11; t12=w12; t13=w13; t14=w14; t15=w15;

        for (i=0; i<10; i=i+1) begin
            // Column round
            chacha_quarterround(t0,t4,t8,t12,t0,t4,t8,t12);
            chacha_quarterround(t1,t5,t9,t13,t1,t5,t9,t13);
            chacha_quarterround(t2,t6,t10,t14,t2,t6,t10,t14);
            chacha_quarterround(t3,t7,t11,t15,t3,t7,t11,t15);
            // Diagonal round
            chacha_quarterround(t0,t5,t10,t15,t0,t5,t10,t15);
            chacha_quarterround(t1,t6,t11,t12,t1,t6,t11,t12);
            chacha_quarterround(t2,t7,t8,t13,t2,t7,t8,t13);
            chacha_quarterround(t3,t4,t9,t14,t3,t4,t9,t14);
        end
    end

    // Feed-forward
    assign state_out = {t0+w0, t1+w1, t2+w2, t3+w3,
                        t4+w4, t5+w5, t6+w6, t7+w7,
                        t8+w8, t9+w9, t10+w10, t11+w11,
                        t12+w12, t13+w13, t14+w14, t15+w15};

endmodule
