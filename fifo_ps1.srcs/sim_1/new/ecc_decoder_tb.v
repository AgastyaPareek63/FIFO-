`timescale 1ns/1ps

module ecc_decoder_tb;


    // Parameters

    parameter DATA_WIDTH  = 8;// width of original data
    parameter PARITY_BITS = 4;// number of Hamming parity bits
    parameter ECC_WIDTH   = DATA_WIDTH + PARITY_BITS + 1;// total ECC codeword width


    // Test signals

    reg [DATA_WIDTH-1:0] data;
    wire [ECC_WIDTH-1:0]  encoded;

    // Modified codeword used to inject errors.
    reg [ECC_WIDTH-1:0]corrupted;

    wire [DATA_WIDTH-1:0]decoded;

    wire single_error;
    wire double_error;


    // Test counters
    integer i;
    integer j;

    integer single_pass;
    integer single_fail;

    integer double_pass;
    integer double_fail;


    // ECC encoder

    // Generates the ECC codeword from the test data.
    ecc_encoder #(
        .DATA_WIDTH  (DATA_WIDTH),
        .PARITY_BITS (PARITY_BITS)
    )
    encoder (
        .data_in  (data),
        .code_out (encoded)
    );


    // ECC decoder

    ecc_decoder #(
        .DATA_WIDTH(DATA_WIDTH),
        .PARITY_BITS(PARITY_BITS)
    )
    decoder (
        .code_in(corrupted),
        .data_out(decoded),
        .single_error(single_error),
        .double_error(double_error)
    );


    // Test sequence

    initial
    begin

        single_pass = 0;
        single_fail = 0;

        double_pass = 0;
        double_fail = 0;


        // Test data

        data = 8'hA5;

        #10;

        $display("PARAMETERIZED SECDED ECC TEST");
        $display("DATA_WIDTH = %0d", DATA_WIDTH);
        $display("PARITY_BITS = %0d", PARITY_BITS);
        $display("ECC_WIDTH = %0d", ECC_WIDTH);
        $display("DATA = %h", data);
        $display("ENCODED = %h", encoded);


        // TEST 1: NO ERROR

        // Pass the original codeword directly to the decoder.
        corrupted = encoded;

        #1;

        $display("TEST 1 : NO ERROR");
        $display("Original = %h", data);
        $display("Encoded = %h", encoded);
        $display("Decoded = %h", decoded);
        $display("Single Error = %b", single_error);
        $display("Double Error = %b", double_error);

        if ((decoded == data) &&(single_error == 1'b0) &&(double_error == 1'b0))
        begin
            $display("PASS");
        end
        else
        begin
            $display("FAIL");
        end


        // TEST 2: ALL SINGLE-BIT ERRORS

        $display("TEST 2 : ALL SINGLE-BIT ERRORS");

        // Flip every bit of the codeword one at a time.
        for (i = 0; i < ECC_WIDTH; i = i + 1)
        begin

            // Start with a clean codeword.
            corrupted = encoded;

            // Flip exactly one bit.
            corrupted[i] = ~corrupted[i];

            #1;

            if ((decoded == data) &&(single_error == 1'b1) &&(double_error == 1'b0))
            begin

                single_pass = single_pass + 1;

                $display(
                    "PASS: Single-bit error at codeword bit %0d | Decoded=%h",i,decoded);

            end
            else
            begin

                single_fail = single_fail + 1;

                $display(
                    "FAIL: Single-bit error at codeword bit %0d | Decoded=%h | SE=%b | DE=%b",i,decoded,single_error,double_error);

            end

        end


        // TEST 3: ALL DOUBLE-BIT ERRORS

        $display("TEST 3 : ALL DOUBLE-BIT ERRORS");

        // Test every possible pair of bit errors.
        // Double-bit errors should be detected but not corrected.
        for (i = 0; i < ECC_WIDTH; i = i + 1)
        begin

            for (j = i + 1; j < ECC_WIDTH; j = j + 1)
            begin

                // Start with a clean codeword.
                corrupted = encoded;

                // Flip two bits.
                corrupted[i] = ~corrupted[i];
                corrupted[j] = ~corrupted[j];

                #1;

                if ((single_error == 1'b0) &&(double_error == 1'b1))
                begin

                    double_pass = double_pass + 1;

                    $display(
                        "PASS: Double-bit error at bits %0d,%0d",i,j);

                end
                else
                begin

                    double_fail = double_fail + 1;

                    $display(
                        "FAIL: Double-bit error at bits %0d,%0d | Decoded=%h | SE=%b | DE=%b",i,j,decoded,single_error,double_error);

                end

            end

        end


        // TEST 4: DIFFERENT DATA PATTERNS
   
        $display("TEST 4 : DIFFERENT DATA PATTERNS");


        // Pattern 1: All zeros

        data = 8'h00;

        #1;

        corrupted = encoded;

        #1;

        if ((decoded == data) &&(single_error == 0) &&(double_error == 0))
        begin
            $display("PASS: Data pattern 00");
        end
        else
        begin
            $display("FAIL: Data pattern 00");
        end


        // Pattern 2: All ones

        data = 8'hFF;

        #1;

        corrupted = encoded;

        #1;

        if ((decoded == data) &&(single_error == 0) &&(double_error == 0))
        begin
            $display("PASS: Data pattern FF");
        end
        else
        begin
            $display("FAIL: Data pattern FF");
        end


        // Pattern 3: Alternating pattern

        data = 8'h3C;

        #1;

        corrupted = encoded;

        #1;

        if ((decoded == data) &&(single_error == 0) &&(double_error == 0))
        begin
            $display("PASS: Data pattern 3C");
        end
        else
        begin
            $display("FAIL: Data pattern 3C");
        end


        // Pattern 4: Alternating pattern

        data = 8'h55;

        #1;

        corrupted = encoded;

        #1;

        if ((decoded == data) &&(single_error == 0) &&(double_error == 0))
        begin
            $display("PASS: Data pattern 55");
        end
        else
        begin
            $display("FAIL: Data pattern 55");
        end


        // FINAL SUMMARY
        
        $display("ECC TEST SUMMARY");

        $display("Single-bit tests : PASS = %0d | FAIL = %0d",single_pass,single_fail);

        $display("Double-bit tests : PASS = %0d | FAIL = %0d",double_pass,double_fail);

        $display("Expected single-bit tests = %0d", ECC_WIDTH);

        $display( "Expected double-bit tests = %0d",(ECC_WIDTH * (ECC_WIDTH - 1)) / 2);


        // Overall result
        if ((single_fail == 0) && (double_fail == 0))
        begin


            $display("ECC VERIFICATION PASSED");
  
        end
        else
        begin

            $display("ECC VERIFICATION FAILED");
        end


        #20;

        $finish;

    end

endmodule