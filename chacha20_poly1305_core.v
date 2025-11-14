`timescale 1ns/1ps
module chacha20_poly1305_core(
    input  wire           clk,
    input  wire           reset_n,

    input  wire           init,
    input  wire           next,
    input  wire           done,
    input  wire           encdec,
    input  wire [255:0]   key,
    input  wire [95 :0]   nonce,
    input  wire [511:0]   data_in,    // full 512-bit block (4 x 128)
    output reg            ready,
    output reg            valid,
    output reg            tag_ok,
    output wire [511:0]   data_out,   // passthrough keystream
    output wire [127:0]   tag
);

  // ----------------------------------------------------------------
  // Parameters / constants
  // ----------------------------------------------------------------
  localparam CTRL_IDLE     = 3'h0;
  localparam CTRL_KEYGEN   = 3'h1;
  localparam CTRL_PROCESS  = 3'h2;
  localparam CTRL_MUL_WAIT = 3'h3;
  localparam CTRL_RED_WAIT = 3'h4;
  localparam CTRL_FINALIZE = 3'h5;

  localparam [127:0] R_CLAMP  = 128'h0ffffffc0ffffffc0ffffffc0fffffff;

  // registers
  reg [127:0] r_reg, r_new;
  reg         r_we;

  reg [127:0] s_reg, s_new;
  reg         s_we;

  reg [129:0] acc_reg, acc_new;
  reg         acc_we;

  reg [2:0] core_ctrl_reg, core_ctrl_new;
  reg       core_ctrl_we;

  // chacha_core handshake
  reg core_init;
  reg core_next;
  reg [31:0] core_init_ctr;

  // ready/valid/tag
  reg tmp_ready, tmp_valid, tmp_tag_ok;

  // internal capture
  reg [511:0] core_block_reg;
  reg         core_block_valid;

  wire chacha_ready, chacha_data_valid;
  wire [511:0] chacha_data_out;
  assign data_out = chacha_data_out;

  wire [63:0] ctr64 = {nonce[31:0], core_init_ctr};
  wire [63:0] iv64  = nonce[95:32];

  chacha_core core (
    .clk(clk), .reset_n(reset_n),
    .init(core_init), .next(core_next),
    .keylen(1'b1), .key(key),
    .iv(iv64), .ctr(ctr64),
    .rounds(5'h14),
    .data_in(data_in),
    .ready(chacha_ready), .data_out(chacha_data_out),
    .data_out_valid(chacha_data_valid)
  );

  // ----------------------------------------------------------------
  // Multiplier (limb-based) and reducer instances
  // ----------------------------------------------------------------
  wire [257:0] mul_product;
  wire mul_busy, mul_done;
  reg mul_start;
  reg [129:0] mul_a;
  reg [127:0] mul_b;

  mult_130x128_limb #(.LIMB(16), .A_BITS(130), .B_BITS(128), .PAR_PER_CYCLE(4)) MUL (
    .clk(clk), .reset_n(reset_n),
    .start(mul_start),
    .a_in(mul_a),
    .b_in(mul_b),
    .product_out(mul_product),
    .busy(mul_busy),
    .done(mul_done)
  );

  wire [129:0] red_out;
  wire red_busy, red_done;
  reg red_start;
  reduce_mod_poly1305 RED (
    .clk(clk), .reset_n(reset_n),
    .start(red_start),
    .value_in(mul_product),
    .value_out(red_out),
    .busy(red_busy),
    .done(red_done)
  );

  // streaming control: process 4 blocks per 512-bit data_in
  reg [1:0] stream_idx; // 0..3
  reg processing_block;

  // combinational temp
  reg [127:0] current_block128;
  reg [129:0] tmp_sum;

  // sequential regs
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      r_reg <= 128'h0; s_reg <= 128'h0; acc_reg <= 130'h0;
      core_block_reg <= 512'h0; core_block_valid <= 1'b0;
      core_ctrl_reg <= CTRL_IDLE;
      tmp_ready <= 1'b1; tmp_valid <= 1'b0; tmp_tag_ok <= 1'b0;
      ready <= 1'b1; valid <= 1'b0; tag_ok <= 1'b0;
      stream_idx <= 2'd0; processing_block <= 1'b0;
    end else begin
      if (core_ctrl_we) core_ctrl_reg <= core_ctrl_new;
      if (r_we) r_reg <= r_new;
      if (s_we) s_reg <= s_new;
      if (acc_we) acc_reg <= acc_new;

      // capture keystream block from chacha
      if (chacha_data_valid) begin
        core_block_reg <= chacha_data_out;
        core_block_valid <= 1'b1;
      end

      // registered outputs
      ready <= tmp_ready; valid <= tmp_valid; tag_ok <= tmp_tag_ok;
    end
  end

  // combinational FSM and control
  always @* begin
    // defaults
    core_init = 1'b0; core_next = 1'b0; core_init_ctr = 32'h0;
    core_ctrl_new = core_ctrl_reg; core_ctrl_we = 1'b0;

    r_new = r_reg; s_new = s_reg; acc_new = acc_reg;
    r_we = 1'b0; s_we = 1'b0; acc_we = 1'b0;

    mul_start = 1'b0; mul_a = 130'h0; mul_b = 128'h0;
    red_start = 1'b0;

    tmp_ready = 1'b0; tmp_valid = 1'b0; tmp_tag_ok = 1'b0;

    current_block128 = 128'h0;
    tmp_sum = acc_reg;

    case (core_ctrl_reg)
      CTRL_IDLE: begin
        tmp_ready = 1'b1;
        if (init) begin
          core_init = 1'b1;
          core_ctrl_new = CTRL_KEYGEN;
          core_ctrl_we = 1'b1;
          tmp_ready = 1'b0;
        end
      end

      CTRL_KEYGEN: begin
        core_init = 1'b1;
        tmp_ready = 1'b0;
        if (core_block_valid) begin
          r_new = (core_block_reg[255:128] & R_CLAMP);
          s_new = core_block_reg[127:0];
          r_we = 1'b1; s_we = 1'b1;
          acc_new = 130'h0; acc_we = 1'b1;
          core_block_valid = 1'b0;
          core_ctrl_new = CTRL_IDLE; core_ctrl_we = 1'b1;
          tmp_ready = 1'b1;
        end
      end

      CTRL_PROCESS: begin
        tmp_ready = 1'b0;
        // if not currently processing a block and next is asserted, request keystream
        if (!processing_block && next) begin
          core_next = 1'b1;
        end
        // when keystream arrives (core_block_valid), process current stream chunk
        if (core_block_valid && !processing_block) begin
          // extract the 128-bit chunk from the 512-bit keystream matching stream_idx
          // stream_idx 0 -> bits [127:0], 1 -> [255:128], 2 -> [383:256], 3 -> [511:384]
          integer off = stream_idx * 128;
          current_block128 = core_block_reg[off +: 128];
          processing_block = 1'b1;
          // fall through to start multiply (we do this combinationally below)
        end
      end

      CTRL_MUL_WAIT: begin
        // waiting for mul_done
        tmp_ready = 1'b0;
      end

      CTRL_RED_WAIT: begin
        // waiting for reduction
        tmp_ready = 1'b0;
      end

      CTRL_FINALIZE: begin
        tmp_tag_ok = 1'b1;
        core_ctrl_new = CTRL_IDLE; core_ctrl_we = 1'b1;
      end

      default: begin
        core_ctrl_new = CTRL_IDLE; core_ctrl_we = 1'b1;
      end
    endcase

    // independent event: start processing when we have a block to process (processing_block)
    if (processing_block && core_ctrl_reg != CTRL_MUL_WAIT && core_ctrl_reg != CTRL_RED_WAIT) begin
      // Build block129 = {1<<128, block128} -> note adding 1<<128 corresponds to setting bit 128
      // block128 is 128-bit; we build 129-bit block by concatenation with top bit 1
      // tmp_sum = acc + block129
      tmp_sum = acc_reg + ({1'b1, current_block128}); // top bit is bit 128 (1<<128)
      // Start multiplication: tmp_sum (130 bits) * r_reg (128 bits)
      mul_a = tmp_sum;
      mul_b = r_reg;
      mul_start = 1'b1;
      core_ctrl_new = CTRL_MUL_WAIT;
      core_ctrl_we = 1'b1;
    end

    // start reduction when multiplier done
    if (core_ctrl_reg == CTRL_MUL_WAIT && mul_done) begin
      red_start = 1'b1;
      core_ctrl_new = CTRL_RED_WAIT; core_ctrl_we = 1'b1;
    end

    // when reducer finishes, latch acc and advance stream index / block processing
    if (core_ctrl_reg == CTRL_RED_WAIT && red_done) begin
      acc_new = red_out; acc_we = 1'b1;
      // we finished one 128-bit block
      stream_idx = stream_idx + 1;
      processing_block = 1'b0;
      core_block_valid = 1'b0; // consume
      tmp_valid = 1'b1;
      // if we've processed all 4 blocks for this 512-bit input, either go to idle or remain ready
      if (stream_idx == 2'd3) begin
        stream_idx = 2'd0;
        // processed all four blocks — tag can be computed when 'done' asserted by external
        core_ctrl_new = CTRL_PROCESS; core_ctrl_we = 1'b1;
      end else begin
        // remain in PROCESS to accept next block (which will likely require another chacha next)
        core_ctrl_new = CTRL_PROCESS; core_ctrl_we = 1'b1;
      end
    end

    // done request handling
    if (done) begin
      core_ctrl_new = CTRL_FINALIZE; core_ctrl_we = 1'b1;
    end

    // outputs
    tmp_ready = tmp_ready;
    tmp_valid = tmp_valid;
    tmp_tag_ok = tmp_tag_ok;
  end

  // Final tag computation: tag = low 128 bits of (acc + s)
  wire [130:0] acc_plus_s = acc_reg + {2'b0, s_reg};
  assign tag = acc_plus_s[127:0];

endmodule
