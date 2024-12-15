`timescale 1ns / 1ns

module wimaxWrapper_tb;

    logic clk_ref;
    logic rst_n;
    logic prbs_correct;
    logic fec_correct;
    logic inter_correct;
    logic mod_correct;

    parameter CLOCK_PERIOD = 20;
    // clock Generation
    always #(CLOCK_PERIOD/2) clk_ref =~clk_ref;


        wimaxWrapper #(
            .data_in_wrap(96'hAC_BC_D2_11_4D_AE_15_77_C6_DB_F4_C9),
            .prbs_data(96'h55_8A_C4_A5_3A_17_24_E1_63_AC_2B_F9),
            .fec_data(192'h28_33_E4_8D_39_20_26_D5_B6_DC_5E_4A_F4_7A_DD_29_49_4B_6C_89_15_13_48_CA),
            .inter_data(192'h4b047dfa42f2a5d5f61c021a5851e9a309a24fd58086bd1e),
            .Q_data_mod(96'b100100101111110010001100001111111110011000000100110011011001000100010000101111110000001001110110),
            .I_data_mod(96'b001100000110111100011101110010001101001000010011001000001110110100101101001110001000100111100011)
        ) u_wimaxWrapper (
            .clk_ref(clk_ref),
            .rst_n(rst_n),
            .prbs_correct(prbs_correct),
            .fec_correct(fec_correct),
            .inter_correct(inter_correct),
            .mod_correct(mod_correct)
        );



    initial 
    begin
        clk_ref = 0;
        rst_n = 0;
        @(posedge clk_ref);
        rst_n = 1;
        repeat(450) @(posedge clk_ref);

        $finish;
    end

endmodule