`timescale 1ns/1ps

module ecc_decoder_tb;

    // --------------------------------------------------
    // 8-bit ECC
    // --------------------------------------------------

    reg  [7:0]  data;
    wire [12:0] encoded;

    reg  [12:0] corrupted;

    wire [7:0] decoded;

    wire single_error;
    wire double_error;


    // --------------------------------------------------
    // Encoder
    // --------------------------------------------------

    ecc_encoder #(
        .DATA_WIDTH(8),
        .PARITY_BITS(4)
    ) encoder (
        .data_in(data),
        .code_out(encoded)
    );


    // --------------------------------------------------
    // Decoder
    // --------------------------------------------------

    ecc_decoder #(
        .DATA_WIDTH(8),
        .PARITY_BITS(4)
    ) decoder (
        .code_in(corrupted),
        .data_out(decoded),
        .single_error(single_error),
        .double_error(double_error)
    );


    // --------------------------------------------------
    // Test sequence
    // --------------------------------------------------

    initial
    begin

        data = 8'hA5;

        #10;

        // --------------------------------------------------
        // TEST 1: No error
        // --------------------------------------------------

        corrupted = encoded;

        #10;

        $display("");
        $display("--------------------------------");
        $display("TEST 1 : NO ERROR");
        $display("Original       = %h", data);
        $display("Encoded        = %h", encoded);
        $display("Decoded        = %h", decoded);
        $display("Single Error   = %b", single_error);
        $display("Double Error   = %b", double_error);

        if ((decoded == data) &&
            (single_error == 0) &&
            (double_error == 0))
        begin
            $display("PASS");
        end
        else
        begin
            $display("FAIL");
        end


        // --------------------------------------------------
        // TEST 2: Single data-bit error
        // --------------------------------------------------

        corrupted = encoded;

        // Flip one bit in the Hamming code.
        corrupted[5] = ~corrupted[5];

        #10;

        $display("");
        $display("--------------------------------");
        $display("TEST 2 : SINGLE BIT ERROR");
        $display("Original       = %h", data);
        $display("Decoded        = %h", decoded);
        $display("Single Error   = %b", single_error);
        $display("Double Error   = %b", double_error);

        if ((decoded == data) &&
            (single_error == 1) &&
            (double_error == 0))
        begin
            $display("PASS: Error detected and corrected");
        end
        else
        begin
            $display("FAIL");
        end


        // --------------------------------------------------
        // TEST 3: Single parity-bit error
        // --------------------------------------------------

        corrupted = encoded;

        // Flip Hamming parity bit at position 1.
        corrupted[0] = ~corrupted[0];

        #10;

        $display("");
        $display("--------------------------------");
        $display("TEST 3 : SINGLE PARITY ERROR");
        $display("Original       = %h", data);
        $display("Decoded        = %h", decoded);
        $display("Single Error   = %b", single_error);
        $display("Double Error   = %b", double_error);

        if ((decoded == data) &&
            (single_error == 1) &&
            (double_error == 0))
        begin
            $display("PASS: Parity error detected and corrected");
        end
        else
        begin
            $display("FAIL");
        end


        // --------------------------------------------------
        // TEST 4: Overall parity error
        // --------------------------------------------------

        corrupted = encoded;

        // Flip the overall parity bit.
        corrupted[12] = ~corrupted[12];

        #10;

        $display("");
        $display("--------------------------------");
        $display("TEST 4 : OVERALL PARITY ERROR");
        $display("Original       = %h", data);
        $display("Decoded        = %h", decoded);
        $display("Single Error   = %b", single_error);
        $display("Double Error   = %b", double_error);

        if ((decoded == data) &&
            (single_error == 1) &&
            (double_error == 0))
        begin
            $display("PASS: Overall parity error detected");
        end
        else
        begin
            $display("FAIL");
        end


        // --------------------------------------------------
        // TEST 5: Double-bit error
        // --------------------------------------------------

        corrupted = encoded;

        corrupted[5] = ~corrupted[5];
        corrupted[8] = ~corrupted[8];

        #10;

        $display("");
        $display("--------------------------------");
        $display("TEST 5 : DOUBLE BIT ERROR");
        $display("Original       = %h", data);
        $display("Decoded        = %h", decoded);
        $display("Single Error   = %b", single_error);
        $display("Double Error   = %b", double_error);

        if ((single_error == 0) &&
            (double_error == 1))
        begin
            $display("PASS: Double error detected");
        end
        else
        begin
            $display("FAIL");
        end


        // --------------------------------------------------
        // Finish
        // --------------------------------------------------

        $display("");
        $display("================================");
        $display("     ECC DECODER TEST COMPLETE");
        $display("================================");

        #20;

        $finish;

    end

endmodule