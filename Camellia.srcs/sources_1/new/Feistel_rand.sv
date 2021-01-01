`timescale 1ns / 1ps

//questo blocco utilizza la F_function che ha sua volta riceve in ingresso le chiavi
//ma alcune sono generate da KA che viene generato in questo blocco.
//devo quindi fare in modo che questo blocco abbia due funzionalità
module Feistel_rand(init, in, out, next, KL, clk, valid, EncOrDec, ready);
	input init;
	input clk;
	input [0:127] in;
	input [0:127] KL;
	output [0:127] out;
	input next;   //input key per i round blocks
//	output [0:127] KA_out;
	input EncOrDec;
	output valid;
	output ready;
	
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
	logic [4:0] round=0, round_comb=0;
	logic [0:63] sx, sx_comb, dx, dx_comb;
	logic [0:63] FX,Fk,Fout,FLX,FLk,FLout,IFLY,IFLk,IFLout;
	logic [0:127] out_s;
	logic [0:127] out_temp;
	logic [0:127] KA_reg=0;
	logic [0:127] KL_reg=0;
	logic [0:127] KA_temp=0;
	logic [0:127] KL_temp=0;
	logic [0:127] KA_15_sx, KA_15_dx, KA_17_sx, KA_17_dx;
	logic [0:127] KL_15_sx, KL_15_dx, KL_17_sx, KL_17_dx;
	logic [0:127] dual_K;
	logic [0:63] single_K;
	
	logic valid_s;
	logic valid_KA;
	logic valid_reg;
	logic ready_s;
	
	assign valid =valid_reg;
	assign ready=ready_s;
	
	always@(posedge clk)
	begin
//		PS<=NS;
//		sx<=sx_comb;
//		dx<=dx_comb;
//		round<=round_comb;
		if (PS==CD_final_xor)
			valid_reg<=1;
		else
			valid_reg<=0;
	end
	
	assign out={sx,dx};
	
	always@(posedge clk)
	begin
		case (PS)
			idle: begin
				valid_KA<=0;
				ready_s<=1;
				round<=0;
				if (init)
				begin 
					PS<=KA_block; 
					sx<=KL[0:63]; 
					dx<=KL[64:127]; 
				end
				if (next)
				begin
					PS<=CD_initial_xor;
				end
				end
			KA_block: begin
				round<=round+1;
				if (round==1)
					PS<=KA_middle_xor;
				if (round==3) begin
					PS<=idle;
					valid_KA<=1;
				end
				sx<=Fout^dx;
				dx<=sx;	
				end	
			KA_middle_xor: begin
				sx<=sx^KL_reg[0:63];
				dx<=dx^KL_reg[64:127];
				PS<=KA_block;
				end
			CD_initial_xor: begin
				sx<=in[0:63]^dual_K[0:63];
				dx<=in[64:127]^dual_K[64:127];
				PS<=CD_block;
				end
			CD_block: begin
				round<=round+1;
				if (round==5 || round==11)
					PS<=CD_FL;		
				if (round==17)	
					PS<=CD_final_xor;
				sx<=Fout^dx;
				dx<=sx;	
				end
			CD_FL: begin
				sx<=FLout;
				dx<=IFLout;
				PS<=CD_block;
				end
			CD_final_xor: begin
				sx<=dx^dual_K[0:63];
				dx<=sx^dual_K[64:127];
				PS<=idle;
				end						
		endcase
			
	end
	always@(PS, round, Fout, in, init, next, sx, dx, FLout, IFLout, dual_K, single_K)
	begin
//		NS=PS;
		FX='0;
		Fk='0;
		FLX='0;
		FLk='0;
		IFLY='0;
		IFLk='0;
//		valid_KA=0;
//		round_comb=0;		
		dx_comb=0;
		sx_comb=0;
//		ready_s=0;
		case (PS)
//			idle: begin
//				ready_s=1;
//				if (init)
//				begin 
////					NS=KA_block; 
//					sx_comb=KL[0:63]; 
//					dx_comb=KL[64:127]; 
//				end
//				if (next)
//				begin
//					NS=CD_initial_xor;
//				end
//				end
			KA_block: begin
//				round_comb=round+1;
				FX=sx;
				if (round==0) begin
//					sx_comb=KL[0:63]; 
//					dx_comb=KL[64:127]; 
					Fk=64'hA09E667F3BCC908B; end
				else if (round==1)
				begin
					Fk=64'hB67AE8584CAA73B2;
//					NS=KA_middle_xor;
				end
				else if(round==2)
					Fk=64'hC6EF372FE94F82BE;
				else if(round==3) begin
					Fk=64'h54FF53A5F1D36F1C;
//					NS=idle;
//					valid_KA=1;
					end
//				sx_comb=Fout^dx;
//				dx_comb=sx;									
				end
//			KA_middle_xor: begin
//				sx_comb=sx^KL_reg[0:63];
//				dx_comb=dx^KL_reg[64:127];
//				NS=KA_block;
//				round_comb=round;
//				end
//			CD_initial_xor: begin
//				sx_comb=in[0:63]^dual_K[0:63];
//				dx_comb=in[64:127]^dual_K[64:127];
//				NS=CD_block;
//				round_comb=round;
//				end
			CD_block: begin
//				round_comb=round+1;
				FX=sx;
				Fk=single_K;
//				sx_comb=Fout^dx;
//				if (round==5 || round==11)
//					NS=CD_FL;		
//				if (round==17)	
//					NS=CD_final_xor;
//				dx_comb=sx;
				end
			CD_FL: begin
				FLX=sx;
				IFLY=dx;
				FLk=(EncOrDec) ? dual_K[0:63] : dual_K[64:127];
				IFLk=(EncOrDec) ? dual_K[64:127] : dual_K[0:63];
//				sx_comb=FLout;
//				dx_comb=IFLout;
//				NS=CD_block;
//				round_comb=round;
				end
//			CD_final_xor: begin
//				sx_comb=dx^dual_K[0:63];
//				dx_comb=sx^dual_K[64:127];
//				NS=idle;
//				round_comb=round;
//				end						
		endcase
	end
	
	assign KA_15_sx={KA_temp[15:127],KA_temp[0:14]};
	assign KL_15_sx={KL_temp[15:127],KL_temp[0:14]};
	assign KA_15_dx={KA_temp[113:127],KA_temp[0:112]};
	assign KL_15_dx={KL_temp[113:127],KL_temp[0:112]};
	
	assign KA_17_sx={KA_temp[17:127],KA_temp[0:16]};
	assign KL_17_sx={KL_temp[17:127],KL_temp[0:16]};
	assign KA_17_dx={KA_temp[111:127],KA_temp[0:110]};
	assign KL_17_dx={KL_temp[111:127],KL_temp[0:110]};
	
	always@(posedge clk)
	begin
		if (init)
			KL_reg<=KL;
		else
			KL_reg<=KL_reg;
	end
	
	always@(posedge clk)
	begin
		if (valid_KA)
			KA_reg<={sx,dx};
		else
			KA_reg<=KA_reg;
	end
	
	always@(posedge clk) 
	begin
		case(PS)
			idle: begin				
				if (next) begin
					KL_temp<=(EncOrDec) ? KL_reg : {KL_reg[111:127],KL_reg[0:110]};;
					KA_temp<=(EncOrDec) ? KA_reg : {KA_reg[111:127],KA_reg[0:110]};; end
				end
			CD_initial_xor: begin
				KA_temp<=(EncOrDec) ? KA_temp : KA_17_dx;
				KL_temp<=(EncOrDec) ? KL_15_sx : KL_temp;
				end
			CD_FL: begin
			case (round)
				6: begin
					KA_temp<=(EncOrDec) ? KA_15_sx : KA_17_dx;
					KL_temp<=(EncOrDec) ? KL_15_sx : KL_17_dx; end
				12:	begin
					KL_temp<=(EncOrDec) ? KL_17_sx : KL_15_dx;
					KA_temp<=(EncOrDec) ? KA_17_sx : KA_15_dx; end
				endcase
			end
			CD_block: begin
			case (round)
				1,5: begin
					KA_temp<=(EncOrDec) ? KA_15_sx : KA_temp; 
					KL_temp<=(EncOrDec) ? KL_temp : KL_17_dx;	end
				8: begin
					KA_temp<=(EncOrDec) ? KA_15_sx : KA_temp;
					KL_temp<=(EncOrDec) ? KL_temp : KL_15_dx;	end
				7: begin
					KL_temp<=(EncOrDec) ? KL_15_sx : KL_temp;
					KA_temp<=(EncOrDec) ? KA_temp : KA_15_dx; end						
				3: begin
					KL_temp<=(EncOrDec) ? KL_15_sx : KL_temp; 
					KA_temp<=(EncOrDec) ? KA_temp : KA_17_dx; end		
				9,13: begin
					KL_temp<=(EncOrDec) ? KL_17_sx : KL_temp; 
					KA_temp<=(EncOrDec) ? KA_temp : KA_15_dx; end	
				11,15: begin
					KA_temp<=(EncOrDec) ? KA_17_sx : KA_temp; 
					KL_temp<=(EncOrDec) ? KL_temp : KL_15_dx; end	
				default: begin
					KA_temp<=KA_temp;
					KL_temp<=KL_temp;
				end		
				endcase
			end
			default: begin
				KA_temp<=KA_temp;
				KL_temp<=KL_temp;
				end
		 endcase
				
	end
	
	always@(PS, KA_temp, KL_temp, round )
	begin
		single_K=0;
		dual_K=0;
		case (PS)
			CD_initial_xor: 
				dual_K=(EncOrDec) ? KL_temp : KA_temp;
			CD_FL: begin
			case (round)
			6:
				dual_K=(EncOrDec) ? KA_temp : KL_temp;	
			12:
				dual_K=(EncOrDec) ? KL_temp : KA_temp;
				endcase
			end
			CD_final_xor: 
				dual_K=(EncOrDec) ? KA_temp : KL_temp;
			CD_block: begin
			case (round)
			0,4,8,10,14:
					single_K=(EncOrDec) ? KA_temp[0:63] : KL_temp[64:127];
			1,5,11,15:
					single_K=(EncOrDec) ? KA_temp[64:127] : KL_temp[0:63];
			2,6,12,16:
					single_K=(EncOrDec) ? KL_temp[0:63] : KA_temp[64:127];
			3,7,9,13,17:
					single_K=(EncOrDec) ? KL_temp[64:127] : KA_temp[0:63];
				endcase
			end			
		 endcase
	end
	
	F_function f(.X(FX), .k(Fk), .out(Fout));
	FL_function fl(.X(FLX), .k(FLk), .out(FLout));
	invFL_function ifl(.Y(IFLY), .k(IFLk), .out(IFLout));
endmodule
