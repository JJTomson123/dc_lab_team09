module rec_tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	localparam lrcclk = CLK*40;
	localparam lrchclk = CLK*20;


    logic temp_clk, templrcclk;
    wire i_AUD_BCLK, i_AUD_ADCLRCK;
	logic start, pause, i_rst_n, stop;
	initial temp_clk = 0;
	initial templrcclk = 1;
	always #HCLK temp_clk = ~temp_clk;
	always #lrchclk templrcclk = ~templrcclk;
	logic [19:0] addr_record;
    logic [15:0] data_record;
	logic i_AUD_ADCDAT;
    logic [47:0] data;

    initial data = 48'b100_0000_0_1001_0111_000_0001_0_1001_0111_000_0010_0_0111_1001;


    AudRecorder recorder0(
	.i_rst_n(i_rst_n), 
	.i_clk(i_AUD_BCLK),
	.i_lrc(i_AUD_ADCLRCK),
	.i_start(start),
	.i_pause(pause),
	.i_stop(stop),
	.i_data(i_AUD_ADCDAT),
	.o_address(addr_record),
	.o_data(data_record)
);

    assign i_AUD_BCLK = temp_clk;
	assign i_AUD_ADCLRCK = templrcclk;

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