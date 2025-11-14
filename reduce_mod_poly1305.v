// reduce_mod_poly1305.v
// Reduce 258-bit input modulo POLY1305 = 2^130 - 5 using MSB->LSB subtract
`timescale 1ns/1ps
module reduce_mod_poly1305 (
    input  wire         clk,
    input  wire         reset_n,
    input  wire         start,
    input  wire [257:0] value_in,
    output reg  [129:0] value_out,
    output reg          busy,
    output reg          done
);
    localparam [129:0] POLY1305 = 130'h3fffffffffffffffffffffffffffffffb;

    reg [257:0] rem;
    reg [7:0] shift_idx;
    reg [257:0] modulus_shifted;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            rem <= 0; busy <= 0; done <= 0; value_out <= 0; shift_idx <= 0; modulus_shifted <= 0;
        end else begin
            done <= 0;
            if(start && !busy) begin
                rem <= value_in; busy <= 1; shift_idx <= 128;
            end else if(busy) begin
                modulus_shifted <= ({ {(128){1'b0}}, POLY1305 } << shift_idx);
                if(rem >= modulus_shifted) rem <= rem - modulus_shifted;
                if(shift_idx == 0) begin
                    value_out <= rem[129:0]; busy <= 0; done <= 1;
                end else shift_idx <= shift_idx - 1;
            end
        end
    end
endmodule
