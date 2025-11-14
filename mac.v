// mac.v
// Simple multiply-accumulate helper (32x32 -> 64, accumulate to 65-bit psum).
module mac(
    input  wire          clk,
    input  wire          reset_n,
    input  wire          clear,
    input  wire          next,
    input  wire [31:0]   a,
    input  wire [31:0]   b,
    output wire [64:0]   psum
);

  // Registers for operands (hold inputs for stable timing)
    reg [31:0] a_reg;
    reg [31:0] b_reg;

  // Pipeline stage for multiplication (reduces critical path)
    reg [63:0] mult_reg;

  // Accumulator register (65 bits to allow carry)
    reg [64:0] psum_reg;
    assign psum = psum_reg;

  //----------------------------------------------------------------
  // Register update: hold inputs and pipeline multiplier
  //---------------------------------------------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
          a_reg    <= 32'd0;
          b_reg    <= 32'd0;
          mult_reg <= 64'd0;
          psum_reg <= 65'd0;
        end else begin
          // capture inputs
          a_reg <= a;
          b_reg <= b;

          // Pipeline multiplication: using registered operands from previous cycle
          mult_reg <= a_reg * b_reg; // 32x32 => 64 bits

          // Accumulator with clear and next controls
          if (clear)
            psum_reg <= 65'd0;        // Clear: reset sum
          else if (next)
            psum_reg <= psum_reg + {1'b0, mult_reg}; // extend product to 65 bits
          else
            psum_reg <= psum_reg; // hold
        end
    end

endmodule
