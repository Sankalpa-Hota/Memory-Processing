// ChaCha20 512-bit block using pipelined quarter rounds
module chacha_block(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [511:0] state_in,
    output reg  [511:0] state_out
);
    // 16 working 32-bit words
    reg [31:0] w[0:15];         // original input words
    reg [31:0] t[0:15];         // working words

    // Pipeline registers for 10 stages
    reg [31:0] stage_t[0:15][0:9];

    integer i, stage;

    // Split input into 16 words
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            for(i=0;i<16;i=i+1) begin
                w[i] <= 0;
                t[i] <= 0;
                for(stage=0; stage<10; stage=stage+1)
                    stage_t[i][stage] <= 0;
            end
            state_out <= 0;
        end else begin
            for(i=0;i<16;i=i+1) begin
                w[i] <= state_in[511-i*32 -:32];
                stage_t[i][0] <= state_in[511-i*32 -:32];
            end
        end
    end

    // 10-stage pipeline
    genvar s;
    generate
        for(s=0;s<10;s=s+1) begin : ROUND_STAGE
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    for(i=0;i<16;i=i+1)
                        stage_t[i][s] <= 0;
                end else begin
                    reg [31:0] in_t[0:15];
                    for(i=0;i<16;i=i+1)
                        in_t[i] = (s==0) ? stage_t[i][0] : stage_t[i][s-1];

                    // Column round
                    wire [31:0] a0,b0,c0,d0;
                    wire [31:0] a1,b1,c1,d1;
                    wire [31:0] a2,b2,c2,d2;
                    wire [31:0] a3,b3,c3,d3;

                    chacha_quarterround cr0(in_t[0], in_t[4], in_t[8], in_t[12], a0,b0,c0,d0);
                    chacha_quarterround cr1(in_t[1], in_t[5], in_t[9], in_t[13], a1,b1,c1,d1);
                    chacha_quarterround cr2(in_t[2], in_t[6], in_t[10], in_t[14], a2,b2,c2,d2);
                    chacha_quarterround cr3(in_t[3], in_t[7], in_t[11], in_t[15], a3,b3,c3,d3);

                    // diagonal round
                    wire [31:0] da0,db0,dc0,dd0;
                    wire [31:0] da1,db1,dc1,dd1;
                    wire [31:0] da2,db2,dc2,dd2;
                    wire [31:0] da3,db3,dc3,dd3;

                    reg [31:0] temp[0:15];
                    temp[0]=a0; temp[4]=b0; temp[8]=c0; temp[12]=d0;
                    temp[1]=a1; temp[5]=b1; temp[9]=c1; temp[13]=d1;
                    temp[2]=a2; temp[6]=b2; temp[10]=c2; temp[14]=d2;
                    temp[3]=a3; temp[7]=b3; temp[11]=c3; temp[15]=d3;

                    chacha_quarterround crd0(temp[0],temp[5],temp[10],temp[15],da0,db0,dc0,dd0);
                    chacha_quarterround crd1(temp[1],temp[6],temp[11],temp[12],da1,db1,dc1,dd1);
                    chacha_quarterround crd2(temp[2],temp[7],temp[8],temp[13],da2,db2,dc2,dd2);
                    chacha_quarterround crd3(temp[3],temp[4],temp[9],temp[14],da3,db3,dc3,dd3);

                    // store outputs to stage
                    stage_t[0][s]  <= da0; stage_t[5][s]  <= db0; stage_t[10][s] <= dc0; stage_t[15][s] <= dd0;
                    stage_t[1][s]  <= da1; stage_t[6][s]  <= db1; stage_t[11][s] <= dc1; stage_t[12][s] <= dd1;
                    stage_t[2][s]  <= da2; stage_t[7][s]  <= db2; stage_t[8][s]  <= dc2; stage_t[13][s] <= dd2;
                    stage_t[3][s]  <= da3; stage_t[4][s]  <= db3; stage_t[9][s]  <= dc3; stage_t[14][s] <= dd3;
                end
            end
        end
    endgenerate

    // feedforward
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) state_out <= 0;
        else begin
            for(i=0;i<16;i=i+1)
                state_out[511-i*32 -:32] <= stage_t[i][9] + w[i];
        end
    end
endmodule
