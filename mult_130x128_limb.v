// mult_130x128_limb.v
// Limb-based multiplier: A (130 bits) * B (128 bits) -> 258 bits
// Uses 16-bit limbs (A -> 9 limbs, B -> 8 limbs). Computes PAR_PER_CYCLE partials/cycle.
// This is synthesizable and much faster than bit-serial.

module mult_130x128_limb #(
    parameter LIMB = 16,
    parameter A_BITS = 130,
    parameter B_BITS = 128,
    parameter PAR_PER_CYCLE = 4
) (
    input  wire              clk,
    input  wire              reset_n,
    input  wire              start,
    input  wire [A_BITS-1:0] a_in,     // multiplicand (130)
    input  wire [B_BITS-1:0] b_in,     // multiplier  (128)
    output reg  [257:0]      product_out,
    output reg               busy,
    output reg               done
);

    // Derived parameters
    localparam A_LIMBS = (A_BITS + LIMB -1) / LIMB; // 9
    localparam B_LIMBS = (B_BITS + LIMB -1) / LIMB; // 8
    localparam TOTAL_PARTIALS = A_LIMBS * B_LIMBS;  // 72
    // cycles required
    localparam CYCLES = (TOTAL_PARTIALS + PAR_PER_CYCLE - 1) / PAR_PER_CYCLE;

    // internal counters and state
    reg [15:0] partial_idx; // up to TOTAL_PARTIALS
    reg [15:0] cycle_idx;
    reg [257:0] acc; // accumulator for product
    reg [A_LIMBS-1:0][LIMB-1:0] a_limbs;
    reg [B_LIMBS-1:0][LIMB-1:0] b_limbs;

    integer i, j, k;

    // Pre-slice limbs into regs for easy indexing (combinational assignment)
    // We'll do this in sequential block at start to ensure stable values
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            busy <= 1'b0;
            done <= 1'b0;
            product_out <= 258'b0;
            acc <= 258'b0;
            partial_idx <= 0;
            cycle_idx <= 0;
            // zero limbs
            for (i=0; i<A_LIMBS; i=i+1) begin
                a_limbs[i] <= {LIMB{1'b0}};
            end
            for (i=0; i<B_LIMBS; i=i+1) begin
                b_limbs[i] <= {LIMB{1'b0}};
            end
        end else begin
            done <= 1'b0;
            if (start && !busy) begin
                // slice A and B into limbs (little-endian: limb 0 = lowest bits)
                for (i=0; i<A_LIMBS; i=i+1) begin
                    // select bits i*LIMB +: LIMB; if out-of-range, zero pad
                    if ((i*LIMB) + LIMB -1 < A_BITS)
                        a_limbs[i] <= a_in[(i*LIMB) +: LIMB];
                    else begin
                        // some upper limbs may be partial; build carefully
                        integer hi_bit;
                        hi_bit = A_BITS - (i*LIMB);
                        if (hi_bit > 0)
                            a_limbs[i] <= { {(LIMB-hi_bit){1'b0}}, a_in[(i*LIMB) +: hi_bit] };
                        else
                            a_limbs[i] <= {LIMB{1'b0}};
                    end
                end
                for (i=0; i<B_LIMBS; i=i+1) begin
                    if ((i*LIMB) + LIMB -1 < B_BITS)
                        b_limbs[i] <= b_in[(i*LIMB) +: LIMB];
                    else begin
                        integer hi_bitb;
                        hi_bitb = B_BITS - (i*LIMB);
                        if (hi_bitb > 0)
                            b_limbs[i] <= { {(LIMB-hi_bitb){1'b0}}, b_in[(i*LIMB) +: hi_bitb] };
                        else
                            b_limbs[i] <= {LIMB{1'b0}};
                    end
                end

                // initialize accumulator and counters
                acc <= 258'b0;
                partial_idx <= 0;
                cycle_idx <= 0;
                busy <= 1'b1;
            end else if (busy) begin
                // compute up to PAR_PER_CYCLE partials starting from partial_idx
                // partial index maps to (ai, bj) with ai in [0..A_LIMBS-1], bj in [0..B_LIMBS-1]
                // mapping: partial_idx = ai * B_LIMBS + bj
                reg [31:0] pp; // 16x16 -> 32
                reg [15:0] pidx;
                integer count;
                count = 0;
                for (k=0; k<PAR_PER_CYCLE; k=k+1) begin
                    pidx = partial_idx + k;
                    if (pidx < TOTAL_PARTIALS) begin
                        integer ai = pidx / B_LIMBS;
                        integer bj = pidx % B_LIMBS;
                        // compute partial product
                        pp = a_limbs[ai] * b_limbs[bj]; // 16x16 -> 32
                        // shift amount in bits = (ai + bj) * LIMB
                        integer shift_bits = (ai + bj) * LIMB;
                        // accumulate into acc with appropriate shift
                        acc <= acc + ( { 226'b0, pp } << shift_bits ); // 32 + shift -> place into 258
                        count = count + 1;
                    end
                end
                partial_idx <= partial_idx + count;
                cycle_idx <= cycle_idx + 1;

                if (partial_idx + PAR_PER_CYCLE >= TOTAL_PARTIALS) begin
                    // we finished all partials this cycle
                    product_out <= acc;
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            end
        end
    end

endmodule
