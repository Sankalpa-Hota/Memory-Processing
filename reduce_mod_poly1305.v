`timescale 1ns/1ps
module reduce_mod_poly1305(
    input wire clk,
    input wire reset_n,
    input wire start,
    input wire [257:0] value_in,
    output reg [129:0] value_out,
    output reg busy,
    output reg done
);
    reg [257:0] val_reg;
    reg state;

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            value_out <= 130'b0;
            busy <= 1'b0;
            done <= 1'b0;
            val_reg <= 258'b0;
            state <= 1'b0;
        end else begin
            done <= 1'b0;
            if(start && !busy) begin
                busy <= 1'b1;
                val_reg <= value_in;
                state <= 1'b1;
            end else if(busy && state) begin
                // fold hi into lo: lo + 5*hi
                // hi = val_reg >> 130;
                // lo = val_reg[129:0];
                // compute sum = lo + 5*hi
                // then conditional subtract modulus (2^130 - 5)
                reg [129:0] lo;
                reg [127:0] hi;
                reg [130:0] tmp; // allow overflow
                lo = val_reg[129:0];
                hi = val_reg[257:130];
                tmp = lo + (hi * 5);
                if (tmp >= (1'b1 << 130)) begin
                    value_out <= tmp - (1'b1 << 130) + 5;
                end else begin
                    value_out <= tmp[129:0];
                end
                busy <= 1'b0;
                done <= 1'b1;
                state <= 1'b0;
            end
        end
    end
endmodule

