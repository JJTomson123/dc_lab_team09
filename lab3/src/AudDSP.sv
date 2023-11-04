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


localparam S_IDLE  = 0;
localparam S_PLAY  = 1;
localparam S_CALC  = 2;
localparam S_PAUSE = 3;

logic [1:0] state_r, state_w;
logic daclrck_p;
logic [20:0] addr_r, addr_w;
logic signed [15:0] data_r, data_w, data_nxt_r, data_nxt_w, del_data_r, del_data_w;
logic [2:0] counter_r, counter_w;


assign o_sram_addr = addr_r[19:0];
assign o_dac_data = data_r;

always_comb begin
    // FSM
    case(state_r)
    S_IDLE: begin
        if (i_start) state_w = S_PLAY;
        else         state_w = S_IDLE;
    end
    S_PLAY: begin
        if (i_stop)                       state_w = S_IDLE;
        else if (i_pause)                 state_w = S_PAUSE;
        else if (!daclrck_p && i_daclrck) state_w = S_CALC;
        else                              state_w = S_PLAY;
    end
    S_CALC: begin
        if (addr_r[20]) state_w = S_IDLE;
        else            state_w = S_PLAY;
    end
    S_PAUSE: begin
        if (i_start) state_w = S_PLAY;
        else         state_w = S_IDLE;
    end
    endcase
end


always_comb begin
    // design your control here
    case(state_r)
    S_IDLE: begin
        counter_w  = 0;
        data_w     = 0;
        del_data_w = 0;
        if (i_start) begin
            addr_w     = i_daclrck;
            data_nxt_w = i_sram_data;
        end
        else begin
            addr_w     = 0;
            data_nxt_w = 0;
        end
    end
    S_PLAY: begin
        counter_w = counter_r;
        data_w    = data_r;
        del_data_w = del_data_r;
        if (!daclrck_p && i_daclrck) begin // Next data when L->R
            if (i_fast)             addr_w = addr_r + i_speed + 1; // Fast playback
            else if (i_slow_0 || i_slow_1) begin // Slow playback
                if (counter_r == 0) addr_w = addr_r + 1;
                else                addr_w = addr_r;
            end
            else                    addr_w = addr_r + 1; // Normal playback
        end
        else addr_w = addr_r;
    end
    S_CALC: begin
        if (addr_r[20]) begin
            addr_w     = 0;
            counter_w  = 0;
            data_w     = 0;
            data_nxt_w = 0;
            del_data_w = 0;
        end else begin
            addr_w = addr_r;

            if (counter_r == 0) begin
                {data_nxt_w, data_w} = {i_sram_data, data_nxt_r};
                del_data_w = (i_sram_data - data_nxt_r) / (i_speed + 1); // used for 1st-order interpol
            end else begin
                data_nxt_w = data_nxt_r;
                del_data_w = del_data_r;
                if (i_slow_1) data_w = data_r + del_data_r;
                else          data_w = data_r;
            end

            if (i_fast || counter_r + 1 >= i_speed) counter_w = 0;
            else                                    counter_w = counter_r + 1;
        end
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

always_ff @(posedge i_clk or posedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r    <= S_IDLE;
        daclrck_p  <= 0;
        addr_r     <= 0;
        counter_r  <= 0;
        data_r     <= 0;
        data_nxt_r <= 0;
        del_data_r <= 0;
    end
    else begin
        state_r    <= state_w;
        daclrck_p  <= i_daclrck;
        addr_r     <= addr_w;
        counter_r  <= counter_w;
        data_r     <= data_w;
        data_nxt_r <= data_nxt_w;
        del_data_r <= del_data_w;
    end
end


endmodule

