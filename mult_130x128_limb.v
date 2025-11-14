`timescale 1ns/1ps
module mult_130x128_limb #(
    parameter LIMB = 16,
    parameter A_BITS = 130,
    parameter B_BITS = 128,
    parameter PAR_PER_CYCLE = 4
)(
    input  wire clk,
    input  wire reset_n,
    input  wire start,
    input  wire [A_BITS-1:0] a_in,
    input  wire [B_BITS-1:0] b_in,
    output reg  [257:0] product_out,
    output reg  busy,
    output reg  done
);
    localparam A_LIMBS = (A_BITS + LIMB -1)/LIMB;
    localparam B_LIMBS = (B_BITS + LIMB -1)/LIMB;
    localparam TOTAL_PARTIALS = A_LIMBS * B_LIMBS;

    reg [LIMB-1:0] a_limbs [0:A_LIMBS-1];
    reg [LIMB-1:0] b_limbs [0:B_LIMBS-1];
    reg [257:0] acc;
    reg [7:0] partial_idx;
    integer i;
    integer ai,bj;
    reg [LIMB-1:0] a_val,b_val;
    reg [31:0] pp;
    reg [257:0] shifted_pp;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            busy <= 0; done <= 0; acc <= 0; product_out <= 0; partial_idx <= 0;
            for(i=0;i<A_LIMBS;i=i+1) a_limbs[i] <= 0;
            for(i=0;i<B_LIMBS;i=i+1) b_limbs[i] <= 0;
        end else begin
            done <= 0;
            if(start && !busy) begin
                // slice a_in into limbs manually
                a_limbs[0] = a_in[15:0];  a_limbs[1] = a_in[31:16];
                a_limbs[2] = a_in[47:32]; a_limbs[3] = a_in[63:48];
                a_limbs[4] = a_in[79:64]; a_limbs[5] = a_in[95:80];
                a_limbs[6] = a_in[111:96]; a_limbs[7] = a_in[127:112];
                a_limbs[8] = a_in[129:128]; // last 2 bits

                // slice b_in into limbs manually
                b_limbs[0] = b_in[15:0];   b_limbs[1] = b_in[31:16];
                b_limbs[2] = b_in[47:32];  b_limbs[3] = b_in[63:48];
                b_limbs[4] = b_in[79:64];  b_limbs[5] = b_in[95:80];
                b_limbs[6] = b_in[111:96]; b_limbs[7] = b_in[127:112];

                acc <= 0; partial_idx <= 0; busy <= 1;
            end else if(busy) begin
                for(i=0;i<PAR_PER_CYCLE;i=i+1) begin
                    if(partial_idx<TOTAL_PARTIALS) begin
                        ai = partial_idx / B_LIMBS;
                        bj = partial_idx % B_LIMBS;
                        a_val = a_limbs[ai];
                        b_val = b_limbs[bj];
                        pp = a_val * b_val;
                        shifted_pp = {226'b0, pp} << ((ai+bj)*LIMB);
                        acc <= acc + shifted_pp;
                        partial_idx <= partial_idx + 1;
                    end
                end
                if(partial_idx >= TOTAL_PARTIALS) begin
                    product_out <= acc;
                    busy <= 0; done <= 1;
                end
            end
        end
    end
endmodule
