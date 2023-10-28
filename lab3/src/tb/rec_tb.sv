module rec_tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;



    wire i_AUD_BCLK, i_AUD_ADCLRCK;
	logic start, pause, i_rst_n, stop;
	initial i_AUD_BCLK = 0;
	always #HCLK i_AUD_BCLK = ~i_AUD_BCLK;
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
	.o_data(data_record),
);

    

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
		for (int i = 0; i < 21; i++) begin
			for (int j = 0; j < 8; j++) begin
				@(posedge o_I2C_SCLK);
				data = {data[166:0],i2c_sdat};
			end
			@(negedge o_I2C_SCLK);
			if (i==20) begin
				ack = 0;
				break;
			end else begin
				ack = 1;
			end
			@(negedge o_I2C_SCLK);
			ack = 0;
		end
		@(posedge fin);
		for (int k=0; k<7; k++) begin
			$display("=========");
			$write("data %3d = ",k);
			for (int x=0; x<3; x++) begin
				for (int y=0; y<8; y++) begin
				$write("%1b", data[((167-y)-x*8)-24*k]);
				end
			end
			$write("\n");
		end
		$display("=========");
		$finish;
	end

	initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

	

endmodule