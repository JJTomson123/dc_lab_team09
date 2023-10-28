module rec_tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	localparam lrcclk = CLK*16;
	localparam lrchclk = (CLK*16)/2;


    logic temp_clk, templrcclk;
    wire i_AUD_BCLK, i_AUD_ADCLRCK;
	logic start, pause, i_rst_n, stop;
	initial temp_clk = 0;
	initial begin
        templrcclk = 1;
		#(3*CLK)
		templrcclk = 0;
	end
	always #HCLK temp_clk = ~temp_clk;
	always #lrchclk templrcclk = ~templrcclk;
	logic [19:0] addr_record;
    logic [15:0] data_record;
	logic i_AUD_ADCDAT;
    logic [47:0] data;

    initial data = 48'b000_0000_0_1001_0111_000_0001_0_1001_0111_000_0010_0_0111_1001;


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
		#(2*CLK)
		i_rst_n = 1;
		@(posedge i_AUD_BCLK);
		start <= 1;
		@(posedge i_AUD_BCLK);
		start <= 0;
		$display("=========");
		for (int i = 0; i < 16; i++) begin
			i_AUD_ADCDAT = data[47];
			data = data << 1;
			$write("%1b", i_AUD_ADCDAT);
			@(posedge i_AUD_BCLK);
		end
		$write("\n");
		$display("=========");
		$finish;
	end

	initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

	

endmodule