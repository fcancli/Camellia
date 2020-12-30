`timescale 1ns / 1ps

module S_function(in, out);
    input [0:63] in;
    output [0:63] out;
    
    
    logic [0:7] s1_out;
    logic [0:7] s11_out;
    logic [0:7] s2_out;
    logic [0:7] s22_out;
    logic [0:7] s3_out;
    logic [0:7] s33_out;
    logic [0:7] s4_out;
    logic [0:7] s44_out;
    
    assign out[0:7]=s1_out;
    assign out[8:15]=s2_out;
    assign out[16:23]=s3_out;
    assign out[24:31]=s4_out;
    assign out[32:39]=s22_out;
    assign out[40:47]=s33_out;
    assign out[48:55]=s44_out;
    assign out[56:63]=s11_out;
    
    s1_box s11(.in(in[0:7]),.out(s1_out));
    s1_box s12(.in(in[56:63]),.out(s11_out));
    s2_box s21(.in(in[8:15]),.out(s2_out));
    s2_box s22(.in(in[32:39]),.out(s22_out));
    s3_box s31(.in(in[16:23]),.out(s3_out));
    s3_box s32(.in(in[40:47]),.out(s33_out));
    s4_box s41(.in(in[24:31]),.out(s4_out));
    s4_box s42(.in(in[48:55]),.out(s44_out));
    
endmodule
