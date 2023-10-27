module AudPlayer(
	input i_rst_n,
	
    inout i_bclk,
	inout i_daclrck,
	
    input i_en, // enable AudPlayer only when playing audio, work with AudDSP
	input [15:0] i_dac_data, //dac_data
	
    output o_aud_dacdat
);

endmodule