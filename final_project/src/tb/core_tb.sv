`timescale 1ns/100ps

module tb;

localparam CLK = 10;
localparam HCLK = CLK/2;

logic clk, valid, done, rst_n, enable;
initial clk = 0;
always #HCLK clk = ~clk;
logic [16:0] varsize;
logic [19:0] x1addr, x2addr, x3addr, addr;
logic [15:0] rdata, wdata;
logic [15:0] sram [0:15];

initial begin
	varsize = 17'd32;
	x1addr = 19'd0;
	x2addr = 19'd5;
	x3addr = 19'd10;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) sram[0:6] <= '{16'h475a, 16'h9844, 16'bx, 16'bx, 16'bx, 16'h457, 16'h000f};
	else if (enable) sram[addr[3:0]] <= wdata;
end

assign rdata = sram[addr];

AdderUnit  #(
	.ADRBW(20),
	.WRDBW(16),
	.VARBW(17)
) adder123 (
	.i_clk(clk),
	.i_rst_n(rst_n),
	.i_valid(valid),
	.i_varsize(varsize),
	.i_x1addr(x1addr),
	.i_x2addr(x2addr),
	.i_x3addr(x3addr),
	.i_rdata(rdata),
	.o_wen(enable),
	.o_addr(addr),
	.o_wdata(wdata),
	.o_done(done)
);

	initial begin
		$fsdbDumpfile("final_project_adder.fsdb");
		$fsdbDumpvars;
		
		
		rst_n = 0;
		#(2*CLK)
		rst_n = 1;

/* 			for (int j = 0; j < 4; j++) begin
				@(posedge clk);
			end */

		valid <= 1;
		@(posedge clk)
		valid <= 0;
		@(posedge done)


		$finish;
	end

	initial begin
		

	end

	initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
