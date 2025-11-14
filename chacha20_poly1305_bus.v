`timescale 1ns/1ps

module chacha20_poly1305_bus (
    input  wire        clk,
    input  wire        reset_n,
    input  wire        cs,
    input  wire        we,
    input  wire [7:0]  address,
    input  wire [127:0] write_data,  // 128-bit chunk
    output reg  [127:0] read_data
);

    // Control registers
    reg init_reg, next_reg, done_reg;
    reg encdec_reg;

    // Key, nonce, 512-bit data registers
    reg [31:0] key_reg [0:7];
    reg [31:0] nonce_reg [0:2];
    reg [31:0] data_reg [0:15]; // 512-bit block

    // Burst index for 128-bit chunks
    reg [1:0] chunk_idx;

    // Pipelined read
    reg [127:0] tmp_read_data;

    // Core connections
    wire core_ready, core_valid, core_tag_ok;
    wire [255:0] core_key;
    wire [95:0] core_nonce;
    wire [511:0] core_data_in;
    wire [511:0] core_data_out;
    wire [127:0] core_tag;

    assign core_key     = {key_reg[0], key_reg[1], key_reg[2], key_reg[3],
                           key_reg[4], key_reg[5], key_reg[6], key_reg[7]};
    assign core_nonce   = {nonce_reg[2], nonce_reg[1], nonce_reg[0]};
    assign core_data_in = {data_reg[0], data_reg[1], data_reg[2], data_reg[3],
                           data_reg[4], data_reg[5], data_reg[6], data_reg[7],
                           data_reg[8], data_reg[9], data_reg[10], data_reg[11],
                           data_reg[12], data_reg[13], data_reg[14], data_reg[15]};

    chacha20_poly1305_core core(
        .clk(clk),
        .reset_n(reset_n),
        .init(init_reg),
        .next(next_reg),
        .done(done_reg),
        .encdec(encdec_reg),
        .key(core_key),
        .nonce(core_nonce),
        .data_in(core_data_in),
        .ready(core_ready),
        .valid(core_valid),
        .tag_ok(core_tag_ok),
        .data_out(core_data_out),
        .tag(core_tag)
    );

    integer i;

    // -------------------------
    // WRITE LOGIC (posedge clk)
    // -------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            init_reg <= 0; next_reg <= 0; done_reg <= 0;
            encdec_reg <= 0;
            chunk_idx <= 0;
            for (i=0; i<8; i=i+1) key_reg[i] <= 32'h0;
            for (i=0; i<3; i=i+1) nonce_reg[i] <= 32'h0;
            for (i=0; i<16; i=i+1) data_reg[i] <= 32'h0;
        end else if (cs && we) begin
            // Write 128-bit chunk to 512-bit block
            if (address >= 8'h30 && address <= 8'h33) begin
                // Map chunk to 4 words in data_reg
                data_reg[chunk_idx*4 + 0] <= write_data[127:96];
                data_reg[chunk_idx*4 + 1] <= write_data[95:64];
                data_reg[chunk_idx*4 + 2] <= write_data[63:32];
                data_reg[chunk_idx*4 + 3] <= write_data[31:0];

                // Advance chunk index
                if (chunk_idx < 2'd3) chunk_idx <= chunk_idx + 1;
                else chunk_idx <= 0; // wrap around after full block
            end else begin
                case (address)
                    8'h08: begin
                        init_reg <= write_data[0];
                        next_reg <= write_data[1];
                        done_reg <= write_data[2];
                    end
                    8'h0a: encdec_reg <= write_data[0];
                    8'h10,8'h11,8'h12,8'h13,8'h14,8'h15,8'h16,8'h17:
                        key_reg[address[2:0]] <= write_data[31:0];
                    8'h20,8'h21,8'h22:
                        nonce_reg[address[1:0]] <= write_data[31:0];
                endcase
            end
        end
    end

    // -------------------------
    // READ LOGIC (posedge clk)
    // -------------------------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            tmp_read_data <= 128'h0;
            read_data <= 128'h0;
        end else if (cs && !we) begin
            case (address)
                8'h00: tmp_read_data <= 128'h6332307031333035302e3031; // "c20p13050.01"
                8'h09: tmp_read_data <= {125'h0, core_tag_ok, core_valid, core_ready};
                8'h0a: tmp_read_data <= {127'h0, encdec_reg};
                8'h30,8'h31,8'h32,8'h33: begin
                    tmp_read_data <= {
                        core_data_out[(15-(address-8'h30)*4-0)*32 +:32],
                        core_data_out[(15-(address-8'h30)*4-1)*32 +:32],
                        core_data_out[(15-(address-8'h30)*4-2)*32 +:32],
                        core_data_out[(15-(address-8'h30)*4-3)*32 +:32]
                    };
                end
                8'h40: tmp_read_data <= core_tag;
                default: tmp_read_data <= 128'h0;
            endcase
            read_data <= tmp_read_data;
        end
    end

endmodule
