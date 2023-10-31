module AudDSP(
	input i_rst_n,
	
    inout i_clk,
	
    input i_start,
	input i_pause,
	input i_stop,
	input i_speed,
	input i_fast,
	input i_slow_0, // constant interpolation
	input i_slow_1, // linear interpolation
	
    inout i_daclrck,
	
    input  [15:0] i_sram_data,
	
    output [15:0] o_dac_data,
	output [19:0] o_sram_addr
);


parameter S_IDLE       = 0;
parameter S_START      = 1;
parameter S_PAUSE      = 2;
parameter S_STOP       = 3;

logic [1:0] state_r, state_w;

always_comb begin
	// design your control here
    case(state_r)
    S_IDLE: begin

    end
    endcase
end

always_ff @(posedge i_clk or posedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r <= S_IDLE;
		
		
	end
	else begin
        state_r <= state_w;
		
	end
end


endmodule