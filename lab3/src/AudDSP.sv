module AudDSP(
    input i_rst_n,
    
    inout i_clk,
    
    input i_start,
    input i_pause,
    input i_stop,
    input [2:0] i_speed,
    input i_fast,
    input i_slow_0, // constant interpolation
    input i_slow_1, // linear interpolation
    input [19:0] i_addr_end,
    
    inout i_daclrck,
    
    input signed [15:0] i_sram_data,
    
    output [15:0] o_dac_data,
    output [19:0] o_sram_addr,
    output o_done
);


localparam S_IDLE  = 0;
localparam S_PLAY  = 1;
localparam S_CALC  = 2;
localparam S_PAUSE = 3;

logic [1:0] state_r, state_w;
logic daclrck_p;
logic [20:0] addr_r, addr_w;
logic signed [15:0] data_r, data_w, data_nxt_r, data_nxt_w, del_data_r, del_data_w;
logic [2:0] counter_r, counter_w;
logic done_r, done_w;

assign o_sram_addr = addr_r[19:0];
assign o_dac_data  = data_r;
assign o_done      = done_r;

always_comb begin
    // FSM
    done_w = 0;
    case(state_r)
    S_IDLE: begin
        if (i_start) state_w = S_PLAY;
        else         state_w = S_IDLE;
    end
    S_PLAY: begin
        if (i_stop) begin
            state_w = S_IDLE;
            done_w = 1;
        end
        else if (i_pause)                 state_w = S_PAUSE;
        else if (!daclrck_p && i_daclrck) state_w = S_CALC;
        else                              state_w = S_PLAY;
    end
    S_CALC: begin
        if (i_stop || addr_r >= i_addr_end) begin
            state_w = S_IDLE;
            done_w = 1;
        end
        else if (i_pause)                   state_w = S_PAUSE;
        else                                state_w = S_PLAY;
    end
    S_PAUSE: begin
        if (i_stop) begin
            state_w = S_IDLE;
            done_w = 1;
        end
        else if (i_start) state_w = S_PLAY;
        else             state_w = S_PAUSE;
    end
    endcase
end


always_comb begin
    // design your control here
    case(state_r)
    S_IDLE: begin
        addr_w     = 0;
        counter_w  = 0;
        data_w     = data_r;
        del_data_w = 0;
        if (i_start) data_nxt_w = i_sram_data;
        else         data_nxt_w = 0;
    end
    S_PLAY: begin
        counter_w = counter_r;
        data_nxt_w = data_nxt_r;
        del_data_w = del_data_r;
        if (!daclrck_p && i_daclrck) begin // Next data when L->R
            if (counter_r == 0) data_w = data_nxt_r;
            else if (i_slow_1)  data_w = data_r + del_data_r;
            else                data_w = data_r;

            if (i_fast)             addr_w = addr_r + i_speed + 1; // Fast playback
            else begin // Slow playback
                if (counter_r == 0) addr_w = addr_r + 1;
                else                addr_w = addr_r;
            end
        end
        else begin
            addr_w = addr_r;
            data_w = data_r;
        end
    end
    S_CALC: begin
        data_w = data_r;
        addr_w = addr_r;
        data_nxt_w = i_sram_data;

        if (counter_r == 0) begin
            del_data_w = (i_sram_data - data_r) / $signed({1'b0, i_speed + 1}); // used for 1st-order interpol
        end else begin
            del_data_w = del_data_r;
        end

        if (i_fast || counter_r >= i_speed) counter_w = 0;
        else                                counter_w = counter_r + 1;
    end
    S_PAUSE: begin
        addr_w     = addr_r;
        counter_w  = counter_r;
        data_w     = data_r;
        data_nxt_w = data_nxt_r;
        del_data_w = del_data_r;
    end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r    <= S_IDLE;
        daclrck_p  <= 0;
        addr_r     <= 0;
        counter_r  <= 0;
        data_r     <= 0;
        data_nxt_r <= 0;
        del_data_r <= 0;
        done_r     <= 0;
    end
    else begin
        state_r    <= state_w;
        daclrck_p  <= i_daclrck;
        addr_r     <= addr_w;
        counter_r  <= counter_w;
        data_r     <= data_w;
        data_nxt_r <= data_nxt_w;
        del_data_r <= del_data_w;
        done_r     <= done_w;
    end
end


endmodule

