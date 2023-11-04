module AudRecorder(
	input i_rst_n, 
	
    inout i_clk,
	inout i_lrc,
	
    input i_start,
	input i_pause,
	input i_stop,
	input i_data,
	
    output [19:0] o_address,
	output [15:0] o_data
);


localparam S_IDLE  = 0;
localparam S_REC   = 1;
localparam S_GET   = 2;
localparam S_PAUSE = 3;

logic [1:0] state_r, state_w;
logic [15:0] data_r, data_w;
logic [20:0] addr_r, addr_w;
logic [5:0] bit_counter_r, bit_counter_w;
logic lr_prev;

assign o_data = data_r;
assign o_address = addr_r;

always_comb begin
    // FSM
    case(state_r)
    S_IDLE: begin
        if (i_start) state_w = S_REC;
        else         state_w = S_IDLE;
    end
    S_REC: begin
        if (i_stop || addr_r[20])   state_w = S_IDLE;
        else if (i_pause)           state_w = S_PAUSE;
        else if (!lr_prev && i_lrc) state_w = S_GET;
        else                        state_w = S_REC;
    end
    S_GET: begin
        if (bit_counter_r == 16) state_w = S_REC;
        else                     state_w = S_GET;
    end
    S_PAUSE: begin
        if (i_start) state_w = S_REC;
        else         state_w = S_IDLE;
    end
    endcase
end

always_comb begin
	// design your control here
    case(state_r)
    S_IDLE: begin
        addr_w        = 0;
        bit_counter_w = 0;
        data_w        = 0;
    end
    S_REC, S_PAUSE: begin
        addr_w        = addr_r;
        bit_counter_w = 0;
        data_w        = data_r;
    end
    S_GET: begin
        if (bit_counter_r == 16) begin
            addr_w        = addr_r + 1;
            bit_counter_w = 0;
            data_w        = 0;
        end
        else begin
            addr_w        = addr_r;
            bit_counter_w = bit_counter_r + 1;
            data_w        = {data_r[14:0], i_data};
        end
    end
    endcase
end

always_ff @(posedge i_clk or posedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r       <= S_IDLE;
        lr_prev       <= i_lrc;
        addr_r        <= 0;
        data_r        <= 0;
        bit_counter_r <= 0;
	end
	else begin
        state_r       <= state_w;
        lr_prev       <= i_lrc;
        addr_r        <= addr_w;
        data_r        <= data_w;
        bit_counter_r <= bit_counter_w;
	end
end



endmodule