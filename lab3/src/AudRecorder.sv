module AudRecorder #(
    parameter ADDR_W = 26
)
(
	input i_rst_n, 
	
    inout i_clk,
	inout i_lrc,
	
    input i_start,
	input i_pause,
	input i_stop,
	input i_data,
	
    output o_dram_write,
    output [ADDR_W-1:0] o_address,
	output [15:0] o_data,
    output        o_done
);


localparam S_IDLE  = 0;
localparam S_RECD  = 1;
localparam S_GET   = 2;
localparam S_PAUSE = 3;

logic [1:0] state_r, state_w;
logic [15:0] data_r, data_w;
logic [ADDR_W:0] addr_r, addr_w;
logic [5:0] bit_counter_r, bit_counter_w;
logic lr_prev;
logic pausing_r, pausing_w, stopping_r, stopping_w;
logic done_r, done_w, write_r, write_w;

assign o_data = data_r;
assign o_address = addr_r[ADDR_W-1:0];
assign o_done = done_r;
assign o_dram_write = write_r;

always_comb begin
    // FSM
    done_w = 0;
    case(state_r)
    S_IDLE: begin
        if (i_start) state_w = S_RECD;
        else         state_w = S_IDLE;
    end
    S_RECD: begin
        if (i_stop) begin 
            state_w = S_IDLE;
            done_w = 1;
        end
        else if (i_pause)           state_w = S_PAUSE;
        else if (!lr_prev && i_lrc) state_w = S_GET;
        else                        state_w = S_RECD;
    end
    S_GET: begin
        if (bit_counter_r == 16) begin
            if (i_stop || stopping_r || addr_r == {ADDR_W{1'b1}}) begin
                state_w = S_IDLE;
                done_w = 1;
            end
            else if (i_pause || pausing_r)                   state_w = S_PAUSE;
            else                                             state_w = S_RECD;
        end else                                             state_w = S_GET;
    end
    S_PAUSE: begin
        if (i_stop) begin
            state_w = S_IDLE;
            done_w = 1;
        end
        else if (i_start) state_w = S_RECD;
        else             state_w = S_PAUSE;
    end
    endcase
end

always_comb begin
	// design your control here
    pausing_w = 0;
    stopping_w = 0;
    write_w    = 0;
    case(state_r)
    S_IDLE: begin
        bit_counter_w = 0;
        data_w        = data_r;
        if (i_start) addr_w = 0;
        else         addr_w = addr_r;
    end
    S_RECD, S_PAUSE: begin
        addr_w        = addr_r;
        bit_counter_w = 0;
        data_w        = data_r;
    end
    S_GET: begin
        if (bit_counter_r == 16) begin
            if (i_stop || stopping_r || addr_r == {ADDR_W{1'b1}}) addr_w = addr_r;
            else                                                  addr_w = addr_r + 1;
            bit_counter_w = 0;
            data_w        = data_r;
        end
        else begin
            addr_w        = addr_r;
            bit_counter_w = bit_counter_r + 1;
            data_w        = {data_r[14:0], i_data};
            pausing_w     = i_pause || pausing_r;
            stopping_w    = i_stop || stopping_r;
        end

        if (bit_counter_r == 15) write_w = 1;
    end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r       <= S_IDLE;
        lr_prev       <= 0;
        addr_r        <= 0;
        data_r        <= 0;
        bit_counter_r <= 0;
        pausing_r     <= 0;
        stopping_r    <= 0;
        done_r        <= 0;
        write_r       <= 0;
	end
	else begin
        state_r       <= state_w;
        lr_prev       <= i_lrc;
        addr_r        <= addr_w;
        data_r        <= data_w;
        bit_counter_r <= bit_counter_w;
        pausing_r     <= pausing_w;
        stopping_r    <= stopping_w;
        done_r        <= done_w;
        write_r       <= write_w;
	end
end



endmodule