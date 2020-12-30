`timescale 1ns / 1ps


module invFL_function(Y, k, out);
	input [0:63] Y;
	input [0:63] k;
	output [0:63] out;
	
	logic [0:31] Yl;
	logic [0:31] Yr;
	logic [0:31] kl;
	logic [0:31] kr;
	
	logic [0:31] temp;
	logic [0:31] Xr;
	logic [0:31] Xl;
	
	assign Yl=Y[0:31]; 
	assign Yr=Y[32:63];
	assign kl=k[0:31]; 
	assign kr=k[32:63];
	
	assign Xl=(Yr | kr)^Yl;
	assign temp=Xl & kl;
	assign Xr={temp[1:31],temp[0]}^Yr;
	assign out={Xl,Xr};
endmodule
