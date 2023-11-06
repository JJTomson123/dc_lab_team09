module SDRAMWrapper(
	input i_rst_n, 
    input i_clk,

    input  [25:0] i_addr,
    input  [15:0] i_data,
    input         i_write,
    input         i_read,
    output [15:0] o_data,
    output        o_valid,

    input  [31:0] i_sdrmctrl_readdata,
    input         i_sdrmctrl_readdatavalid,
    input         i_sdrmctrl_waitrequest,

	output [24:0] o_sdrmctrl_address,
    output [3:0]  o_sdrmctrl_byteenable_n,
    output        o_sdrmctrl_chipselect,
    output [31:0] o_sdrmctrl_writedata,
    output        o_sdrmctrl_read_n,
    output        o_sdrmctrl_write_n
);


localparam S_IDLE  = 0;
localparam S_WRITE = 1;
localparam S_READ  = 2;

logic [2:0]  state_r, state_w;
logic [25:0] addr_r, addr_w;
logic [15:0] data_r, data_w;

assign o_data  = (addr_r[0]) ? i_sdrmctrl_readdata[31:16] : i_sdrmctrl_readdata[15:0];
assign o_valid = i_sdrmctrl_readdatavalid;

assign o_sdrmctrl_address      = addr_r[24:0];
assign o_sdrmctrl_byteenable_n = (addr_r[0]) ? 4'b0011 : 4'b1100;
assign o_sdrmctrl_chipselect   = 1'b1;
assign o_sdrmctrl_writedata    = (addr_r[0]) ? {data_r, 16'b0} : {16'b0, data_r};
assign o_sdrmctrl_read_n       = !(state_r == S_READ);
assign o_sdrmctrl_write_n      = !(state_r == S_WRITE);

always_comb begin
    // FSM
    addr_w    = addr_r;
    data_w    = data_r;
    case(state_r)
    S_IDLE: begin
        if (i_write) begin
            state_w = S_WRITE;
            addr_w  = i_addr;
            data_w  = i_data;
        end else if (i_read) begin
            state_w = S_READ;
            addr_w  = i_addr;
        end
        else state_w = S_IDLE;
    end
    S_WRITE: begin
        if (i_sdrmctrl_waitrequest) state_w = S_WRITE;
        else                        state_w = S_IDLE;
    end
    S_READ: begin
        if (i_sdrmctrl_waitrequest) state_w = S_READ;
        else                        state_w = S_IDLE;
    end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r   <= S_IDLE;
        data_r    <= 0;
        addr_r    <= 0;
	end
	else begin
        state_r   <= state_w;
        data_r    <= data_w;
        addr_r    <= addr_w;
	end
end


endmodule