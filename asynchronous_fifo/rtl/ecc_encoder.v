`timescale 1ns/1ps

module ecc_encoder(
    input  wire [7:0]  data_in,
    output reg  [12:0] code_out
);

    reg p1, p2, p4, p8, p0;

    always @(*)
    begin
        // Place data bits
        code_out = 13'b0;

        code_out[2]  = data_in[0];
        code_out[4]  = data_in[1];
        code_out[5]  = data_in[2];
        code_out[6]  = data_in[3];
        code_out[8]  = data_in[4];
        code_out[9]  = data_in[5];
        code_out[10] = data_in[6];
        code_out[11] = data_in[7];

        // Hamming parity bits
        p1 = code_out[2] ^ code_out[4] ^ code_out[6] ^
             code_out[8] ^ code_out[10];

        p2 = code_out[2] ^ code_out[5] ^ code_out[6] ^
             code_out[9] ^ code_out[10];

        p4 = code_out[4] ^ code_out[5] ^ code_out[6] ^
             code_out[11];

        p8 = code_out[8] ^ code_out[9] ^ code_out[10] ^
             code_out[11];

        code_out[0] = p1;
        code_out[1] = p2;
        code_out[3] = p4;
        code_out[7] = p8;

        // Overall parity
        p0 = ^code_out[11:0];

        code_out[12] = p0;
    end

endmodule
