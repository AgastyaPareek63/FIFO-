`timescale 1ns/1ps

// Parameterized SECDED ECC encoder.
//
// DATA_WIDTH  : Number of original data bits.
// PARITY_BITS : Number of Hamming parity bits.
//
// Total codeword width:
//     DATA_WIDTH + PARITY_BITS + 1
//
// The extra 1 bit is the overall parity bit used for
// double-error detection.

module ecc_encoder #(
    parameter DATA_WIDTH  = 8,
    parameter PARITY_BITS = 4
)(
    input  wire [DATA_WIDTH-1:0] data_in,

    output reg [DATA_WIDTH+PARITY_BITS:0] code_out
);

    localparam HAMMING_WIDTH = DATA_WIDTH + PARITY_BITS;

    reg [HAMMING_WIDTH-1:0] hamming_code;

    integer position;
    integer parity_index;
    integer data_index;

    reg parity_value;
    reg overall_parity;


    always @(*)
    begin

        // Start with all bits cleared.
        hamming_code = {HAMMING_WIDTH{1'b0}};

        data_index = 0;

        // Put data bits into positions that are not powers of two.
        //
        // Position 1,2,4,8,... are reserved for parity bits.

        for (position = 1;
             position <= HAMMING_WIDTH;
             position = position + 1)
        begin

            if ((position & (position - 1)) != 0)
            begin
                if (data_index < DATA_WIDTH)
                begin
                    hamming_code[position-1] =
                        data_in[data_index];

                    data_index = data_index + 1;
                end
            end

        end


        // Calculate each Hamming parity bit.

        for (parity_index = 0;
             parity_index < PARITY_BITS;
             parity_index = parity_index + 1)
        begin

            parity_value = 1'b0;

            for (position = 1;
                 position <= HAMMING_WIDTH;
                 position = position + 1)
            begin

                // Skip the parity bit itself.
                if ((position != (1 << parity_index)) &&
                    ((position & (1 << parity_index)) != 0))
                begin
                    parity_value =
                        parity_value ^
                        hamming_code[position-1];
                end

            end

            // Put calculated parity into its position.
            if ((1 << parity_index) <= HAMMING_WIDTH)
            begin
                hamming_code[(1 << parity_index)-1] =
                    parity_value;
            end

        end


        // Overall parity covers the complete Hamming code.
        overall_parity = ^hamming_code;


        // Final codeword:
        //
        // [HAMMING_WIDTH-1:0] = Hamming code
        // [HAMMING_WIDTH]     = overall parity

        code_out = {overall_parity, hamming_code};

    end

endmodule