`timescale 1ns / 1ps
`include "wimax_pkg.sv"
module Wimax_tb;

    // Import the package
    import wimax_pkg::*;

    // Use the package types and parameters
    clk_t clk_ref;
    load_t load;
    enable_t enable;
    clk_t clk_50;
    clk_t clk_100;
    rst_t rst_n;
    data_in_t data_in;
    ready_t ready_in;
    ready_t ready_out;
    valid_t valid_in;
    valid_t valid_out;
    iq_t Q;
    iq_t I;

    
    logic [95:0] indata_reg = 96'hAC_BC_D2_11_4D_AE_15_77_C6_DB_F4_C9;

    Wimax #(
        .Ncbps(Ncbps),
        .Ncpc(Ncpc),
        .s(s),
        .d(d),
        .seed(seed)
    ) dut (
        .load(load),
        .clk_ref(clk_ref),
        .rst_n(rst_n),
        .enable(enable),
        .data_in(data_in),
        .ready_in(ready_in),
        .valid_in(valid_in),
        .valid_out(valid_out),
        .ready_out(ready_out),
        .data_out_Q(Q),
        .data_out_I(I)
    ); 
logic [(Ncbps/2) - 1:0] randomizer_check = 96'h55_8A_C4_A5_3A_17_24_E1_63_AC_2B_F9;
logic [(Ncbps/2) - 1:0] randomizer_test;
logic [Ncbps-1:0] fec_check = 192'h28_33_E4_8D_39_20_26_D5_B6_DC_5E_4A_F4_7A_DD_29_49_4B_6C_89_15_13_48_CA;
logic [Ncbps-1:0] fec_test;
logic [Ncbps-1:0] inter_check = 192'h4b047dfa42f2a5d5f61c021a5851e9a309a24fd58086bd1e;
logic [Ncbps-1:0] inter_test;
int j = 95;
int k = 191;
int L = 191;
logic first_inter = 0;
logic first = 0;
logic first_randomizer = 0;
logic first_mod = 0;
int M = 95;
logic [(Ncbps/2) - 1 : 0] Q_check = 96'b100100101111110010001100001111111110011000000100110011011001000100010000101111110000001001110110;
logic [(Ncbps/2) - 1 : 0] I_check = 96'b001100000110111100011101110010001101001000010011001000001110110100101101001110001000100111100011;
logic [6:0] count_block1 = 0;
 logic [6:0] count_block2 = 0;

task automatic check_modulator_block(
    input logic [(Ncbps/2) - 1:0] check_data_Q,
    input logic [(Ncbps/2) - 1:0] check_data_I,
    ref int counter,
    ref logic first_flag,
    ref logic [6:0] count_block1,
    ref logic [6:0] count_block2
);
    logic [15:0] Q_check1;
    logic [15:0] I_check1;



if (counter >= 0 && counter < 96 && dut.mod.valid == 1 && !first_flag) 
    
begin
        Q_check1 = (check_data_Q[counter] == 0) ? 16'h5a82 : 16'hA57E;
        I_check1 = (check_data_I[counter] == 0) ? 16'h5a82 : 16'hA57E;

        if (Q_check1 == dut.mod.Q_val && I_check1 == dut.mod.I_val) begin
            count_block1++;
        end else begin
            $display("Test failed for modulator block 1 at : %h : %h : counter: %d", dut.mod.Q_val, Q_check1, counter);
            counter = 96;

        end

        counter--;
    end

if (counter < 0 && !first_flag) 
    
    begin
        first_flag = 1;

        if (count_block1 == 96) begin
            $display("Test succeeded for modulator block 1");
        end else begin
            $display("Test failed for modulator block 1, mismatched data count: %d", counter);
        end

        counter = 96;

    end

    if (first_flag && counter >= 0 && counter <= 96 && dut.mod.valid) 
    
    begin

if(counter != 96)

begin

        Q_check1 = (check_data_Q[counter] == 0) ? 16'h5a82 : 16'hA57E;
        I_check1 = (check_data_I[counter] == 0) ? 16'h5a82 : 16'hA57E;

        if (Q_check1 == dut.mod.Q_val && I_check1 == dut.mod.I_val) begin
            count_block2++;
        end else begin
            $display("Test failed for modulator block 2 at index: %d", counter);
            counter = 99;//exit
        end
 end
        counter--;

    end

    if (first_flag && counter < 0) 
    begin
        if (count_block2 == 96) begin
            $display("Test Passed for modulator block 2");
            counter = 99;//exit
        end else begin
            $display("Test failed for modulator block 2, mismatched data count: %d", counter);
            counter = 99;
        end
    end
endtask
      



task automatic check_prbs_block

(
    input logic [(Ncbps/2) - 1:0] check_data,
    ref logic [(Ncbps/2) - 1:0] test_data,
    ref int counter,
    ref logic first_flag
);
    if(counter>=0 && dut.randomizer.valid_out == 1 && counter<96)

    begin
        test_data[counter] = dut.randomizer.data_out1;
        counter = counter-1;
        end
        else if (counter<0)
        begin
        if(check_data == test_data && !first_flag)
        begin
        $display("Test Passed for PRBS block1, data: %h", test_data);
        first_flag = 1;
        end
        else if (!first_flag && check_data != test_data)
        begin
        $display("Test failed for PRBS block1, data: %h", test_data);
        first_flag = 1;
        end
        else if (check_data == test_data && (first_flag))
        begin
            $display("Test Passed for PRBS block2, data: %h", test_data);
            counter = 96;
        end
        else if (first_flag && (check_data != test_data))
        begin
         $display("Test failed for PRBS block2, data: %h", test_data);
         counter = 96;
        end
    end
endtask



task automatic check_fec_block

(
    input logic [Ncbps - 1:0] check_data,
    ref logic [Ncbps - 1:0] test_data,
    ref int counter,
    ref logic first_flag
);
    if(counter>=0 && dut.fec.out_valid == 1 && counter<193)

    begin
        test_data[counter] = dut.fec.out_data;
        counter = counter-1;
        end
        else if (counter<0)
        begin
        if(check_data == test_data && !first_flag)
        begin
        $display("Test Passed for fec block1, data: %h", test_data);
        first_flag = 1;
        counter = 191;
        test_data[counter] = dut.fec.out_data;
        counter = counter-1;
        end
        else if (!first_flag && check_data != test_data)
        begin
        $display("Test failed for fec block1, data: %h", test_data);
        first_flag = 1;
        counter = 191;
        test_data[counter] = dut.fec.out_data;
        counter = counter-1;
        end
        else if (check_data == test_data && (first_flag))
        begin
            $display("Test Passed for fec block2, data: %h", test_data);
            counter = 193;
        end
        else if (first_flag && (check_data != test_data))
        begin
         $display("Test failed for fec block2, data: %h", test_data);
         counter = 193;
        end
    end
endtask



task automatic check_interleaver_block

(
    input logic [Ncbps - 1:0] check_data,
    ref logic [Ncbps - 1:0] test_data,
    ref int counter,
    ref logic first_flag
);
    if(counter>=0 && dut.inter.valid == 1 && counter<193)

    begin
        test_data[counter] = dut.inter.bitstream;
        counter = counter-1;
        end
        else if (counter<0)
        begin
        if(check_data == test_data && !first_flag)
        begin
        $display("Test Passed for interleaver block1, data: %h", test_data);
        first_flag = 1;
        counter = 191;
        test_data[counter] = dut.inter.bitstream;
        counter = counter-1;
        end
        else if (!first_flag && check_data != test_data)
        begin
        $display("Test failed for interleaver block1, data: %h", test_data);
        first_flag = 1;
        counter = 191;
        test_data[counter] = dut.inter.bitstream;
        counter = counter-1;
        end
        else if (check_data == test_data && (first_flag))
        begin
            $display("Test Passed for interleaver block2, data: %h", test_data);
            counter = 193;
        end
        else if (first_flag && (check_data != test_data))
        begin
         $display("Test failed for interleaver block2, data: %h", test_data);
         counter = 193;
        end
    end
endtask





    initial begin
        clk_ref = 0;
        forever #10 clk_ref = ~clk_ref; // 50 MHz clock
    end

    // Stimulus generation
    initial begin
        $display("Starting test...");
        
        rst_n = 0;
        @(posedge clk_ref);
        rst_n = 1;
        @(posedge clk_ref);

        valid_in = 1;
        ready_in = 1;
        enable = 0;
        load = 1;
        @(posedge clk_ref);
        load = 0;
        enable = 1;

        for (int i = 95; i >= 0; i--) 
        begin
            wait (ready_out == 1);

           
            data_in = indata_reg[i];

            @(posedge clk_ref);

        end
         

       enable = 0;
       load = 1;

       @(posedge clk_ref);

       enable = 1;
       load = 0;

    for (int i = 95; i >= 0; i--) 
     begin
            wait (ready_out == 1);

            data_in = indata_reg[i];
            @(posedge clk_ref);
            

        end

        repeat(250)@(posedge clk_ref);

        $stop;
end






always @(negedge dut.clk_50) begin
    check_prbs_block(randomizer_check, randomizer_test, j, first_randomizer);
end



always @(negedge dut.clk_100) begin
    check_fec_block(fec_check, fec_test, k, first);
end


always @(negedge dut.clk_100) begin
    check_interleaver_block(inter_check, inter_test, L, first_inter);
end


always @(posedge dut.clk_50) begin
    check_modulator_block(Q_check, I_check, M, first_mod, count_block1, count_block2);
end


endmodule
