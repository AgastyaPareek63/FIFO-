`timescale 1ns/1ps

module ecc_decoder(

    input wire [12:0] code_in,
    output wire [7:0] data_out,
    output wire single_error,
    output wire double_error

);

    // Received bits

    wire p1 = code_in[0];
    wire p2 = code_in[1];

    wire d0 = code_in[2];

    wire p4 = code_in[3];

    wire d1 = code_in[4];
    wire d2 = code_in[5];
    wire d3 = code_in[6];

    wire p8 = code_in[7];

    wire d4 = code_in[8];
    wire d5 = code_in[9];
    wire d6 = code_in[10];
    wire d7 = code_in[11];

    wire p0 = code_in[12];


    // Syndrome calculation

    wire s1;
    wire s2;
    wire s4;
    wire s8;

    assign s1 = p1 ^ d0 ^ d1 ^ d3 ^ d4 ^ d6;
    assign s2 = p2 ^ d0 ^ d2 ^ d3 ^ d5 ^ d6;
    assign s4 = p4 ^ d1 ^ d2 ^ d3 ^ d7;
    assign s8 = p8 ^ d4 ^ d5 ^ d6 ^ d7;

    wire [3:0] syndrome;

    assign syndrome = {s8, s4, s2, s1};


    // Overall parity

    wire parity_check;

    assign parity_check =
        p0 ^ p1 ^ p2 ^ p4 ^ p8 ^
        d0 ^ d1 ^ d2 ^ d3 ^
        d4 ^ d5 ^ d6 ^ d7;


    // Error detection

    assign single_error =
        parity_check;

    assign double_error =
        !parity_check && (syndrome != 0);


    // Correct the received code

    reg [12:0] corrected;

    always @(*) begin

        corrected = code_in;

        if (single_error && (syndrome != 0)) begin

            if (syndrome <= 12)
                corrected[syndrome - 1] =
                    ~corrected[syndrome - 1];

        end

    end


    // Extract data bits

    assign data_out = {
        corrected[11],
        corrected[10],
        corrected[9],
        corrected[8],
        corrected[6],
        corrected[5],
        corrected[4],
        corrected[2]
    };

endmodule