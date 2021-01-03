`timescale 1ns / 1ps

module F_function(X, k, out, clk);
	input [0:63] X;
	input [0:63] k;
	output [0:63] out;
	input clk;
	
	logic [0:63] temp;
	logic [0:63] out_reg, out_s;
	
	S_function sfunction(.in(X^k), .out(temp));
	P_function pfunction(.in(temp), .out(out_s));
	
	assign out=out_reg;
	
	always@(posedge clk)
	begin
		out_reg<=out_s;
	end
	
endmodule
