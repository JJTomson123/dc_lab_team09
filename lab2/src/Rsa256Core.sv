module Rsa256Core (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_d, // private key
	input  [255:0] i_n,
	output [255:0] o_a_pow_d, // plain text x
	output         o_finished
);

// operations for RSA256 decryption
// namely, the Montgomery algorithm
localparam S_IDLE = 2'b00;
localparam S_PREP = 2'b01;
localparam S_MONT = 2'b10;
localparam S_CALC = 2'b11;

logic state_r, state_w;

RsaPrep rsa_prep(.i_clk(i_clk), .i_rst(i_rst), .i_a(.i_a), .i_n(i_n));

always_comb begin

end

always_ff begin

end

endmodule


module RsaPrep (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a, // cipher text y
	input  [255:0] i_n,
	output [255:0] o_t, // t = y * 2^256
	output         o_finished
);

localparam S_IDLE = 0;
localparam S_CALC = 1;

logic 

always_comb begin

end

always_ff begin

end

endmodule