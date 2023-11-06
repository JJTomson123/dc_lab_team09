module Top (
    input i_rst_n,
    input i_clk,
    input i_play_sel, // play when high, rec when low
    input i_speed_sel, // accel when high, decel when low
    input i_inter_sel, // interpol when high
    input i_key_0,
    input i_key_1,
    input i_key_2,
    // input [3:0] i_speed, // design how user can decide mode on your own
    
    // AudDSP and SRAM
    /* output [19:0] o_SRAM_ADDR,
    inout  [15:0] io_SRAM_DQ,
    output        o_SRAM_WE_N,
    output        o_SRAM_CE_N,
    output        o_SRAM_OE_N,
    output        o_SRAM_LB_N,
    output        o_SRAM_UB_N, */

    // SDRAM
    input  [25:0] i_SDRAM_DATA,
    input         i_SDRAM_VALID,
    output        o_SDRAM_WRITE,
    output        o_SDRAM_READ,
    output [25:0] o_SDRAM_ADDR,
    output [15:0] o_SDRAM_DQ,
    
    // I2C
    input  i_clk_100k,
    output o_I2C_SCLK,
    inout  io_I2C_SDAT,
    
    // AudPlayer
    input  i_AUD_ADCDAT,
    inout  i_AUD_ADCLRCK,
    inout  i_AUD_BCLK,
    inout  i_AUD_DACLRCK,
    output o_AUD_DACDAT,

    // SEVENDECODER (optional display)
    output reg [3:0] o_state
    // output [5:0] o_record_time,
    // output [5:0] o_play_time,

    // LCD (optional display)
    // input        i_clk_800k,
    // inout  [7:0] o_LCD_DATA,
    // output       o_LCD_EN,
    // output       o_LCD_RS,
    // output       o_LCD_RW,
    // output       o_LCD_ON,
    // output       o_LCD_BLON,

    // LED
    // output  [8:0] o_ledg,
    // output [17:0] o_ledr
);

// design the FSM and states as you like
parameter S_IDLE       = 0;
parameter S_I2C        = 1;
parameter S_RECD       = 2;
parameter S_RECD_PAUSE = 3;
parameter S_PLAY       = 4;
parameter S_PLAY_PAUSE = 5;

logic i2c_oen;
wire i2c_sdat;
logic [25:0] addr_record, addr_play, addr_SDC;
logic [15:0] dac_data;
/* logic [15:0] data_record, data_play; */
logic done_play, done_record;

logic dsp_fast, dsp_slow0, dsp_slow1;
logic i2c_fin, i2c_st_r, i2c_st_w;
logic fast_r, fast_w;
logic [2:0]  speed_r, speed_w;
logic play_st, rec_st, play_en;
logic [25:0] addr_end_w, addr_end_r;
logic [2:0] state_r, state_w;

assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SDRAM_ADDR = (state_r == S_RECD) ? addr_record : addr_play;
/* assign io_SRAM_DQ  = (state_r == S_RECD) ? data_record : 16'dz; // sram_dq as output
assign data_play   = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input */

assign dsp_fast  = fast_r;
assign dsp_slow0 = !fast_r && !i_inter_sel;
assign dsp_slow1 = !fast_r && i_inter_sel;

assign play_st = i_play_sel && i_key_0;
assign rec_st  = !i_play_sel && i_key_0;
assign play_en = (state_r == S_PLAY);

/* assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0; */

assign o_state = {1'b0, state_r[2:0]};

// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
    .i_rst_n(i_rst_n),
    .i_clk(i_clk_100k),
    .i_start(i2c_st_r),
    .o_finished(i2c_fin),
    .o_sclk(o_I2C_SCLK),
    .o_sdat(i2c_sdat),
    .o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 
AudDSP dsp0(
    .i_rst_n(i_rst_n),
    .i_clk(i_AUD_BCLK),
    .i_start(play_st),
    .i_pause(play_st),
    .i_stop(i_key_1),
    .i_speed(speed_r),
    .i_fast(dsp_fast),
    .i_slow_0(dsp_slow0), // constant interpolation
    .i_slow_1(dsp_slow1), // linear interpolation
    .i_addr_end(addr_end_r),
    .i_daclrck(i_AUD_DACLRCK),
    .i_sram_data(i_SDRAM_DATA),
    .i_data_valid(i_SDRAM_VALID),
    .o_dram_read(o_SDRAM_READ),
    .o_dac_data(dac_data),
    .o_sram_addr(addr_play),
    .o_done(done_play)
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
AudPlayer player0(
    .i_rst_n(i_rst_n),
    .i_bclk(i_AUD_BCLK),
    .i_daclrck(i_AUD_DACLRCK),
    .i_en(play_en), // enable AudPlayer only when playing audio, work with AudDSP
    .i_dac_data(dac_data), //dac_data
    .o_aud_dacdat(o_AUD_DACDAT)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
AudRecorder recorder0(
    .i_rst_n(i_rst_n), 
    .i_clk(i_AUD_BCLK),
    .i_lrc(i_AUD_ADCLRCK),
    .i_start(rec_st),
    .i_pause(rec_st),
    .i_stop(i_key_1),
    .i_data(i_AUD_ADCDAT),
    .o_dram_write(o_SDRAM_WRITE),
    .o_address(addr_record),
    .o_data(o_SDRAM_DQ),
    .o_done(done_record)
);

always_comb begin
    // speed control
    if (i_key_2) begin
        if (i_speed_sel == fast_r) begin
            fast_w = fast_r;
            if (speed_r == 3'd7) speed_w = 3'd7;
            else                 speed_w = speed_r + 1;
        end else begin
            if (speed_r == 3'd0) begin
                fast_w  = !fast_r;
                speed_w = 3'd1;
            end
            else begin
                fast_w = fast_r;
                speed_w = speed_r - 1;
            end
        end
    end else begin
        fast_w = fast_r;
        speed_w = speed_r;
    end
end

always_comb begin
    // design your control here
    i2c_st_w = 0;
    addr_end_w = addr_end_r;
    case(state_r)
    S_IDLE: begin
        if (i_key_0) begin
            if (i_play_sel) state_w = S_PLAY;
            else            state_w = S_RECD;
        end else            state_w = S_IDLE;
    end
    S_I2C: begin
        if (i2c_st_r) begin
            if (i2c_oen) i2c_st_w = 0;
            else         i2c_st_w = 1;
        end else         i2c_st_w = 0;

        if (i2c_fin) state_w = S_IDLE;
        else state_w = S_I2C;
    end
    S_RECD: begin
        if (i_key_1 || done_record) begin
            state_w    = S_IDLE;
            addr_end_w = addr_record;
        end
        else if (i_key_0) state_w = S_RECD_PAUSE;
        else              state_w = S_RECD;
    end
    S_RECD_PAUSE: begin
        if (i_key_1) begin
            state_w    = S_IDLE;
            addr_end_w = addr_record;
        end
        else if (i_key_0) state_w = S_RECD;
        else              state_w = S_RECD_PAUSE;
    end
    S_PLAY: begin
        if (i_key_1 || done_play) state_w = S_IDLE;
        else if (i_key_0)         state_w = S_PLAY_PAUSE;
        else                      state_w = S_PLAY;
    end
    S_PLAY_PAUSE: begin
        if (i_key_1)      state_w = S_IDLE;
        else if (i_key_0) state_w = S_PLAY;
        else              state_w = S_PLAY_PAUSE;
    end
    default: state_w = S_IDLE;
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_I2C;
        i2c_st_r <= 1;
        fast_r <= 0;
        speed_r <= 0;
        addr_end_r <= 0;
    end
    else begin
        state_r <= state_w;
        i2c_st_r <= i2c_st_w;
        fast_r <= fast_w;
        speed_r <= speed_w;
        addr_end_r <= addr_end_w;
    end
end

endmodule