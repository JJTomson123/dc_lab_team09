module Top (
    input i_rst_n,
    input i_clk,
    input i_valid,
    output o_valid,
    input [1:0] op,
    // input [3:0] i_speed, // design how user can decide mode on your own
    
    // AudDSP and SRAM
    output [19:0] o_SRAM_ADDR,
    inout  [15:0] io_SRAM_DQ,
    output        o_SRAM_WE_N,
    output        o_SRAM_CE_N,
    output        o_SRAM_OE_N,
    output        o_SRAM_LB_N,
    output        o_SRAM_UB_N,
    
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
parameter S_PREP       = 1;
parameter S_ARITH      = 2;
parameter S_CALC       = 3;

logic i2c_oen;
wire i2c_sdat;
logic [19:0] addr_record, addr_play;
logic [15:0] data_record, data_play, dac_data;
logic done_play, done_record;

logic dsp_fast, dsp_slow0, dsp_slow1;
logic i2c_fin, i2c_st_r, i2c_st_w;
logic fast_r, fast_w;
logic [2:0]  speed_r, speed_w;
logic play_st, rec_st, play_en;
logic [19:0] addr_end_w, addr_end_r;
logic [2:0] state_r, state_w;

assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_SRAM_ADDR = (state_r == S_RECD) ? addr_record : addr_play[19:0];
assign io_SRAM_DQ  = (state_r == S_RECD) ? data_record : 16'dz; // sram_dq as output
assign data_play   = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input

assign dsp_fast  = fast_r;
assign dsp_slow0 = !fast_r && !i_inter_sel;
assign dsp_slow1 = !fast_r && i_inter_sel;

assign play_st = i_play_sel && i_key_0;
assign rec_st  = !i_play_sel && i_key_0;
assign play_en = (state_r == S_PLAY);

assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

assign o_state = {1'b0,state_r[2:0]};


always_comb begin
    // design your control here
    case(state_r)
    S_IDLE: begin
        arith_start_w = 0;
        if (i_valid) begin
            state_w = S_PREP;
            prep_start = 1;
        end 
        else begin
            state_w = S_IDLE;
            prep_start = 0;
        end
    end
    S_PREP: begin
        prep_start = 0;
        if (prep_rdy && !prep_start) begin
            state_w       = S_ARITH;
            arith_start_w = 1;
        end
        else begin
            state_w = S_PREP;
            arith_start_w = 0;
        end
    end
    S_ARITH: begin
        prep_start = 0;
        arith_start_w = 0;
        if (prep_rdy && !prep_start) begin
            state_w       = S_CALC;
        end
        else begin
            state_w       = S_ARITH;
        end
    end
    default: state_w = S_IDLE;
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_IDLE;

    end
    else begin
        state_r <= state_w;

    end
end

endmodule

module PREP(
    input              i_clk,
    input              i_rst,
    input              i_start,
    input       [1:0]  op;
    input      [31:0]  i_b, // cipher text y
    output reg         o_carryin,
    output             o_rdy,
    output reg [31:0]  o_b_mod
);

localparam S_IDLE = 1'b0;
localparam S_CALC = 1'b1;
logic  state_r, state_w;
assign o_rdy = (state_r == S_IDLE);

always_comb begin
    case (state_r)
    S_IDLE: begin
        o_b_mod = 0;
        o_carryin = 0;
        if (i_start) begin
            state_w = S_CALC;
        end else begin
            state_w = S_IDLE;
        end
    end
    S_CALC: begin
        if (op == 1'b01) begin
            o_b_mod = ~(i_b);
            o_carryin = 1'b1;
        end else begin
            o_b_mod = i_b;
            o_carryin = 1'b0;
        end
        state_w = S_IDLE;
    end
    endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        state_r    <= S_IDLE;
        o_carryin  <= 0;
        o_b_mod    <= 0;

    end else begin
        state_r    <= state_w;
        o_carryin  <= o_carryin;
        o_b_mod    <= o_b_mod;

    end
end

endmodule

module ARITHMETIC(
    input              i_clk,
    input              i_rst,
    input              i_start,
    input       [1:0]  op;
    input      [31:0]  i_a,
    input      [31:0]  i_b, // cipher text y
    input              i_carryin,
    output     [31:0]  o_data, // t = y * 2^256
    output             o_rdy
);

localparam S_IDLE  = 2'b00;
localparam S_ADD   = 2'b01;
localparam S_MUL   = 2'b10;
localparam S_DIV   = 2'b11;


logic [1:0]   state_r, state_w;
logic [7:0]   count_r, count_w;
logic [255:0] n_r, n_w;
logic [255:0] m_w;

assign o_rdy = (state_r == S_IDLE);

always_comb begin
    case(state_r)
    S_IDLE: begin
        count_w = 0;
        if (i_start) begin
            if (op==2'b00) begin
                state_w = S_ADD;
            end
            else if (op==2'b01) begin
                state_w = S_SUB;
            end
            else if (op==2'b10) begin
                state_w = S_MUL;
            end
            else begin
                state_w = S_DIV;
            end
        end else begin
            state_w = S_IDLE;
        end
    end
    S_ADD: begin
        pg = 1;
        temp = 0;
        FA fa0(sum_w[0], c[1], i_a[0], i_b[0], i_carryin);
        FA fa[30:1](sum_w[30:1], c[31:2], i_a[30:1], i_b[30:1], c[30:1]);
        FA fa31(sum_w[31], cout, i_a[31], i_b[31], c[31]);
        for (int i=0; i<32; i++) begin
            temp = i_a[i]^i_b[i];
            pg = pg & temp;
        end
        cout_w = (pg)? i_carryin : cout;
 
        /* if (count_r == 7) begin
            state_w = S_UPDT;
            count_w = 0;
        end else begin
            state_w = S_CALC;
            count_w = count_r + 1;
        end */
        state_w = S_IDLE;
    end
    endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        state_r    <= S_IDLE;
        count_r    <= 0;

    end
    else begin
        state_r    <= state_w;
        count_r    <= count_w;

    end
end

endmodule

module FA(output sum, cout, input a, b, cin);
  wire w0, w1, w2;
  
  xor (w0, a, b);
  xor (sum, w0, cin);
  
  and (w1, w0, cin);
  and (w2, a, b);
  or (cout, w1, w2);

endmodule
