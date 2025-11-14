// chacha_core.v
// Generates 512-bit keystream block using chacha_block
// ChaCha20 block: 16 words, 20 rounds
module chacha_block(
    input  wire [511:0] state_in,
    output reg  [511:0] state_out
);
    reg [31:0] x [0:15];
    integer i;

    always @(*) begin
        // unpack input 512-bit state into 16 words
        for(i=0;i<16;i=i+1) x[i] = state_in[i*32 +: 32];

        // Simple behavioral simulation: 20 rounds
        // Column rounds
        for(i=0;i<10;i=i+1) begin
            x[0] = x[0] + x[4]; x[12] = {x[12][15:0], x[12][31:16]} ^ x[0];
            x[1] = x[1] + x[5]; x[13] = {x[13][15:0], x[13][31:16]} ^ x[1];
            x[2] = x[2] + x[6]; x[14] = {x[14][15:0], x[14][31:16]} ^ x[2];
            x[3] = x[3] + x[7]; x[15] = {x[15][15:0], x[15][31:16]} ^ x[3];
            // Diagonal rounds simplified
            x[0] = x[0] + x[5]; x[15] = {x[15][15:0], x[15][31:16]} ^ x[0];
            x[1] = x[1] + x[6]; x[12] = {x[12][15:0], x[12][31:16]} ^ x[1];
            x[2] = x[2] + x[7]; x[13] = {x[13][15:0], x[13][31:16]} ^ x[2];
            x[3] = x[3] + x[4]; x[14] = {x[14][15:0], x[14][31:16]} ^ x[3];
        end

        // add original input (state_in)
        for(i=0;i<16;i=i+1)
            state_out[i*32 +: 32] = x[i] + state_in[i*32 +:32];
    end
endmodule
