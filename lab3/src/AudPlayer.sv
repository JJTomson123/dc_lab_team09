module AudPlayer(
	input i_rst_n,
	
    inout i_bclk,
	inout i_daclrck,
	
    input i_en, // enable AudPlayer only when playing audio, work with AudDSP
	input [15:0] i_dac_data, //dac_data
	
    output o_aud_dacdat
);


parameter S_IDLE = 0;
parameter S_PLAY = 1;

logic        state_r, state_w;
logic [15:0] data_r, data_w;
logic [3:0]  bit_counter_r, bit_counter_w;
logic        lr_prev, lr_pulse;

assign o_aud_dacdat = data_r[15];

always_comb begin
	// design your control here
    case(state_r)
    S_IDLE: begin
        bit_counter_w = 0;
        if (i_en && lr_pulse) begin
            state_w = S_PLAY;
            data_w  = i_dac_data;
        end else begin
            state_w = S_IDLE;
            data_w  = 0;
        end
    end
    S_PLAY: begin
        bit_counter_w = bit_counter_r + 1;
        data_w        = data_r << 1;
        if (bit_counter_r == 4'd15) state_w = S_IDLE;
        else                        state_w = S_PLAY;
    end
    endcase
end

always_ff @(posedge i_bclk) begin
    lr_pulse <= lr_prev ^ i_daclrck;
    lr_prev  <= i_daclrck;
end

always_ff @(negedge i_bclk or negedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r       <= S_IDLE;
        data_r        <= 0;
        bit_counter_r <= 0;
	end
	else begin
        state_r       <= state_w;
        data_r        <= data_w;
        bit_counter_r <= bit_counter_w;
	end
end




endmodule