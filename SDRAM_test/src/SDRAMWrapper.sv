module SDRAMWrapper(
	input i_rst_n, 
    input i_clk,

    input  [25:0] i_addr,
    input  [15:0] i_data,
    input         i_write,
    input         i_read,
    output [15:0] o_data,
    output        o_valid,

    input  [31:0] avm_readdata,
    input         avm_readdatavalid,
    input         avm_waitrequest,

	output [24:0] avm_address,
    output [3:0]  avm_byteenable_n,
    output        avm_chipselect,
    output [31:0] avm_writedata,
    output        avm_read_n,
    output        avm_write_n
);


localparam S_IDLE  = 0;
localparam S_WRITE = 1;
localparam S_READ  = 2;

logic [2:0]  state_r, state_w;
logic [25:0] addr_r, addr_w;
logic [15:0] data_r, data_w;
logic        read_r, read_w, write_r, write_w;

assign o_data  = data_r;
assign o_valid = avm_readdatavalid;

assign avm_address      = addr_r[24:0];
assign avm_byteenable_n = (addr_r[0]) ? 4'b0011 : 4'b1100;
assign avm_chipselect   = 1'b1;
assign avm_writedata    = (addr_r[0]) ? {data_r, 16'b0} : {16'b0, data_r};
assign avm_read_n       = !read_r;
assign avm_write_n      = !write_r;

always_comb begin
    // FSM
    addr_w    = addr_r;
    data_w    = data_r;
    read_w    = 0;
    write_w   = 0;
    case(state_r)
    S_IDLE: begin
        if (i_write) begin
            state_w = S_WRITE;
            addr_w  = i_addr;
            data_w  = i_data;
            write_w = 1;
        end else if (i_read) begin
            state_w = S_READ;
            addr_w  = i_addr;
            data_w  = 0;
            read_w  = 1;
        end
        else state_w = S_IDLE;
    end
    S_WRITE: begin
        if (avm_waitrequest) begin 
            state_w = S_WRITE;
            write_w = 1;
        end
        else state_w = S_IDLE;
    end
    S_READ: begin
        if (avm_waitrequest || !avm_readdatavalid) begin
            state_w = S_READ;
            read_w  = 1;
        end
        else begin
            state_w = S_IDLE;
            data_w  = (addr_r[0]) ? avm_readdata[31:16] : avm_readdata[15:0];
        end
    end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r   <= S_IDLE;
        data_r    <= 0;
        addr_r    <= 0;
        read_r    <= 0;
        write_r   <= 0;
	end
	else begin
        state_r   <= state_w;
        data_r    <= data_w;
        addr_r    <= addr_w;
        read_r    <= read_w;
        write_r   <= write_w;
	end
end


endmodule