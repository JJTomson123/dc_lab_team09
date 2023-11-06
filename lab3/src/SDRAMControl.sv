module SDRAMControl(
	input i_rst_n, 
	
    inout i_clk,

    input  [25:0] i_addr,
    input  [15:0] i_data,
    output [15:0] o_data,
    input  i_write,
    input  i_read,
    output o_rdy,

	output [12:0] o_DRAM_ADDR,
	output [1:0]  o_DRAM_BA,
	output        o_DRAM_CAS_N, //
	output        o_DRAM_CKE, //
	output        o_DRAM_CLK,  //
	output        o_DRAM_CS_N, //
	inout [31:0]  io_DRAM_DQ, 
	output [3:0]  o_DRAM_DQM, //
	output        o_DRAM_RAS_N, //
	output 		  o_DRAM_WE_N
);


localparam S_IDLE  = 0;
localparam S_ACT   = 1;
localparam S_WRITE = 2;
localparam S_READ  = 3;

logic [2:0]  state_r, state_w;
logic [31:0] data_r, data_w;
logic [25:0] addr_r, addr_w;
logic writing_w, writing_r, rdy_r, rdy_w;

assign o_data = (addr_r[0]) ? io_DRAM_DQ[31:16] : io_DRAM_DQ[15:0];
assign o_rdy  = rdy_r;

assign o_DRAM_ADDR = (state_r == S_ACT) ? addr_r[23:11] : {3'b001, addr_r[10:1]};
assign o_DRAM_BA   = addr_r[25:24];
assign o_DRAM_CAS_N = (state_r == S_ACT);
assign o_DRAM_CKE = (state_r != S_IDLE);
assign o_DRAM_CLK = i_clk;
assign o_DRAM_CS_N = 1'b0;
assign io_DRAM_DQ = (state_r == S_WRITE) ? data_r : 32'bz;
assign o_DRAM_DQM = (addr_r[0]) ? 4'b0011 : 4'b1100;
assign o_DRAM_RAS_N = (state_r != S_ACT);
assign o_DRAM_WE_N = ~(state_r == S_WRITE);

always_comb begin
    // FSM
    writing_w = 0;
    addr_w    = addr_r;
    data_w    = data_r;
    rdy_w    = 0;
    case(state_r)
    S_IDLE: begin
        if (i_write) begin
            state_w = S_ACT;
            writing_w = 1;
            addr_w = i_addr;
            data_w = (i_addr[0]) ? {i_data, 16'b0} : {16'b0, i_data};
        end else if (i_read) begin
            state_w = S_ACT;
            writing_w = 0;
            addr_w = i_addr;
            data_w = 0;
        end
        else state_w = S_IDLE;
    end
    S_ACT: begin
        if (writing_r) state_w = S_WRITE;
        else           state_w = S_READ;
    end
    S_WRITE: begin
        state_w = S_IDLE;
    end
    S_READ: begin
        state_w = S_IDLE;
        rdy_w = 1;
    end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r   <= S_IDLE;
        data_r    <= 0;
        addr_r    <= 0;
        writing_r <= 0;
        rdy_r     <= 0;
	end
	else begin
        state_r   <= state_w;
        data_r    <= data_w;
        addr_r    <= addr_w;
        writing_r <= writing_w;
        rdy_r     <= rdy_w;
	end
end



endmodule