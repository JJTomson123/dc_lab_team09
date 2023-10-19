module Top (
		input             i_clk,
		input             i_rst_n,
		input             i_start,
		input             i_capture,
		input		      i_scroll,
		input             i_dir,
		output reg  [3:0] o_random_out,
		output reg [3:0] o_result
	);

	// ===== States =====
	parameter S_IDLE = 1'b0;
	parameter S_PROC = 1'b1;

	// ===== Registers & Wires =====
	reg            state_c;
	logic          state_n;
	wire [1:0] lfsr_next;
	wire       lfsr_set;
	wire [3:0] lfsr_rand;
	reg [1:0]  index;
	reg [3:0]  results[3:0];

	// ===== Submoddules =====
	lfsr random_number_generation(
        .clk      (i_clk),
        .rst_n    (i_rst_n),
		.st       (lfsr_set),
        .nxt      (lfsr_next[0]),
        .num   	  (lfsr_rand)
    );

	slow_clock lfsr_trigger(
		.clk      (i_clk),
        .rst_n    (i_rst_n),
		.st       (i_start),
		.set_seed (lfsr_set),
		.sig      (lfsr_next)
	);

	// ===== Combinational Circuits =====
	always_comb begin
		case (state_c)
		S_IDLE: state_n = S_IDLE;
		S_PROC: begin
			if (lfsr_next[1] == 1) state_n = S_IDLE;
			else state_n = S_PROC;
		end
		endcase

		o_result = results[index];
	end

	// ===== Sequential Circuits =====
	always_ff @(posedge i_clk or negedge i_rst_n) begin
		// reset
		if (!i_rst_n) begin
			o_random_out <= 4'd0;
			state_c      <= S_IDLE;
			index        <= 2'b0;
			results      <= '{4{0}};
		end
		else begin 
			if (i_start) begin
				o_random_out <= lfsr_rand;
				state_c      <= S_PROC;
			end
			else begin
				o_random_out <= lfsr_rand;
				state_c      <= state_n;
			end

			if (i_capture) begin
				results <= '{results[2], results[1], results[0], lfsr_rand};
			end
			else begin
				results <= results;
			end

			if (i_scroll) begin
				if (i_dir) begin
					index <= index + 1;
				end
				else begin
					index <= index - 1;
				end
			end
			else begin
				index <= index;
			end

		end
	end

endmodule

module lfsr (
		input             clk,
		input             rst_n,
		input             st,
		input             nxt,
		output wire [3:0] num
	);
    
	reg  [15:0] seed_c;
	wire [15:0] seed_n;
	reg  [15:0] rand_c;
	wire [15:0] rand_n;
	
	assign num = rand_c[3:0];
	assign seed_n = seed_c + 1;
	assign rand_n = {rand_c[14:0], (rand_c[15] ^ rand_c[13]) ^ (rand_c[12] ^ rand_c[10])};

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			seed_c <= 0;
			rand_c <= 0;
		end
		else begin
			seed_c <= seed_n;
			if (st) begin
				rand_c <= seed_n;
			end
			else if (nxt) begin
				rand_c <= rand_n;
			end
			else begin
				rand_c <= rand_c;
			end
		end
	end
    
endmodule

module slow_clock (
		input           clk,
		input           rst_n,
		input           st,
		output reg      set_seed,
		output reg[1:0] sig
	);
    
	reg         is_running;
	reg  [31:0] count_c;
	wire [31:0] count_n;
	reg  [3:0]  trig_count;
	wire [3:0]  trig_count_n;
	wire [31:0] count_lim;
	
	assign count_n = count_c + 1;
	assign trig_count_n = trig_count + 1;
	assign count_lim = trig_count_n << 22;

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			set_seed   <= 0;
			sig        <= 2'b00;
			is_running <= 0;
			count_c    <= 0;
			trig_count <= 0;
		end
		else if (is_running) begin
			set_seed <= 0;
			if (count_n >= count_lim) begin
				case (trig_count)
				0, 1, 2, 3, 4, 5, 6: begin
					sig        <= 2'b01;
					is_running <= 1;
					count_c    <= 0;
					trig_count <= trig_count_n;
				end
				7: begin
					sig        <= 2'b11;
					is_running <= 0;
					count_c    <= 0;
					trig_count <= 0;
				end
				endcase
			end
			else begin
				sig        <= 2'b00;
				is_running <= 1;
				count_c    <= count_n;
				trig_count <= trig_count;
			end
		end
		else if (st) begin
			set_seed   <= 1;
			sig        <= 2'b00;
			is_running <= 1;
			count_c    <= 0;
			trig_count <= 0;
		end
		else begin
			set_seed   <= 0;
			sig        <= 2'b00;
			is_running <= is_running;
			count_c    <= count_c;
			trig_count <= trig_count;
		end
	end
    
endmodule