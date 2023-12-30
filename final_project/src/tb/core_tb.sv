`timescale 1ns/100ps

module tb;

localparam CLK = 10;
localparam HCLK = CLK/2;

logic clk, valid, done, rst_n, enable;
initial clk = 0;
always #HCLK clk = ~clk;
logic [15:0] varsize1, varsize2, varsize3;
logic [19:0] x1addr, x2addr, x3addr, addr;
logic [15:0] rdata, wdata;
logic [15:0] sram [0:15];

initial begin
	varsize1 = 16'd4;
	varsize2 = 16'd3;
	x1addr = 20'd0;
	x2addr = 20'd5;
	x3addr = 20'd10;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) sram[0:7] <= '{16'h4430, 16'h14D4, 16'h3540, 16'hB7F1, 16'bx, 16'h6B75, 16'hB0AC, 16'h94A8
							   };
	else if (enable) sram[addr[3:0]] <= wdata;
end

assign rdata = sram[addr];

AdderUnit  #(
	.ADRBW(20),
	.WRDBW(16),
	.VARBW(16)
) adder123 (
	.i_clk(clk),
	.i_rst_n(rst_n),
	.i_valid(valid),
	.i_sub(1'b0),
	.i_varsize_x1(varsize1),
	.i_varsize_x2(varsize2),
	.i_x1addr(x1addr),
	.i_x2addr(x2addr),
	.i_x3addr(x3addr),
	.i_rdata(rdata),
	.o_wen(enable),
	.o_addr(addr),
	.o_wdata(wdata),
	.o_varsize_x3(varsize3),
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
		@(posedge done);

	end

	initial begin
		#(500000*CLK)
		$display("Too slow, abort.");
		$finish;
	end

endmodule
