`timescale 1ns / 1ps

module Feistel_rand_tb();
	logic clk, start, KA_gen;
	logic [0:127] in, out;
	logic [0:63] K_in;
	logic valid;
	initial
		begin
			clk<=0;
			in='0;
			KA_gen=0;
			K_in=64'hB05688C2B3E6C1FD;
			repeat(10) @(posedge clk);
			start=1;
//			KA_gen=1;
//			@(posedge clk)
//			begin
//				if (valid)
//					start=0;
//					repeat(10) @(posedge clk);
//					$finish;
//			end
		end
		always@(valid)
		begin
			if (valid) begin
				start=0;
				repeat(10) @(posedge clk);
				$finish;
			end
		end

	always #5 clk=~clk;
	Feistel_rand Feist(.start(start), .KA_gen(KA_gen), .in(in), .out(out), .K_in(K_in), .KFL_in({K_in,K_in}), .clk(clk), .valid(valid));
endmodule
