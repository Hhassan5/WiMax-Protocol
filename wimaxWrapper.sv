module wimaxWrapper #(
    parameter [0:95] data_in_wrap = 96'hAC_BC_D2_11_4D_AE_15_77_C6_DB_F4_C9,
    parameter [0:95] prbs_data = 96'h55_8A_C4_A5_3A_17_24_E1_63_AC_2B_F9,
    parameter [0:191] fec_data = 192'h28_33_E4_8D_39_20_26_D5_B6_DC_5E_4A_F4_7A_DD_29_49_4B_6C_89_15_13_48_CA,
    parameter [0:191] inter_data = 192'h4b_04_7d_fa_42_f2_a5_d5_f6_1c_02_1a_58_51_e9_a3_09_a2_4f_d5_80_86_bd_1e,
    parameter [0:95] Q_data_mod = 96'b100100101111110010001100001111111110011000000100110011011001000100010000101111110000001001110110,
    parameter [0:95] I_data_mod = 96'b001100000110111100011101110010001101001000010011001000001110110100101101001110001000100111100011
)(
    input logic clk_ref,
    input logic rst_n,
    output logic prbs_correct,
    output logic fec_correct,
    output logic inter_correct,
    output logic mod_correct
);

logic load;
logic enable;
logic data_in;
logic ready_in;
logic valid_in;
logic ready_out;
logic valid_out_mod;
logic valid_out_PRBS;
logic data_out_PRBS;
logic valid_out_fec;
logic fec_out;
logic clk_50;
logic clk_100;
logic valid_out_interleaver;
logic data_out_interleaver;
logic [15:0] data_out_Q;
logic [15:0] data_out_I;

Wimax #(
    .Ncbps(8'd192),
    .Ncpc(8'd2),
    .s(8'd1), 
    .d(8'd16),
    .seed(15'b101_010_001_110_110)
) wimax_inst (
    .load(load),
    .clk_ref(clk_ref),
    .rst_n(rst_n),
    .enable(enable),
    .data_in(data_in),
    .ready_in(ready_in),
    .valid_in(valid_in),
    .valid_in_fec_out_PRBS1(valid_out_PRBS),
    .in_fec_out_PRBS1(data_out_PRBS),
    .valid_in_interleaver_out_fec1(valid_out_fec),
    .fec_out1(fec_out),
    .valid_in_moudlator_out_interleaver1(valid_out_interleaver),
    .bitstream1(data_out_interleaver),
    .ready_out(ready_out),
    .valid_out(valid_out_mod),
    .data_out_Q(data_out_Q),
    .data_out_I(data_out_I),
    .clk_fast (clk_100)
);

logic [7:0] data_counter;
logic [7:0] prbs_counter;
logic [7:0] fec_counter;
logic [7:0] inter_counter;
logic [7:0] mod_counter;
logic [1:0] bit_counter;
logic I_sign;
logic Q_sign;
logic counter;

assign valid_in = 1;
assign ready_in = 1;

// in_data to wrapper 
assign data_in = data_in_wrap [data_counter];       

assign Q_sign = (data_out_Q == 16'h5a82) ? 0 : (data_out_Q == 16'hA57E) ? 1 : 0;
assign I_sign = (data_out_I == 16'h5a82) ? 0 : (data_out_I == 16'hA57E) ? 1 : 0;


// in_data counter
always_ff @(posedge clk_ref or negedge rst_n)
 begin
    if(!rst_n)
        data_counter <= 0;
    else if (enable) begin
        if (data_counter == 95)
            data_counter <= 'b0;
        else
            data_counter <= data_counter + 1;
    end
end

always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n) begin
        prbs_correct <= 0;
        mod_correct <= 0;
    end 

    else begin

        if (valid_out_PRBS)
            prbs_correct <= prbs_data[prbs_counter] == data_out_PRBS;

        if (valid_out_mod) begin
	    if (bit_counter == 2)
            mod_correct <= (I_sign == I_data_mod[mod_counter]) & (Q_sign == Q_data_mod[mod_counter]);	
	end
	end
end


always_ff @(posedge clk_100 or negedge rst_n) begin
    if (!rst_n) begin
        fec_correct <= 0;
        inter_correct <= 0;
    end 

    else begin

        if (valid_out_fec)
            fec_correct <= (fec_data[fec_counter] == fec_out);

        if (valid_out_interleaver) begin
            inter_correct <= (inter_data[inter_counter] == data_out_interleaver);
			
	end
		
	end
end



always_ff @(posedge clk_ref or negedge rst_n) begin
    if (!rst_n)
        mod_counter <= 0;
    else if (valid_out_mod) begin
        if (mod_counter == 95)
            mod_counter <= 0;
        else
            mod_counter <= mod_counter + 1;
    end
end

always_ff @(posedge clk_100 or negedge rst_n) begin
    if(!rst_n)
        inter_counter <= 0;
    else if (valid_out_interleaver) begin
        if (inter_counter == 191)
            inter_counter <= 0;
        else
            inter_counter <= inter_counter + 1;
    end
end


always_ff @(posedge clk_100 or negedge rst_n) begin
    if(!rst_n)
        bit_counter <= 0;
    else if (valid_out_mod) begin
        if (bit_counter == 2)
            bit_counter <= 0;
        else
            bit_counter <= bit_counter + 1;
    end
end

always_ff @(posedge clk_100 or negedge rst_n) begin
    if(!rst_n)
        fec_counter <= 0;
    else if (valid_out_fec) begin
        if (fec_counter == 191)
            fec_counter <= 0;
        else
            fec_counter <= fec_counter + 1;
    end
end

always_ff @(posedge clk_ref or negedge rst_n) begin
    if(!rst_n)
        prbs_counter <= 0;
    else if (valid_out_PRBS) begin
        if (prbs_counter == 96)
            prbs_counter <= 'b0;
        else
            prbs_counter <= prbs_counter + 1;
    end
end



always_ff @ (posedge clk_ref or negedge rst_n) 
begin
    if(!rst_n) begin
        counter <= 0;
        load <= 0;
        enable <= 0;
    end
    else begin
        if (counter == 0) begin
            load <= 1;
            enable <= 'b0;
            counter <= counter + 1;
        end
        else begin
            load <= 0;
            enable <= 1;
            if (data_counter == 94) begin
                counter <= 'b0;
            end
        end
    end
end
endmodule
