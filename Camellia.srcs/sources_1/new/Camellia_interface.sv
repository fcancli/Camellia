`timescale 1ns / 1ps

module Camellia_interface(block, result, key, clk, EncOrDec, rst, init, next, ready, valid);
    input [127:0] block;
    input [127:0] key;
    output [127:0] result;
    input EncOrDec;
    input clk;
    input rst;
    input init;
    input next;
    output ready;
    output valid;
    
   logic [0:127] feist_out;

    
   
	Camellia_core core(.init(init), .in(block), .out(result), .next(next), .KL(key), .clk(clk), .valid(valid), .EncOrDec(EncOrDec), .ready(ready), .rst(rst));
    
endmodule
