// ChaCha20 512-bit block using pipelined quarter rounds
`timescale 1ns/1ps
module chacha_block(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [511:0] state_in,
    output reg  [511:0] state_out
);
    reg [31:0] w[0:15];
    reg [31:0] t[0:15];
    integer i;

    // Load input words
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0;i<16;i=i+1) w[i] <= 0;
        end else begin
            for(i=0;i<16;i=i+1)
                w[i] <= state_in[511-i*32 -:32];
        end
    end

    // Main 10-round pipeline
    reg [31:0] temp[0:15];
    integer round, j;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0;i<16;i=i+1) t[i] <= 0;
        end else begin
            for(i=0;i<16;i=i+1) t[i] <= w[i];

            for(round=0; round<10; round=round+1) begin
                // Column rounds
                chacha_quarterround cr0(t[0],t[4],t[8],t[12],temp[0],temp[4],temp[8],temp[12]);
                chacha_quarterround cr1(t[1],t[5],t[9],t[13],temp[1],temp[5],temp[9],temp[13]);
                chacha_quarterround cr2(t[2],t[6],t[10],t[14],temp[2],temp[6],temp[10],temp[14]);
                chacha_quarterround cr3(t[3],t[7],t[11],t[15],temp[3],temp[7],temp[11],temp[15]);

                // Diagonal rounds
                chacha_quarterround crd0(temp[0],temp[5],temp[10],temp[15],t[0],t[5],t[10],t[15]);
                chacha_quarterround crd1(temp[1],temp[6],temp[11],temp[12],t[1],t[6],t[11],t[12]);
                chacha_quarterround crd2(temp[2],temp[7],temp[8],temp[13],t[2],t[7],t[8],t[13]);
                chacha_quarterround crd3(temp[3],temp[4],temp[9],temp[14],t[3],t[4],t[9],t[14]);
            end

            // Feed-forward
            for(i=0;i<16;i=i+1)
                state_out[511-i*32 -:32] <= t[i] + w[i];
        end
    end
endmodule
