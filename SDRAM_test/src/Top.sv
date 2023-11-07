module Top (
    input i_rst_n,
    input i_clk,
    input i_key_0,
    input i_key_1,
    input i_key_2,
    input [15:0] i_data,
    input i_inc_sel,

    // SDRAM
    input  [15:0] i_SDRAM_DATA,
    input         i_SDRAM_VALID,
    output        o_SDRAM_WRITE,
    output        o_SDRAM_READ,
    output [25:0] o_SDRAM_ADDR,
    output [15:0] o_SDRAM_DQ,

    // SEVENDECODER
    output [15:0] o_data,
    output [1:0]  o_state
);

// design the FSM and states as you like
parameter S_IDLE  = 0;
parameter S_STORE = 1;
parameter S_BUFF  = 2;
parameter S_LOAD  = 3;

logic [25:0] addr_r, addr_w;
logic [15:0] data_load_r, data_load_w, data_store_r, data_store_w;
logic [1:0] state_r, state_w;
logic write_r, write_w, read_r, read_w;

assign o_SDRAM_WRITE = write_r;
assign o_SDRAM_READ  = read_r;
assign o_SDRAM_ADDR  = addr_r;
assign o_SDRAM_DQ    = data_store_r;

assign o_data = data_load_r;
assign o_state = state_r;

always_comb begin
    // design your control here
    addr_w  = addr_r;
    write_w = 0;
    read_w  = 0;
    data_load_w  = data_load_r;
    data_store_w = data_store_r;
    case(state_r)
    S_IDLE: begin
        if (i_key_2) begin
            state_w = S_IDLE;
            if (i_inc_sel) addr_w = addr_r + 1;
            else           addr_w = addr_r - 1;
        end else if (i_key_0) begin
            state_w = S_STORE;
            write_w = 1;
            data_store_w = i_data;
        end else if (i_key_1) begin
            state_w = S_LOAD;
            read_w  = 1;
        end else state_w = S_IDLE;
    end
    S_STORE: begin
        state_w = S_IDLE;
    end
    S_LOAD: begin
        if (!i_SDRAM_VALID) state_w = S_LOAD;
        else begin
            state_w = S_IDLE;
            data_load_w = i_SDRAM_DATA;
        end
    end
    default: state_w = S_IDLE;
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r      <= S_IDLE;
        addr_r       <= 0;
        write_r      <= 0;
        read_r       <= 0;
        data_load_r  <= 0;
        data_store_r <= 0;
    end
    else begin
        state_r      <= state_w;
        addr_r       <= addr_w;
        write_r      <= write_w;
        read_r       <= read_w;
        data_load_r  <= data_load_w;
        data_store_r <= data_store_w;
    end
end

endmodule