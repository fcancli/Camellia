`timescale 1ns / 1ps

module Camellia_core(block, result, key, clk, EncOrDec, rst, init, next, ready, valid);
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
    
    logic ready_s,valid_s;
    logic valid_feist;
    logic start_feist;
    logic KA_gen;
    logic [4:0] round_feist;
    logic [0:127] KA_feist=0;
    logic [0:127] feist_in, feist_out, KL_feist=0;
    logic [1:0] NS;
    logic [1:0] PS=0;
    localparam idle=0, KA_generation=1, key_scheduling=2, data_random=3;
    
    assign ready=ready_s;
    assign valid=valid_s;
    assign result=feist_out;
    
    always@(posedge clk)
    begin
        if (rst) PS<=idle;
        else PS<=NS;                    
    end
    
    always@(posedge clk)
    begin
    	if (valid_feist==1 & PS==KA_generation)
    		KA_feist<=feist_out;
    	else
    		KA_feist<=KA_feist;
    end
    
    always@(posedge clk)
    begin
    	if (init)
    		KL_feist<=key;
    	else
    		KL_feist<=KL_feist;
    end
    
    always@(PS, init, next, valid_feist, key, block)
    begin
    	NS=PS;
    	valid_s=0;
    	ready_s=1;
    	start_feist=0;
    	feist_in=0;
    	KA_gen=0;
    	case (PS)
    		idle: begin
    			if (init)
    				NS=KA_generation;
    			else if (next)
    				NS=data_random;
    			end
    		KA_generation: begin
    			ready_s=0;
    			start_feist=1;
    			KA_gen=1;
    			feist_in=key;
    			if (valid_feist)
    			begin
    				KA_gen=0;
    				start_feist=0;
    				NS=idle;
    			end
    			end
    		data_random: begin
    			ready_s=0;
    			start_feist=1;
    			feist_in=block;
    			if (valid_feist)
				begin
					start_feist=0;
					NS=idle;
				end
    			end
    	endcase   			    				
    				    			 
    end
    
	Feistel_rand feist(.start(start_feist), .KA_gen(KA_gen), .in(feist_in), .out(feist_out), .KA(KA_feist), .KL(KL_feist), .clk(clk), .valid(valid_feist));
    
endmodule
