// ChaCha20 512-bit block using quarter rounds
module chacha_block(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [511:0] state_in,
    output reg  [511:0] state_out
);

    // Working words for 16x32-bit
    reg [31:0] w[0:15];         // original input words
    reg [31:0] t[0:15];         // working pipeline words

    // Pipeline registers for each stage (10 stages)
    reg [31:0] stage_t[0:15][0:9]; // stage_t[word][stage]

    integer i, stage;

    // Temporary variables for quarterround outputs
    wire [31:0] a0,b0,c0,d0,a1,b1,c1,d1,a2,b2,c2,d2,a3,b3,c3,d3;

    // Split state input into words
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state_out <= 0;
            for(i=0;i<16;i=i+1) begin
                w[i] <= 0;
                t[i] <= 0;
                for(stage=0; stage<10; stage=stage+1)
                    stage_t[i][stage] <= 0;
            end
        end else begin
            // Load input into stage 0
            for(i=0;i<16;i=i+1) begin
                w[i] <= state_in[511-i*32 -: 32];
                stage_t[i][0] <= state_in[511-i*32 -: 32];
            end
        end
    end

    // Pipeline: 10 stages
    genvar s;
    generate
        for(s=0; s<10; s=s+1) begin : ROUND_STAGE
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    for(i=0;i<16;i=i+1)
                        stage_t[i][s] <= 0;
                end else begin
                    // previous stage input
                    reg [31:0] in_t[0:15];
                    for(i=0;i<16;i=i+1)
                        in_t[i] = (s==0) ? stage_t[i][0] : stage_t[i][s-1];

                    // Column round
                    chacha_quarterround cr0(in_t[0],in_t[4],in_t[8],in_t[12],a0,b0,c0,d0);
                    chacha_quarterround cr1(in_t[1],in_t[5],in_t[9],in_t[13],a1,b1,c1,d1);
                    chacha_quarterround cr2(in_t[2],in_t[6],in_t[10],in_t[14],a2,b2,c2,d2);
                    chacha_quarterround cr3(in_t[3],in_t[7],in_t[11],in_t[15],a3,b3,c3,d3);

                    reg [31:0] temp[0:15];
                    temp[0]=a0; temp[4]=b0; temp[8]=c0; temp[12]=d0;
                    temp[1]=a1; temp[5]=b1; temp[9]=c1; temp[13]=d1;
                    temp[2]=a2; temp[6]=b2; temp[10]=c2; temp[14]=d2;
                    temp[3]=a3; temp[7]=b3; temp[11]=c3; temp[15]=d3;

                    // Diagonal round
                    chacha_quarterround crd0(temp[0],temp[5],temp[10],temp[15],a0,b0,c0,d0);
                    chacha_quarterround crd1(temp[1],temp[6],temp[11],temp[12],a1,b1,c1,d1);
                    chacha_quarterround crd2(temp[2],temp[7],temp[8],temp[13],a2,b2,c2,d2);
                    chacha_quarterround crd3(temp[3],temp[4],temp[9],temp[14],a3,b3,c3,d3);

                    // Store output into next stage
                    stage_t[0][s]  <= a0; stage_t[5][s]  <= b0; stage_t[10][s] <= c0; stage_t[15][s] <= d0;
                    stage_t[1][s]  <= a1; stage_t[6][s]  <= b1; stage_t[11][s] <= c1; stage_t[12][s] <= d1;
                    stage_t[2][s]  <= a2; stage_t[7][s]  <= b2; stage_t[8][s]  <= c2; stage_t[13][s] <= d2;
                    stage_t[3][s]  <= a3; stage_t[4][s]  <= b3; stage_t[9][s]  <= c3; stage_t[14][s] <= d3;
                end
            end
        end
    endgenerate

    // Feed-forward after final stage
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) state_out <= 0;
        else begin
            for(i=0;i<16;i=i+1)
                state_out[511-i*32 -:32] <= stage_t[i][9] + w[i];
        end
    end

endmodule
