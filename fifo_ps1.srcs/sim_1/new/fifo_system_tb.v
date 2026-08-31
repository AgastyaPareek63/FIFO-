`timescale 1ns/1ps

module fifo_system_tb;

    // Parameters

    parameter DATA_WIDTH = 8;// width of data
    parameter PARITY_BITS = 4;// number of ECC parity bits
    parameter DEPTH = 16;// no. of FIFO entries


    reg wr_clk;
    reg rd_clk;

    reg wr_rst;
    reg rd_rst;

    reg wr_en;
    reg rd_en;

    reg[DATA_WIDTH-1:0] din;
    wire[DATA_WIDTH-1:0] dout;

    // FIFO status

    wire full;
    wire empty;

    wire almost_full;
    wire almost_empty;

    wire prog_full;
    wire prog_empty;

    // ECC status flags

    wire ecc_single_error;
    wire ecc_double_error;

    // Test variables

    integer errors;
    integer reads;


    // DUT

    fifo_system #(
        .DATA_WIDTH(DATA_WIDTH),
        .PARITY_BITS(PARITY_BITS),
        .DEPTH(DEPTH)
    )
    dut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),

        .wr_rst(wr_rst),
        .rd_rst(rd_rst),

        .wr_en(wr_en),
        .rd_en(rd_en),

        .din(din),
        .dout(dout),

        .full(full),
        .empty(empty),

        .almost_full(almost_full),
        .almost_empty(almost_empty),

        .prog_full(prog_full),
        .prog_empty(prog_empty),

        .ecc_single_error(ecc_single_error),
        .ecc_double_error(ecc_double_error)
    );

    // 10 ns write clock period.
    initial
        wr_clk = 1'b0;

    always #5 wr_clk = ~wr_clk;


    // 14 ns read clock period.
    // Different clock periods are used to verify operation between independent clock domains.
    initial
        rd_clk = 1'b0;

    always #7 rd_clk = ~rd_clk;


    // Write task

    // Writes one data word when FIFO has space.
    task write_word;

        input [DATA_WIDTH-1:0] data;

        begin

            @(negedge wr_clk);

            if (!full)
            begin

                din = data;
                wr_en = 1'b1;

                @(negedge wr_clk);

                wr_en = 1'b0;
                din = {DATA_WIDTH{1'b0}};

                $display("[WRITE] time=%0t DATA=%h",$time,data);

            end
            else
            begin

                // write is rejected when FIFO is full.
                $display("[WRITE BLOCKED] time=%0t FIFO FULL",$time);

                errors = errors + 1;

            end

        end

    endtask


    // Reads one word from the FIFO and compares it with the expected value.
    task read_word;

        input [DATA_WIDTH-1:0] expected;

        begin

            wait(empty == 1'b0);

            @(negedge rd_clk);

            rd_en = 1'b1;

            @(posedge rd_clk);

            #1;

            $display("[READ] time=%0t EXPECTED=%h GOT=%h",$time,expected,dout);

            // Check that the FIFO returned the expected word.
            if (dout !== expected)
            begin

                $display("ERROR: DATA MISMATCH");

                errors = errors + 1;

            end
            else
            begin

                $display("PASS: DATA CORRECT"
);

            end

            @(negedge rd_clk);

            rd_en = 1'b0;

        end

    endtask


    task display_status;// Displays the FIFO status and ECC error flags.

        begin

            $display("");
            $display("TIME = %0t", $time);
            $display("FULL = %b", full);
            $display("EMPTY = %b", empty);
            $display("ALMOST_FULL  %b", almost_full);
            $display("ALMOST_EMPTY = %b", almost_empty);
            $display("PROG_FULL = %b", prog_full);
            $display("PROG_EMPTY = %b", prog_empty);
            $display("ECC_SINGLE = %b", ecc_single_error);
            $display("ECC_DOUBLE = %b", ecc_double_error);
        end

    endtask


    // Main test

    initial
    begin

        errors = 0;
        reads = 0;

        wr_rst = 1'b1;
        rd_rst = 1'b1;

        wr_en = 1'b0;
        rd_en = 1'b0;

        din = 8'h00;

        // TEST 1 : RESET

        $display("TEST 1 : RESET");

        #50;

        wr_rst = 1'b0;
        rd_rst = 1'b0;

        #100;

        if (empty === 1'b1)
            $display("PASS: FIFO starts EMPTY");
        else
        begin
            $display("FAIL: FIFO should start EMPTY");
            errors = errors + 1;
        end

        // TEST 2 : SINGLE WORD

        $display("TEST 2 : SINGLE WORD WRITE / READ");

        write_word(8'hA5);

        #100;

        read_word(8'hA5);
        reads = reads + 1;

        #50;


        // TEST 3 : MULTIPLE WORDS

        $display("TEST 3 : MULTIPLE WORD DATA INTEGRITY");

        // Write several words and verify that they are read back in the same order.
        write_word(8'h3C);
        write_word(8'h55);
        write_word(8'hFF);

        #150;

        read_word(8'h3C);
        reads = reads + 1;

        read_word(8'h55);
        reads = reads + 1;

        read_word(8'hFF);
        reads = reads + 1;

        #100;


        // TEST 4 : EMPTY FLAG

        $display("TEST 4 : EMPTY FLAG");

        #100;

        if (empty === 1'b1)
            $display("PASS: FIFO correctly reports EMPTY");
        else
        begin
            $display("FAIL: FIFO should be EMPTY");
            errors = errors + 1;
        end


        // TEST 5 : FIFO REFILL

        $display("TEST 5 : FIFO REFILL");

        // Verify that the FIFO can be reused after becoming empty.
        write_word(8'hCA);
        write_word(8'hDE);

        #150;

        read_word(8'hCA);
        reads = reads + 1;

        read_word(8'hDE);
        reads = reads + 1;

        #100;


        // TEST 6 : MULTIPLE CONSECUTIVE WRITES

        $display("TEST 6 : MULTIPLE CONSECUTIVE WRITES");
        
        // Write a sequence of consecutive values and verifythat FIFO preserves their order.
        write_word(8'h01);
        write_word(8'h02);
        write_word(8'h03);
        write_word(8'h04);
        write_word(8'h05);
        write_word(8'h06);

        #200;

        read_word(8'h01);
        reads = reads + 1;

        read_word(8'h02);
        reads = reads + 1;

        read_word(8'h03);
        reads = reads + 1;

        read_word(8'h04);
        reads = reads + 1;

        read_word(8'h05);
        reads = reads + 1;

        read_word(8'h06);
        reads = reads + 1;

        #100;


        // TEST 7 : NORMAL ECC STATUS

        $display("TEST 7 : NORMAL ECC STATUS");

        // Normal FIFO operation should not generate ECC errors.
        if ((ecc_single_error === 1'b0) &&(ecc_double_error === 1'b0))
        begin

            $display("PASS: No ECC error during normal operation");

        end
        else
        begin

            $display("FAIL: Unexpected ECC error");

            errors = errors + 1;

        end


        // TEST 8 : STATUS FLAGS

        $display("TEST 8 : STATUS FLAGS");

        display_status;


        // TEST 9 : RESET RECOVERY

        $display("TEST 9 : RESET RECOVERY");
    
        wr_rst = 1'b1;
        rd_rst = 1'b1;

        #50;

        wr_rst = 1'b0;
        rd_rst = 1'b0;

        #100;

        if (empty === 1'b1)
        begin
            $display("PASS: FIFO EMPTY after reset");
        end
        else
        begin
            $display("FAIL: FIFO not EMPTY after reset");
            errors = errors + 1;
        end


        // TEST 10 : POST-RESET DATA

        $display("TEST 10 : POST-RESET DATA");

        write_word(8'h34);

        #150;

        read_word(8'h34);
        reads = reads + 1;

        #100;


        // TEST 11 : SINGLE-BIT ECC ERROR

        $display("TEST 11 : SINGLE-BIT ECC ERROR");

        wr_rst = 1'b1;
        rd_rst = 1'b1;

        #50;

        wr_rst = 1'b0;
        rd_rst = 1'b0;

        #100;

        write_word(8'hA5);

        #30;


        // Check the ECC codeword before corruption.

        $display("MEM[0] BEFORE ERROR = %h",dut.fifo_inst.mem_inst.mem[0]);

        // Flip one bit of the ECC codeword.

        dut.fifo_inst.mem_inst.mem[0][5] =~dut.fifo_inst.mem_inst.mem[0][5];

        $display("Injected SINGLE-BIT error at mem[0][5]");


        $display("MEM[0] AFTER ERROR  = %h",dut.fifo_inst.mem_inst.mem[0]);

        #100;

        // Read the corrupted entry.

        @(negedge rd_clk);

        rd_en = 1'b1;

        @(posedge rd_clk);

        #1;


        $display("DOUT = %h",dout);

        $display("ECC_SINGLE = %b",ecc_single_error);

        $display("ECC_DOUBLE = %b",ecc_double_error);

        // Data should be corrected back to A5.


        if ((dout === 8'hA5) &&(ecc_single_error === 1'b1) &&(ecc_double_error === 1'b0))
        begin

            $display(
                "PASS: SINGLE-BIT ERROR DETECTED AND CORRECTED");

        end
        else
        begin

            $display("FAIL: SINGLE-BIT ECC TEST");

            errors = errors + 1;

        end


        @(negedge rd_clk);

        rd_en = 1'b0;

        // TEST 12 : DOUBLE-BIT ECC ERROR

        $display("TEST 12 : DOUBLE-BIT ECC ERROR");

        wr_rst = 1'b1;
        rd_rst = 1'b1;

        #50;

        wr_rst = 1'b0;
        rd_rst = 1'b0;

        #100;


        // Write known data.

        write_word(8'h3C);

        #30;

        $display("MEM[0] BEFORE ERROR = %h",dut.fifo_inst.mem_inst.mem[0]);


        // Flip two bits of the ECC codeword.

        dut.fifo_inst.mem_inst.mem[0][5] =~dut.fifo_inst.mem_inst.mem[0][5];

        dut.fifo_inst.mem_inst.mem[0][8] =~dut.fifo_inst.mem_inst.mem[0][8];

        $display("Injected DOUBLE-BIT error at mem[0][5] and mem[0][8]");


        $display("MEM[0] AFTER ERROR  = %h",dut.fifo_inst.mem_inst.mem[0]);


        #100;

        // Read the corrupted entry.

        @(negedge rd_clk);

        rd_en = 1'b1;

        @(posedge rd_clk);

        #1;


        $display("DOUT = %h",dout);

        $display("ECC_SINGLE = %b",ecc_single_error);

        $display("ECC_DOUBLE = %b",ecc_double_error);

        // Double error should be detected.

        if ((ecc_single_error === 1'b0) &&(ecc_double_error === 1'b1))
        begin

            $display("PASS: DOUBLE-BIT ERROR DETECTED");

        end
        else
        begin

            $display("FAIL: DOUBLE-BIT ECC TEST");

            errors = errors + 1;

        end


        @(negedge rd_clk);

        rd_en = 1'b0;

        #100;

        $display("FINAL TEST SUMMARY");
        $display("TOTAL READS = %0d",reads);

        $display("TOTAL ERRORS = %0d",errors);


        if (errors == 0)
        begin

            $display("ALL FIFO/ECC TESTS PASSED");

        end
        else
        begin

            $display("TESTS FAILED");
            $display("ERRORS = %0d",errors);

        end
        #50;

        $finish;

    end

endmodule