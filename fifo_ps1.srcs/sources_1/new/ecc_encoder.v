`timescale 1ns/1ps

// Converts 8-bit input data into a 13-bit ECC codeword using Hamming-code
// parity bits along with one overall parity bit for SECDED (Single Error
// Correction, Double Error Detection).
//
// The 13-bit codeword contains:
// 8 original data bits
// 4 Hamming parity bits
// 1 overall parity bit

module ecc_encoder(

    input  wire [7:0]  data_in,// input data 
    output wire [12:0] code_out// codeword

);

    // Data Bits

// Individual data bits are given separate names to make the Hamming parity equations easier to understand.
    wire d0 = data_in[0];
    wire d1 = data_in[1];
    wire d2 = data_in[2];
    wire d3 = data_in[3];
    wire d4 = data_in[4];
    wire d5 = data_in[5];
    wire d6 = data_in[6];
    wire d7 = data_in[7];

    // Hamming Parity Bits

    // Position 1
    wire p1 = d0 ^ d1 ^ d3 ^ d4 ^ d6;

    // Position 2
    wire p2 = d0 ^ d2 ^ d3 ^ d5 ^ d6;

    // Position 4
    wire p4 = d1 ^ d2 ^ d3 ^ d7;

    // Position 8
    wire p8 = d4 ^ d5 ^ d6 ^ d7;

    // Overall SECDED Parity

    wire p0;// overall parity bit

    assign p0 =
        p1 ^ p2 ^ p4 ^ p8 ^
        d0 ^ d1 ^ d2 ^ d3 ^
        d4 ^ d5 ^ d6 ^ d7;


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