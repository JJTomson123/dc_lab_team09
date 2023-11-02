`timescale 1us/100ns

module i2c_tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic i_clk_100K, start_cal, fin, i_rst_n;
	initial i_clk_100K = 0;
	always #HCLK i_clk_100K = ~i_clk_100K;
	logic i2c_sclk, i2c_oen, ack, sdat_write, comm;
	logic [7:0] data;
	wire  i2c_sdat;

    I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100K),
	.i_start(start_cal),
	.o_finished(fin),
	.o_sclk(i2c_sclk),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
    );

	assign i2c_sdat = (ack && !i2c_oen) ? sdat_write : 1'bz;

	initial begin
		$fsdbDumpfile("lab3_i2c.fsdb");
		$fsdbDumpvars;
		i_rst_n = 0;
		start_cal = 0;
		ack = 0;
		comm = 0;
		#(2*CLK)
		i_rst_n = 1;
		@(posedge i_clk_100K);
		start_cal <= 1;
		@(posedge i_clk_100K);
		start_cal <= 0;
		while (!fin) begin
			while (!comm) begin
				@(edge i2c_sdat or posedge fin)
				if (fin) break;
				if (i2c_sclk) comm = !i2c_sdat;
			end
			if (fin) break;
			for (int i = 0; i < 8; i++) begin
				@(posedge i2c_sclk);
				data = {data[6:0], i2c_sdat};
			end
			$display("=========");
			$display("device address: %8b", data);
			if (data == 8'b0011_0100) begin
				$display("address matched! communication start");
				@(negedge i2c_sclk);
				ack = 1;
				sdat_write = 0;
				@(negedge i2c_sclk);
				ack = 0;

				$write("data = ");
				for (int i = 0; i < 8; i++) begin
					@(posedge i2c_sclk);
					data = {data[6:0], i2c_sdat};
				end
				$write("%8b", data);
				@(negedge i2c_sclk);
				ack = 1;
				sdat_write = 0;
				@(negedge i2c_sclk);
				ack = 0;
				
				for (int i = 0; i < 8; i++) begin
					@(posedge i2c_sclk);
					data = {data[6:0], i2c_sdat};
				end
				$write("%8b\n", data);
			end
			else begin
				$display("address not matched! wait for start signal");
			end
			comm = 0;
		end
		/* for (int i = 0; i < 21; i++) begin
			for (int j = 0; j < 8; j++) begin
				@(posedge i2c_sclk);
				data = {data[166:0],i2c_sdat};
			end
			@(negedge i2c_sclk);
			if (i==20) begin
				ack = 0;
				break;
			end else begin
				ack = 1;
			end
			@(negedge i2c_sclk);
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
		$display("========="); */
		$finish;
	end

	initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

	

endmodule