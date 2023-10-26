module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic i_clk_100K, start_cal, fin, i_rst_n;
	initial i_clk_100K = 0;
	always #HCLK i_clk_100K = ~i_clk_100K;
	logic o_I2C_SCLK,i2c_oen, ack;
	logic [167:0] data;
	wire i2c_sdat;


    I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100K),
	.i_start(start_cal),
	.o_finished(fin),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
    );

	assign i2c_sdat = (ack && !i2c_oen) ? 1'b0 : 1'bz;

	initial begin
		$fsdbDumpfile("lab3_i2c.fsdb");
		$fsdbDumpvars;
		i_rst_n = 0;
		ack = 0;
		#(2*CLK)
		i_rst_n = 1;
		@(posedge i_clk_100K)
		start_cal <= 1;
		@(posedge i_clk_100K)
		start_cal <= 0;
		for (int i = 0; i < 21; i++) begin
			for (int j = 0; j < 8; j++) begin
				@(posedge o_I2C_SCLK);
				data = {data[166:0],i2c_sdat};
			end
			@(negedge o_I2C_SCLK);
			ack = 1;
			@(negedge o_I2C_SCLK);
			ack = 0;
		end
		@(posedge fin)
		$display("=========");
		$display("i2c_data  %168b", data);
		$display("=========");
		$finish;
	end

	initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

	

endmodule