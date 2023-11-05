`timescale 1ns/100ps

module top_tb;
	localparam CLK50M = 20;
	localparam HCLK50M = CLK50M/2;
    localparam CLK12M = 80;
    localparam HCLK12M = CLK12M/2;
    localparam CLK100K = 10000;
    localparam HCLK100K = CLK100K/2;
	localparam lrcclk = CLK12M*40;
	localparam lrchclk = CLK12M*20;


    logic clk_50, clk_100k, clk_12k, I2C_SCLK;
    wire AUD_ADCLRCK, AUD_BCLK, AUD_DACLRCK;
	logic i_rst_n, play_sel, inter_sel, speed_sel, key0down, key0down_fast, key1down, key2down;
	

	initial templrcclk = 1;
	always #lrchclk templrcclk = ~templrcclk;

    initial clk_50 = 0;
	initial clk_12k = 0;
    initial clk_100k = 0;
	always #HCLK50M clk_50 = ~clk_50;
	always #HCLK12M clk_12k = ~clk_12k;
    always #HCLK100K clk_100k = ~clk_100k;



	logic [19:0] SRAM_ADDR;
    wire [15:0] SRAM_DQ;
	logic SRAM_WE_N, SRAM_CE_N, SRAM_OE_N, SRAM_LB_N, SRAM_UB_N;
    wire I2C_SDAT,
    logic AUD_ADCDAT, AUD_DACDAT;
    logic seven;

    Top top0(
	.i_rst_n(i_rst_n),
	.i_clk(clk_50),
	.i_play_sel(play_sel), // play when high, rec when low
	.i_speed_sel(speed_sel), // accel when high, decel when low
	.i_inter_sel(inter_sel), // interpol when high
	.i_key_0(key0down), // rec start and pause
	.i_key_0_fast(key0down_fast), // play start and pause
	.i_key_1(key1down), // play/rec stop
	.i_key_2(key2down), // speed change
	// .i_speed(SW[3:0]), // design how user can decide mode on your own
	
	// AudDSP and SRAM
	.o_SRAM_ADDR(SRAM_ADDR), // [19:0]
	.io_SRAM_DQ(SRAM_DQ), // [15:0]
	.o_SRAM_WE_N(SRAM_WE_N),
	.o_SRAM_CE_N(SRAM_CE_N),
	.o_SRAM_OE_N(SRAM_OE_N),
	.o_SRAM_LB_N(SRAM_LB_N),
	.o_SRAM_UB_N(SRAM_UB_N),
	
	// I2C
	.i_clk_100k(clk_100k),
	.o_I2C_SCLK(I2C_SCLK),
	.io_I2C_SDAT(I2C_SDAT),
	
	// AudPlayer
	.i_AUD_ADCDAT(AUD_ADCDAT),
	.i_AUD_ADCLRCK(AUD_ADCLRCK),
	.i_AUD_BCLK(AUD_BCLK),
	.i_AUD_DACLRCK(AUD_DACLRCK),
	.o_AUD_DACDAT(AUD_DACDAT),

	// SEVENDECODER (optional display)
	.o_state(seven)
	// .o_record_time(recd_time),
	// .o_play_time(play_time),

	// LCD (optional display)
	// .i_clk_800k(CLK_800K),
	// .o_LCD_DATA(LCD_DATA), // [7:0]
	// .o_LCD_EN(LCD_EN),
	// .o_LCD_RS(LCD_RS),
	// .o_LCD_RW(LCD_RW),
	// .o_LCD_ON(LCD_ON),
	// .o_LCD_BLON(LCD_BLON),

	// LED
	// .o_ledg(LEDG), // [8:0]
	// .o_ledr(LEDR) // [17:0]
);

    assign AUD_BCLK = clk_12k;
	assign AUD_ADCLRCK = templrcclk;
    assign AUD_DACLRCK = templrcclk;

	initial begin
		$fsdbDumpfile("lab3_rec.fsdb");
		$fsdbDumpvars;
		i_rst_n = 0;
		start   = 0;
		pause   = 0;
		stop    = 0;
		i_AUD_ADCDAT = 1;
		#(2*CLK)
		i_rst_n = 1;
		#(CLK)
		start = 1;
		#(CLK)
		start = 0;
		@(posedge i_AUD_ADCLRCK);
		for (int i = 0; i < 1; i++) begin
			for (int i = 0; i < 16; i++) begin
                @(negedge i_AUD_BCLK);
				i_AUD_ADCDAT = data[47];
				data = data << 1;
			end
			@(posedge i_AUD_BCLK);
			stop <= 1;
			@(posedge i_AUD_BCLK);
			stop <= 0;
			@(posedge i_AUD_ADCLRCK);
		end
		$display("=========");
		$display("data : %16b",data_record);
		$display("=========");
		$display("addr : %5h",addr_record);
		$display("=========");
		$finish;
	end

	initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

	

endmodule