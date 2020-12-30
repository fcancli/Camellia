`timescale 1ns / 1ps


module FL_function(X, k, out);
	input [0:63] X;
	input [0:63] k;
	output [0:63] out;
	
	logic [0:31] Xl;
	logic [0:31] Xr;
	logic [0:31] kl;
	logic [0:31] kr;
	
	logic [0:31] temp;
	logic [0:31] Yr;
	logic [0:31] Yl;
	
	assign Xl=X[0:31]; 
	assign Xr=X[32:63];
	assign kl=k[0:31]; 
	assign kr=k[32:63];	
	assign temp=Xl & kl;
	assign Yr={temp[1:31], temp[0]}^Xr;
	assign Yl=(Yr | kr)^Xl;
	assign out={Yl,Yr};
endmodule
