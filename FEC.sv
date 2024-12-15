// Hassan Mohamed Hassan
// Osama Amer
// Thomas Wahid



// This code implements a Forward Error Correction (FEC) block that encodes input data to improve 
// reliability during transmission by detecting and correcting errors. The encoding process uses 
// a tailbiting convolutional technique, where the shift register is initialized with the last 
// bits of the input data for seamless encoding across data blocks.
//
// |States|: The design has three states (idle, encode, done) to manage the encoding process based on
//  input readiness and validity signals. Done state was done to accomodate for continous block streaming.
// |DPR|: The input data is stored and alternately accessed using two data banks where one is read from 
//  while the other is writing in and vice versa. They are accessed using separate counters.
// |Toggle Logic|: The encoder toggles between producing the X and Y bits at double the input data 
//  rate, ensuring compatibility with downstream systems.
// |Flow Control|: Ready/valid handshake signals ensure proper synchronization between the sender 
//  and receiver during data transmission.
// |Clock Domains|: The design operates with two clock signals (50 MHz and 100 MHz) to support 
// input and output data rates.


`timescale 1ns / 1ns

module FEC (
    input logic in_ready, // ready to send 
    input logic in_valid,
    input logic in_data,

    input logic reset,
    input logic clock_50,
    input logic clock_100,

    output logic out_valid,
    output logic out_ready, // ready to recieve 
    output logic out_data
);


logic toggle;
logic [5: 0] shift_register;
logic [5: 0] seed;
logic q_a;  // data to encode


logic [7: 0] counter_a;
logic [7: 0] counter_b;
logic write_bank;
logic read_bank;

logic flag;


parameter G1 = 7'b1111001;
parameter G2 = 7'b1011011;

logic enable; // enable encoding
logic first;

DPR DUT (
    .address_a (counter_a), // input signal
	.address_b (counter_b),
	.clock_a (clock_50), // read clock
	.clock_b (clock_50), // write clock
	.data_a (),
	.data_b (in_data),
	.rden_a (1), 
	.rden_b (),
	.wren_a (),
	.wren_b (1), 
	.q_a (q_a),
	.q_b ()
);


// define state 
typedef enum logic [1:0] {idle, encode, done} fec_state_type;

// state register
fec_state_type state_reg, state_next;

// state register
always_ff @(posedge clock_50 or negedge reset) begin
    if (!reset)
        state_reg <= idle;
    else
        state_reg <= state_next;
end

// next-state logic
always_comb begin
    case (state_reg)
        idle: begin 
            if (in_valid && in_ready ) 
                state_next = encode;
            else 
                state_next = idle;
        end
        encode: begin 
            if (in_valid == 0 || in_ready == 0) 
                state_next = idle;
            else if (counter_a == 192 || counter_a == 96 )
                state_next = done;
            else
                state_next = encode;
        end
        done: begin 
            if (in_valid == 0 || in_ready == 0) 
                state_next = idle;
            else
                state_next = encode;
        end
    endcase
end

// Moore output logic
always_comb begin
    case (state_reg)
        idle: begin
            enable = 1; // enable encoding
            if (in_ready == 1) 
                out_ready = 1'b1;
            else
                out_ready = 1'b0;
        end
        encode: begin
            enable = 1;
            out_ready = 1'b1;
        end
        done: begin
            out_ready = 1'b1;
            if(flag) 
                enable = 1;
            else
                enable = 0;
        end
    endcase
end


// 0->95 bank0
// 96->191 bank1

// write counter
always_ff @(posedge clock_50 or negedge reset) begin
    if (!reset) begin
        counter_b <= 'b0;
        flag <= 1'b0;
    end 
    else if (enable && out_ready && in_valid) begin
        if (counter_b == 96) begin
            flag <= 'b1;
            counter_b <= counter_b + 1;
        end 
        else if (counter_b < 192)
            counter_b <= counter_b + 1'b1;
        else    
            counter_b <= 'b0;
    end
end


// read counter
always_ff @(posedge clock_50 or negedge reset) begin
    if (!reset)
        counter_a <= 96;
    else if (enable == 1 && out_ready == 1 && in_valid == 1) begin 
        if (counter_a < 192)
            counter_a <= counter_a + 1'b1;
        else begin 
            counter_a <= 'b0;
        end 
    end
end

// initialize shift_register
always_ff @(posedge clock_50 or negedge reset) begin
    if (!reset)
        seed <= 'b0;
    else if (enable && in_valid) begin 
        if ((counter_b >= 90 && counter_b <= 95) || (counter_b >= 187 && counter_b <= 192))
            seed <= {in_data, seed[5:1]};
	else
	    seed <= 0;
    end
end

// FEC operations 
always_ff @(posedge clock_50 or negedge reset) begin
    if (!reset)
        shift_register <= 'b0;
    else if (enable && in_valid && state_reg == encode) begin
        if ((counter_b == 96 || counter_b == 191) && (shift_register == 'b0 || shift_register == 'b001111))
            shift_register <= seed; 
        else if (q_a == 1'b1 || q_a == 1'b0)  // block is read from DPR
            shift_register <= {q_a, shift_register [5:1]};
    end
end
 
// multiplexer of x and y
always_ff @(posedge clock_100 or negedge reset) begin
    if (!reset)
        toggle <= 1'b1;  
    else if (enable && out_ready && in_valid)
        toggle <= ~toggle; // Toggle the selection every clock cycle
end

// out_data output
always_ff @(posedge clock_100 or negedge reset) begin
    if (!reset) 
        out_data <= 1'b0;
    else if (enable && out_ready && in_valid && flag)
        out_data <= toggle ? ^({q_a, shift_register} & G1) : ^({q_a, shift_register} & G2); // output X then Y
end
always_comb begin
    if ((out_data == 'b0 || out_data == 'b1) && flag) // assert start valid data read
        out_valid = in_valid && (state_reg == encode);
    else
        out_valid = 'b0; // if x assert zero
end
endmodule
