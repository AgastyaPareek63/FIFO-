`timescale 1ns/1ps

module width_converter #(
    parameter IN_WIDTH = 8,// width of input
    parameter OUT_WIDTH = 16// width of combined output
)(
    input  wire clk,
    input  wire rst,

    input  wire valid_in,// valid input data
    input  wire [IN_WIDTH-1:0] data_in,

    output reg valid_out,// valid output data
    output reg [OUT_WIDTH-1:0] data_out
);

// Internal Registers

reg [IN_WIDTH-1:0] buffer; // stores the first input word while waiting for the second word.
reg toggle;// 0 -> waiting for the first input word
           // 1 -> first word received, waiting for the second

// Packing Logic

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        // Clear all registers 
        buffer <= 0;
        toggle <= 0;
        data_out <= 0;
        valid_out <= 0;
    end
    else
    begin
        valid_out <= 0;

        if(valid_in)
        begin
            // Store the first input word in the buffer and wait for the next valid input word.
            if(toggle == 0)
            begin
                buffer <= data_in;
                toggle <= 1;
            end
            else
             // Combine the new input with the previously stored word.
             // For 8-bit inputs:
             //     data_out = {second_word, first_word}
            begin
                data_out <= {data_in, buffer};
                valid_out <= 1;
                toggle <= 0;
            end
        end
    end
end

endmodule