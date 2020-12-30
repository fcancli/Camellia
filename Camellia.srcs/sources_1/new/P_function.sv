module P_function (in, out);
    input [0:63] in;
    output [0:63] out;
    
    logic [0:63] temp;
    logic [0:7] z1;
    logic [0:7] z2;
    logic [0:7] z3;
    logic [0:7] z4;
    logic [0:7] z5;
    logic [0:7] z6;
    logic [0:7] z7;
    logic [0:7] z8;
	
	assign z1=in[0:7];
	assign z2=in[8:15];
	assign z3=in[16:23];
	assign z4=in[24:31];
	assign z5=in[32:39];
	assign z6=in[40:47];
	assign z7=in[48:55];
	assign z8=in[56:63];
    
    assign out[0:7]=z1^z3^z4^z6^z7^z8;
	assign out[8:15]=z1^z2^z4^z5^z7^z8;
	assign out[16:23]=z1^z2^z3^z5^z6^z8;
	assign out[24:31]=z2^z3^z4^z5^z6^z7;
	assign out[32:39]=z1^z2^z6^z7^z8;
	assign out[40:47]=z2^z3^z5^z7^z8;
	assign out[48:55]=z3^z4^z5^z6^z8;
	assign out[56:63]=z1^z4^z5^z6^z7;
endmodule