`timescale 1ns/100ps

module i2c_tb;


localparam CLK = 20;
localparam HCLK = CLK/2;
/* localparam LRC = 31250; */
localparam LRC = 3125;
localparam HLRC = LRC/2;
localparam [15:0] test_data[0:6] = {
    16'hAC97,
    16'hB6E2,
    16'h8514,
    16'hF03D,
    16'h31B0,
    16'h76dF,
    16'h29B5
};

logic clk_50M;
initial clk_50M = 0;
always #HCLK clk_50M = ~clk_50M;
wire i_clk;
assign i_clk = clk_50M;

logic clk_32K;
initial clk_32K = 0;
always #HLRC clk_32K = ~clk_32K;
wire i_daclrck;
assign i_daclrck = clk_32K;

logic i_rst_n, start, pause, stop, fast, interpol;
logic [2:0] speed;
logic [15:0] dac_data;
logic [19:0] addr_play;
logic slow_0, slow_1;
assign slow_0 = !fast && !interpol;
assign slow_1 = !fast && interpol;

logic [15:0] data_play;
always @(addr_play) begin
    #HCLK
    data_play = test_data[addr_play % 7];
end

AudDSP dsp0(
.i_rst_n(i_rst_n),
.i_clk(i_clk),
.i_start(start),
.i_pause(pause),
.i_stop(stop),
.i_speed(speed),
.i_fast(fast),
.i_slow_0(slow_0), // constant interpolation
.i_slow_1(slow_1), // linear interpolation
.i_daclrck(i_daclrck),
.i_sram_data(data_play),
.o_dac_data(dac_data),
.o_sram_addr(addr_play)
);

initial begin
    $fsdbDumpfile("lab3_dsp.fsdb");
    $fsdbDumpvars;
    i_rst_n = 0;
    {start, pause, stop, fast, interpol} = 5'b00001;
    speed = 3'd2;
    #(2*CLK)
    i_rst_n = 1;
    @(posedge clk_50M);
    start = 1;
    @(posedge clk_50M);
    start = 0;
    #(80*LRC)
    $finish;
end

	

endmodule