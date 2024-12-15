module Wimax #(
        parameter Ncbps = 8'd192,
        parameter Ncpc = 8'd2,
        parameter s = Ncpc / 2,
        parameter d = 8'd16,
        parameter [14:0] seed  = 15'b101_010_001_110_110
    )
    (
        input logic load,
        input logic clk_ref,
        input logic rst_n,
        input logic enable,
        input logic data_in, 
        input logic ready_in,
        input logic valid_in,
        output valid_in_fec_out_PRBS1,
        output in_fec_out_PRBS1,
        output valid_in_interleaver_out_fec1,
        output fec_out1,
        output valid_in_moudlator_out_interleaver1,
        output bitstream1, 
        output logic ready_out,
        output logic valid_out,
        output [15:0] data_out_Q,
        output [15:0] data_out_I,
        output clk_fast
    );

    logic valid_in_fec_out_PRBS;
    logic in_fec_out_PRBS;
    logic valid_in_interleaver_out_fec;
    logic fec_out;
    logic ready_in_fec_out_interleaver;
    logic ready_in_interleaver_out_modulator;
    logic valid_in_inter;
    logic bitstream;
    logic in_data;
    logic valid_in_modulator_out_interleaver;
    logic ready_in_PRBS_out_fec;
    logic clk_100;


  assign valid_in_fec_out_PRBS1 = valid_in_fec_out_PRBS;
  assign in_fec_out_PRBS1 = in_fec_out_PRBS;
  assign valid_in_interleaver_out_fec1 = valid_in_interleaver_out_fec;
  assign fec_out1 = fec_out;
  assign valid_in_moudlator_out_interleaver1 = valid_in_modulator_out_interleaver;
  assign bitstream1 = bitstream;
  assign clk_fast = clk_100;

    modulator mod (
        .clk(clk_100),
        .rst_n(locked),
        .serial_in(bitstream),
        .ready_in(ready_in),
        .valid(valid_out),
        .ready_out(ready_in_interleaver_out_modulator),
        .I_val(data_out_I),
        .Q_val(data_out_Q),
        .valid_in(valid_in_modulator_out_interleaver)
    );

    tom_interleaver #(
        .Ncbps(Ncbps),
        .Ncpc(Ncpc),
        .s(s),
        .d(d)
    ) 
    inter (
        .clk(clk_100),
        .rst_n(locked),
        .serial(fec_out),
        .valid_in(valid_in_interleaver_out_fec),
        .ready_in(ready_in_interleaver_out_modulator),
        .ready_out(ready_in_fec_out_interleaver),
        .bitstream(bitstream),
        .valid(valid_in_modulator_out_interleaver)
    );

    FEC fec (
        .in_ready(ready_in_fec_out_interleaver), // ready to send 
        .in_valid(valid_in_fec_out_PRBS),
        .in_data(in_fec_out_PRBS),
        .reset(locked),
        .clock_50(clk_50),
        .clock_100(clk_100),
        .out_valid(valid_in_interleaver_out_fec),
        .out_ready(ready_in_PRBS_out_fec), // ready to recieve 
        .out_data(fec_out)
    );

    prbs #(
        .seed(seed)
    ) randomizer(
        .clock(clk_50),
        .load(load),
        .reset(locked),
        .enable(enable),
        .data_in(data_in),
        .ready_in(ready_in_PRBS_out_fec),
        .valid_in(valid_in), // data coming in is valid
        .valid_out(valid_in_fec_out_PRBS),
        .ready_out(ready_out),
        .data_out1(in_fec_out_PRBS)
    );

    
    PLL DUT2 (
        .refclk (clk_ref),  
        .rst (!rst_n),      
        .outclk_0 (clk_100),
        .outclk_1 (clk_50),
        .locked (locked)    //  Don't work until locked signal asserted
    );

endmodule