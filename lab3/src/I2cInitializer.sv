module I2cInitializer(
    input  i_rst_n,
	input  i_clk,
	input  i_start,
	output o_finished,
	output o_sclk,
	inout  o_sdat,
	output o_oen
);


parameter S_IDLE       = 0;
parameter S_CHANGE     = 1;
parameter S_READ       = 2;
parameter S_END        = 3;

localparam Reset = 24'b0011_0100_000_1111_0_0000_0000;
localparam AnalogueAudioPathControl = 24'b0011_0100_000_0100_0_0001_0101;
localparam DigitalAudioPathControl = 24'b0011_0100_000_0101_0_0000_0000;
localparam PowerDownControl = 24'b0011_0100_000_0110_0_0000_0000;
localparam DigitalAudioInterfaceFormat = 24'b0011_0100_000_0111_0_0100_0010;
localparam SamplingControl = 24'b0011_0100_000_1000_0_0001_1001;
localparam ActiveControl = 24'b0011_0100_000_1001_0_0000_0001;

logic [1:0] state_r, state_w;
logic sdat_r, sdat_w, sclk_r, sclk_w;
logic [167:0] setting_data_r, setting_data_w;
logic [3:0] bit_counter_r, bit_counter_w;
logic enable_r, enable_w, done_r, done_w;

assign o_sclk = sclk_r;
assign o_sdat = sdat_r;
assign o_oen = enable_r;
assign o_finished = done_r;

always_comb begin
    setting_data_w = setting_data_r;
    done_w = done_r;
	case(state_r)
    S_IDLE: begin
        sclk_w = 1;
        bit_counter_w = 0;
        if (i_start) begin
            sdat_w = 0;
            state_w = S_CHANGE;
            enable_w = 1;
        end else begin
            sdat_w = 1;
            state_w = S_IDLE;
            enable_w = 0;
        end
    end
    S_CHANGE: begin
        sclk_w = 0;
        if (sclk_r) begin
            state_w = S_CHANGE;
            sdat_w = sdat_r;
            bit_counter_w = bit_counter_r;
            enable_w = enable_r;
        end 
        else begin
            state_w = S_READ;
            if (bit_counter_r == 4'b1000) begin
                sdat_w = 1'bz;
                bit_counter_w = 0;
                enable_w = 0;
            end
            else begin
                sdat_w = sdat_r;
                sdat_w = setting_data_r[167];
                setting_data_w = setting_data_r << 1;
                bit_counter_w = bit_counter_r + 1;
                enable_w = enable_r;
            end
        end
    end
    S_READ: begin
        sclk_w = 1;
        bit_counter_w = bit_counter_r;
        sdat_w = sdat_r;
        if (sclk_r) begin
            if (setting_data_r==0) begin
                state_w = S_END;
                enable_w = 0;
            end else begin
                state_w = S_CHANGE;
                enable_w = 1;
            end
        end
        else begin
            state_w = S_READ;
            enable_w = enable_r;
        end
    end
    S_END: begin
        sdat_w = 1;
        sclk_w = 1;
        enable_w = enable_r;
        bit_counter_w = 0;
        if (sdat_r) begin
            state_w = S_IDLE;
            done_w = 1;
        end
        else begin
            state_w = S_END;
            done_w = 0;
        end
    end
    endcase
end

always_ff @(posedge i_clk or posedge i_rst_n) begin
	if (!i_rst_n) begin
        state_r <= S_IDLE;
        sclk_r <= 1;
        sdat_r <= 1;
        setting_data_r <= {Reset,
                        AnalogueAudioPathControl,
                        DigitalAudioPathControl,
                        PowerDownControl,
                        DigitalAudioInterfaceFormat,
                        SamplingControl,
                        ActiveControl};
        done_r <= 0;
        enable_r <= 0;
        bit_counter_r <= 0;

		
	end
	else begin
        state_r <= state_w;
        setting_data_r <= setting_data_w;
        sclk_r <= sclk_w;
        sdat_r <= sdat_w;
        done_r <= done_w;
        enable_r <= enable_w;
        bit_counter_r <= bit_counter_w;
		
	end
end


endmodule