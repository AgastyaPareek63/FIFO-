`timescale 1ns/1ps

module async_fifo_ecc_tb;

    parameter DATA_WIDTH = 8;
    parameter DEPTH = 16;

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


    // DUT
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
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


    // Write Clock
    initial wr_clk = 0;
    always #5 wr_clk = ~wr_clk;

    // Read Clock
    initial rd_clk = 0;
    always #7 rd_clk = ~rd_clk;


    initial begin

        // Initial values
        wr_rst = 1;
        rd_rst = 1;
        wr_en  = 0;
        rd_en  = 0;
        din    = 0;

        // Reset
        #20;
        wr_rst = 0;
        rd_rst = 0;


        // ==========================================
        // TEST 1 : NORMAL ECC OPERATION
        // ==========================================

        $display("TEST 1: Normal ECC Operation");

        @(negedge wr_clk);
        din   = 8'hA5;
        wr_en = 1;

        @(negedge wr_clk);
        wr_en = 0;

        #50;

        @(negedge rd_clk);
        rd_en = 1;

        @(negedge rd_clk);
        rd_en = 0;

        #10;

        if (dout == 8'hA5 &&
            ecc_single_error == 0 &&
            ecc_double_error == 0)
            $display("PASS: Normal data read correctly");
        else
            $display("FAIL: Normal ECC operation");


        // Reset before next test
        #20;
        wr_rst = 1;
        rd_rst = 1;

        #20;
        wr_rst = 0;
        rd_rst = 0;


        // ==========================================
        // TEST 2 : SINGLE-BIT ERROR
        // ==========================================

        $display("TEST 2: Single-Bit Error Correction");

        @(negedge wr_clk);
        din   = 8'h3C;
        wr_en = 1;

        @(negedge wr_clk);
        wr_en = 0;

        #50;

        // Inject single-bit error
        dut.mem_inst.mem[0][5] =
            ~dut.mem_inst.mem[0][5];

        @(negedge rd_clk);
        rd_en = 1;

        @(negedge rd_clk);
        rd_en = 0;

        #10;

        if (dout == 8'h3C &&
            ecc_single_error == 1 &&
            ecc_double_error == 0)
            $display("PASS: Single-bit error corrected");
        else
            $display("FAIL: Single-bit error test");


        // Reset before next test
        #20;
        wr_rst = 1;
        rd_rst = 1;

        #20;
        wr_rst = 0;
        rd_rst = 0;


        // ==========================================
        // TEST 3 : DOUBLE-BIT ERROR
        // ==========================================

        $display("TEST 3: Double-Bit Error Detection");

        @(negedge wr_clk);
        din   = 8'h55;
        wr_en = 1;

        @(negedge wr_clk);
        wr_en = 0;

        #50;

        // Inject two-bit error
        dut.mem_inst.mem[0][5] =
            ~dut.mem_inst.mem[0][5];

        dut.mem_inst.mem[0][8] =
            ~dut.mem_inst.mem[0][8];

        @(negedge rd_clk);
        rd_en = 1;

        @(negedge rd_clk);
        rd_en = 0;

        #10;

        if (ecc_single_error == 0 &&
            ecc_double_error == 1)
            $display("PASS: Double-bit error detected");
        else
            $display("FAIL: Double-bit error test");


        #20;

        $display("------------------------------");
        $display("ECC TEST COMPLETED");
        $display("------------------------------");

        $finish;

    end

endmodule
