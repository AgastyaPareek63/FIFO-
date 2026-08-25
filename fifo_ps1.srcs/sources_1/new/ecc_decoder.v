`timescale 1ns/1ps

// ============================================================
// Parameterized SECDED ECC Decoder
//
// Corrects single-bit errors and detects double-bit errors.
//
// DATA_WIDTH  : Original user data width
// PARITY_BITS : Number of Hamming parity bits
//
// Codeword format:
//     Hamming code + overall parity bit
//
// ECC_WIDTH = DATA_WIDTH + PARITY_BITS + 1
// ============================================================

module ecc_decoder #(
    parameter DATA_WIDTH  = 8,
    parameter PARITY_BITS = 4
)(
    input wire [DATA_WIDTH+PARITY_BITS:0] code_in,

    output reg [DATA_WIDTH-1:0] data_out,

    output reg single_error,
    output reg double_error
);

    // Number of bits excluding the overall parity bit.
    localparam HAMMING_WIDTH =
        DATA_WIDTH + PARITY_BITS;


    // Received Hamming portion.
    reg [HAMMING_WIDTH-1:0] hamming_code;

    // Corrected Hamming portion.
    reg [HAMMING_WIDTH-1:0] corrected_code;


    // Syndrome and overall parity result.
    reg [PARITY_BITS-1:0] syndrome;
    reg parity_check;


    integer position;
    integer parity_index;
    integer data_index;
    integer error_position;


    // ========================================================
    // ECC decoding
    // ========================================================

    always @(*)
    begin

        // Start with the received Hamming bits.
        hamming_code = code_in[HAMMING_WIDTH-1:0];

        // Calculate overall parity.
        //
        // For a correct codeword this XOR is zero.
        // A value of one means an odd number of bits
        // are different from the original codeword.
        parity_check = ^code_in;


        // ----------------------------------------------------
        // Calculate Hamming syndrome
        // ----------------------------------------------------

        syndrome = {PARITY_BITS{1'b0}};

        for (parity_index = 0;
             parity_index < PARITY_BITS;
             parity_index = parity_index + 1)
        begin

            for (position = 1;
                 position <= HAMMING_WIDTH;
                 position = position + 1)
            begin

                // A parity bit checks all positions whose
                // binary address contains that parity bit.
                if ((position & (1 << parity_index)) != 0)
                begin
                    syndrome[parity_index] =
                        syndrome[parity_index] ^
                        hamming_code[position-1];
                end

            end

        end


        // ----------------------------------------------------
        // Default values
        // ----------------------------------------------------

        single_error = 1'b0;
        double_error = 1'b0;

        corrected_code = hamming_code;


        // ----------------------------------------------------
        // SECDED error classification
        // ----------------------------------------------------

        if (!parity_check && (syndrome == 0))
        begin
            // No error.
            single_error = 1'b0;
            double_error = 1'b0;
        end

        else if (parity_check && (syndrome != 0))
        begin
            // Single-bit error in the Hamming portion.
            //
            // Syndrome gives the 1-based position of the
            // corrupted bit.

            single_error = 1'b1;
            double_error = 1'b0;

            error_position = syndrome;

            if (error_position <= HAMMING_WIDTH)
            begin
                corrected_code[error_position-1] =
                    ~corrected_code[error_position-1];
            end
        end

        else if (parity_check && (syndrome == 0))
        begin
            // Only the overall parity bit is corrupted.
            //
            // The actual data is already correct.

            single_error = 1'b1;
            double_error = 1'b0;
        end

        else
        begin
            // syndrome != 0
            // parity_check = 0
            //
            // This combination indicates a double-bit error.
            //
            // SECDED detects the error but does NOT attempt
            // to correct the data.

            single_error = 1'b0;
            double_error = 1'b1;
        end


        // ----------------------------------------------------
        // Extract original data bits
        // ----------------------------------------------------

        data_out = {DATA_WIDTH{1'b0}};
        data_index = 0;

        for (position = 1;
             position <= HAMMING_WIDTH;
             position = position + 1)
        begin

            // Positions that are not powers of two contain
            // actual data bits.
            if ((position & (position - 1)) != 0)
            begin

                if (data_index < DATA_WIDTH)
                begin
                    data_out[data_index] =
                        corrected_code[position-1];

                    data_index = data_index + 1;
                end

            end

        end

    end

endmodule