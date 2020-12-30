`timescale 1ns / 1ps

//questo blocco utilizza la F_function che ha sua volta riceve in ingresso le chiavi
//ma alcune sono generate da KA che viene generato in questo blocco.
//devo quindi fare in modo che questo blocco abbia due funzionalità
module Feistel_rand(init, in, out, next, KL, clk, valid);
	input init;
	input clk;
	input [0:127] in;
	input [0:127] KL;
	output [0:127] out;
	input next;   //input key per i round blocks
//	output [0:127] KA_out;
	output valid;
	
	localparam idle=0;
//stati per la generazione dell KA
	localparam KA_block=1;
	localparam KA_middle_xor=2;
//	localparam KA_second_block=3;
	localparam KA_done=3;
//stati per la crittazione/decrittazione
	localparam CD_initial_xor=4;
	localparam CD_block=5;
	localparam CD_FL=6;
	localparam CD_final_xor=7;
	
	logic [2:0] NS;
	logic [2:0] PS=0;
	logic [4:0] round, round_comb;
	logic [0:63] sx, sx_comb, dx, dx_comb;
	logic [0:63] FX,Fk,Fout,FLX,FLk,FLout,IFLY,IFLk,IFLout;
	logic [0:127] out_s;
	logic [0:127] out_temp;
	logic [0:127] KA_reg, KA_comb;
	logic [0:127] KL_reg, KL_comb;
	logic [0:127] dual_K;
	logic [0:63] single_K;
	
	logic valid_s;
	logic valid_KA;
	logic valid_reg;
	
	assign valid =valid_reg;
//	assign KA_out=KA_out_s;
	assign out=out_s;
	
	always@(posedge clk)
	begin
		PS<=NS;
		sx<=sx_comb;
		dx<=dx_comb;
		round<=round_comb;
		out_s<=out_temp;
		valid_reg<=valid_s;
	end
	
	always@(posedge clk)
	begin
		if (valid_KA)
			KA_reg<={sx_comb,dx_comb};
		else
			KA_reg<=KA_comb;
	end
	
	always@(posedge clk)
	begin
		if (init)
			KL_reg<=in;
		else
			KL_reg<=KL_comb;
	end
	
	
	
	always@(PS, round, Fout, in, init, next, sx, dx, FLout, IFLout, dual_K, single_K)
	begin
		NS=PS;
		FX='0;
		Fk='0;
		FLX='0;
		FLk='0;
		IFLY='0;
		IFLk='0;
		valid_s=0;
		valid_KA=0;
		round_comb=5'd0;
		dx_comb=0;
		sx_comb=0;
		out_temp=0;
		case (PS)
			idle: begin
				if (init)
				begin 
					NS=KA_block; 
					sx_comb=in[0:63]; 
					dx_comb=in[64:127]; 
				end
				if (next)
					NS=CD_initial_xor;
				end
			KA_block: begin
				round_comb=round+1;
				FX=sx;
				if (round==0)
					Fk=64'hA09E667F3BCC908B;
				else if (round==1)
				begin
					Fk=64'hB67AE8584CAA73B2;
					NS=KA_middle_xor;
				end
				else if(round==2)
					Fk=64'hC6EF372FE94F82BE;
				else if(round==3)
					Fk=64'h54FF53A5F1D36F1C;
				sx_comb=Fout^dx;
				dx_comb=sx;		
				if (round==3) begin
					NS=idle;
					valid_KA=1;
				end							
				end
			KA_middle_xor: begin
				sx_comb=sx^in[0:63];
				dx_comb=dx^in[64:127];
				NS=KA_block;
				round_comb=round;
				end
			CD_initial_xor: begin
				sx_comb=in[0:63]^dual_K[0:63];
				dx_comb=in[64:127]^dual_K[64:127];
				NS=CD_block;
				end
			CD_block: begin
				round_comb=round+1;
				FX=sx;
				Fk=single_K;
				sx_comb=Fout^dx;
				if (round==5 || round==11)
					NS=CD_FL;		
				if (round==17)	
					NS=CD_final_xor;
				dx_comb=sx;
				end
			CD_FL: begin
				FLX=sx;
				IFLY=dx;
				FLk=dual_K[0:63];
				IFLk=dual_K[64:127];
				sx_comb=FLout;
				dx_comb=IFLout;
				NS=CD_block;
				round_comb=round;
				end
			CD_final_xor: begin
				sx_comb=dx^dual_K[0:63];
				dx_comb=sx^dual_K[64:127];
				NS=idle;
				valid_s=1;
				out_temp={sx_comb,dx_comb};
				round_comb=round;
				end						
		endcase
	end
	
	
	//poi prova a usare una fuinction per evitare di scrivere sempre la stessa cosa
	always_comb
	begin
		single_K=0;
		dual_K=0;
		case (PS)
			CD_initial_xor: begin
					dual_K=KL_reg;
					KL_comb={KL_reg[15:127],KL_reg[0:14]};
					end
			CD_FL: begin
				if (round==6) begin
					dual_K=KA_reg;	
					KA_comb={KA_reg[15:127],KA_reg[0:14]};
					KL_comb={KL_reg[15:127],KL_reg[0:14]}; end
				else if (round==12)	begin
					dual_K=KL_reg;
					KL_comb={KL_reg[17:127],KL_reg[0:16]};
					KA_comb={KA_reg[17:127],KA_reg[0:16]}; end
				end
			CD_final_xor: begin
				dual_K=KA_reg;
				end
			CD_block: begin
				if (round==0)
					single_K=KA_reg[0:63];
				else if (round==1) begin
					single_K=KA_reg[64:127];
					KA_comb={KA_reg[15:127],KA_reg[0:14]}; end
				else if (round==2)
					single_K=KL_reg[0:63];
				else if (round==3) begin
					single_K=KL_reg[64:127];
					KL_comb={KL_reg[15:127],KL_reg[0:14]}; end
				else if (round==4)
					single_K=KA_reg[0:63];
				else if	(round==5) begin
					single_K=KA_reg[64:127];
					KA_comb={KA_reg[15:127],KA_reg[0:14]}; end
				else if (round==6)
					single_K=KL_reg[0:63];
				else if (round==7) begin
					single_K=KL_reg[64:127];
					KL_comb={KL_reg[15:127],KL_reg[0:14]}; end		
				else if (round==8) begin
					single_K=KA_reg[0:63];	
					KA_comb={KA_reg[15:127],KA_reg[0:14]}; end
				else if (round==9) begin
					single_K=KL_reg[64:127];
					KL_comb={KL_reg[17:127],KL_reg[0:16]}; end	
				else if (round==10)
					single_K=KA_reg[0:63];
				else if (round==11) begin
					single_K=KA_reg[64:127];
					KA_comb={KA_reg[17:127],KA_reg[0:16]}; end	
				else if (round==12)
					single_K=KL_reg[0:63];
				else if (round==13) begin
					single_K=KL_reg[64:127];
					KL_comb={KL_reg[17:127],KL_reg[0:16]}; end	
				else if (round==14)
					single_K=KA_reg[0:63];
				else if (round==15) begin
					single_K=KA_reg[64:127];
					KA_comb={KA_reg[17:127],KA_reg[0:16]}; end	
				else if (round==16) 
					single_K=KL_reg[0:63];
				else if (round==17)
					single_K=KL_reg[64:127];
				end				
			default: begin
				KA_comb=0;
				KL_comb=0;
				end
		 endcase
	end
	
	F_function f(.X(FX), .k(Fk), .out(Fout));
	FL_function fl(.X(FLX), .k(FLk), .out(FLout));
	invFL_function ifl(.Y(IFLY), .k(IFLk), .out(IFLout));
endmodule
