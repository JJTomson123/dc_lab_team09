`timescale 1ns/100ps

module tb;
	localparam CLK = 10;
	localparam HCLK = CLK/2;

	logic clk, start_cal, fin, rst;
	initial clk = 0;
	always #HCLK clk = ~clk;
	logic [255:0] encrypted_data, decrypted_data;
	logic [247:0] golden;
	integer fp_e, fp_d;

	Top core(
		.i_clk(clk),
		.i_rst(rst),
		.i_start(start_cal),
		.i_a(encrypted_data),
		.o_a_pow_d(decrypted_data),
		.o_finished(fin)
	);

	initial begin
		$fsdbDumpfile("lab2.fsdb");
		$fsdbDumpvars;
		fp_e = $fopen("../pc_python/golden/enc1.bin", "rb");
		fp_d = $fopen("../pc_python/golden/dec1.txt", "rb");
		rst = 1;
		#(2*CLK)
		rst = 0;
		for (int i = 0; i < 5; i++) begin
			for (int j = 0; j < 10; j++) begin
				@(posedge clk);
			end
			$fread(encrypted_data, fp_e);
			$fread(golden, fp_d);
			$display("=========");
			$display("enc  %2d = %64x", i, encrypted_data);
			$display("=========");
			start_cal <= 1;
			@(posedge clk)
			encrypted_data <= 'x;
			start_cal <= 0;
			@(posedge fin)
			$display("=========");
			$display("dec  %2d = %64x", i, decrypted_data);
			$display("gold %2d = %64x", i, golden);
			$display("=========");
		end
		$finish;
	end

	initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
