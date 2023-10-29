module play_tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;
	localparam lrcclk = CLK*40;
	localparam lrchclk = CLK*20;


    logic temp_clk, templrcclk;
    wire i_AUD_BCLK, i_AUD_DACLRCK;
	logic i_rst_n;
	initial temp_clk = 0;
	initial templrcclk = 1;
	always #HCLK temp_clk = ~temp_clk;
	always #lrchclk templrcclk = ~templrcclk;
    logic [15:0] dac_data;
	logic o_AUD_DACDAT, enable;

    initial dac_data = 16'b000_0000_0_1001_0111;


AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(enable), // enable AudPlayer only when playing audio, work with AudDSP
	.i_dac_data(dac_data), //dac_data
	.o_aud_dacdat(o_AUD_DACDAT)
);

    assign i_AUD_BCLK = temp_clk;
	assign i_AUD_DACLRCK = templrcclk;

	initial begin
		$fsdbDumpfile("lab3_play.fsdb");
		$fsdbDumpvars;
		i_rst_n = 0;
		#(2*CLK)
		i_rst_n = 1;
		@(posedge i_AUD_BCLK);
		enable <= 1;
		@(negedge i_AUD_DACLRCK);
        @(negedge i_AUD_BCLK);
		for (int i = 0; i < 1; i++) begin
            $display("=========");
			for (int i = 0; i < 16; i++) begin
                @(negedge i_AUD_BCLK);
                $write("%1b",o_AUD_DACDAT);
			end
            $display("\n");
            $display("=========");
		end
        @(posedge i_AUD_BCLK);
        enable <= 0;
         @(posedge i_AUD_DACLRCK);
		$finish;
	end

	initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

	

endmodule