module SevenHexDecoder (
	input        [3:0] i_hex,
	output logic [6:0] o_seven_hexit
);

/* The layout of seven segment display, 1: dark
 *    00
 *   5  1
 *    66
 *   4  2
 *    33
 */
localparam logic [6:0] D[0:15] = '{
	7'b1000000,
	7'b1111001,
	7'b0100100,
	7'b0110000,
	7'b0011001,
	7'b0010010,
	7'b0000010,
	7'b1011000,
	7'b0000000,
	7'b0010000,
	7'b0001000,
	7'b0000011,
	7'b1000110,
	7'b0100001,
	7'b0000110,
	7'b0001110
};

assign o_seven_hexit = D[i_hex];

endmodule
