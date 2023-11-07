module DE2_115 (
	input CLOCK_50,
	input CLOCK2_50,
	input CLOCK3_50,
	input ENETCLK_25,
	input SMA_CLKIN,
	output SMA_CLKOUT,
	output [8:0] LEDG,
	output [17:0] LEDR,
	input [3:0] KEY,
	input [17:0] SW,
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7,
	output LCD_BLON,
	inout [7:0] LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RS,
	output LCD_RW,
	output UART_CTS,
	input UART_RTS,
	input UART_RXD,
	output UART_TXD,
	inout PS2_CLK,
	inout PS2_DAT,
	inout PS2_CLK2,
	inout PS2_DAT2,
	output SD_CLK,
	inout SD_CMD,
	inout [3:0] SD_DAT,
	input SD_WP_N,
	output [7:0] VGA_B,
	output VGA_BLANK_N,
	output VGA_CLK,
	output [7:0] VGA_G,
	output VGA_HS,
	output [7:0] VGA_R,
	output VGA_SYNC_N,
	output VGA_VS,
	input AUD_ADCDAT,
	inout AUD_ADCLRCK,
	inout AUD_BCLK,
	output AUD_DACDAT,
	inout AUD_DACLRCK,
	output AUD_XCK,
	output EEP_I2C_SCLK,
	inout EEP_I2C_SDAT,
	output I2C_SCLK,
	inout I2C_SDAT,
	output ENET0_GTX_CLK,
	input ENET0_INT_N,
	output ENET0_MDC,
	input ENET0_MDIO,
	output ENET0_RST_N,
	input ENET0_RX_CLK,
	input ENET0_RX_COL,
	input ENET0_RX_CRS,
	input [3:0] ENET0_RX_DATA,
	input ENET0_RX_DV,
	input ENET0_RX_ER,
	input ENET0_TX_CLK,
	output [3:0] ENET0_TX_DATA,
	output ENET0_TX_EN,
	output ENET0_TX_ER,
	input ENET0_LINK100,
	output ENET1_GTX_CLK,
	input ENET1_INT_N,
	output ENET1_MDC,
	input ENET1_MDIO,
	output ENET1_RST_N,
	input ENET1_RX_CLK,
	input ENET1_RX_COL,
	input ENET1_RX_CRS,
	input [3:0] ENET1_RX_DATA,
	input ENET1_RX_DV,
	input ENET1_RX_ER,
	input ENET1_TX_CLK,
	output [3:0] ENET1_TX_DATA,
	output ENET1_TX_EN,
	output ENET1_TX_ER,
	input ENET1_LINK100,
	input TD_CLK27,
	input [7:0] TD_DATA,
	input TD_HS,
	output TD_RESET_N,
	input TD_VS,
	inout [15:0] OTG_DATA,
	output [1:0] OTG_ADDR,
	output OTG_CS_N,
	output OTG_WR_N,
	output OTG_RD_N,
	input OTG_INT,
	output OTG_RST_N,
	input IRDA_RXD,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout [31:0] DRAM_DQ,
	output [3:0] DRAM_DQM,
	output DRAM_RAS_N,
	output DRAM_WE_N,
	output [19:0] SRAM_ADDR,
	output SRAM_CE_N,
	inout [15:0] SRAM_DQ,
	output SRAM_LB_N,
	output SRAM_OE_N,
	output SRAM_UB_N,
	output SRAM_WE_N,
	output [22:0] FL_ADDR,
	output FL_CE_N,
	inout [7:0] FL_DQ,
	output FL_OE_N,
	output FL_RST_N,
	input FL_RY,
	output FL_WE_N,
	output FL_WP_N,
	inout [35:0] GPIO,
	input HSMC_CLKIN_P1,
	input HSMC_CLKIN_P2,
	input HSMC_CLKIN0,
	output HSMC_CLKOUT_P1,
	output HSMC_CLKOUT_P2,
	output HSMC_CLKOUT0,
	inout [3:0] HSMC_D,
	input [16:0] HSMC_RX_D_P,
	output [16:0] HSMC_TX_D_P,
	inout [6:0] EX_IO
);

logic key0down, key1down, key2down;
logic [15:0] seven;
logic [1:0]  state;
logic SDRMCTRL_WRITE, SDRMCTRL_READ, SDRMCTRL_VALID;
logic [15:0] SDRMCTRL_READDATA, SDRMCTRL_WRITEDATA;
logic [25:0] SDRMCTRL_ADDR;

SDRAM_qsys qsys0( // generate with qsys, please follow lab2 tutorials
	.clk_clk(CLOCK_50),
	.reset_reset_n(KEY[3]),
	.sdramclk_clk(DRAM_CLK),
	.sdrmctrl_addr(DRAM_ADDR),   //    sdrmctrl.addr
	.sdrmctrl_ba(DRAM_BA),       //            .ba
	.sdrmctrl_cas_n(DRAM_CAS_N), //            .cas_n
	.sdrmctrl_cke(DRAM_CKE),     //            .cke
	.sdrmctrl_cs_n(DRAM_CS_N),   //            .cs_n
	.sdrmctrl_dq(DRAM_DQ),       //            .dq
	.sdrmctrl_dqm(DRAM_DQM),     //            .dqm
	.sdrmctrl_ras_n(DRAM_RAS_N), //            .ras_n
	.sdrmctrl_we_n(DRAM_WE_N),   //            .we_n
	.sdrmwrapper_i_write(SDRMCTRL_WRITE),    // sdrmwrapper.i_write
	.sdrmwrapper_i_read(SDRMCTRL_READ),      //            .i_read
	.sdrmwrapper_o_data(SDRMCTRL_READDATA),  //            .o_data
	.sdrmwrapper_i_addr(SDRMCTRL_ADDR),      //            .i_addr
	.sdrmwrapper_i_data(SDRMCTRL_WRITEDATA), //            .i_data
	.sdrmwrapper_o_valid(SDRMCTRL_VALID),
);

// you can decide key down settings on your own, below is just an example
Debounce deb0(
	.i_in(KEY[0]), // rec start/pause
	.i_rst_n(KEY[3]),
	.i_clk(CLOCK_50),
	.o_neg(key0down) 
);

Debounce deb1(
	.i_in(KEY[1]), // play/rec stop
	.i_rst_n(KEY[3]),
	.i_clk(CLOCK_50),
	.o_neg(key1down) 
);

Debounce deb2(
	.i_in(KEY[2]), // speed change
	.i_rst_n(KEY[3]),
	.i_clk(CLOCK_50),
	.o_neg(key2down) 
);

Top top0(
	.i_rst_n(KEY[3]),
	.i_clk(CLOCK_50),
	.i_key_0(key0down), // store
	.i_key_1(key1down), // load
	.i_key_2(key2down), // next addr
	.i_data(SW[15:0]),
	.i_inc_sel(SW[16]),

	// SDRAM
	.i_SDRAM_DATA(SDRMCTRL_READDATA),
    .i_SDRAM_VALID(SDRMCTRL_VALID),
    .o_SDRAM_WRITE(SDRMCTRL_WRITE),
    .o_SDRAM_READ(SDRMCTRL_READ),
    .o_SDRAM_ADDR(SDRMCTRL_ADDR),
    .o_SDRAM_DQ(SDRMCTRL_WRITEDATA),

	// SEVENDECODER
	.o_data(seven),
	.o_state(state)
);

SevenHexDecoder seven_dec0(
	.i_hex(SDRMCTRL_READDATA[3:0]),
	.o_seven_hexit(HEX0)
);

SevenHexDecoder seven_dec1(
	.i_hex(SDRMCTRL_READDATA[7:4]),
	.o_seven_hexit(HEX1)
);

SevenHexDecoder seven_dec2(
	.i_hex(SDRMCTRL_READDATA[11:8]),
	.o_seven_hexit(HEX2)
);

SevenHexDecoder seven_dec3(
	.i_hex(SDRMCTRL_READDATA[15:12]),
	.o_seven_hexit(HEX3)
);

SevenDecDecoder seven_dec4(
	.i_hex(state),
	.o_seven_one(HEX4)
);

// comment those are use for display
/* assign HEX0 = '1;
assign HEX1 = '1;
assign HEX2 = '1;
assign HEX3 = '1;
assign HEX4 = '1; */
assign HEX5 = '1;
assign HEX6 = '1;
assign HEX7 = '1;

endmodule