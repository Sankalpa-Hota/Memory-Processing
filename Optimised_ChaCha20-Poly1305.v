// chacha20_poly1305_opt.v
`timescale 1ns/1ps

module chacha20_poly1305_opt(
    input wire clk,
    input wire reset_n,

    input wire cs,
    input wire we,
    input wire [7:0] address,
    input wire [31:0] write_data,
    output reg [31:0] read_data
);

reg init_reg, init_new;
reg next_reg, next_new;
reg done_reg, done_new;
reg encdec_reg, encdec_we;
reg [31:0] init_ctr_reg[0:1];
reg init_ctr_we;
reg [31:0] key_reg [0:7];
reg key_we;
reg [31:0] nonce_reg [0:2];
reg nonce_we;
reg [31:0] data_reg [0:15];
reg data_we;
reg [4:0] rounds_reg;
reg rounds_we;

// tmp register for pipelined read
reg [31:0] tmp_read_data;

wire core_ready, core_valid, core_tag_ok;
wire [255:0] core_key;
wire [95:0] core_nonce;
wire [511:0] core_data_in;
wire [511:0] core_data_out;
wire [127:0] core_tag;

assign core_key = {key_reg[0], key_reg[1], key_reg[2], key_reg[3],
                   key_reg[4], key_reg[5], key_reg[6], key_reg[7]};

// nonce_reg[0] = lowest word, [1] mid, [2] top -> assemble into 96-bit
assign core_nonce = {nonce_reg[2], nonce_reg[1], nonce_reg[0]};

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
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        init_reg <= 0; next_reg <= 0; done_reg <= 0;
        encdec_reg <= 0;
        init_ctr_reg[0] <= 32'h0; init_ctr_reg[1] <= 32'h0;
        nonce_reg[0] <= 32'h0; nonce_reg[1] <= 32'h0; nonce_reg[2] <= 32'h0;
        for (i=0; i<8; i=i+1) begin
            key_reg[i] <= 32'h0;
        end
        for (i=0; i<16; i=i+1) begin
            data_reg[i] <= 32'h0;
        end
    end else begin
        init_reg <= init_new;
        next_reg <= next_new;
        done_reg <= done_new;

        if (encdec_we) encdec_reg <= write_data[0];
        if (init_ctr_we) init_ctr_reg[address[0]] <= write_data;
        if (key_we) key_reg[address[2:0]] <= write_data;
        if (nonce_we) nonce_reg[address[1:0]] <= write_data;
        if (data_we) data_reg[address[3:0]] <= write_data;
    end
end

always @(negedge clk) begin
    if (cs && !we) begin
        case (address)
            8'h00: tmp_read_data <= 32'h63323070;
            8'h01: tmp_read_data <= 32'h31333035;
            8'h02: tmp_read_data <= 32'h302e3031;
            8'h09: tmp_read_data <= {29'h0, core_tag_ok, core_valid, core_ready};
            8'h0a: tmp_read_data <= {31'h0, encdec_reg};
            default: begin
                if ((address >= 8'h10) && (address <= 8'h17)) tmp_read_data <= key_reg[address[2:0]];
                else if ((address >= 8'h20) && (address <= 8'h22)) tmp_read_data <= nonce_reg[address[1:0]];
                else if ((address >= 8'h30) && (address <= 8'h3f)) begin
                    // core_data_out has 16 words, slice accordingly
                    tmp_read_data <= core_data_out[(15-(address-8'h30))*32 +:32];
                end else if ((address >= 8'h40) && (address <= 8'h43)) begin
                    tmp_read_data <= core_tag[(3-(address-8'h40))*32 +:32];
                end else tmp_read_data <= 32'h0;
            end
        endcase
    end
end

always @(posedge clk) begin
    read_data <= tmp_read_data;
end

always @* begin
    init_new = 0; next_new = 0; done_new = 0;
    encdec_we = 0; key_we = 0; nonce_we = 0; data_we = 0; init_ctr_we = 0;
    if (cs && we) begin
        if (address == 8'h08) begin
            init_new = write_data[0];
            next_new = write_data[1];
            done_new = write_data[2];
        end else if (address == 8'h0a) encdec_we = 1;
        else if ((address >= 8'h10) && (address <= 8'h17)) key_we = 1;
        else if ((address >= 8'h20) && (address <= 8'h22)) nonce_we = 1;
        else if ((address >= 8'h30) && (address <= 8'h3f)) data_we = 1;
    end
end

endmodule

