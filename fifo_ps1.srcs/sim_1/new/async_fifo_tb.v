`timescale 1ns/1ps

module async_fifo_tb;

    parameter DATA_WIDTH  = 8;
    parameter PARITY_BITS = 4;
    parameter DEPTH       = 16;

    reg wr_clk;
    reg rd_clk;

    reg wr_rst;
    reg rd_rst;

    reg wr_en;
    reg rd_en;

    reg [DATA_WIDTH-1:0] din;

    wire [DATA_WIDTH-1:0] dout;

    wire full;
    wire empty;

    wire almost_full;
    wire almost_empty;

    wire prog_full;
    wire prog_empty;

    wire ecc_single_error;
    wire ecc_double_error;


    // --------------------------------------------------
    // DUT
    // --------------------------------------------------

    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .PARITY_BITS(PARITY_BITS),
        .DEPTH(DEPTH),
        .SYNC_STAGES(2)
    ) dut (

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


    // --------------------------------------------------
    // Write clock
    // --------------------------------------------------

    initial
        wr_clk = 0;

    always #5 wr_clk = ~wr_clk;


    // --------------------------------------------------
    // Read clock
    // --------------------------------------------------

    initial
        rd_clk = 0;

    always #7 rd_clk = ~rd_clk;


    // --------------------------------------------------
    // Test sequence
    // --------------------------------------------------

    initial
    begin

        wr_rst = 1;
        rd_rst = 1;

        wr_en = 0;
        rd_en = 0;

        din = 0;


        // --------------------------------------------------
        // Reset
        // --------------------------------------------------

        #30;

        wr_rst = 0;
        rd_rst = 0;


        // --------------------------------------------------
        // TEST 1: Normal write
        // --------------------------------------------------

        $display("");
        $display("====================================");
        $display("TEST 1 : NORMAL WRITE");
        $display("====================================");

        @(negedge wr_clk);

        din   = 8'hA5;
        wr_en = 1;

        @(negedge wr_clk);

        wr_en = 0;
        din   = 0;

        $display("Wrote A5");


        // Allow pointer synchronization.
        #50;


        // --------------------------------------------------
        // TEST 2: Normal read
        // --------------------------------------------------

        $display("");
        $display("====================================");
        $display("TEST 2 : NORMAL READ");
        $display("====================================");

        @(negedge rd_clk);

        rd_en = 1;

        @(posedge rd_clk);

        #1;

        $display("DOUT = %h", dout);

        if (dout == 8'hA5)
            $display("PASS: Correct data received");
        else
            $display("FAIL: Expected A5");


        @(negedge rd_clk);

        rd_en = 0;


        // --------------------------------------------------
        // Wait until FIFO becomes empty.
        // --------------------------------------------------

        #40;


        // --------------------------------------------------
        // TEST 3: Single-bit ECC error
        // --------------------------------------------------

        $display("");
        $display("====================================");
        $display("TEST 3 : SINGLE-BIT ECC ERROR");
        $display("====================================");


        // Write another word.

        @(negedge wr_clk);

        din   = 8'h3C;
        wr_en = 1;

        @(negedge wr_clk);

        wr_en = 0;
        din = 0;


        // Wait for the write pointer to cross
        // into the read clock domain.

        #50;


        // Corrupt one bit in the stored ECC codeword.
        //
        // Memory location 0 contains the first entry.
        // Bit 5 is deliberately flipped.

        dut.mem_inst.mem[0][5] =
            ~dut.mem_inst.mem[0][5];

        $display("Injected single-bit error");


        // Read the corrupted word.

        @(negedge rd_clk);

        rd_en = 1;

        @(posedge rd_clk);

        #1;

        $display("DOUT = %h", dout);
        $display("Single Error = %b", ecc_single_error);
        $display("Double Error = %b", ecc_double_error);


        if ((dout == 8'h3C) &&
            (ecc_single_error == 1'b1) &&
            (ecc_double_error == 1'b0))
        begin
            $display("PASS: Single-bit error corrected");
        end
        else
        begin
            $display("FAIL: Single-bit ECC test");
        end


        @(negedge rd_clk);

        rd_en = 0;


        // --------------------------------------------------
        // Wait until FIFO becomes empty.
        // --------------------------------------------------

        #40;


        // --------------------------------------------------
        // TEST 4: Double-bit ECC error
        // --------------------------------------------------

        $display("");
        $display("====================================");
        $display("TEST 4 : DOUBLE-BIT ECC ERROR");
        $display("====================================");


        // Write another word.

        @(negedge wr_clk);

        din   = 8'h55;
        wr_en = 1;

        @(negedge wr_clk);

        wr_en = 0;
        din = 0;


        #50;


        // Inject two bit errors.

        dut.mem_inst.mem[1][5] =
    ~dut.mem_inst.mem[1][5];

        dut.mem_inst.mem[2][8] =
            ~dut.mem_inst.mem[2][8];

        $display("Injected double-bit error");


        // Read the corrupted word.

        @(negedge rd_clk);

        rd_en = 1;

        @(posedge rd_clk);

        #1;

        $display("DOUT = %h", dout);
        $display("Single Error = %b", ecc_single_error);
        $display("Double Error = %b", ecc_double_error);


        if ((ecc_single_error == 1'b0) &&
            (ecc_double_error == 1'b1))
        begin
            $display("PASS: Double-bit error detected");
        end
        else
        begin
            $display("FAIL: Double-bit ECC test");
        end


        @(negedge rd_clk);

        rd_en = 0;


        // --------------------------------------------------
        // Finish
        // --------------------------------------------------

        #30;

        $display("");
        $display("====================================");
        $display("ASYNC FIFO ECC TEST COMPLETE");
        $display("====================================");

        $finish;

    end

endmodule