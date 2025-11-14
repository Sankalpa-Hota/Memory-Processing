// chacha_block.v
// ChaCha20 512-bit block implementation using quarter rounds
// Input: 512-bit state = {constants, key, counter, nonce}
// Output: 512-bit keystream block

module chacha_block(
    input  wire [511:0] state_in,
    output wire [511:0] state_out
);

    // Internal state: 16 words of 32-bit
    wire [31:0] x0, x1, x2, x3, x4, x5, x6, x7;
    wire [31:0] x8, x9, x10, x11, x12, x13, x14, x15;

    assign x0  = state_in[511:480];
    assign x1  = state_in[479:448];
    assign x2  = state_in[447:416];
    assign x3  = state_in[415:384];
    assign x4  = state_in[383:352];
    assign x5  = state_in[351:320];
    assign x6  = state_in[319:288];
    assign x7  = state_in[287:256];
    assign x8  = state_in[255:224];
    assign x9  = state_in[223:192];
    assign x10 = state_in[191:160];
    assign x11 = state_in[159:128];
    assign x12 = state_in[127:96];
    assign x13 = state_in[95:64];
    assign x14 = state_in[63:32];
    assign x15 = state_in[31:0];

    // Declare registers for rounds
    reg [31:0] state [0:15];
    integer i;

    always @(*) begin
        state[0]  = x0;
        state[1]  = x1;
        state[2]  = x2;
        state[3]  = x3;
        state[4]  = x4;
        state[5]  = x5;
        state[6]  = x6;
        state[7]  = x7;
        state[8]  = x8;
        state[9]  = x9;
        state[10] = x10;
        state[11] = x11;
        state[12] = x12;
        state[13] = x13;
        state[14] = x14;
        state[15] = x15;

        // 20 rounds: 10 column + 10 diagonal
        for (i=0; i<10; i=i+1) begin
            // Column rounds
            column_round(state);
            // Diagonal rounds
            diagonal_round(state);
        end
    end

    // Column round procedure
    task column_round(inout reg [31:0] s[0:15]);
        reg [31:0] a,b,c,d;
        begin
            // Column 0
            a = s[0]; b = s[4]; c = s[8]; d = s[12];
            chacha_quarterround QR0(a,b,c,d, s[0],s[4],s[8],s[12]);

            // Column 1
            a = s[1]; b = s[5]; c = s[9]; d = s[13];
            chacha_quarterround QR1(a,b,c,d, s[1],s[5],s[9],s[13]);

            // Column 2
            a = s[2]; b = s[6]; c = s[10]; d = s[14];
            chacha_quarterround QR2(a,b,c,d, s[2],s[6],s[10],s[14]);

            // Column 3
            a = s[3]; b = s[7]; c = s[11]; d = s[15];
            chacha_quarterround QR3(a,b,c,d, s[3],s[7],s[11],s[15]);
        end
    endtask

    // Diagonal round procedure
    task diagonal_round(inout reg [31:0] s[0:15]);
        reg [31:0] a,b,c,d;
        begin
            // Diagonal 0
            a = s[0]; b = s[5]; c = s[10]; d = s[15];
            chacha_quarterround QR0(a,b,c,d, s[0],s[5],s[10],s[15]);

            // Diagonal 1
            a = s[1]; b = s[6]; c = s[11]; d = s[12];
            chacha_quarterround QR1(a,b,c,d, s[1],s[6],s[11],s[12]);

            // Diagonal 2
            a = s[2]; b = s[7]; c = s[8]; d = s[13];
            chacha_quarterround QR2(a,b,c,d, s[2],s[7],s[8],s[13]);

            // Diagonal 3
            a = s[3]; b = s[4]; c = s[9]; d = s[14];
            chacha_quarterround QR3(a,b,c,d, s[3],s[4],s[9],s[14]);
        end
    endtask

    // Add original state (feed-forward)
    wire [31:0] final_state [0:15];
    genvar g;
    generate
        for (g=0; g<16; g=g+1) begin : add_feedforward
            assign final_state[g] = state[g] + state_in[511 - g*32 -: 32];
        end
    endgenerate

    // Recombine output
    assign state_out = {final_state[0], final_state[1], final_state[2], final_state[3],
                        final_state[4], final_state[5], final_state[6], final_state[7],
                        final_state[8], final_state[9], final_state[10], final_state[11],
                        final_state[12], final_state[13], final_state[14], final_state[15]};

endmodule
