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

logic [1:0] state_r, state_w;
logic prep_finished, m_mont_finished, t_mont_finished, finish;
logic prep_start, m_mont_start, t_mont_start;
logic [7:0]  count_r, count_w;
logic [255:0] t_r, t_w, t_prep, t_mont, m_r, m_w, m_mont;

RsaPrep rsa_prep(
	.i_clk(i_clk), 
	.i_rst(i_rst), 
	.i_start(prep_start), 
	.i_b(i_a), 
	.i_n(i_n), 
	.o_t(t_prep),
	.o_finished(prep_finished) 
);

RsaMont m_rsa_mont(
	.i_clk(i_clk), 
	.i_rst(i_rst), 
	.i_start(m_mont_start), 
	.i_a(m_r),
	.i_b(t_r), 
	.i_n(i_n),
	.o_m(m_mont),
	.o_finished(m_mont_finished)
);

RsaMont t_rsa_mont(
	.i_clk(i_clk), 
	.i_rst(i_rst), 
	.i_start(t_mont_start), 
	.i_a(t_r),
	.i_b(t_r), 
	.i_n(i_n),
	.o_m(t_mont),
	.o_finished(t_mont_finished)
);


always_comb begin
	case(state_r)
	S_IDLE: begin
		t_mont_start = 0;
		m_mont_start = 0;
		finish = 0;
		if (i_start) begin
			prep_start = 1;
			m_w = 1;
			t_w = 0;
			state_w = S_PREP;
			count_w = 0;
		end
		else begin
			prep_start = 0;
			m_w = m_r;
			t_w = t_r;
			state_w = S_IDLE;
			count_w = count_r;

		end
	end
	S_PREP: begin
		prep_start = 0;
		finish = 0;
		if (prep_finished) begin
			m_w = m_r;
			t_w = t_prep;
            t_mont_start = 1;
			m_mont_start = 1;
			state_w = S_MONT;
			count_w = count_r;
		end
		else begin
			t_w = t_r;
			m_w = m_r;
            t_mont_start = 0;
			m_mont_start = 0;
			state_w = S_PREP;
			count_w = count_r;
		end

	end
	S_MONT: begin
		t_mont_start = 0;
		m_mont_start = 0;
		prep_start = 0;
		finish = 0;
		count_w = count_r;
		if (m_mont_finished && t_mont_finished) begin
			if (i_d[count_r]) begin
				m_w = m_mont;
				t_w = t_mont;
				state_w = S_CALC;
			end else begin
				m_w = m_r;
				t_w = t_mont;
				state_w = S_CALC;
			end
		end else begin
			m_w = m_r;
			t_w = t_r;
			state_w = S_MONT;
		end
	end
	S_CALC: begin
		count_w = count_r + 1;
		prep_start = 0;
		m_w = m_r;
		t_w = t_r;
		if (count_r==255) begin
			finish = 1;	
			state_w = S_IDLE;
			t_mont_start = 0;
			m_mont_start = 0;
		
		end else begin
			finish = 0;
			state_w = S_MONT;
			t_mont_start = 1;
			m_mont_start = 1;
		end	
	end
	endcase
end

always_ff @(posedge i_clk or posedge i_rst) begin
	if (i_rst) begin
		t_mont_start <= 0;
		m_mont_start <= 0;
		o_finished <= 0;
		prep_start <= 0;
		o_a_pow_d <= 0;
		t_r <= 0;
		state_r <= S_IDLE;
		count_r <= 0;
	end
	else begin
		t_mont_start <= t_mont_start;
		m_mont_start <= m_mont_start;
		o_finished <= finish;
		prep_start <= prep_start;
		o_a_pow_d <= m_w;
		t_r <= t_w;
		state_r <= state_w;
		count_r <= count_w;
	end

end

endmodule

/////////////////////////////////////////////////////////////////////////////////

module RsaPrep (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_b, // cipher text y
	input  [255:0] i_n,
	output [255:0] o_t, // t = y * 2^256
	output         o_finished
);

localparam S_IDLE = 0;
localparam S_CALC = 1;

logic state;
logic [7:0]   count_r, count_w;
logic [255:0] n_r;
logic [255:0] t_w;

always_comb begin
	count_w = count_r + 1;
	if (o_t[255] || (o_t << 1) >= n_r) begin
		t_w = o_t << 1 - n_r;
	end	else begin
		t_w = o_t << 1;
	end
end

always_ff @(posedge i_clk or posedge i_rst) begin
	if (i_rst) begin
        o_t        <= 0;
		o_finished <= 0;
		state      <= S_IDLE;
        count_r    <= 0;
		n_r          <= 0;
    end else begin
        case (state)
		S_IDLE: begin
			if (i_start) begin
				o_t        <= i_b;
				o_finished <= 0;
				state      <= S_CALC;
				count_r    <= 0;
				n_r        <= i_n;
			end else begin
				o_t        <= o_t;
				o_finished <= o_finished;
				state      <= state;
				count_r    <= count_r;
				n_r        <= n_r;
			end
		end
		S_CALC: begin
			o_t <= t_w;
			n_r   <= n_r;
			if (count_w == 0) begin
				o_finished <= 1;
				state      <= S_IDLE;
				count_r    <= 0;
			end else begin
				o_finished <= 0;
				state      <= S_CALC;
				count_r    <= count_w;
			end
		end
		endcase
    end

end

endmodule



///////////////////////////////////////////////////////////////////////////////////////






module RsaMont (
	input          i_clk,
	input          i_rst,
	input          i_start,
	input  [255:0] i_a,
	input  [255:0] i_b, // cipher text y
	input  [255:0] i_n,
	output [255:0] o_m, // t = y * 2^256
	output         o_finished
);


localparam S_IDLE = 0;
localparam S_CALC = 1;

logic state_r, state_w;
logic [7:0]   count_r, count_w;
logic [255:0] n_r, n_w;
logic [255:0] m_r, m_w, m_final;
wire finished_w;

assign o_m = m_r;

always_comb begin
	case(state_r)
	S_IDLE: begin
		if (i_start) begin
			m_w        = 0;
			m_final    = 0;
            finished_w = 0;
			state_w    = S_CALC;
			count_w    = 0;
			n_w        = i_n;
		end
		else begin
			m_w        = m_r;
			m_final    = m_r;
            finished_w = o_finished;
			state_w    = state_r;
			count_w    = count_r;
			n_w        = n_r;
		end
	end
	S_CALC: begin
		count_w = count_r + 1;
		n_w = n_r;
		if (i_a[count_r]) begin
			if (m_r[0] ^ i_b[0]) begin
				m_w = (m_r + i_b + n_r) >> 1;
			end else begin
				m_w = (m_r + i_b) >> 1;
			end
		end else begin
			if (m_r[0]) begin
				m_w = (m_r + n_r) >> 1;
			end else begin
				m_w = m_r >> 1;
			end
		end

		if (count_r == 255) begin
			state_w = S_IDLE;
			finished_w = 1;
			if (m_w >= n_r) begin
				m_final = m_w - n_r;
			end else begin
				m_final = m_w;
			end
		end
		else begin
			state_w = S_CALC;
			m_final = m_w;
			finished_w = 0;
		end
	end
	endcase
end



always_ff @(posedge i_clk or posedge i_rst) begin
	if (i_rst) begin
        m_r        <= 0;
		o_finished <= 0;
		state_r    <= S_IDLE;
        count_r    <= 0;
		n_r        <= 0;
	end
	else begin
		m_r        <= m_final;
		o_finished <= finished_w;
		state_r    <= state_w;
        count_r    <= count_w;
		n_r        <= n_w;

	end

end



endmodule