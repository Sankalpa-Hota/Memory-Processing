module mulacc2_opt(
    input  wire          clk,
    input  wire          reset_n,
    input  wire          clear,
    input  wire          next,
    input  wire [25:0]   a,
    input  wire [28:0]   b,
    output wire [58:0]   psum
);

  // Registers for operands (hold inputs for stable timing)
  reg [25:0] a_reg;
  reg [28:0] b_reg;

  // Pipeline stage for multiplication (reduces critical path)
  reg [58:0] mult_reg;

  // Accumulator register
  reg [58:0] psum_reg;

  assign psum = psum_reg;

  //----------------------------------------------------------------
  // Register update: hold inputs and pipeline multiplier
  //----------------------------------------------------------------
  always @(posedge clk) begin
    if (!reset_n) begin
      a_reg    <= 26'd0;
      b_reg    <= 29'd0;
      mult_reg <= 59'd0;
      psum_reg <= 59'd0;
    end else begin
      a_reg <= a;
      b_reg <= b;

      // Pipeline multiplication
      mult_reg <= a_reg * b_reg;

      // Accumulator with clear and next controls
      if (clear)
        psum_reg <= 59'd0;        // Clear: reset sum
      else if (next)
        psum_reg <= psum_reg + mult_reg; // Accumulate pipelined result
      // No action if next=0, saves unnecessary toggling
    end
  end

endmodule
