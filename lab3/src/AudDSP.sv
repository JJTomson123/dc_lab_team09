module AudDSP(
	input i_rst_n,
	
    inout i_clk,
	
    input i_start,
	input i_pause,
	input i_stop,
	input [3:0] i_speed,
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



logic pclk_r, pclk_w;

logic [1:0] state_r, state_w;
logic [20:0] addr_r, addr_w;
logic signed [15:0] data_r, data_w, data_nxt_r, data_nxt_w;
logic [2:0] counter_r, counter_w;


assign o_sram_addr = addr_r[19:0];
assign o_dac_data = data_nxt_r;


always_comb begin
	// design your control here
    case(state_r)
    S_IDLE: begin
		addr_w = 0;
		data_w = 0;
		counter_w = 0;
		data_nxt_w = 0;
		if (i_start) begin
			state_w = S_START;
		end
		else begin
			state_w = S_IDLE;
		end

    end
	S_START: begin
		if(i_pause) begin
			state_w = S_PAUSE;
			addr_w = addr_r;
			data_nxt_w = data_nxt_r;

		end
		else if (i_stop) begin
			state_w = S_IDLE;
			addr_w = addr_r;
			data_nxt_w = data_nxt_r;

		end
		else if (pclk_r ^ i_daclrck) begin
			data_nxt_w = i_sram_data;
			if (addr_r[20]) begin
				addr_w = addr_r;
				counter_w = 0;
				state_w = S_IDLE;
			end
			else if (i_fast) begin
				addr_w = addr_r + i_speed + 1;
				state_w = S_START;
				counter_w = 0;
			end
			else if (i_slow_0) begin
				state_w = S_START;
				if (counter_r==i_speed) begin
					addr_w = addr_r + 1;
					counter_w = 0;
				end
				else begin
					addr_w = addr_r;
					counter_w = counter_r + 1;

				end		
			end
			else if (i_slow_1) begin
				state_w = S_START;
				if (counter_r==i_speed) begin
					data_w = data_nxt_r;
					addr_w = addr_r + 1;
					counter_w = 0;
				end
				else begin
					data_w = data_r;
					addr_w = addr_r;
                    counter_w = counter_r + 1;
				end
			end
			else begin
				addr_w = addr_r + 1;
				state_w = S_START;
				counter_w = 0;
			end
		end
		else begin
			data_w = data_r;
			addr_w = addr_r;
			state_w = S_START;
			counter_w = counter_r;
			if (i_slow_1) begin
				data_nxt_w = data_r + (data_nxt_r - data_r)/(i_speed + 1);
			end
			else begin
				data_nxt_w = data_nxt_r;
			end

		end

	end
	S_PAUSE: begin
		addr_w = addr_r;
		data_w = data_r;
		if (i_start) begin
			state_w = S_START;
		end
		else begin
			state_w = S_PAUSE;
		
		end
	end
    endcase
end

always_ff @(posedge i_clk or posedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r <= S_IDLE;
		data_r <= 0;
		addr_r <= 0;
		
		
	end
	else begin
        state_r <= state_w;
		data_r <= data_w;
		addr_r <= addr_w;
		
	end
end


endmodule

