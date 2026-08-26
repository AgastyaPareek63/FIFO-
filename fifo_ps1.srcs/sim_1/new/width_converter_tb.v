`timescale 1ns/1ps

module width_converter_tb;

    // ==================================================
    // CLOCK / RESET
    // ==================================================

    reg clk;
    reg rst;


    // ==================================================
    // TEST 1 : 32-bit -> 64-bit
    // ==================================================

    reg         valid_in_32;
    reg  [31:0] data_in_32;

    wire        valid_out_64;
    wire [63:0] data_out_64;
    wire        ready_in_32;


    width_converter #(
        .IN_WIDTH  (32),
        .OUT_WIDTH (64)
    ) dut_32_to_64 (

        .clk       (clk),
        .rst       (rst),

        .valid_in  (valid_in_32),
        .data_in   (data_in_32),

        .valid_out (valid_out_64),
        .data_out  (data_out_64),

        .ready_in  (ready_in_32)
    );


    // ==================================================
    // TEST 2 : 64-bit -> 32-bit
    // ==================================================

    reg         valid_in_64;
    reg  [63:0] data_in_64;

    wire        valid_out_32;
    wire [31:0] data_out_32;
    wire        ready_in_64;


    width_converter #(
        .IN_WIDTH  (64),
        .OUT_WIDTH (32)
    ) dut_64_to_32 (

        .clk       (clk),
        .rst       (rst),

        .valid_in  (valid_in_64),
        .data_in   (data_in_64),

        .valid_out (valid_out_32),
        .data_out  (data_out_32),

        .ready_in  (ready_in_64)
    );


    // ==================================================
    // CLOCK
    // 10 ns period
    // ==================================================

    initial begin
        clk = 0;

        forever #5 clk = ~clk;
    end


    // ==================================================
    // TEST SEQUENCE
    // ==================================================

    initial begin

        // ----------------------------------------------
        // Initial values
        // ----------------------------------------------

        rst = 1;

        valid_in_32 = 0;
        data_in_32  = 0;

        valid_in_64 = 0;
        data_in_64  = 0;


        // ----------------------------------------------
        // Reset
        // ----------------------------------------------

        #20;

        rst = 0;


        // ==================================================
        // TEST 1
        // 32-bit -> 64-bit
        // ==================================================

        $display("");
        $display("==============================================");
        $display("TEST 1 : 32-bit -> 64-bit");
        $display("==============================================");


        // First 32-bit word
        @(posedge clk);

        valid_in_32 <= 1;
        data_in_32  <= 32'hAAAAAAAA;


        @(posedge clk);

        valid_in_32 <= 0;


        // Second 32-bit word
        @(posedge clk);

        valid_in_32 <= 1;
        data_in_32  <= 32'h55555555;


        @(posedge clk);

        valid_in_32 <= 0;


        // Wait for output
        @(posedge clk);


        // ----------------------------------------------
        // Check 32 -> 64 result
        // ----------------------------------------------

        if (data_out_64 == 64'h55555555AAAAAAAA &&
            valid_out_64 == 1'b1)
        begin

            $display("PASS");
            $display("Input 1  = %h", 32'hAAAAAAAA);
            $display("Input 2  = %h", 32'h55555555);
            $display("Output   = %h", data_out_64);

        end

        else
        begin

            $display("FAIL");
            $display("Expected = 55555555AAAAAAAA");
            $display("Actual   = %h", data_out_64);
            $display("Valid    = %b", valid_out_64);

        end


        // ==================================================
        // TEST 2
        // 64-bit -> 32-bit
        // ==================================================

        $display("");
        $display("==============================================");
        $display("TEST 2 : 64-bit -> 32-bit");
        $display("==============================================");


        // Give one 64-bit word
        @(posedge clk);

        valid_in_64 <= 1;
        data_in_64  <= 64'h55555555AAAAAAAA;


        @(posedge clk);

        valid_in_64 <= 0;


        // ----------------------------------------------
        // First 32-bit output
        // ----------------------------------------------

        @(posedge clk);


        if (data_out_32 == 32'hAAAAAAAA &&
            valid_out_32 == 1'b1)
        begin

            $display("PASS : First 32-bit word");
            $display("Expected = AAAAAAAA");
            $display("Actual   = %h", data_out_32);

        end

        else
        begin

            $display("FAIL : First 32-bit word");
            $display("Expected = AAAAAAAA");
            $display("Actual   = %h", data_out_32);
            $display("Valid    = %b", valid_out_32);

        end


        // ----------------------------------------------
        // Second 32-bit output
        // ----------------------------------------------

        @(posedge clk);


        if (data_out_32 == 32'h55555555 &&
            valid_out_32 == 1'b1)
        begin

            $display("PASS : Second 32-bit word");
            $display("Expected = 55555555");
            $display("Actual   = %h", data_out_32);

        end

        else
        begin

            $display("FAIL : Second 32-bit word");
            $display("Expected = 55555555");
            $display("Actual   = %h", data_out_32);
            $display("Valid    = %b", valid_out_32);

        end


        // ==================================================
        // FINAL
        // ==================================================

        $display("");
        $display("==============================================");
        $display("WIDTH CONVERTER TEST COMPLETE");
        $display("==============================================");


        #20;

        $finish;

    end


endmodule