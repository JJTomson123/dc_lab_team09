module Rsa256Wrapper (
    input         avm_rst,
    input         avm_clk,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    input         avm_waitrequest
);

localparam RX_BASE     = 0*4;
localparam TX_BASE     = 1*4;
localparam STATUS_BASE = 2*4;
localparam TX_OK_BIT   = 6;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_QUERY_RX = 0;
localparam S_GET_DATA = 2;
localparam S_WAIT_CALCULATE = 3;
localparam S_QUERY_TX = 4;
localparam S_SEND_DATA = 5;

logic [255:0] instr_r, instr_w;
logic [255:0] n_r, n_w, d_r, d_w, enc_r, enc_w, dec_r, dec_w;
logic [2:0] state_r, state_w, state_save_r, state_save_w;
logic [6:0] bytes_counter_r, bytes_counter_w;
logic [4:0] avm_address_r, avm_address_w;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

logic rsa_start_r, rsa_start_w;
logic rsa_finished;
logic [255:0] rsa_dec;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = dec_r[247-:8];

Rsa256Core rsa256_core(
    .i_clk(avm_clk),
    .i_rst(avm_rst),
    .i_start(rsa_start_r),
    .i_a(enc_r),
    .i_d(d_r),
    .i_n(n_r),
    .o_a_pow_d(rsa_dec),
    .o_finished(rsa_finished)
);

task StartRead;
    input [4:0] addr;
    begin
        avm_read_w = 1;
        avm_write_w = 0;
        avm_address_w = addr;
    end
endtask
task StartWrite;
    input [4:0] addr;
    begin
        avm_read_w = 0;
        avm_write_w = 1;
        avm_address_w = addr;
    end
endtask

always_comb begin
    {n_w, d_w, enc_w} = {n_r, d_r, enc_r};
    instr_w = instr_r;
    dec_w = dec_r;
    avm_address_w = STATUS_BASE;
    avm_read_w = 0;
    avm_write_w = 0;
    bytes_counter_w = 0;
    rsa_start_w = 0;
    case(state_r)
    S_QUERY_RX: begin
        bytes_counter_w = bytes_counter_r;
        if (avm_waitrequest || !avm_readdata[7]) begin
            state_w = S_QUERY_RX;
            StartRead(STATUS_BASE);
        end else begin
            state_w = S_GET_DATA;
            StartRead(RX_BASE);
        end
    end
    S_GET_DATA: begin
        if (avm_waitrequest) begin
            state_w         = S_GET_DATA;
            bytes_counter_w = bytes_counter_r;
            StartRead(RX_BASE);
        end else begin
            if (bytes_counter_r == 32) begin
                bytes_counter_w = 0;
                instr_w         = 0;
                case (avm_readdata[1:0])
                2'b00: begin
                    state_w = S_QUERY_RX;
                    n_w     = instr_r;
                end
                2'b01: begin
                    state_w = S_QUERY_RX;
                    d_w     = instr_r;
                end
                2'b10: begin
                    state_w     = S_WAIT_CALCULATE;
                    enc_w       = instr_r;
                    rsa_start_w = 1;
                end
                default begin
                    state_w = S_QUERY_RX;
                end
                endcase
            end else begin
                state_w         = S_QUERY_RX;
                bytes_counter_w = bytes_counter_r + 1;
                instr_w         = {instr_r[247:0], avm_readdata[7:0]};
            end
        end
    end
    S_WAIT_CALCULATE: begin
        if (rsa_finished && !rsa_start_r) begin
            state_w = S_QUERY_TX;
            dec_w   = rsa_dec;
        end else begin
            state_w = S_WAIT_CALCULATE;
        end
    end
    S_QUERY_TX: begin
        bytes_counter_w = bytes_counter_r;
        if (avm_waitrequest || !avm_readdata[6]) begin
            state_w = S_QUERY_TX;
            StartRead(STATUS_BASE);
        end else begin
            state_w = S_SEND_DATA;
            StartWrite(TX_BASE);
        end
    end
    S_SEND_DATA: begin
        if (avm_waitrequest) begin
            state_w = S_SEND_DATA;
            bytes_counter_w = bytes_counter_r;
            StartWrite(TX_BASE);
        end else begin
            if (bytes_counter_r == 30) begin
                state_w         = S_QUERY_RX;
                bytes_counter_w = 0;
                enc_w           = 0;
            end else begin
                state_w         = S_QUERY_TX;
                bytes_counter_w = bytes_counter_r + 1;
                dec_w           = dec_r << 8;
            end
        end
    end
    endcase
end

always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        instr_r <= 0;
        n_r <= 0;
        d_r <= 0;
        enc_r <= 0;
        dec_r <= 0;
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 0;
        avm_write_r <= 0;
        state_r <= S_QUERY_RX;
        bytes_counter_r <= 0;
        rsa_start_r <= 0;
    end else begin
        instr_r <= instr_w;
        n_r <= n_w;
        d_r <= d_w;
        enc_r <= enc_w;
        dec_r <= dec_w;
        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;
        state_r <= state_w;
        bytes_counter_r <= bytes_counter_w;
        rsa_start_r <= rsa_start_w;
    end
end

endmodule
