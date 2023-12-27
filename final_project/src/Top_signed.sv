/* module Top (
    input  i_rst_n,
    input  i_clk,
    input  i_valid,
    output o_valid,
    input [1:0] op,
    
    output [19:0] o_SRAM_ADDR,
    inout  [15:0] io_SRAM_DQ,
    output        o_SRAM_WE_N,
    output        o_SRAM_CE_N,
    output        o_SRAM_OE_N,
    output        o_SRAM_LB_N,
    output        o_SRAM_UB_N
);

// design the FSM and states as you like
parameter S_IDLE  = 0;
parameter S_PREP  = 1;
parameter S_ARITH = 2;
parameter S_CALC  = 3;

logic [2:0] state_r, state_w;

assign o_SRAM_ADDR = (state_r == S_RECD) ? SRAM_waddr : SRAM_raddr;
assign io_SRAM_DQ  = (state_r == S_RECD) ? SRAM_wdata : 16'dz; // sram_dq as output
assign SRAM_rdata  = (state_r != S_RECD) ? io_SRAM_DQ : 16'd0; // sram_dq as input
assign o_SRAM_WE_N = (state_r == S_RECD) ? 1'b0 : 1'b1;
assign o_SRAM_CE_N = 1'b0;
assign o_SRAM_OE_N = 1'b0;
assign o_SRAM_LB_N = 1'b0;
assign o_SRAM_UB_N = 1'b0;

always_comb begin
    // design your control here
    case(state_r)
    S_IDLE: begin
        arith_start_w = 0;
        if (i_valid) begin
            state_w = S_PREP;
            prep_start = 1;
        end 
        else begin
            state_w = S_IDLE;
            prep_start = 0;
        end
    end
    S_PREP: begin
        prep_start = 0;
        if (prep_rdy && !prep_start) begin
            state_w       = S_ARITH;
            arith_start_w = 1;
        end
        else begin
            state_w = S_PREP;
            arith_start_w = 0;
        end
    end
    S_ARITH: begin
        prep_start = 0;
        arith_start_w = 0;
        if (prep_rdy && !prep_start) begin
            state_w       = S_CALC;
        end
        else begin
            state_w       = S_ARITH;
        end
    end
    default: state_w = S_IDLE;
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_IDLE;

    end
    else begin
        state_r <= state_w;

    end
end

endmodule
 */

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
            if (varsize_r <= WRDBW) state_w = S_CARRY;
            else                    state_w = S_IDLE;
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
            varsize_w = varsize_r - WRDBW;
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
            data_w    = i_rdata + ~data_r;
            addr_w    = x3_addr_r;
            x1_addr_w = x1_addr_r;
            x2_addr_w = x2_addr_r + 1;
            x3_addr_w = x3_addr_r;
        end
        S_STORE: begin
            varsize_w = varsize_r - WRDBW;
            if (varsize_r == WRDBW) begin
                data_w = (~data_r) >> WRDBW;
                addr_w = x3_addr_r + WRDBW;
            end
            else if (varsize_r < WRDBW) begin
                data_w = data_r ^ {{WRDBW{1'b0}}, 1'b1} << WRDBW;
                addr_w = addr_r;
            end
            else begin
                data_w = data_r >> WRDBW;
                addr_w = x1_addr_r;
            end
            x1_addr_w = x1_addr_r;
            x2_addr_w = x2_addr_r;
            x3_addr_w = x3_addr_r + WRDBW;
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

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state_r <= S_IDLE;
        varsize_r <= 0;
        data_r <= 0;
    end
    else begin
        state_r <= state_w;
        varsize_r <= varsize_w;
        data_r <= data_w;
    end
end

endmodule








/* module ARITHMETIC(
    input              i_clk,
    input              i_rst_n,
    input              i_start,
    input       [1:0]  op;
    input      [31:0]  i_a,
    input      [31:0]  i_b, // cipher text y
    input              i_carryin,
    output     [31:0]  o_data, // t = y * 2^256
    output             o_rdy
);

localparam S_IDLE  = 2'b00;
localparam S_ADD   = 2'b01;
localparam S_MUL   = 2'b10;
localparam S_DIV   = 2'b11;


logic [1:0]   state_r, state_w;
logic [7:0]   count_r, count_w;
logic [255:0] n_r, n_w;
logic [255:0] m_w;

assign o_rdy = (state_r == S_IDLE);

always_comb begin
    case(state_r)
    S_IDLE: begin
        count_w = 0;
        if (i_start) begin
            if (op==2'b00) begin
                state_w = S_ADD;
            end
            else if (op==2'b01) begin
                state_w = S_ADD;
            end
            else if (op==2'b10) begin
                state_w = S_MUL;
            end
            else begin
                state_w = S_DIV;
            end
        end else begin
            state_w = S_IDLE;
        end
    end
    S_ADD: begin
        pg = 1;
        temp = 0;
        FA fa0(sum_w[0], c[1], i_a[0], i_b[0], i_carryin);
        FA fa[30:1](sum_w[30:1], c[31:2], i_a[30:1], i_b[30:1], c[30:1]);
        FA fa31(sum_w[31], cout, i_a[31], i_b[31], c[31]);
        for (int i=0; i<32; i++) begin
            temp = i_a[i]^i_b[i];
            pg = pg & temp;
        end
        cout_w = (pg)? i_carryin : cout;
 
        if (count_r == 7) begin
            state_w = S_UPDT;
            count_w = 0;
        end else begin
            state_w = S_CALC;
            count_w = count_r + 1;
        end
        state_w = S_IDLE;
    end
    endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        state_r    <= S_IDLE;
        count_r    <= 0;
    end
    else begin
        state_r    <= state_w;
        count_r    <= count_w;
    end
end

endmodule

module FA(output sum, cout, input a, b, cin);
  wire w0, w1, w2;
  
  xor (w0, a, b);
  xor (sum, w0, cin);
  
  and (w1, w0, cin);
  and (w2, a, b);
  or (cout, w1, w2);

endmodule
 */