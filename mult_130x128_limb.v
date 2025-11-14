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

    localparam A_LIMBS = (A_BITS + LIMB -1)/LIMB; // 9
    localparam B_LIMBS = (B_BITS + LIMB -1)/LIMB; // 8
    localparam TOTAL_PARTIALS = A_LIMBS * B_LIMBS; // 72

    reg [LIMB-1:0] a_limbs [0:A_LIMBS-1];
    reg [LIMB-1:0] b_limbs [0:B_LIMBS-1];
    reg [257:0] acc;
    reg [7:0] partial_idx;

    integer i, j;
    integer hi; // moved to module scope
    integer ai, bj; // moved to module scope
    reg [31:0] pp;
    reg [257:0] shifted_pp;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            busy <= 0;
            done <= 0;
            acc <= 0;
            product_out <= 0;
            partial_idx <= 0;
            // clear limbs
            for(i=0;i<A_LIMBS;i=i+1) a_limbs[i] <= 0;
            for(i=0;i<B_LIMBS;i=i+1) b_limbs[i] <= 0;
        end else begin
            done <= 0;
            if(start && !busy) begin
                // slice input into limbs
                for(i=0;i<A_LIMBS;i=i+1) begin
                    if((i*LIMB)+LIMB-1 < A_BITS)
                        a_limbs[i] <= a_in[i*LIMB +: LIMB];
                    else begin
                        hi = A_BITS - i*LIMB;
                        a_limbs[i] <= (hi>0) ? { {(LIMB-hi){1'b0}}, a_in[i*LIMB +: hi] } : 0;
                    end
                end
                for(i=0;i<B_LIMBS;i=i+1) begin
                    if((i*LIMB)+LIMB-1 < B_BITS)
                        b_limbs[i] <= b_in[i*LIMB +: LIMB];
                    else begin
                        hi = B_BITS - i*LIMB;
                        b_limbs[i] <= (hi>0) ? { {(LIMB-hi){1'b0}}, b_in[i*LIMB +: hi] } : 0;
                    end
                end
                acc <= 0;
                partial_idx <= 0;
                busy <= 1;
            end else if(busy) begin
                for(i=0;i<PAR_PER_CYCLE;i=i+1) begin
                    if(partial_idx<TOTAL_PARTIALS) begin
                        ai = partial_idx / B_LIMBS;
                        bj = partial_idx % B_LIMBS;
                        pp = a_limbs[ai] * b_limbs[bj];
                        shifted_pp = {226'b0, pp} << ((ai+bj)*LIMB);
                        acc <= acc + shifted_pp;
                        partial_idx <= partial_idx + 1;
                    end
                end
                if(partial_idx >= TOTAL_PARTIALS) begin
                    product_out <= acc;
                    busy <= 0;
                    done <= 1;
                end
            end
        end
    end

endmodule

