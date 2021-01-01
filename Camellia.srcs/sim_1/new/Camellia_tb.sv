`timescale 1ns / 1ps


module Camellia_tb();

logic [0:127] block,result,key;
logic clk;
logic EncOrDec, rst, init, next, ready, valid;

initial
begin
	clk<=0;
//	block=128'h0123456789abcdeffedcba9876543210;
	block=128'h67673138549669730857065648eabe43;
	key=128'h0123456789abcdeffedcba9876543210;
	EncOrDec=0;
	rst=0;
	init=0;
	next=0;
	repeat(10) @(posedge clk);
	init=1;
	@(posedge clk)
	init=0;
//	init=0;
	repeat(10) @(posedge clk);
	next=1;
	@(posedge clk)
	next=0;
	repeat(50) @(posedge clk);
	$finish;
end
//always_comb
//begin
//	if (valid)==1
//		$display(
//end
always #5 clk=~clk;

Camellia_core core(.block(block), .result(result), .key(key), .clk(clk), .EncOrDec(EncOrDec), .rst(rst), .init(init), .next(next), .ready(ready), .valid(valid));
endmodule
