`timescale 1ns/1ps

module ecc_decoder_tb;

    // ============================================================
    // PARAMETERS
    // ============================================================

    parameter DATA_WIDTH  = 8;
    parameter PARITY_BITS = 4;
    parameter ECC_WIDTH   = DATA_WIDTH + PARITY_BITS + 1;


    // ============================================================
    // TEST SIGNALS
    // ============================================================

    reg  [DATA_WIDTH-1:0] data;
    wire [ECC_WIDTH-1:0]  encoded;

    reg  [ECC_WIDTH-1:0]  corrupted;

    wire [DATA_WIDTH-1:0] decoded;

    wire single_error;
    wire double_error;


    integer i;
    integer j;

    integer single_pass;
    integer single_fail;

    integer double_pass;
    integer double_fail;


    // ============================================================
    // ECC ENCODER
    // ============================================================

    ecc_encoder #(
        .DATA_WIDTH  (DATA_WIDTH),
        .PARITY_BITS (PARITY_BITS)
    )
    encoder (
        .data_in  (data),
        .code_out (encoded)
    );


    // ============================================================
    // ECC DECODER
    // ============================================================

    ecc_decoder #(
        .DATA_WIDTH  (DATA_WIDTH),
        .PARITY_BITS (PARITY_BITS)
    )
    decoder (
        .code_in       (corrupted),
        .data_out      (decoded),
        .single_error  (single_error),
        .double_error  (double_error)
    );


    // ============================================================
    // TEST SEQUENCE
    // ============================================================

    initial
    begin

        single_pass = 0;
        single_fail = 0;

        double_pass = 0;
        double_fail = 0;


        // --------------------------------------------------------
        // Test data
        // --------------------------------------------------------

        data = 8'hA5;

        #10;


        $display("");
        $display("================================================");
        $display("        PARAMETERIZED SECDED ECC TEST");
        $display("================================================");
        $display("DATA_WIDTH  = %0d", DATA_WIDTH);
        $display("PARITY_BITS = %0d", PARITY_BITS);
        $display("ECC_WIDTH   = %0d", ECC_WIDTH);
        $display("DATA        = %h", data);
        $display("ENCODED     = %h", encoded);
        $display("================================================");


        // ========================================================
        // TEST 1: NO ERROR
        // ========================================================

        corrupted = encoded;

        #1;

        $display("");
        $display("-----------------------------------------------");
        $display("TEST 1 : NO ERROR");
        $display("-----------------------------------------------");
        $display("Original       = %h", data);
        $display("Encoded        = %h", encoded);
        $display("Decoded        = %h", decoded);
        $display("Single Error   = %b", single_error);
        $display("Double Error   = %b", double_error);

        if ((decoded == data) &&
            (single_error == 1'b0) &&
            (double_error == 1'b0))
        begin
            $display("PASS");
        end
        else
        begin
            $display("FAIL");
        end


        // ========================================================
        // TEST 2: ALL SINGLE-BIT ERRORS
        // ========================================================

        $display("");
        $display("================================================");
        $display("TEST 2 : ALL SINGLE-BIT ERRORS");
        $display("================================================");

        for (i = 0; i < ECC_WIDTH; i = i + 1)
        begin

            // Start from a clean codeword.
            corrupted = encoded;

            // Flip exactly one bit.
            corrupted[i] = ~corrupted[i];

            #1;

            if ((decoded == data) &&
                (single_error == 1'b1) &&
                (double_error == 1'b0))
            begin

                single_pass = single_pass + 1;

                $display(
                    "PASS: Single-bit error at codeword bit %0d | Decoded=%h",
                    i,
                    decoded
                );

            end
            else
            begin

                single_fail = single_fail + 1;

                $display(
                    "FAIL: Single-bit error at codeword bit %0d | Decoded=%h | SE=%b | DE=%b",
                    i,
                    decoded,
                    single_error,
                    double_error
                );

            end

        end


        // ========================================================
        // TEST 3: ALL DOUBLE-BIT ERRORS
        // ========================================================

        $display("");
        $display("================================================");
        $display("TEST 3 : ALL DOUBLE-BIT ERRORS");
        $display("================================================");

        for (i = 0; i < ECC_WIDTH; i = i + 1)
        begin

            for (j = i + 1; j < ECC_WIDTH; j = j + 1)
            begin

                // Start from clean codeword.
                corrupted = encoded;

                // Flip two different bits.
                corrupted[i] = ~corrupted[i];
                corrupted[j] = ~corrupted[j];

                #1;

                if ((single_error == 1'b0) &&
                    (double_error == 1'b1))
                begin

                    double_pass = double_pass + 1;

                    $display(
                        "PASS: Double-bit error at bits %0d,%0d",
                        i,
                        j
                    );

                end
                else
                begin

                    double_fail = double_fail + 1;

                    $display(
                        "FAIL: Double-bit error at bits %0d,%0d | Decoded=%h | SE=%b | DE=%b",
                        i,
                        j,
                        decoded,
                        single_error,
                        double_error
                    );

                end

            end

        end


        // ========================================================
        // TEST 4: DIFFERENT DATA PATTERNS
        // ========================================================

        $display("");
        $display("================================================");
        $display("TEST 4 : DIFFERENT DATA PATTERNS");
        $display("================================================");


        // --------------------------------------------------------
        // Pattern 1
        // --------------------------------------------------------

        data = 8'h00;

        #1;

        corrupted = encoded;

        #1;

        if ((decoded == data) &&
            (single_error == 0) &&
            (double_error == 0))
        begin
            $display("PASS: Data pattern 00");
        end
        else
        begin
            $display("FAIL: Data pattern 00");
        end


        // --------------------------------------------------------
        // Pattern 2
        // --------------------------------------------------------

        data = 8'hFF;

        #1;

        corrupted = encoded;

        #1;

        if ((decoded == data) &&
            (single_error == 0) &&
            (double_error == 0))
        begin
            $display("PASS: Data pattern FF");
        end
        else
        begin
            $display("FAIL: Data pattern FF");
        end


        // --------------------------------------------------------
        // Pattern 3
        // --------------------------------------------------------

        data = 8'h3C;

        #1;

        corrupted = encoded;

        #1;

        if ((decoded == data) &&
            (single_error == 0) &&
            (double_error == 0))
        begin
            $display("PASS: Data pattern 3C");
        end
        else
        begin
            $display("FAIL: Data pattern 3C");
        end


        // --------------------------------------------------------
        // Pattern 4
        // --------------------------------------------------------

        data = 8'h55;

        #1;

        corrupted = encoded;

        #1;

        if ((decoded == data) &&
            (single_error == 0) &&
            (double_error == 0))
        begin
            $display("PASS: Data pattern 55");
        end
        else
        begin
            $display("FAIL: Data pattern 55");
        end


        // ========================================================
        // FINAL SUMMARY
        // ========================================================

        $display("");
        $display("================================================");
        $display("             ECC TEST SUMMARY");
        $display("================================================");

        $display(
            "Single-bit tests : PASS = %0d | FAIL = %0d",
            single_pass,
            single_fail
        );

        $display(
            "Double-bit tests : PASS = %0d | FAIL = %0d",
            double_pass,
            double_fail
        );

        $display("Expected single-bit tests = %0d", ECC_WIDTH);
        $display(
            "Expected double-bit tests = %0d",
            (ECC_WIDTH * (ECC_WIDTH - 1)) / 2
        );


        if ((single_fail == 0) &&
            (double_fail == 0))
        begin

            $display("");
            $display("***********************************************");
            $display("*                                             *");
            $display("*          ECC VERIFICATION PASSED           *");
            $display("*                                             *");
            $display("***********************************************");

        end
        else
        begin

            $display("");
            $display("***********************************************");
            $display("*                                             *");
            $display("*          ECC VERIFICATION FAILED           *");
            $display("*                                             *");
            $display("***********************************************");

        end


        #20;

        $finish;

    end

endmodule