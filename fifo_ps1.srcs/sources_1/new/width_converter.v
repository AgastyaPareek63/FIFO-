`timescale 1ns/1ps

module width_converter #(
    parameter IN_WIDTH = 8,// width of input data
    parameter OUT_WIDTH = 16// width of output data
)(
    input wire clk,
    input wire rst,

    input wire valid_in,
    input wire [IN_WIDTH-1:0] data_in,// input data word

    output reg valid_out,
    output reg [OUT_WIDTH-1:0] data_out,// converted output data

    output wire ready_in// indicates that converter can accept new input
);


    // Width relationship

    // Number of input words required to create one wider output word.
    localparam WIDER_RATIO = (OUT_WIDTH / IN_WIDTH);

    // no. of output words produced from one wider input word.
    localparam NARROW_RATIO = (IN_WIDTH / OUT_WIDTH);

    // required to keep track of the words being collected or produced.
    localparam COUNT_WIDTH = (WIDER_RATIO > NARROW_RATIO) ? ((WIDER_RATIO <= 1) ? 1 : $clog2(WIDER_RATIO)) : ((NARROW_RATIO <= 1) ? 1 : $clog2(NARROW_RATIO));


    // Internal registers

    reg [OUT_WIDTH-1:0] buffer;// Used when combining multiple smaller input words

    reg [IN_WIDTH-1:0] narrow_buffer;// Stores the wider input word while its smaller output portions are being generated.

    reg [COUNT_WIDTH-1:0] count;

    reg busy;//converter is still producing output words from a previously received input.


// Input ready signal

// For widening, another input word can be accepted at any time 
// For narrowing, a new input is accepted only after all output portions from the previous input are sent.
    assign ready_in =
        (OUT_WIDTH >= IN_WIDTH) ? 1'b1 :
        !busy;

// Parameter checks

// The input and output widths must be positive.
    initial begin

        if (IN_WIDTH <= 0 || OUT_WIDTH <= 0)
            $error("ERROR: IN_WIDTH and OUT_WIDTH must be > 0");

        if ((OUT_WIDTH > IN_WIDTH) && ((OUT_WIDTH % IN_WIDTH) != 0))
            $error("ERROR: OUT_WIDTH must be an integer multiple of IN_WIDTH");

        if ((IN_WIDTH > OUT_WIDTH) && ((IN_WIDTH % OUT_WIDTH) != 0))
            $error("ERROR: IN_WIDTH must be an integer multiple of OUT_WIDTH");

    end


// WIDENING
// Example:32-bit -> 64-bit
// First input  = AAAAAAAA
// Second input = 55555555
// Final output = 55555555AAAAAAAA
    generate

        if (OUT_WIDTH > IN_WIDTH) begin : GEN_WIDEN

            always @(posedge clk or posedge rst)
            begin

                if (rst)
                begin
                    buffer <= 0;
                    count <= 0;
                    data_out <= 0;
                    valid_out <= 0;
                end

                else
                begin

                    // valid_out is cleared every cycle and
                    // asserted only when a complete output
                    // word has been formed.
                    valid_out <= 0;

                    if (valid_in)
                    begin

                        // The current input completes the
                        // wider output word.
                        if (count == WIDER_RATIO-1)
                        begin

                            data_out <= buffer |(data_in << (count * IN_WIDTH));

                            valid_out <= 1;

          // Start collecting the next wider output word.
                            buffer <= 0;
                            count  <= 0;
                        end

                        else
                        begin

         // Store the current input in the correct portion of the buffer.
                            buffer <= buffer |(data_in << (count * IN_WIDTH));

                            count <= count + 1'b1;

                        end

                    end

                end

            end

        end

    endgenerate


// NARROWING
// Example:64-bit -> 32-bit
// Input = 55555555AAAAAAAA
// Output sequence:
// 1st output = AAAAAAAA
// 2nd output = 55555555
// The input word is stored and then sent in smaller portions 

    generate

        if (IN_WIDTH > OUT_WIDTH) begin : GEN_NARROW

            always @(posedge clk or posedge rst)
            begin

                if (rst)
                begin
                    narrow_buffer <= 0;
                    count <= 0;
                    data_out <= 0;
                    valid_out <= 0;
                    busy <= 0;
                end

                else
                begin

                    // No output is valid 
                    valid_out <= 0;

                    // Accept a new input word

                    if (valid_in && !busy)
                    begin

                        // Store the complete input 
                        narrow_buffer <= data_in;

                        // Send the lower portion first.
                        data_out <= data_in[OUT_WIDTH-1:0];

                        valid_out <= 1;

                        // More output portions remain.
                        busy  <= 1;
                        count <= 1;

                    end

                    // Output remaining portions

                    else if (busy)
                    begin

                        // Select the next smaller portion
                        // from the stored input word.
                        data_out <= narrow_buffer[count * OUT_WIDTH +:OUT_WIDTH];

                        valid_out <= 1;


                        // Check whether this was the last
                        // portion of the stored input word.
                        if (count == NARROW_RATIO-1)
                        begin
                            busy  <= 0;
                            count <= 0;
                        end

                        else
                        begin
                            count <= count + 1'b1;
                        end

                    end

                end

            end

        end

    endgenerate

    // SAME WIDTH
    // Example:32-bit -> 32-bit
    // Input data is passed directly to the output 

    generate

        if (IN_WIDTH == OUT_WIDTH) begin : GEN_SAME

            always @(posedge clk or posedge rst)
            begin

                if (rst)
                begin
                    data_out  <= 0;
                    valid_out <= 0;
                end

                else
                begin
                    valid_out <= valid_in;

                    if (valid_in)
                        data_out <= data_in;

                end

            end

        end

    endgenerate
endmodule