`timescale 1ns / 1ps

//questo blocco utilizza la F_function che ha sua volta riceve in ingresso le chiavi
//ma alcune sono generate da KA che viene generato in questo blocco.
//devo quindi fare in modo che questo blocco abbia due funzionalità
module Feistel_rand(init, in, out, next, KL, clk, valid, EncOrDec);
	input init;
	input clk;
	input [0:127] in;
	input [0:127] KL;
	output [0:127] out;
	input next;   //input key per i round blocks
//	output [0:127] KA_out;
	input EncOrDec;
	output valid;
	
	localparam idle=0;
//stati per la generazione dell KA
	localparam KA_block=1;
	localparam KA_middle_xor=2;
	localparam KA_done=3;
//stati per la crittazione/decrittazione
	localparam CD_initial_xor=4;
	localparam CD_block=5;
	localparam CD_FL=6;
	localparam CD_final_xor=7;
	
	logic [2:0] NS;
	logic [2:0] PS=0;
	logic [4:0] round, round_comb=0;
	logic [0:63] sx, sx_comb, dx, dx_comb;
	logic [0:63] FX,Fk,Fout,FLX,FLk,FLout,IFLY,IFLk,IFLout;
	logic [0:127] out_s;
	logic [0:127] out_temp;
	logic [0:127] KA_reg=0;
	logic [0:127] KL_reg=0;
	logic [0:127] KA_15_sx, KA_15_dx, KA_17_sx, KA_17_dx;
	logic [0:127] KL_15_sx, KL_15_dx, KL_17_sx, KL_17_dx;
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
		round_comb=0;		
		dx_comb=0;
		sx_comb=0;
		out_temp=0;
		case (PS)
			idle: begin
				if (init)
				begin 
					NS=KA_block; 
					sx_comb=KL[0:63]; 
					dx_comb=KL[64:127]; 
				end
				if (next)
				begin
					NS=CD_initial_xor;
				end
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
				else if(round==3) begin
					Fk=64'h54FF53A5F1D36F1C;
					NS=idle;
					valid_KA=1;
					end
				sx_comb=Fout^dx;
				dx_comb=sx;									
				end
			KA_middle_xor: begin
				sx_comb=sx^KL_reg[0:63];
				dx_comb=dx^KL_reg[64:127];
				NS=KA_block;
				round_comb=round;
				end
			CD_initial_xor: begin
				sx_comb=in[0:63]^dual_K[0:63];
				dx_comb=in[64:127]^dual_K[64:127];
				NS=CD_block;
				round_comb=round;
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
				FLk=(EncOrDec) ? dual_K[0:63] : dual_K[64:127];
				IFLk=(EncOrDec) ? dual_K[64:127] : dual_K[0:63];
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
	
	assign KA_15_sx={KA_reg[15:127],KA_reg[0:14]};
	assign KL_15_sx={KL_reg[15:127],KL_reg[0:14]};
	assign KA_15_dx={KA_reg[113:127],KA_reg[0:112]};
	assign KL_15_dx={KL_reg[113:127],KL_reg[0:112]};
	
	assign KA_17_sx={KA_reg[17:127],KA_reg[0:16]};
	assign KL_17_sx={KL_reg[17:127],KL_reg[0:16]};
	assign KA_17_dx={KA_reg[111:127],KA_reg[0:110]};
	assign KL_17_dx={KL_reg[111:127],KL_reg[0:110]};
	
	always@(posedge clk) 
	begin
		case(PS)
			idle: begin
				if (init) begin
					KL_reg<=KL;
					KA_reg<=0; end
				else if (next) begin
					KL_reg<=(EncOrDec) ? KL_reg : KL_17_dx;
					KA_reg<=(EncOrDec) ? KA_reg : KA_17_dx; end
				end
			KA_block: begin
				if (valid_KA)
					KA_reg<={sx_comb,dx_comb};
				else
					KA_reg<=KA_reg;
				end
			CD_initial_xor: begin
				KA_reg<=(EncOrDec) ? KA_reg : KA_17_dx;
				KL_reg<=(EncOrDec) ? KL_15_sx : KL_reg;
				end
			CD_FL: begin
			case (round)
				6: begin
					KA_reg<=(EncOrDec) ? KA_15_sx : KA_17_dx;
					KL_reg<=(EncOrDec) ? KL_15_sx : KL_17_dx; end
				12:	begin
					KL_reg<=(EncOrDec) ? KL_17_sx : KL_15_dx;
					KA_reg<=(EncOrDec) ? KA_17_sx : KA_15_dx; end
				endcase
			end
			CD_block: begin
			case (round)
				1,5: begin
					KA_reg<=(EncOrDec) ? KA_15_sx : KA_reg; 
					KL_reg<=(EncOrDec) ? KL_reg : KL_17_dx;	end
				8: begin
					KA_reg<=(EncOrDec) ? KA_15_sx : KA_reg;
					KL_reg<=(EncOrDec) ? KL_reg : KL_15_dx;	end
				7: begin
					KL_reg<=(EncOrDec) ? KL_15_sx : KL_reg;
					KA_reg<=(EncOrDec) ? KA_reg : KA_15_dx; end						
				3: begin
					KL_reg<=(EncOrDec) ? KL_15_sx : KL_reg; 
					KA_reg<=(EncOrDec) ? KA_reg : KA_17_dx; end		
				9,13: begin
					KL_reg<=(EncOrDec) ? KL_17_sx : KL_reg; 
					KA_reg<=(EncOrDec) ? KA_reg : KA_15_dx; end	
				11,15: begin
					KA_reg<=(EncOrDec) ? KA_17_sx : KA_reg; 
					KL_reg<=(EncOrDec) ? KL_reg : KL_15_dx; end	
				default: begin
					KA_reg<=KA_reg;
					KL_reg<=KL_reg;
				end		
				endcase
			end
			default: begin
				KA_reg<=KA_reg;
				KL_reg<=KL_reg;
				end
		 endcase
				
	end
	
	always@(PS, KA_reg, KL_reg, round )
	begin
		single_K=0;
		dual_K=0;
		case (PS)
			CD_initial_xor: 
				dual_K=(EncOrDec) ? KL_reg : KA_reg;
			CD_FL: begin
			case (round)
			6:
				dual_K=(EncOrDec) ? KA_reg : KL_reg;	
			12:
				dual_K=(EncOrDec) ? KL_reg : KA_reg;
				endcase
			end
			CD_final_xor: 
				dual_K=(EncOrDec) ? KA_reg : KL_reg;
			CD_block: begin
			case (round)
			0,4,8,10,14:
					single_K=(EncOrDec) ? KA_reg[0:63] : KL_reg[64:127];
			1,5,11,15:
					single_K=(EncOrDec) ? KA_reg[64:127] : KL_reg[0:63];
			2,6,12,16:
					single_K=(EncOrDec) ? KL_reg[0:63] : KA_reg[64:127];
			3,7,9,13,17:
					single_K=(EncOrDec) ? KL_reg[64:127] : KA_reg[0:63];
				endcase
			end			
		 endcase
	end
	
	F_function f(.X(FX), .k(Fk), .out(Fout));
	FL_function fl(.X(FLX), .k(FLk), .out(FLout));
	invFL_function ifl(.Y(IFLY), .k(IFLk), .out(IFLout));
endmodule
