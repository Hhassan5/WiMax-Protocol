// Hassan Mohamed Hassan
// Osama Amer
// Thomas Wahid


// This block implements a QPSK modulator, which maps input serial data into two orthogonal components, I (in-phase) and Q (quadrature-phase), for transmission.
//
// |QPSK Mapping|: 
// - Maps 2-bit input data into predefined 16-bit fixed-point values for the I and Q components. 
// - The values correspond to the four QPSK constellation points: (00, 01, 10, 11).
// - Each point represents a phase shift combination for the modulated signal.
// |Bit Buffering|: 
// - A 2-bit shift register accumulates incoming serial data to form bit pairs for QPSK mapping.
// |Timing and Control|: 
// - A counter (`bit_count`) ensures that two bits are buffered before generating output.
// - A `valid` signal is asserted once the buffer is ready, ensuring proper data flow downstream.
// |Output Update|: 
// - Outputs are updated only when valid input data is received and the bit buffer is full.
// - Previous I and Q values are held until new valid data is ready, providing smooth transitions.
// |Flow Control|: 
// - Implements a ready/valid handshake mechanism to synchronize with upstream and downstream modules.
// |Pre-Defined Constants|:
// - I and Q values are scaled and normalized for accurate representation of the QPSK constellation.


module modulator 
  (
    input logic serial_in,
    input logic clk,
    input logic rst_n,
    input logic ready_in,
    input logic valid_in,
    output logic valid,
    output logic ready_out,
    output logic [15:0] I_val, Q_val

);

logic [1:0] bit_buffer;
logic [1:0] bit_count;
logic [15:0] I_val1, Q_val1;
logic [15:0] I_val2, Q_val2;
logic [1:0] first;


always_comb begin
  valid = 0;
  Q_val2 = 0;
  Q_val = Q_val1;
  I_val = I_val1;
  I_val2 = 0; 


if (valid_in && ready_in)
        begin
        case (bit_buffer)
            2'b00: begin
                Q_val2 = 16'h5a82; 
                I_val2 = 16'h5a82;
            end
            2'b01: begin

                I_val2 = 16'h5a82;
                Q_val2 = 16'hA57E;
            end
            2'b10: begin
                I_val2 = 16'hA57E;
                Q_val2 = 16'h5a82;

            end
            2'b11: begin
                Q_val2 = 16'hA57E;
                I_val2 = 16'hA57E;
            end
            default: begin
                Q_val2 = 16'd0;
                I_val2 = 16'd0;
            end
        endcase
              
              valid = (first == 2); 
              
              
     if (bit_count == 2) 
      
      begin
         Q_val = Q_val2;
         I_val = I_val2; // display the new value 
        
      end

    else 
      
    begin

        Q_val = Q_val1; 
        I_val = I_val1; // display the old value in the output 
        
     end


   end
   
end

  
 always_ff @(posedge clk or negedge rst_n)
   
   begin
     
    if (!rst_n) 
      
      begin
        bit_buffer <= 2'b0;
        ready_out <= 1'b0;
        bit_count <= 2'b0;
        first <=0;
        I_val1 <= 0;
        Q_val1 <= 0;
    end 
   
     
     
   else 
     
     begin
         ready_out <= 1;
         bit_buffer <= {bit_buffer[0], serial_in}; // two bit shift left register
       
       if(bit_count < 2 && valid_in && ready_in)
         
         begin
           
           bit_count <= bit_count + 1;
           
         end
       
       
       else if (valid_in && ready_in)
         begin
         bit_count <= 1;
         I_val1 <= I_val;
         Q_val1 <= Q_val;
         end

        if ((first < 2) && valid_in && ready_in) // make sure that valid is one once the buffer is filled with correct data
         
         begin
           
        first <= first + 1;
           
         end
       
       
     end
         
end
  
  
endmodule
