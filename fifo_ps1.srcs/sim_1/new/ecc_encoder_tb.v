`timescale 1ns/1ps

module ecc_encoder_tb;

    // --------------------------------------------------
    // 8-bit ECC
    // --------------------------------------------------

    reg  [7:0]  data8;
    wire [12:0] code8;

    ecc_encoder #(
        .DATA_WIDTH(8),
        .PARITY_BITS(4)
    ) encoder8 (
        .data_in(data8),
        .code_out(code8)
    );


    // --------------------------------------------------
    // 16-bit ECC
    // --------------------------------------------------

    reg  [15:0] data16;
    wire [21:0] code16;

    ecc_encoder #(
        .DATA_WIDTH(16),
        .PARITY_BITS(5)
    ) encoder16 (
        .data_in(data16),
        .code_out(code16)
    );


    // --------------------------------------------------
    // 32-bit ECC
    // --------------------------------------------------

    reg  [31:0] data32;
    wire [38:0] code32;

    ecc_encoder #(
        .DATA_WIDTH(32),
        .PARITY_BITS(6)
    ) encoder32 (
        .data_in(data32),
        .code_out(code32)
    );


    // --------------------------------------------------
    // Test
    // --------------------------------------------------

    initial
    begin

        $display("");
        $display("======================================");
        $display("      PARAMETERIZED ECC ENCODER");
        $display("======================================");


        // 8-bit test
        data8 = 8'h00;

        #10;

        $display("");
        $display("TEST 1 : 8-bit");
        $display("DATA = %h", data8);
        $display("CODE = %h", code8);

        if (code8 == 13'h000)
            $display("PASS");
        else
            $display("FAIL");


        // Another 8-bit test
        data8 = 8'hA5;

        #10;

        $display("");
        $display("TEST 2 : 8-bit");
        $display("DATA = %h", data8);
        $display("CODE = %h", code8);

        if (code8 == 13'hA27)
            $display("PASS");
        else
            $display("FAIL: Expected A27, Got %h", code8);


        // 16-bit test
        data16 = 16'hA55A;

        #10;

        $display("");
        $display("TEST 3 : 16-bit");
        $display("DATA = %h", data16);
        $display("CODE = %h", code16);

        if (^code16 !== 1'b0)
            $display("FAIL: Codeword does not have even parity");
        else
            $display("PASS: 22-bit codeword generated");


        // 32-bit test
        data32 = 32'hA5A55A5A;

        #10;

        $display("");
        $display("TEST 4 : 32-bit");
        $display("DATA = %h", data32);
        $display("CODE = %h", code32);

        if (^code32 !== 1'b0)
            $display("FAIL: Codeword does not have even parity");
        else
            $display("PASS: 39-bit codeword generated");


        // Finish
        $display("");
        $display("======================================");
        $display("       ECC ENCODER TEST COMPLETE");
        $display("======================================");

        #20;

        $finish;

    end

endmodule