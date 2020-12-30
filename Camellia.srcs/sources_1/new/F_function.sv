`timescale 1ns / 1ps

module F_function(X, k, out);
	input [0:63] X;
	input [0:63] k;
	output [0:63] out;
	
	logic [0:63] temp;
	
	S_function sfunction(.in(X^k), .out(temp));
	P_function pfunction(.in(temp), .out(out));
	
endmodule
