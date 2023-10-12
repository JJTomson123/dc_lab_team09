module Rsa256Core (
    input          i_clk,
    input          i_rst,
    input          i_start,
    input  [255:0] i_a, // cipher text y
    input  [255:0] i_d, // private key
    input  [255:0] i_n,
    output [255:0] o_a_pow_d, // plain text x
    output         o_finished
);

// operations for RSA256 decryption
// namely, the Montgomery algorithm
localparam S_IDLE = 2'b00;
localparam S_PREP = 2'b01;
localparam S_MONT = 2'b10;
localparam S_CALC = 2'b11;

logic [1:0]   state_r, state_w;
logic         prep_rdy, m_mont_rdy, t_mont_rdy;
logic         prep_start, prep_start_w, m_mont_start, m_mont_start_w, t_mont_start, t_mont_start_w;
logic [7:0]   count_r, count_w;
logic [255:0] y_r, y_w, n_r, n_w, t_r, t_w, t_prep, t_mont, m_r, m_w, m_mont;

assign o_a_pow_d  = m_r;
assign o_finished = (state_r == S_IDLE);

RsaPrep rsa_prep(
    .i_clk(i_clk), 
    .i_rst(i_rst), 
    .i_start(prep_start), 
    .i_b(y_r), 
    .i_n(n_r), 
    .o_t(t_prep),
    .o_rdy(prep_rdy) 
);

RsaMont m_rsa_mont(
    .i_clk(i_clk), 
    .i_rst(i_rst), 
    .i_start(m_mont_start), 
    .i_a(m_r),
    .i_b(t_r), 
    .i_n(n_r),
    .o_m(m_mont),
    .o_rdy(m_mont_rdy)
);

RsaMont t_rsa_mont(
    .i_clk(i_clk), 
    .i_rst(i_rst), 
    .i_start(t_mont_start), 
    .i_a(t_r),
    .i_b(t_r), 
    .i_n(n_r),
    .o_m(t_mont),
    .o_rdy(t_mont_rdy)
);

always_comb begin
    case(state_r)
    S_IDLE: begin
        t_mont_start_w = 0;
        m_mont_start_w = 0;
        count_w        = 0;
        t_w            = 0;
        if (i_start) begin
            state_w      = S_PREP;
            prep_start_w = 1;
            y_w          = i_a;
            n_w          = i_n;
            m_w          = 1;
        end
        else begin
            state_w      = S_IDLE;
            prep_start_w = 0;
            y_w          = 0;
            n_w          = 0;
            m_w          = m_r;
        end
    end
    S_PREP: begin
        prep_start_w = 0;
        count_w      = count_r;
        y_w          = y_r;
        n_w          = n_r;
        m_w          = m_r;
        if (prep_rdy && !prep_start) begin
            state_w        = S_MONT;
            t_mont_start_w = 1;
            m_mont_start_w = 1;
            t_w            = t_prep;
        end
        else begin
            state_w        = S_PREP;
            t_mont_start_w = 0;
            m_mont_start_w = 0;
            t_w            = t_r;
        end
    end
    S_MONT: begin
        prep_start_w   = 0;
        t_mont_start_w = 0;
        m_mont_start_w = 0;
        count_w        = count_r;
        y_w            = y_r;
        n_w            = n_r;
        if ((m_mont_rdy && !m_mont_start) && (t_mont_rdy && !t_mont_start)) begin
            state_w = S_CALC;
            t_w     = t_mont;
            m_w     = (i_d[count_r]) ? m_mont : m_r;
        end else begin
            state_w = S_MONT;
            t_w     = t_r;
            m_w     = m_r;
        end
    end
    S_CALC: begin
        prep_start_w = 0;
        count_w      = count_r + 1;
        y_w          = y_r;
        n_w          = n_r;
        t_w          = t_r;
        m_w          = m_r;
        if (count_r == 255) begin
            state_w        = S_IDLE;
            t_mont_start_w = 0;
            m_mont_start_w = 0;
        end else begin
            state_w        = S_MONT;
            t_mont_start_w = 1;
            m_mont_start_w = 1;
        end    
    end
    endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        state_r      <= S_IDLE;
        prep_start   <= 0;
        t_mont_start <= 0;
        m_mont_start <= 0;
        count_r      <= 0;
        y_r          <= 0;
        n_r          <= 0;
        t_r          <= 0;
        m_r          <= 0;
    end
    else begin
        state_r      <= state_w;
        prep_start   <= prep_start_w;
        t_mont_start <= t_mont_start_w;
        m_mont_start <= m_mont_start_w;
        count_r      <= count_w;
        y_r          <= y_w;
        n_r          <= n_w;
        t_r          <= t_w;
        m_r          <= m_w;
    end
end

endmodule


/////////////////////////////////////////////////////////////////////////////////


module RsaPrep (
    input              i_clk,
    input              i_rst,
    input              i_start,
    input      [255:0] i_b, // cipher text y
    input      [255:0] i_n,
    output reg [255:0] o_t, // t = y * 2^256
    output             o_rdy
);

localparam S_IDLE = 1'b0;
localparam S_CALC = 1'b1;

logic         state_r, state_w;
logic [7:0]   count_r, count_w;
logic [255:0] n_r, n_w, t_w;

assign o_rdy = (state_r == S_IDLE);

always_comb begin
    case (state_r)
    S_IDLE: begin
        count_w = 0;
        if (i_start) begin
            state_w    = S_CALC;
            n_w        = i_n;
            t_w        = i_b;
        end else begin
            state_w    = S_IDLE;
            n_w        = 0;
            t_w        = o_t;
        end
    end
    S_CALC: begin
        state_w = (count_r == 255) ? S_IDLE : S_CALC;
        count_w = count_r + 1;
        n_w     = n_r;
        t_w     = (o_t[255] || (o_t << 1) >= n_r) ? (o_t << 1) - n_r : o_t << 1; // Is 2*t >= n?
    end
    endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        state_r    <= S_IDLE;
        count_r    <= 0;
        n_r        <= 0;
        o_t        <= 0;
    end else begin
        state_r    <= state_w;
        count_r    <= count_w;
        n_r        <= n_w;
        o_t        <= t_w;
    end
end

endmodule


/////////////////////////////////////////////////////////////////////////////////


module RsaMont (
    input              i_clk,
    input              i_rst,
    input              i_start,
    input      [255:0] i_a,
    input      [255:0] i_b, // cipher text y
    input      [255:0] i_n,
    output reg [255:0] o_m, // t = y * 2^256
    output             o_rdy
);

localparam S_IDLE = 2'b00;
localparam S_CALC = 2'b01;
localparam S_UPDT = 2'b10;

logic [1:0]   state_r, state_w;
logic [7:0]   count_r, count_w;
logic [255:0] n_r, n_w;
logic [255:0] m_w;

assign o_rdy = (state_r == S_IDLE);

always_comb begin
    case(state_r)
    S_IDLE: begin
        count_w     = 0;
        if (i_start) begin
            state_w    = S_CALC;
            n_w        = i_n;
            m_w        = 0;
        end else begin
            state_w    = S_IDLE;
            n_w        = 0;
            m_w        = o_m;
        end
    end
    S_CALC: begin
        n_w = n_r;
        case ({i_a[count_r], o_m[0], i_b[0], o_m > -i_b})
        4'b0000, 4'b0001, 4'b0010, 4'b0011: m_w = {1'b0, o_m[255:1]}; // a[i] = 0, m even
        4'b0100, 4'b0101, 4'b0110, 4'b0111: m_w = ({1'b0, o_m} + n_r) >> 1; // a[i] = 0, m odd
        4'b1000, 4'b1001, 4'b1110, 4'b1111: m_w = ({1'b0, o_m} + i_b) >> 1; // a[i] = 1, m + b even
        4'b1100, 4'b1010: m_w = ({1'b0, o_m} + i_b + n_r) >> 1; // a[i] = 1, m + b odd and < 2^256
        4'b1101, 4'b1011: m_w = ({1'b0, o_m} + i_b - n_r) >> 1; // a[i] = 1, m + b odd and >= 2^256
        endcase
        if (count_r == 255) begin
            state_w = S_UPDT;
            count_w = 0;
        end else begin
            state_w = S_CALC;
            count_w = count_r + 1;
        end
    end
    S_UPDT: begin
        state_w = S_IDLE;
        count_w = 0;
        n_w     = 0;
        if (o_m >= n_r) m_w = o_m - n_r;
        else            m_w = o_m;
    end
    endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
    if (i_rst) begin
        state_r    <= S_IDLE;
        count_r    <= 0;
        n_r        <= 0;
        o_m        <= 0;
    end
    else begin
        state_r    <= state_w;
        count_r    <= count_w;
        n_r        <= n_w;
        o_m        <= m_w;
    end
end

endmodule