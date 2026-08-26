`timescale 1ns/1ps

module ecc_decoder #(
    parameter DATA_WIDTH = 8,// width of original data
    parameter PARITY_BITS = 4// number of Hamming parity bits
)(
    input wire [DATA_WIDTH+PARITY_BITS:0] code_in,

    output reg [DATA_WIDTH-1:0] data_out,

    output reg single_error,
    output reg double_error
);

    // Width of data plus Hamming parity bits
    localparam HAMMING_WIDTH = DATA_WIDTH + PARITY_BITS;

    // Hamming portion of received codeword
    reg [HAMMING_WIDTH-1:0] hamming_code;

    // Hamming code after single-bit correction
    reg [HAMMING_WIDTH-1:0] corrected_code;

    // Error position calculated from parity checks
    reg [PARITY_BITS-1:0] syndrome;

    // Overall parity check result
    reg parity_check;

    integer position;
    integer parity_index;
    integer data_index;
    integer error_position;

    reg parity_value;


    // ECC decoding
    always @(*)
    begin

        // Separate the Hamming code from the overall parity bit.
        hamming_code = code_in[HAMMING_WIDTH-1:0];
        
        parity_check = ^code_in;// 0 = even number of errors
                               // 1 = odd number of errors

        corrected_code = hamming_code;

        syndrome = {PARITY_BITS{1'b0}};


        // Calculate the Hamming syndrome.
        for (parity_index = 0; parity_index < PARITY_BITS;parity_index = parity_index + 1)
        begin

            parity_value = 1'b0;

            for (position = 1; position <= HAMMING_WIDTH; position = position + 1)
            begin

                if ((position & (1 << parity_index)) != 0)
                begin
                    parity_value = parity_value ^ hamming_code[position-1];
                end

            end

            syndrome[parity_index] = parity_value;

        end


        // default
        single_error = 1'b0;
        double_error = 1'b0;


        // Check the syndrome and overall parity to determine type of error.
        if ((syndrome == 0) && !parity_check)
        begin

            // No error
            single_error = 1'b0;
            double_error = 1'b0;

        end

        else if ((syndrome != 0) && parity_check)
        begin

            // Single-bit error in the Hamming code
            single_error = 1'b1;
            double_error = 1'b0;

            error_position = syndrome;

            // Correct the bit 
            if ((error_position >= 1) &&
                (error_position <= HAMMING_WIDTH))
            begin
                corrected_code[error_position-1] = ~corrected_code[error_position-1];
            end

        end

        else if ((syndrome == 0) && parity_check)
        begin

            single_error = 1'b1;
            double_error = 1'b0;

        end

        else
        begin

     // Non-zero syndrome with even overall parity indicates a double-bit error.

            single_error = 1'b0;
            double_error = 1'b1;

     // Double-bit errors are detected but not corrected.

        end


        // Extract the original data bits 

        data_out = {DATA_WIDTH{1'b0}};

        data_index = 0;

        for (position = 1; position <= HAMMING_WIDTH; position = position + 1)
        begin

            // Non-power-of-two positions contain data.
            
            if ((position & (position - 1)) != 0)
            begin

                if (data_index < DATA_WIDTH)
                begin
                    data_out[data_index] = corrected_code[position-1];

                    data_index = data_index + 1;
                end

            end

        end

    end

endmodule