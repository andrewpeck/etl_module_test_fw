`timescale 1ns / 100ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Southern Methodist University
// Author: Datao Gong
//
// Create Date: Mon Feb  8 19:42:43 CST 2021
// Module Name: CRC8
// Project Name: ETROC2 readout
// Description:
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
//  CRC-8 generator at behavior level
//  Polynomial: 0X97 = X^8+X^5+X^3+X^2+X+1
//  Southern Methodist University
//
//
//0 C0 C1 C2 C3 C4 C5 C6 C7
//1 A0C7 A0C0C7 A0C1C7 A0C2C7 C3 A0C4C7 C5 C6
//1 A0C7 A0C0C7 A0C1C7 A0C2C7 C3  A0C4C7 C5 C6


//////////////////////////////////////////////////////////////////////////////////

module CRC8 #(parameter WORDWIDTH = 40)
(
	input [7:0] 	        cin,          //input CRC code 8bits
    input                   dis,
	input [WORDWIDTH-1:0]   din,        //input data 40 bits
	output [7:0]            dout        //output CRC 8 bits
);
// tmrg default triplicate

    wire [WORDWIDTH-1:0] d;
    assign d = (dis == 1'b1) ? {WORDWIDTH{1'b0}} : din;
    wire [7:0] cc [WORDWIDTH:0];  //chain
    generate
        genvar i;
        for (i = 0; i < WORDWIDTH; i = i+1 )
        begin : CRCloop
            assign cc[i+1] = {
                            cc[i][6],
                            cc[i][5],
                            d[WORDWIDTH-1-i] ^ cc[i][4] ^ cc[i][7],
                            cc[i][3],
                            d[WORDWIDTH-1-i] ^ cc[i][2] ^ cc[i][7],
                            d[WORDWIDTH-1-i] ^ cc[i][1] ^ cc[i][7],
                            d[WORDWIDTH-1-i] ^ cc[i][0] ^ cc[i][7],
                            d[WORDWIDTH-1-i] ^ cc[i][7]
            };
        end
    endgenerate

    assign cc[0] = cin;
    assign dout = cc[WORDWIDTH];

endmodule
