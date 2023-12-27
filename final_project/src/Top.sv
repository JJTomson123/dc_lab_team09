module Top #(
    parameter ADRBW = 20,
    parameter WRDBW = 16,
    parameter VARBW = 17
) (
    input         i_rst_n,
    input         i_clk,

    output [4 :0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest,
    
    output [19:0] o_SRAM_ADDR,
    inout  [15:0] io_SRAM_DQ,
    output        o_SRAM_WE_N,
    output        o_SRAM_CE_N,
    output        o_SRAM_OE_N,
    output        o_SRAM_LB_N,
    output        o_SRAM_UB_N
);

// design the FSM and states as you like
localparam S_QRX   = 0;
localparam S_INST  = 1;
localparam S_STORE = 2;
localparam S_QTX   = 3;
localparam S_LOAD  = 4;
localparam S_ADD   = 5;
localparam S_MUL   = 7;
localparam S_PREP1 = 8;
localparam S_PREP2 = 9;

localparam ADD   = 4'b0000;
localparam SUB   = 4'b0001;
localparam MUL   = 4'b0010;
localparam DIV   = 4'b0011;
localparam LOAD  = 4'b0100;
localparam STORE = 4'b0101;

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

logic [2:0] state_r, state_w;
logic [1:0] counter_r, counter_w;
logic [19:0] var_addr_r, var_addr_w;
logic [19:0] SRAM_addr, add_addr, mul_addr;
logic [19:0] top_addr_r, top_addr_w;
logic [15:0] top_wdata_r, top_wdata_w;
logic        add_valid, add_sub, mul_valid;
logic [16:0] varsize_x1_r, varsize_x1_w, varsize_x2_r, varsize_x2_w, varsize_r, varsize_w;
logic [19:0] x1_addr_r, x1_addr_w, x2_addr_r, x2_addr_w, x3_addr_r, x3_addr_w;
logic        SRAM_wen, add_wen, mul_wen, add_done, mul_done;
logic [15:0] SRAM_wdata, add_wdata, mul_wdata, SRAM_rdata;
logic [4:0] rs_addr_r, rs_addr_w;
logic [3:0] inst_r, inst_w, x1_r, x1_w, x2_r, x2_w, x3_r, x3_w;

assign avm_address = rs_addr_r;
assign o_SRAM_ADDR = SRAM_addr;
assign io_SRAM_DQ  = (state_r == S_ADD) ? add_wdata : (state_r == S_MUL) ? mul_wdata : (state_r == S_STORE) ? SRAM_wdata : 16'dz; // sram_dq as output
assign SRAM_rdata  = io_SRAM_DQ; // sram_dq as input
assign o_SRAM_WE_N = !SRAM_wen;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

AdderUnit  #(
	.ADRBW(20),
	.WRDBW(16),
	.VARBW(17)
) adder0 (
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_valid(add_valid),
	.i_varsize(varsize_r),
	.i_x1addr(x1_addr_r),
	.i_x2addr(x2_addr_r),
	.i_x3addr(x3_addr_r),
	.i_rdata(SRAM_rdata),
	.i_sub(add_sub),
	.o_wen(add_wen),
	.o_addr(add_addr),
	.o_wdata(add_wdata),
	.o_done(add_done)
);

MultUnit  #(
	.ADRBW(20),
	.WRDBW(16),
	.VARBW(17)
) multer0 (
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_valid(mul_valid),
	.i_varsize_x1(varsize_x1_r),
    .i_varsize_x2(varsize_x2_r),
	.i_x1addr(x1_addr_r),
	.i_x2addr(x2_addr_r),
	.i_x3addr(x3_addr_r),
	.i_rdata(SRAM_rdata),
	.o_wen(mul_wen),
	.o_addr(mul_addr),
	.o_wdata(mul_wdata),
	.o_done(mul_done)
);

always_comb begin
    case (state_r)
        S_INST: begin
            if (avm_waitrequest || rs_addr_r == STATUS_BASE) state_w = S_INST;
            else case (avm_readdata[7:4])
                ADD, SUB, MUL, DIV: state_w = S_PREP1;
                LOAD              : state_w = S_LOAD;
                STORE             : state_w = S_PREP2;
                default           : state_w = S_INST;
            endcase
        end
        S_PREP1: begin
            case (inst_r)
                ADD, SUB: state_w = S_ADD;
                MUL     : state_w = S_MUL;
                default : state_w = S_INST;
            endcase
        end
        S_ADD  : state_w = add_done ? S_INST : S_ADD;
        S_MUL  : state_w = mul_done ? S_INST : S_MUL;
        S_LOAD : state_w = (counter_r == 2 && varsize_r <= WRDBW) ? S_INST : S_LOAD;
        S_STORE: state_w = (counter_r == 2 && varsize_r <= WRDBW) ? S_INST : S_STORE;
        default: state_w = S_INST;
    endcase
end

always_comb begin
    case (state_r)
        S_ADD  : SRAM_addr = add_addr;
        S_MUL  : SRAM_addr = mul_addr;
        default: SRAM_addr = top_addr_r;
    endcase
end

always_comb begin
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_INST;

    end
    else begin
        state_r <= state_w;

    end
end

endmodule


module AdderUnit #(
    parameter ADRBW = 20,
    parameter WRDBW = 16,
    parameter VARBW = 17
) (
    input              i_clk,
    input              i_rst_n,
    input              i_valid,
    input              i_sub,
    input  [VARBW-1:0] i_varsize,
    input  [ADRBW-1:0] i_x1addr,
    input  [ADRBW-1:0] i_x2addr,
    input  [ADRBW-1:0] i_x3addr,
    input  [WRDBW-1:0] i_rdata,
    output             o_wen,
    output [ADRBW-1:0] o_addr,
    output [WRDBW-1:0] o_wdata,
    output [VARBW-1:0] o_varsize_x3,
    output             o_done
);

localparam S_IDLE  = 3'd0;
localparam S_LOAD  = 3'd1;
localparam S_ADD   = 3'd2;
localparam S_SUB   = 3'd5;
localparam S_STORE = 3'd3;
localparam S_CARRY = 3'd4;

logic [2      :0] state_r, state_w;
logic [VARBW  :0] varsize_r, varsize_w;
logic [ADRBW-1:0] x1_addr_r, x2_addr_r, x1_addr_w, x2_addr_w, x3_addr_r, x3_addr_w;
logic [WRDBW  :0] data_r, data_w;
logic [ADRBW-1:0] addr_r, addr_w;
logic [ADRBW-1:0] size3_r, size3_w;
logic             is_sub_r, is_sub_w;

assign o_wen = (state_r == S_STORE) || (state_r == S_CARRY);
assign o_addr = addr_r;
assign o_wdata = data_r[WRDBW-1:0];
assign o_done = (state_r == S_IDLE) && !i_valid;
assign is_sub_w = (state_r == S_IDLE) ? i_sub : is_sub_r;

always_comb begin
    case (state_r)
        S_IDLE: state_w = i_valid ? S_LOAD : S_IDLE;
        S_LOAD: state_w = is_sub_r ? S_SUB : S_ADD;
        S_ADD : state_w = S_STORE;
        S_SUB : state_w = S_STORE;
        S_STORE: begin
            if (is_sub_r) begin
                if (varsize_r <= WRDBW) state_w = S_IDLE;
                else                    state_w = S_LOAD;
            end
            else begin
                if (varsize_r == WRDBW)     state_w = data_r[WRDBW] ? S_CARRY : S_IDLE;
                else if (varsize_r < WRDBW) state_w = S_IDLE;
                else                        state_w = S_LOAD;
            end
        end
        S_CARRY: state_w = S_IDLE;
        default: state_w = S_IDLE;
    endcase
end

always_comb begin
    case (state_r)
        S_IDLE: begin
            varsize_w = i_varsize;
            data_w    = {{WRDBW{1'b0}}, i_sub};
            addr_w    = i_x1addr;
            x1_addr_w = i_x1addr;
            x2_addr_w = i_x2addr;
            x3_addr_w = i_x3addr;
        end
        S_LOAD: begin
            varsize_w = varsize_r;
            data_w    = i_rdata + data_r;
            addr_w    = x2_addr_r;
            x1_addr_w = x1_addr_r + 1;
            x2_addr_w = x2_addr_r;
            x3_addr_w = x3_addr_r;
        end
        S_ADD: begin
            varsize_w = varsize_r;
            data_w    = i_rdata + data_r;
            addr_w    = x3_addr_r;
            x1_addr_w = x1_addr_r;
            x2_addr_w = x2_addr_r + 1;
            x3_addr_w = x3_addr_r;
        end
        S_SUB: begin
            varsize_w = varsize_r;
            data_w    = {1'b0, ~i_rdata} + data_r;
            addr_w    = x3_addr_r;
            x1_addr_w = x1_addr_r;
            x2_addr_w = x2_addr_r + 1;
            x3_addr_w = x3_addr_r;
        end
        S_STORE: begin
            varsize_w = varsize_r - WRDBW;
            data_w    = data_r >> WRDBW;
            addr_w    = (state_w == S_CARRY) ? (x3_addr_r + 1) : x1_addr_r;
            x1_addr_w = x1_addr_r;
            x2_addr_w = x2_addr_r;
            x3_addr_w = x3_addr_r + 1;
        end
        S_CARRY: begin
            varsize_w = varsize_r;
            data_w    = data_r;
            addr_w    = addr_r;
            x1_addr_w = x1_addr_r;
            x2_addr_w = x2_addr_r;
            x3_addr_w = x3_addr_r;
        end
    endcase
end

always_comb begin
    if (state_r == S_STORE && varsize_r <= VARBW) size3_w = i_varsize + data_r[varsize_r];
    else                                          size3_w = i_varsize;
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_IDLE;
        varsize_r <= 0;
        data_r <= 0;
        x1_addr_r <= 0;
        x2_addr_r <= 0;
        x3_addr_r <= 0;
        addr_r <= 0;
        is_sub_r <= 0;
        size3_r <= 0;
    end
    else begin
        state_r <= state_w;
        varsize_r <= varsize_w;
        data_r <= data_w;
        x1_addr_r <= x1_addr_w;
        x2_addr_r <= x2_addr_w;
        x3_addr_r <= x3_addr_w;
        addr_r <= addr_w;
        is_sub_r <= is_sub_w;
        size3_r <= size3_w;
    end
end

endmodule


module MultUnit #(
    parameter ADRBW = 20,
    parameter WRDBW = 16,
    parameter VARBW = 17
) (
    input              i_clk,
    input              i_rst_n,
    input              i_valid,
    input  [VARBW-1:0] i_varsize_x1,
    input  [VARBW-1:0] i_varsize_x2,
    input  [ADRBW-1:0] i_x1addr,
    input  [ADRBW-1:0] i_x2addr,
    input  [ADRBW-1:0] i_x3addr,
    input  [WRDBW-1:0] i_rdata,
    output             o_wen,
    output [ADRBW-1:0] o_addr,
    output [WRDBW-1:0] o_wdata,
    output [VARBW-1:0] o_varsize_x3,
    output             o_done
);

localparam S_IDLE  = 3'd0;
localparam S_LOAD  = 3'd1;
localparam S_MUL   = 3'd2;
localparam S_SUM   = 3'd3;
localparam S_STORE = 3'd4;
localparam S_CARRY = 3'd5;

logic [VARBW  :0] varsize_x2_r, varsize_x1_r, varsize_x1_w, varsize_x2_w;
logic [ADRBW-1:0] x1_addr_r, x2_addr_r, x1_addr_w, x2_addr_w, x3_addr_r, x3_addr_w, prod_addr_r, prod_addr_w;
logic [WRDBW*2-1  :0] data_r, data_w;
logic [ADRBW-1:0] addr_r, addr_w;
logic [2 :0] state_r, state_w;
logic [WRDBW-1 :0] x1_data_w, x1_data_r;
logic first_row_r, first_row_w;
logic [ADRBW-1:0] nxtaddr_r, nxtaddr_w;

assign o_wen   = (state_r == S_STORE) || (state_r == S_CARRY);
assign o_addr  = addr_r;
assign o_wdata = data_r[WRDBW-1:0];
assign o_varsize_x3 = i_varsize_x1 + i_varsize_x2;
assign o_done  = (state_r == S_IDLE) && !i_valid;

always_comb begin
    case (state_r)
        S_IDLE: state_w = i_valid ? S_LOAD : S_IDLE;
        S_LOAD: state_w = S_MUL;
        S_MUL : state_w = first_row_r ? S_STORE : S_SUM;
        S_SUM: state_w = S_STORE;
        S_STORE: begin
            if (~|varsize_x2_r || varsize_x2_r[VARBW]) state_w = S_CARRY;
            else                                       state_w = S_MUL;
        end
        S_CARRY: begin
            if (~|varsize_x1_r || varsize_x1_r[VARBW]) state_w = S_IDLE;
            else                                       state_w = S_LOAD;
        end
        default: state_w = S_IDLE;
    endcase
end


always_comb begin
    case(state_r)
        S_IDLE: begin
            varsize_x1_w = i_varsize_x1;
            varsize_x2_w = i_varsize_x2;
            x1_data_w = {WRDBW{1'b0}};
            data_w    = {(WRDBW*2){1'b0}};
            addr_w    = i_x1addr;
            x1_addr_w = i_x1addr;
            x2_addr_w = i_x2addr;
            x3_addr_w = i_x3addr;
            prod_addr_w = i_x3addr;
            first_row_w = 1'b1;
        end
        S_LOAD: begin
            varsize_x1_w = varsize_x1_r - WRDBW;
            varsize_x2_w = varsize_x2_r;
            x1_data_w = i_rdata;
            data_w    = data_r;
            addr_w    = x2_addr_r;
            x1_addr_w = x1_addr_r + 1;
            x2_addr_w = x2_addr_r;
            x3_addr_w = x3_addr_r;
            prod_addr_w = prod_addr_r + 1;
            first_row_w = first_row_r;
        end
        S_MUL: begin
            varsize_x1_w = varsize_x1_r;
            varsize_x2_w = varsize_x2_r - WRDBW;
            x1_data_w = x1_data_r;
            data_w    = i_rdata * x1_data_r + data_r;
            addr_w    = x3_addr_r;
            x1_addr_w = x1_addr_r;
            x2_addr_w = x2_addr_r + 1;
            x3_addr_w = x3_addr_r;
            prod_addr_w = prod_addr_r;
            first_row_w = first_row_r;
        end
        S_SUM: begin
            varsize_x1_w = varsize_x1_r;
            varsize_x2_w = varsize_x2_r;
            x1_data_w = x1_data_r;
            data_w    = i_rdata + data_r;
            addr_w    = addr_r;
            x1_addr_w = x1_addr_r;
            x2_addr_w = x2_addr_r;
            x3_addr_w = x3_addr_r;
            prod_addr_w = prod_addr_r;
            first_row_w = first_row_r;
        end
        S_STORE: begin
            varsize_x1_w = varsize_x1_r;
            varsize_x2_w = varsize_x2_r;
            x1_data_w = x1_data_r;
            data_w    = data_r >> WRDBW;
            addr_w    = (state_w == S_CARRY) ? (x3_addr_r + 1) : x2_addr_r;
            x1_addr_w = x1_addr_r;
            x2_addr_w = x2_addr_r;
            x3_addr_w = x3_addr_r + 1;
            prod_addr_w = prod_addr_r;
            first_row_w = first_row_r;
        end
        S_CARRY: begin
            varsize_x1_w = varsize_x1_r;
            varsize_x2_w = i_varsize_x2;
            x1_data_w = x1_data_r;
            data_w    = {(WRDBW*2){1'b0}};
            addr_w    = x1_addr_r;
            x1_addr_w = x1_addr_r;
            x2_addr_w = i_x2addr;
            x3_addr_w = prod_addr_r;
            prod_addr_w = prod_addr_r;
            first_row_w = 1'b0;
        end
    endcase
end
    
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_IDLE;
        varsize_x1_r <= 0;
        varsize_x2_r <= 0;
        x1_data_r <= 0;
        data_r <= 0;
        x1_addr_r <= 0;
        x2_addr_r <= 0;
        x3_addr_r <= 0;
        addr_r <= 0;
        prod_addr_r <= 0;
        first_row_r <= 0;
    end
    else begin
        state_r <= state_w;
        varsize_x1_r <= varsize_x1_w;
        varsize_x2_r <= varsize_x2_w;
        x1_data_r <= x1_data_w;
        data_r <= data_w;
        x1_addr_r <= x1_addr_w;
        x2_addr_r <= x2_addr_w;
        x3_addr_r <= x3_addr_w;
        addr_r <= addr_w;
        prod_addr_r <= prod_addr_w;
        first_row_r <= first_row_w;
    end
end

    
endmodule


module DivUnit #(
    parameter ADRBW = 20,
    parameter WRDBW = 16,
    parameter VARBW = 17
) (
    input              i_clk,
    input              i_rst_n,
    input              i_valid,
    input  [VARBW-1:0] i_varsize_x1,
    input  [VARBW-1:0] i_varsize_x2,
    input  [ADRBW-1:0] i_x1addr,
    input  [ADRBW-1:0] i_x2addr,
    input  [ADRBW-1:0] i_x3addr,
    input  [WRDBW-1:0] i_rdata,
    output             o_wen,
    output [ADRBW-1:0] o_addr,
    output [WRDBW-1:0] o_wdata,
    output             o_done
);

endmodule