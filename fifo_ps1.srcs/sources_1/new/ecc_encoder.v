`timescale 1ns/1ps

module ecc_encoder(

    input  wire [7:0]  data_in,
    output wire [12:0] code_out

);

    //--------------------------------------------------
    // Data Bits
    //--------------------------------------------------

    wire d0 = data_in[0];
    wire d1 = data_in[1];
    wire d2 = data_in[2];
    wire d3 = data_in[3];
    wire d4 = data_in[4];
    wire d5 = data_in[5];
    wire d6 = data_in[6];
    wire d7 = data_in[7];

    //--------------------------------------------------
    // Hamming Parity Bits
    //--------------------------------------------------

    // Position 1
    wire p1 = d0 ^ d1 ^ d3 ^ d4 ^ d6;

    // Position 2
    wire p2 = d0 ^ d2 ^ d3 ^ d5 ^ d6;

    // Position 4
    wire p4 = d1 ^ d2 ^ d3 ^ d7;

    // Position 8
    wire p8 = d4 ^ d5 ^ d6 ^ d7;

    //--------------------------------------------------
    // Overall SECDED Parity
    //--------------------------------------------------

    wire p0;

    assign p0 =
        p1 ^ p2 ^ p4 ^ p8 ^
        d0 ^ d1 ^ d2 ^ d3 ^
        d4 ^ d5 ^ d6 ^ d7;

    //--------------------------------------------------
    // Code Word
    //
    // Bit Position (1-based)
    //
    //  1  -> p1
    //  2  -> p2
    //  3  -> d0
    //  4  -> p4
    //  5  -> d1
    //  6  -> d2
    //  7  -> d3
    //  8  -> p8
    //  9  -> d4
    // 10  -> d5
    // 11  -> d6
    // 12  -> d7
    // 13  -> p0
    //--------------------------------------------------

    assign code_out =
    {
        p0,
        d7,
        d6,
        d5,
        d4,
        p8,
        d3,
        d2,
        d1,
        p4,
        d0,
        p2,
        p1
    };

endmodule