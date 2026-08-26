`timescale 1ns/1ps

module async_fifo_tb;

    parameter DATA_WIDTH = 8;// width of data
    parameter PARITY_BITS = 4;// number of ECC parity bits
    parameter DEPTH = 16;// no. of FIFO entries


    reg wr_clk;
    reg rd_clk;

    reg wr_rst;
    reg rd_rst;

    // FIFO inputs

    reg wr_en;
    reg rd_en;

    reg [DATA_WIDTH-1:0] din;


    // FIFO outputs
    wire [DATA_WIDTH-1:0] dout;

    wire full;
    wire empty;

    wire almost_full;
    wire almost_empty;

    wire prog_full;
    wire prog_empty;

    // ECC status

    wire ecc_single_error;
    wire ecc_double_error;

    // DUT

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .PARITY_BITS(PARITY_BITS),
        .DEPTH(DEPTH),
        .SYNC_STAGES(2),

        .AFULL_LEVEL(DEPTH-2),
        .AEMPTY_LEVEL(2),
        .PFULL_LEVEL(DEPTH-4),
        .PEMPTY_LEVEL(4)
    )
    dut
    (
        .wr_clk(wr_clk),
        .wr_rst(wr_rst),
        .wr_en(wr_en),
        .din(din),

        .rd_clk(rd_clk),
        .rd_rst(rd_rst),
        .rd_en(rd_en),
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


    // Write clock

    initial
        wr_clk = 1'b0;

    always #5 wr_clk = ~wr_clk;


    // Read clock

    initial
        rd_clk = 1'b0;

    always #7 rd_clk = ~rd_clk;


    // Write one word

    task write_word;

        input [DATA_WIDTH-1:0] value;

        begin

            @(negedge wr_clk);

            din = value;
            wr_en = 1'b1;

            @(posedge wr_clk);

            #1;

            wr_en = 1'b0;
            din = 0;

        end

    endtask;


    // Read one word

    task read_word;

        begin

            // Wait until FIFO is no longer empty.
            wait(empty == 1'b0);

            @(negedge rd_clk);

            rd_en = 1'b1;

            @(posedge rd_clk);

            #2;

            rd_en = 1'b0;

        end

    endtask;


    // Wait for FIFO to become empty

    task wait_for_empty;

        begin

            wait(empty == 1'b1);

            repeat(2)
                @(posedge rd_clk);

        end

    endtask;


    // Display FIFO status

    task display_status;

        begin

            $display(
                "TIME=%0t | FULL=%b EMPTY=%b | AFULL=%b AEMPTY=%b | PFULL=%b PEMPTY=%b | DOUT=%h",
                $time,
                full,
                empty,
                almost_full,
                almost_empty,
                prog_full,
                prog_empty,
                dout
            );

        end

    endtask;


    // Main test

    initial
    begin

        // Initial values
        wr_rst = 1'b1;
        rd_rst = 1'b1;

        wr_en = 1'b0;
        rd_en = 1'b0;

        din = 0;

        // TEST 0 : RESET

        $display("TEST 0 : RESET");

        #40;

        wr_rst = 1'b0;
        rd_rst = 1'b0;

        repeat(5)
            @(posedge rd_clk);

        display_status();


        // TEST 1 : NORMAL WRITE / READ

       $display("TEST 1 : NORMAL WRITE / READ");

        // Write three different values and read them
        write_word(8'hA5);
        write_word(8'h3C);
        write_word(8'h55);

        $display("Written: A5, 3C, 55");


        // write pointer to crosses into read clock domain.
        repeat(6)
            @(posedge rd_clk);

        display_status();


        // Read A5

        read_word();

        $display("Read DOUT = %h", dout);

        if (dout == 8'hA5)
            $display("PASS: A5 received");
        else
            $display("FAIL: Expected A5, got %h", dout);


        // Read 3C

        read_word();

        $display("Read DOUT = %h", dout);

        if (dout == 8'h3C)
            $display("PASS: 3C received");
        else
            $display("FAIL: Expected 3C, got %h", dout);


        // Read 55

        read_word();

        $display("Read DOUT = %h", dout);

        if (dout == 8'h55)
            $display("PASS: 55 received");
        else
            $display("FAIL: Expected 55, got %h", dout);


        wait_for_empty();

        display_status();

        // TEST 2 : EMPTY / PROGRAMMABLE EMPTY THRESHOLDS
 
        $display("TEST 2 : EMPTY THRESHOLDS");


        // Write six words.
        // At an occupancy of 6, both flags should be low.

        write_word(8'h10);
        write_word(8'h11);
        write_word(8'h12);
        write_word(8'h13);
        write_word(8'h14);
        write_word(8'h15);

        repeat(8)
            @(posedge rd_clk);

        $display("FIFO now contains 6 words.");

        display_status();

        if (prog_empty == 1'b0)
            $display("PASS: prog_empty deasserted");
        else
            $display("FAIL: prog_empty should be 0 when occupancy > 4");

        if (almost_empty == 1'b0)
            $display("PASS: almost_empty deasserted");
        else
            $display("FAIL: almost_empty should be 0 when occupancy > 2");

        // Read three words.
        // Remaining occupancy = 3.
        
        read_word();
        read_word();
        read_word();

        repeat(5)
            @(posedge rd_clk);

        $display("FIFO should now contain approximately 3 words.");

        display_status();

        if (prog_empty == 1'b1)
            $display("PASS: prog_empty asserted at low occupancy");
        else
            $display("FAIL: prog_empty should be 1");


        // Read one more word.
        read_word();

        repeat(4)
            @(posedge rd_clk);

        display_status();

        if (almost_empty == 1'b1)
            $display("PASS: almost_empty asserted");
        else
            $display("FAIL: almost_empty should be 1");


        // Empty the remaining words.
        read_word();
        read_word();

        wait_for_empty();

        display_status();

        // TEST 3 : FULL / PROGRAMMABLE FULL THRESHOLDS

        $display("TEST 3 : FULL THRESHOLDS");

  

        write_word(8'h20);
        write_word(8'h21);
        write_word(8'h22);
        write_word(8'h23);
        write_word(8'h24);
        write_word(8'h25);
        write_word(8'h26);
        write_word(8'h27);
        write_word(8'h28);
        write_word(8'h29);
        write_word(8'h2A);
        write_word(8'h2B);
        write_word(8'h2C);

        repeat(8)
            @(posedge wr_clk);

        $display("FIFO should contain approximately 13 words.");

        display_status();

        if (prog_full == 1'b1)
            $display("PASS: prog_full asserted");
        else
            $display("FAIL: prog_full should be 1 at occupancy >= 12");

        if (almost_full == 1'b0)
            $display("PASS: almost_full still low below threshold");
        else
            $display("INFO: almost_full already asserted");


        // Write two more words.
     
        write_word(8'h2D);
        write_word(8'h2E);

        repeat(8)
            @(posedge wr_clk);

        $display("FIFO should contain approximately 15 words.");

        display_status();

        if (almost_full == 1'b1)
            $display("PASS: almost_full asserted");
        else
            $display("FAIL: almost_full should be 1");


        // Read all stored data back.
        repeat(15)
            read_word();

        wait_for_empty();

        display_status();


        // TEST 4 : SINGLE-BIT ECC ERROR

        $display("TEST 4 : SINGLE-BIT ECC ERROR");
 

        // Reset the FIFO so the next write uses memory address 0.
        wr_rst = 1'b1;
        rd_rst = 1'b1;

        wr_en = 1'b0;
        rd_en = 1'b0;

        din = 0;

        #40;

        wr_rst = 1'b0;
        rd_rst = 1'b0;

        repeat(5)
            @(posedge rd_clk);


        // Write 3C to memory address 0.
        write_word(8'h3C);

        repeat(5)
            @(posedge wr_clk);

        $display("Wrote 3C to FIFO.");


        // Inject a single-bit error.

        dut.mem_inst.mem[0][5] =
            ~dut.mem_inst.mem[0][5];

        $display("Injected SINGLE-BIT error at mem[0][5]");

        repeat(8)
            @(posedge rd_clk);


        // Read the corrupted word.
        read_word();

        #2;

        $display("DOUT = %h", dout);
        $display("ECC SINGLE = %b", ecc_single_error);
        $display("ECC DOUBLE = %b", ecc_double_error);


        if ((dout == 8'h3C) &&(ecc_single_error == 1'b1) &&(ecc_double_error == 1'b0))
        begin
            $display("PASS: Single-bit error detected and corrected");
        end
        else
        begin
            $display("FAIL: Single-bit ECC test");
        end


        wait_for_empty();

        // TEST 5 : DOUBLE-BIT ECC ERROR

        $display("TEST 5 : DOUBLE-BIT ECC ERROR");
 

        // Reset again so that memory address 0 is used.
        wr_rst = 1'b1;
        rd_rst = 1'b1;

        wr_en = 1'b0;
        rd_en = 1'b0;

        din = 0;

        #40;

        wr_rst = 1'b0;
        rd_rst = 1'b0;

        repeat(5)
            @(posedge rd_clk);


        // Write 55 to memory address 0.
        write_word(8'h55);

        repeat(5)
            @(posedge wr_clk);

        $display("Wrote 55 to FIFO.");


        // Inject two errors into the ECC codeword.
        
        dut.mem_inst.mem[0][5] = ~dut.mem_inst.mem[0][5];

        dut.mem_inst.mem[0][8] = ~dut.mem_inst.mem[0][8];

        $display(
            "Injected DOUBLE-BIT error at mem[0][5] and mem[0][8]"
        );

        repeat(8)
            @(posedge rd_clk);


        // Read the corrupted word.
        read_word();

        #2;

        $display("DOUT = %h", dout);
        $display("ECC SINGLE = %b", ecc_single_error);
        $display("ECC DOUBLE = %b", ecc_double_error);


        if ((ecc_single_error == 1'b0) && (ecc_double_error == 1'b1))
        begin
            $display("PASS: Double-bit error detected");
        end
        else
        begin
            $display("FAIL: Double-bit ECC test");
        end

        // FINAL STATUS

        #50;

        $display("ASYNC FIFO VERIFICATION COMPLETE");
        $finish;

    end

endmodule