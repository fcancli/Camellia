`timescale 1ns / 1ps

module F_function_tb();
	logic clk;
	logic [0:63] X='0;
	logic [0:63] k='0;
	logic [0:63] out;
	always #5 clk=~clk;
	
	initial
	begin
		clk<=0;
		X='0;
		k='0;
		repeat(50) @(posedge clk);
		$finish;
	end
	
	F_function ffunction(.X(X),.k(k),.out(out));
endmodule
