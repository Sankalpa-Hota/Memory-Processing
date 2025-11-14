// chacha_core.v -- corrected behavioral stub
// Produces deterministic 512-bit "keystream" block one cycle after init/next is asserted.

module chacha_core (
    input  wire         clk,
    input  wire         reset_n,
    input  wire         init,
    input  wire         next,
    input  wire         keylen,        // ignored in stub
    input  wire [255:0] key,
    input  wire [63:0]  ctr,           // lower 64 bits from wrapper
    input  wire [63:0]  iv,            // upper 64 bits (we pass nonce pieces)
    input  wire [4:0]   rounds,        // ignored in stub
    input  wire [511:0] data_in,       // optional - passed through if desired

    output reg          ready,
    output reg [511:0]  data_out,
    output reg          data_out_valid
);

  // internal registers
  reg [255:0] latched_key;
  reg [127:0] counter_reg;
  reg request_pending;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      latched_key <= 256'h0;
      counter_reg <= 128'h0;
      ready <= 1'b1;
      data_out <= 512'h0;
      data_out_valid <= 1'b0;
      request_pending <= 1'b0;
    end else begin
      // default deassert
      data_out_valid <= 1'b0;

      // accept request (init or next) when ready
      if ((init || next) && ready) begin
        latched_key <= key;
        counter_reg <= counter_reg + 1;
        request_pending <= 1'b1;
        ready <= 1'b0;
      end else if (request_pending) begin
        // produce keystream one cycle after request
        data_out <= {
            latched_key[255:128] ^ {64'h0, ctr},
            latched_key[127:0]   ^ {64'h0, iv},
            latched_key[255:128] ^ {64'h0, counter_reg[63:0]},
            latched_key[127:0]   ^ {64'h0, counter_reg[127:64]}
        };
        data_out_valid <= 1'b1;
        request_pending <= 1'b0;
        ready <= 1'b1;
      end
    end
  end

endmodule
