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
    localparam A_LIMBS = (A_BITS + LIMB -1)/LIMB; // 9
    localparam B_LIMBS = (B_BITS + LIMB -1)/LIMB; // 8
    localparam TOTAL_PARTIALS = A_LIMBS * B_LIMBS; // 72

    reg [LIMB-1:0] a_limbs [0:A_LIMBS-1];
    reg [LIMB-1:0] b_limbs [0:B_LIMBS-1];

    // registers that hold state between cycles
    reg [257:0] acc;
    reg [7:0] partial_idx;
    integer i;
    integer ai, bj;
    reg [LIMB-1:0] a_val, b_val;
    reg [31:0] pp;
    reg [257:0] shifted_pp;

    // Local variables used within a clock cycle (blocking updates)
    reg [257:0] acc_local;
    reg [7:0]  partial_idx_local;

    // Slice a_in/b_in into limbs (manual)
    task slice_inputs;
        input [A_BITS-1:0] a;
        input [B_BITS-1:0] b;
        begin
            // A limbs (9 limbs, last is 2 bits for A=130)
            a_limbs[0] = a[15:0];
            a_limbs[1] = a[31:16];
            a_limbs[2] = a[47:32];
            a_limbs[3] = a[63:48];
            a_limbs[4] = a[79:64];
            a_limbs[5] = a[95:80];
            a_limbs[6] = a[111:96];
            a_limbs[7] = a[127:112];
            a_limbs[8] = a[129:128]; // remaining 2 bits
            // B limbs (8 limbs)
            b_limbs[0] = b[15:0];
            b_limbs[1] = b[31:16];
            b_limbs[2] = b[47:32];
            b_limbs[3] = b[63:48];
            b_limbs[4] = b[79:64];
            b_limbs[5] = b[95:80];
            b_limbs[6] = b[111:96];
            b_limbs[7] = b[127:112];
        end
    endtask

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            busy <= 0; done <= 0; acc <= 0; product_out <= 0; partial_idx <= 0;
            for(i=0;i<A_LIMBS;i=i+1) a_limbs[i] <= 0;
            for(i=0;i<B_LIMBS;i=i+1) b_limbs[i] <= 0;
        end else begin
            done <= 0; // default
            if(start && !busy) begin
                // slice inputs into limbs synchronously (blocking is OK here)
                slice_inputs(a_in, b_in);
                acc <= 0;
                partial_idx <= 0;
                busy <= 1;
            end else if(busy) begin
                // initialize local accumulators with current state
                acc_local = acc;                 // blocking local copy
                partial_idx_local = partial_idx; // blocking local copy

                // perform PAR_PER_CYCLE partials in this cycle,
                // updating local copies blocking so each iteration sees updates
                for(i=0;i<PAR_PER_CYCLE;i=i+1) begin
                    if(partial_idx_local < TOTAL_PARTIALS) begin
                        ai = partial_idx_local / B_LIMBS;
                        bj = partial_idx_local % B_LIMBS;
                        a_val = a_limbs[ai];
                        b_val = b_limbs[bj];
                        pp = a_val * b_val;
                        shifted_pp = {226'b0, pp} << ((ai + bj) * LIMB);
                        acc_local = acc_local + shifted_pp;     // blocking update
                        partial_idx_local = partial_idx_local + 1; // blocking update
                    end
                end

                // commit local copies back to regs (non-blocking for synthesis style)
                acc <= acc_local;
                partial_idx <= partial_idx_local;

                // if finished
                if(partial_idx_local >= TOTAL_PARTIALS) begin
                    product_out <= acc_local;
                    busy <= 0;
                    done <= 1;
                end
            end
        end
    end
endmodule
