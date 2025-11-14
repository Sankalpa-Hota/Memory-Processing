`timescale 1ns/1ps
module mult_130x128_limb #(
    parameter A_BITS = 130,
    parameter B_BITS = 128
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
    // serial shift-add multiplier (B_BITS cycles)
    reg [A_BITS+B_BITS-1:0] mult_shift; // extended multiplicand shifted left
    reg [B_BITS-1:0] multiplier;
    reg [257:0] acc;
    reg [7:0] bit_idx;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            product_out <= 258'b0;
            busy <= 1'b0;
            done <= 1'b0;
            mult_shift <= {(A_BITS+B_BITS){1'b0}};
            multiplier <= {B_BITS{1'b0}};
            acc <= 258'b0;
            bit_idx <= 8'd0;
        end else begin
            done <= 1'b0;
            if(start && !busy) begin
                // load inputs
                mult_shift <= { {B_BITS{1'b0}}, a_in }; // place a_in in lower bits so shifting left multiplies
                multiplier <= b_in;
                acc <= 258'b0;
                bit_idx <= 8'd0;
                busy <= 1'b1;
            end else if(busy) begin
                // if LSB of multiplier is 1, add current multiplicand to acc
                if(multiplier[0]) begin
                    acc <= acc + mult_shift[257:0];
                end
                // shift multiplicand left, shift multiplier right
                mult_shift <= mult_shift << 1;
                multiplier <= multiplier >> 1;
                bit_idx <= bit_idx + 1'b1;
                if(bit_idx == (B_BITS-1)) begin
                    product_out <= acc;
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            end
        end
    end
endmodule
