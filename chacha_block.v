`timescale 1ns/1ps
`include "chacha_functions.v"

module chacha_block(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [511:0] state_in,
    output reg  [511:0] state_out
);
    reg [31:0] w[0:15];
    reg [31:0] t[0:15];
    integer i, r;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_out <= 512'h0;
            for(i=0;i<16;i=i+1) begin w[i]<=0; t[i]<=0; end
        end else begin
            // load state_in
            for(i=0;i<16;i=i+1)
                w[i] = state_in[511-i*32 -:32];

            t = w;

            // 10 double rounds (column + diagonal)
            for(r=0;r<10;r=r+1) begin
                // column rounds
                {t[0], t[4], t[8], t[12]} = chacha_functions.quarterround(t[0],t[4],t[8],t[12]);
                {t[1], t[5], t[9], t[13]} = chacha_functions.quarterround(t[1],t[5],t[9],t[13]);
                {t[2], t[6], t[10], t[14]} = chacha_functions.quarterround(t[2],t[6],t[10],t[14]);
                {t[3], t[7], t[11], t[15]} = chacha_functions.quarterround(t[3],t[7],t[11],t[15]);

                // diagonal rounds
                {t[0], t[5], t[10], t[15]} = chacha_functions.quarterround(t[0],t[5],t[10],t[15]);
                {t[1], t[6], t[11], t[12]} = chacha_functions.quarterround(t[1],t[6],t[11],t[12]);
                {t[2], t[7], t[8], t[13]} = chacha_functions.quarterround(t[2],t[7],t[8],t[13]);
                {t[3], t[4], t[9], t[14]} = chacha_functions.quarterround(t[3],t[4],t[9],t[14]);
            end

            // feed-forward
            for(i=0;i<16;i=i+1)
                state_out[511-i*32 -:32] <= t[i] + w[i];
        end
    end
endmodule
