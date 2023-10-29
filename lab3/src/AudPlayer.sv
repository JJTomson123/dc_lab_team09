module AudPlayer(
	input i_rst_n,
	
    inout i_bclk,
	inout i_daclrck,
	
    input i_en, // enable AudPlayer only when playing audio, work with AudDSP
	input [15:0] i_dac_data, //dac_data
	
    output o_aud_dacdat
);


parameter S_IDLE      = 0;
parameter S_PLAY      = 1;

logic state_r, state_w;
logic data_r, data_w;
logic [4:0] bit_counter_r, bit_counter_w;
logic [3:0] i_r, i_w;
logic pclk_r,pclk_w;

assign o_aud_dacdat = (state_r == S_PLAY && i_en) ? data_r : 1'b0;

always_comb begin
	// design your control here
    case(state_r)
    S_IDLE: begin
        bit_counter_w = bit_counter_r;
        data_w = data_r;
        i_w = i_r;
        if (i_en && ~(pclk_r==i_daclrck)) begin
            pclk_w = i_daclrck;
            state_w = S_PLAY;
        end else begin
            state_w = S_IDLE;
            pclk_w = pclk_r;
        end
    end
    S_PLAY: begin  
        pclk_w = pclk_r;   
        if (i_en) begin
            if (bit_counter_r==16) begin
                data_w = i_dac_data[i_r];
                state_w = S_IDLE;
                i_w = 4'b1111;
                bit_counter_w = 0;
            end
            else begin
                data_w = i_dac_data[i_r];
                i_w = i_r - 4'b0001;
                state_w = S_PLAY;
                bit_counter_w = bit_counter_r + 1;
            end      
        end
        else begin
            data_w = data_r;
            i_w = i_r;
            state_w = S_PLAY;
            bit_counter_w = bit_counter_r;
        end
    end
    endcase
end

always_ff @(posedge i_bclk or posedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r <= S_IDLE;
        data_r <= 0;
        bit_counter_r = 0;
        pclk_r <= 1;
        i_r <= 4'b1111;
		
		
	end
	else begin
        state_r <= state_w;
        data_r <= data_w;
        bit_counter_r <= bit_counter_w;
        pclk_r <= pclk_w;
        i_r <= i_w;
		
	end
end




endmodule