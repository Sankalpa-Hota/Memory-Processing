`timescale 1ns/1ps
module chacha_core(
    input  wire clk,
    input  wire reset_n,
    input  wire init,
    input  wire next,
    input  wire [255:0] key,
    input  wire [63:0] ctr,
    input  wire [63:0] iv,
    input  wire [511:0] data_in,
    output reg  ready,
    output reg  data_out_valid,
    output reg [511:0] data_out
);
    reg [511:0] state;
    reg request_pending;
    wire [511:0] chacha_out;

    wire [511:0] init_state = {
        32'h61707865,32'h3320646e,32'h79622d32,32'h6b206574,
        key[255:224], key[223:192], key[191:160], key[159:128],
        key[127:96], key[95:64], key[63:32], key[31:0],
        ctr, iv
    };

    chacha_block BLOCK(.clk(clk), .rst_n(reset_n), .state_in(state), .state_out(chacha_out));

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state <= 512'h0;
            ready <= 1'b1;
            data_out_valid <= 0;
            request_pending <= 0;
            data_out <= 512'h0;
        end else begin
            data_out_valid <= 0;
            if((init || next) && ready) begin
                state <= init_state;
                request_pending <= 1'b1;
                ready <= 0;
            end else if(request_pending) begin
                data_out <= data_in ^ chacha_out;
                data_out_valid <= 1'b1;
                request_pending <= 0;
                ready <= 1'b1;
            end
        end
    end
endmodule
