module tom_interleaver 
    #(
    parameter Ncbps = 192,
    parameter Ncpc = 2,
    parameter s = Ncpc / 2,
    parameter d = 16
    )
    (
      input logic valid_in,
      input logic ready_in,
      input logic clk,
      input logic rst_n,
      input logic serial, //ind_data
      output logic ready_out,
      output logic bitstream, //out_data
      output logic valid
    );

logic [8:0] address_a;
logic [8:0] address_b;
logic q_b; // read port

// Dual-port RAM instance
dual_port dpr(
    .address_a(address_a),
    .address_b(address_b),
    .clock(clk),
    .data_a(serial),
    .data_b(1'b0),
    .rden_a(1'b0),
    .rden_b(1'b1),
    .wren_a(1'b1),
    .wren_b(1'b0),
    .q_a(),
    .q_b(q_b)
);

typedef enum logic [1:0] {idle, transmit_buff0, transmit_buff1} states_t;
states_t current_state, next_state;

logic [7:0] count_transmit_buff0;
logic [7:0] count_transmit_buff1;
logic [7:0] bit_count_init; //counter for idle state

function [7:0] first_permutation(input [7:0] k);
    begin
        first_permutation = (Ncbps / d) * (k % d) + (k / d);
    end
endfunction


function [7:0] second_permutation(input [7:0] m);
    begin
        second_permutation = s * (m / s) + ((m + Ncbps - ((d * m) / Ncbps)) % s);
    end
endfunction
  
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        current_state <= idle;
    else
        current_state <= next_state;
end

// Next state logic
always_comb begin
    case (current_state)
        idle: begin
            ready_out = 1;
            if (bit_count_init == Ncbps)
                next_state = transmit_buff0;
            else
                next_state = idle;
        end
        transmit_buff0: begin
            ready_out = ready_in;
            if (count_transmit_buff0 == Ncbps - 1) 
                next_state = transmit_buff1;
            else
                next_state = transmit_buff0;
        end
        transmit_buff1: begin
            ready_out = ready_in;
            if (count_transmit_buff1 == Ncbps - 1) 
                next_state = transmit_buff0;
            else
                next_state = transmit_buff1;
        end
    endcase
end

always_comb begin
	address_a = 0;
	address_b = Ncbps + 1;
    case (current_state)
        idle: begin
            if (valid_in && ready_in) begin
                if (bit_count_init < Ncbps) begin
                    address_a = second_permutation(first_permutation(bit_count_init));
                    address_b = Ncbps + 1;  // The default initialization of address_b in idle
                end
                else if(bit_count_init == Ncbps) begin
                    address_a = second_permutation(first_permutation(0)) + Ncbps;
                    address_b = 0;  //
                end
            end
        end
        transmit_buff0: begin
            if (valid_in && ready_in) begin   
                if (count_transmit_buff0 < Ncbps - 1) begin
                    address_a = second_permutation(first_permutation(count_transmit_buff0 + 1)) + Ncbps;  // Update address_b
                    address_b = count_transmit_buff0 + 1;
                end
                else if (count_transmit_buff0 == Ncbps - 1) begin
                    address_a = second_permutation(first_permutation(0)) ;
                    address_b = Ncbps;
                end
            end
        end
        transmit_buff1: begin
            if (valid_in && ready_in) begin
                if(count_transmit_buff1 < Ncbps - 1) begin
                    address_a = second_permutation(first_permutation(count_transmit_buff1 + 1));
                    address_b = count_transmit_buff1 + Ncbps + 1;
                end              
                else if (count_transmit_buff1 == Ncbps - 1) begin
                    address_a = second_permutation(first_permutation(0)) + Ncbps;
                    address_b = 0;
                end
            end
        end
    endcase
end

// output bitstream
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        bitstream <= 0;
        valid <= 0; 
    end 
    else if (current_state == transmit_buff0 || current_state == transmit_buff1) begin
        bitstream <= q_b;
        valid <= valid_in;
    end
end

// Counters always block
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count_transmit_buff0 <= 0;
        count_transmit_buff1 <= 0;
        bit_count_init <= 0;
    end 
    else begin
        case (current_state)
            idle: begin
                if (valid_in && ready_in) begin
                    if (bit_count_init < Ncbps)
                        bit_count_init <= bit_count_init + 1'b1;
                    else
                        bit_count_init <= 0;
                end
            end
            transmit_buff0: begin
                if (valid_in && ready_in) begin
                    if (count_transmit_buff0 < Ncbps - 1)
                        count_transmit_buff0 <= count_transmit_buff0 + 1'b1;
                    else
                        count_transmit_buff0 <= 0;
                end
            end
            transmit_buff1: begin
                if (valid_in && ready_in) begin
                    if (count_transmit_buff1 < Ncbps - 1)
                        count_transmit_buff1 <= count_transmit_buff1 + 1'b1;
                    else
                        count_transmit_buff1 <= 0;
                end
            end
        endcase
    end
end



endmodule
