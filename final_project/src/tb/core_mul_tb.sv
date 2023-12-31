`timescale 1ns/100ps

module tb;

localparam CLK = 10;
localparam HCLK = CLK/2;

logic clk, valid, done, rst_n, enable;
initial clk = 0;
always #HCLK clk = ~clk;
logic [15:0] varsize_x1, varsize_x2, varsize_x3;
logic [19:0] x1addr, x2addr, x3addr, addr;
logic [15:0] rdata, wdata;
logic [15:0] sram [0:16];

initial begin
	varsize_x1 = 16'd3;
    varsize_x2 = 16'd3;
	x1addr = 19'd0;
	x2addr = 19'd3;
	x3addr = 19'd6;
end

always @(posedge clk or negedge rst_n) begin
	if (!rst_n) sram[0:6] <= '{16'ha836, 16'h5cb4, 16'h000b, 16'h0fcb, 16'h334f, 16'hdeac, 16'h100f};
	else if (enable) sram[addr[3:0]] <= wdata;
end

assign rdata = sram[addr];

MultUnit  #(
	.ADRBW(20),
	.WRDBW(16),
	.VARBW(16)
) multer1 (
	.i_clk(clk),
	.i_rst_n(rst_n),
	.i_valid(valid),
	.i_varsize_x1(varsize_x1),
    .i_varsize_x2(varsize_x2),
	.i_x1addr(x1addr),
	.i_x2addr(x2addr),
	.i_x3addr(x3addr),
	.i_rdata(rdata),
	.o_wen(enable),
	.o_addr(addr),
	.o_wdata(wdata),
	.o_varsize_x3(varsize_x3),
	.o_done(done)
);

	initial begin
		$fsdbDumpfile("final_project_adder.fsdb");
		$fsdbDumpvars("+all");
		
		
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
