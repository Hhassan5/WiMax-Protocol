`timescale 1ns / 1ns

module prbs 
 #(
    parameter [14:0] seed = 15'b101_010_001_110_110
 )


(
    input logic clock,
    input logic load,
    input logic reset,
    input logic enable,
    input logic data_in,
    input logic ready_in, 
    input logic valid_in, // data coming in is valid
    output logic valid_out,
    output logic ready_out,
    output logic data_out1
    );

    logic [14:0] shift_register;
    logic xor1;
    logic data_out;


    // clock and asynchronous reset, synchronous seed load and clock enable inputs
    always_ff @(posedge clock or negedge reset) begin
        if (!reset) begin
            shift_register <= 'b0;
            valid_out <= 0;
            data_out1 <= 0; 
        end else if (valid_in && ready_in) begin
            if (load) begin
                shift_register <= seed;
            end else if (enable) begin
                shift_register <= {shift_register[13:0], xor1};
                valid_out <= valid_in;
                data_out1 <= data_out;
            end
        end
    end

    always_comb begin

     xor1 = 0;
     ready_out = ready_in;
     data_out = 0;

    if (ready_in && valid_in) 
     begin
            ready_out = ready_in;  // Set ready_out to 1 when both are valid
            xor1 = shift_register[13] ^ shift_register[14]; // XOR logic for PRBS
            data_out = (xor1 ^ data_in); // Output the data
       
    end

end

endmodule