
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
    input  wire [511:0]   data_in,

    output wire           ready,
    output wire           valid,
    output wire           tag_ok,
    output wire [511:0]   data_out,
    output wire [127:0]   tag
);

  // ----------------------------------------------------------------
  // Parameters / constants
  // ----------------------------------------------------------------
  localparam CTRL_IDLE     = 3'h0;
  localparam CTRL_KEYGEN   = 3'h1;
  localparam CTRL_PROCESS  = 3'h2;
  localparam CTRL_FINALIZE = 3'h3;

  // R clamp per Poly1305
  localparam [127:0] R_CLAMP  = 128'h0ffffffc0ffffffc0ffffffc0fffffff;
  // modulus 2^130 - 5
  localparam [129:0] POLY1305 = 130'h3fffffffffffffffffffffffffffffffb;

  // ----------------------------------------------------------------
  // Registers (state-holding)
  // ----------------------------------------------------------------
  reg [127:0] r_reg, r_new;
  reg         r_we;

  reg [127:0] s_reg, s_new;
  reg         s_we;

  // accumulator: 130-bit (fits Poly1305 arithmetic)
  reg [129:0] acc_reg, acc_new;
  reg         acc_we;

  reg [2:0]   core_ctrl_reg, core_ctrl_new;
  reg         core_ctrl_we;

  // flags (combinational handshakes)
  reg         poly1305_keygen;
  reg         poly1305_init;
  reg         poly1305_next;

  // local control for chacha_core
  reg         core_init;
  reg         core_next;
  reg  [31:0] core_init_ctr;

  // ready/valid internal (registered)
  reg tmp_ready;
  reg tmp_valid;
  reg tmp_tag_ok;

  // internal buffer for captured chacha output (used for keygen)
  reg [511:0] core_keyblock_reg;

  // ----------------------------------------------------------------
  // Wire connections to the chacha_core instance (stubbed)
  // ----------------------------------------------------------------
  wire        chacha_ready;
  wire        chacha_data_valid;
  wire [511:0] chacha_data_out;

  assign data_out = chacha_data_out;

  assign ready = tmp_ready;
  assign valid = tmp_valid;
  assign tag_ok = tmp_tag_ok;

  // Instantiate chacha_core stub (behavioral)
  wire [63:0] ctr64 = {nonce[31:0], core_init_ctr}; // lower 64 used
  wire [63:0] iv64  = nonce[95:32];

  chacha_core core (
      .clk(clk),
      .reset_n(reset_n),
      .init(core_init),
      .next(core_next),
      .keylen(1'b1),
      .key(key),
      .iv(iv64),
      .ctr(ctr64),
      .rounds(5'h14),
      .data_in(data_in),
      .ready(chacha_ready),
      .data_out(chacha_data_out),
      .data_out_valid(chacha_data_valid)
  );

  // ----------------------------------------------------------------
  // Register update (synchronous)
  // ----------------------------------------------------------------
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      r_reg         <= 128'h0;
      s_reg         <= 128'h0;
      acc_reg       <= 130'h0;
      core_keyblock_reg <= 512'h0;
      core_ctrl_reg <= CTRL_IDLE;
      tmp_ready     <= 1'b1;
      tmp_valid     <= 1'b0;
      tmp_tag_ok    <= 1'b0;
    end else begin
      if (core_ctrl_we) core_ctrl_reg <= core_ctrl_new;
      if (r_we) r_reg <= r_new;
      if (s_we) s_reg <= s_new;
      if (acc_we) acc_reg <= acc_new;

      // capture the key block output from chacha for later extraction
      if (poly1305_keygen && chacha_data_valid) begin
        core_keyblock_reg <= chacha_data_out;
      end

      // Register outputs for stable handshake (tmp_valid/tag_ok already driven combinationally but we keep registered outputs)
      tmp_valid <= tmp_valid; // already set combinationally in FSM; kept stable
      tmp_tag_ok <= tmp_tag_ok;
      tmp_ready <= tmp_ready;
    end
  end

  // ----------------------------------------------------------------
  // Poly1305 datapath (combinational control signals & next-values)
  // ----------------------------------------------------------------
  always @* begin
    // defaults (keep current reg values)
    r_new   = r_reg;
    s_new   = s_reg;
    acc_new = acc_reg;

    r_we    = 1'b0;
    s_we    = 1'b0;
    acc_we  = 1'b0;

    // Key extraction mapping: use lower 256 bits of keystream block as r||s
    // core_keyblock_reg[255:128] => r candidate; [127:0] => s
    if (poly1305_init) begin
      r_new = (core_keyblock_reg[255:128] & R_CLAMP);
      s_new = core_keyblock_reg[127:0];
      r_we = 1'b1;
      s_we = 1'b1;
      acc_new = 130'h0;
      acc_we = 1'b1;
    end

    if (poly1305_next) begin
      // Build 129-bit block = data (LSB 128) + 1<<128 per RFC (we treat 128-bit block + 1 bit)
      // Use ciphertext (chacha_data_out) when encdec=1 (encrypt), otherwise plaintext data_in
      reg [127:0] block128;
      reg [129:0] block129;
      if (encdec) begin
        block128 = chacha_data_out[127:0]; // take lower 128 of keystream XOR data_in in real design
      end else begin
        block128 = data_in[127:0];
      end
      block129 = {1'b0, block128} + 130'h100000000000000000000000000000000; // add 1<<128
      // acc_new = ((acc + block) * r) mod POLY1305
      // multiplication: (130 + 128) bits -> up to 258 bits
      reg [257:0] mult_full;
      reg [257:0] tmp_sum;
      tmp_sum = acc_reg + block129;
      mult_full = tmp_sum * r_reg;
      // reduce mod POLY1305 (behavioral): simple subtract loop (not optimized)
      reg [257:0] mod_tmp;
      mod_tmp = mult_full;
      while (mod_tmp >= POLY1305)
        mod_tmp = mod_tmp - POLY1305;
      acc_new = mod_tmp[129:0];
      acc_we  = 1'b1;
    end
  end

  // ----------------------------------------------------------------
  // FSM / Control logic (combinational)
  // ----------------------------------------------------------------
  always @* begin
    // default combinational outputs
    core_init      = 1'b0;
    core_next      = 1'b0;
    core_init_ctr  = 32'h0;

    poly1305_keygen = 1'b0;
    poly1305_init   = 1'b0;
    poly1305_next   = 1'b0;

    tmp_ready      = 1'b0;
    tmp_valid      = 1'b0;
    tmp_tag_ok     = 1'b0;

    core_ctrl_new  = core_ctrl_reg;
    core_ctrl_we   = 1'b0;

    case (core_ctrl_reg)
      CTRL_IDLE: begin
        tmp_ready = 1'b1;
        if (init) begin
          core_ctrl_new = CTRL_KEYGEN;
          core_ctrl_we  = 1'b1;
        end
      end

      CTRL_KEYGEN: begin
        poly1305_keygen = 1'b1;
        core_init = 1'b1;
        core_init_ctr = 32'h0;
        // when chacha block available, latch r/s
        if (chacha_data_valid) begin
          poly1305_init = 1'b1;
          core_ctrl_new = CTRL_IDLE;
          core_ctrl_we = 1'b1;
        end
      end

      CTRL_PROCESS: begin
        tmp_ready = 1'b0;
        if (chacha_data_valid) begin
          tmp_valid = 1'b1;
        end
      end

      CTRL_FINALIZE: begin
        tmp_tag_ok = 1'b1;
        core_ctrl_new = CTRL_IDLE;
        core_ctrl_we = 1'b1;
      end

      default: begin
        core_ctrl_new = CTRL_IDLE;
        core_ctrl_we  = 1'b1;
      end
    endcase

    // Independent handling of next
    if (next) begin
      core_next = 1'b1;
      core_init_ctr = 32'h1;
      tmp_ready = 1'b0;
      if (chacha_data_valid) begin
        poly1305_next = 1'b1;
        tmp_valid = 1'b1;
      end
    end

    // done -> tag ready
    if (done) begin
      tmp_tag_ok = 1'b1;
    end
  end

  // ----------------------------------------------------------------
  // Final tag computation (combinational)
  // ----------------------------------------------------------------
  // tag = low 128 bits of (acc_reg + s_reg)
  wire [130:0] acc_plus_s = acc_reg + {2'b0, s_reg}; // align s_reg into low 128
  assign tag = acc_plus_s[127:0];

endmodule
