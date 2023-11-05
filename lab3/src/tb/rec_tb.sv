`timescale 1ns/100ps

module rec_tb;


localparam CLK = 84;
localparam HCLK = CLK/2;
/* localparam LRC = 31250; */
localparam LRC = 31500;
localparam HLRC = LRC/2;

logic clk_12m;
initial clk_12m = 1;
always #HCLK clk_12m = ~clk_12m;
wire i_clk;
assign i_clk = clk_12m;

logic clk_32k;
initial clk_32k = 0;
always #HLRC clk_32k = ~clk_32k;
wire i_daclrck;
assign i_daclrck = clk_32k;

logic [19:0] addr_record;
logic [15:0] data_record;
logic i_rst_n, start, pause, stop, i_AUD_ADCDAT;
logic [15:0] data;

localparam [15:0] test_data[0:6] = {
	16'hAC97,
	16'hB6E2,
	16'h8514,
	16'hF03D,
	16'h31B0,
	16'h76dF,
	16'h29B5
};

AudRecorder recorder0(
.i_rst_n(i_rst_n), 
.i_clk(i_clk),
.i_lrc(i_daclrck),
.i_start(start),
.i_pause(pause),
.i_stop(stop),
.i_data(i_AUD_ADCDAT),
.o_address(addr_record),
.o_data(data_record)
);

initial begin
	$fsdbDumpfile("lab3_rec.fsdb");
	$fsdbDumpvars;
	{i_rst_n, start, pause, i_AUD_ADCDAT} = 5'b00001;
    data = 0;
	#(2*CLK)
	i_rst_n = 1;
	#(CLK)
	start = 1;
	#(CLK)
	start = 0;
	for (int i = 0; i < 20; i++) begin
	    @(posedge clk_32k);
		data = test_data[i % 7];
		for (int j = 0; j < 16; j++) begin
			@(negedge clk_12m);
			i_AUD_ADCDAT = data[15];
			data = data << 1;
		end
	end

    #(10*CLK)
	$finish;
end

initial begin
    stop = 0;
    #(10*LRC)
    @(posedge clk_32k);
    #(5*CLK)
    stop <= 1;
    @(posedge clk_12m);
    stop <= 0;
end
    

initial begin
	#(500000*CLK)
	$display("Too slow, abort.");
	$finish;
end

	
endmodule