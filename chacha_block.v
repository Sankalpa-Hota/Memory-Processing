// ChaCha20 512-bit block using quarter rounds
module chacha_block(
    input  wire [511:0] state_in,
    output wire [511:0] state_out
);

    reg [31:0] state [0:15];
    integer i;

    // Initialize internal state words
    always @(*) begin
        for (i=0; i<16; i=i+1)
            state[i] = state_in[511-i*32 -: 32];
    end

    // 20 rounds: 10 column + 10 diagonal
    always @(*) begin
        for (i=0; i<10; i=i+1) begin
            column_round(state);
            diagonal_round(state);
        end
    end

    task column_round(inout reg [31:0] s[0:15]);
        begin
            chacha_quarterround QR0(s[0],s[4],s[8],s[12], s[0],s[4],s[8],s[12]);
            chacha_quarterround QR1(s[1],s[5],s[9],s[13], s[1],s[5],s[9],s[13]);
            chacha_quarterround QR2(s[2],s[6],s[10],s[14], s[2],s[6],s[10],s[14]);
            chacha_quarterround QR3(s[3],s[7],s[11],s[15], s[3],s[7],s[11],s[15]);
        end
    endtask

    task diagonal_round(inout reg [31:0] s[0:15]);
        begin
            chacha_quarterround QR0(s[0],s[5],s[10],s[15], s[0],s[5],s[10],s[15]);
            chacha_quarterround QR1(s[1],s[6],s[11],s[12], s[1],s[6],s[11],s[12]);
            chacha_quarterround QR2(s[2],s[7],s[8],s[13], s[2],s[7],s[8],s[13]);
            chacha_quarterround QR3(s[3],s[4],s[9],s[14], s[3],s[4],s[9],s[14]);
        end
    endtask

    // Feed-forward original state
    wire [31:0] final_state [0:15];
    genvar g;
    generate
        for (g=0; g<16; g=g+1) begin : add_feedforward
            assign final_state[g] = state[g] + state_in[511 - g*32 -: 32];
        end
    endgenerate

    assign state_out = {final_state[0], final_state[1], final_state[2], final_state[3],
                        final_state[4], final_state[5], final_state[6], final_state[7],
                        final_state[8], final_state[9], final_state[10], final_state[11],
                        final_state[12], final_state[13], final_state[14], final_state[15]};
endmodule
