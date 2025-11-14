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
    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            value_out <= 0; busy <= 0; done <= 0;
        end else if(start) begin
            busy <= 1;
            value_out <= value_in[129:0]; // stub: simulate reduction
            done <= 1;
            busy <= 0;
        end else begin
            done <= 0;
        end
    end
endmodule
