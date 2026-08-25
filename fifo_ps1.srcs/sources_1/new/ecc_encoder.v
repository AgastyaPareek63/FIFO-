`timescale 1ns/1ps

// ------------------------------------------------------------
// Parameterized SECDED ECC Encoder
//
// DATA_WIDTH  : Number of original data bits
// PARITY_BITS : Number of Hamming parity bits
//
// Total codeword width:
//     DATA_WIDTH + PARITY_BITS + 1
//
// The extra 1 bit is the overall parity bit.
//
// Example:
//     DATA_WIDTH  = 8
//     PARITY_BITS = 4
//     ECC_WIDTH   = 13
// ------------------------------------------------------------

module ecc_encoder #(
    parameter DATA_WIDTH  = 8,
    parameter PARITY_BITS = 4
)(
    input  wire [DATA_WIDTH-1:0] data_in,

    output reg [DATA_WIDTH+PARITY_BITS:0] code_out
);

    // Number of Hamming-code positions.
    // The overall parity bit is added separately.
    localparam HAMMING_WIDTH = DATA_WIDTH + PARITY_BITS;

    // Internal Hamming codeword.
    //
    // Position 1, 2, 4, 8, ... are parity positions.
    // All other positions contain data.
    reg [HAMMING_WIDTH-1:0] hamming_code;

    integer position;
    integer data_index;
    integer parity_index;


    // --------------------------------------------------------
    // Encoder
    // --------------------------------------------------------

    always @(*)
    begin

        // Start with an empty Hamming codeword.
        hamming_code = {HAMMING_WIDTH{1'b0}};

        data_index = 0;


        // ----------------------------------------------------
        // Place data bits into the non-parity positions.
        //
        // Hamming parity positions are powers of two:
        //
        // 1, 2, 4, 8, 16, ...
        // ----------------------------------------------------

        for (position = 1;
             position <= HAMMING_WIDTH;
             position = position + 1)
        begin

            // If position is not a power of two,
            // it is a data position.
            if ((position & (position - 1)) != 0)
            begin
                hamming_code[position-1] = data_in[data_index];
                data_index = data_index + 1;
            end

        end


        // ----------------------------------------------------
        // Calculate Hamming parity bits.
        //
        // Each parity bit checks positions whose binary
        // address contains that parity bit.
        // ----------------------------------------------------

        for (parity_index = 0;
             parity_index < PARITY_BITS;
             parity_index = parity_index + 1)
        begin

            // Position of this parity bit:
            //
            // parity_index = 0 → position 1
            // parity_index = 1 → position 2
            // parity_index = 2 → position 4
            // parity_index = 3 → position 8
            //
            // Start the calculation from zero.
            hamming_code[(1 << parity_index)-1] = 1'b0;


            for (position = 1;
                 position <= HAMMING_WIDTH;
                 position = position + 1)
            begin

                if ((position & (1 << parity_index)) != 0)
                begin
                    hamming_code[(1 << parity_index)-1] =
                        hamming_code[(1 << parity_index)-1] ^
                        hamming_code[position-1];
                end

            end

        end


        // ----------------------------------------------------
        // Add overall parity.
        //
        // ^hamming_code is the XOR of all Hamming-code bits.
        //
        // This makes the complete codeword have even parity.
        // ----------------------------------------------------

        code_out = {
            ^hamming_code,
            hamming_code
        };

    end

endmodule