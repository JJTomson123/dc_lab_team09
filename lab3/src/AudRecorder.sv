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


parameter S_IDLE       = 0;
parameter S_START      = 1;
parameter S_PAUSE      = 2;
parameter S_STOP       = 3;

logic [1:0] state_r, state_w;
logic [15:0] data_r, data_w;
logic [19:0] addr_r, addr_w;
logic [5:0] bit_counter_r, bit_counter_w;

assign o_data = data_r;
assign o_address = addr_r;


always_comb begin
	// design your control here
    case(state_r)
    S_IDLE: begin
        if (i_start) begin
            state_w = S_START;
        end else begin
            state_w = S_IDLE;
        end
    end
    S_START: begin
        if (~i_lrc) begin
            if (bit_counter_r==16) begin
                state_w = S_STOP;
            end
            else begin
                data_w = {data_r[14:0],i_data};
                state_w = S_START;
            end

        end 
        else begin
        end
    end
    S_PAUSE:
    S_STOP:
    endcase
end

always_ff @(posedge i_clk or posedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r <= S_IDLE;
        addr_r <= 20'h00000;
        data_r <= 16'b0;
		
	end
	else begin
        state_r <= state_w;
        addr_r <= addr_w;
        data_r <= data_w;
		
	end
end



endmodule