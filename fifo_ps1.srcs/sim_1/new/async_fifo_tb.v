`timescale 1ns/1ps

module async_fifo_tb;

    parameter DATA_WIDTH = 8;
    parameter DEPTH = 16;
    parameter ADDR_WIDTH = $clog2(DEPTH);

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

    integer i;
    integer errors;

    // Used to remember where a test word was written.
    integer write_address;


    //==================================================
    // DUT
    //==================================================

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


    //==================================================
    // CLOCKS
    //==================================================

    initial begin
        wr_clk = 0;
        forever #5 wr_clk = ~wr_clk;
    end

    initial begin
        rd_clk = 0;
        forever #7 rd_clk = ~rd_clk;
    end


    //==================================================
    // RESET TASK
    //==================================================

    task reset_fifo;
    begin

        wr_rst = 1;
        rd_rst = 1;

        wr_en = 0;
        rd_en = 0;

        din = 0;

        #20;

        wr_rst = 0;
        rd_rst = 0;

        // Give the synchronizers some time to settle.
        repeat(3)
            @(posedge wr_clk);

        repeat(3)
            @(posedge rd_clk);

    end
    endtask


    //==================================================
    // WRITE ONE WORD
    //==================================================

    task write_word;
        input [DATA_WIDTH-1:0] data;
    begin

        @(negedge wr_clk);

        din = data;
        wr_en = 1;

        @(posedge wr_clk);

        @(negedge wr_clk);

        wr_en = 0;

    end
    endtask


    //==================================================
    // READ ONE WORD
    //==================================================

    task read_word;
    begin

        @(negedge rd_clk);

        rd_en = 1;

        @(posedge rd_clk);

        #1;

        @(negedge rd_clk);

        rd_en = 0;

        #1;

    end
    endtask


    //==================================================
    // MAIN TEST
    //==================================================

    initial begin

        errors = 0;

        wr_rst = 1;
        rd_rst = 1;
        wr_en = 0;
        rd_en = 0;
        din = 0;


        //================================================
        // TEST 1 : RESET
        //================================================

        $display("");
        $display("========================================");
        $display("TEST 1 : RESET");
        $display("========================================");

        reset_fifo;

        #5;

        if (empty == 1'b1)
            $display("PASS : FIFO is empty after reset");
        else begin
            $display("FAIL : FIFO is not empty after reset");
            errors = errors + 1;
        end


        //================================================
        // TEST 2 : NORMAL WRITE / READ
        //================================================

        $display("");
        $display("========================================");
        $display("TEST 2 : NORMAL WRITE / READ");
        $display("========================================");

        reset_fifo;

        write_word(8'hA5);

        // The write pointer must cross into the
        // read clock domain before empty changes.
        repeat(4)
            @(posedge rd_clk);

        if (empty == 1'b0)
            $display("PASS : FIFO contains data");
        else begin
            $display("FAIL : FIFO still reports empty");
            errors = errors + 1;
        end

        read_word;

        if (dout == 8'hA5)
            $display("PASS : Read A5 correctly");
        else begin
            $display("FAIL : Expected A5, got %h", dout);
            errors = errors + 1;
        end


        //================================================
        // TEST 3 : MULTIPLE DATA
        //================================================

        $display("");
        $display("========================================");
        $display("TEST 3 : MULTIPLE DATA");
        $display("========================================");

        reset_fifo;

        write_word(8'h11);
        write_word(8'h22);
        write_word(8'h33);
        write_word(8'h44);

        repeat(4)
            @(posedge rd_clk);

        read_word;

        if (dout == 8'h11)
            $display("PASS : Read 11");
        else begin
            $display("FAIL : Expected 11, got %h", dout);
            errors = errors + 1;
        end

        read_word;

        if (dout == 8'h22)
            $display("PASS : Read 22");
        else begin
            $display("FAIL : Expected 22, got %h", dout);
            errors = errors + 1;
        end

        read_word;

        if (dout == 8'h33)
            $display("PASS : Read 33");
        else begin
            $display("FAIL : Expected 33, got %h", dout);
            errors = errors + 1;
        end

        read_word;

        if (dout == 8'h44)
            $display("PASS : Read 44");
        else begin
            $display("FAIL : Expected 44, got %h", dout);
            errors = errors + 1;
        end


        //================================================
        // TEST 4 : FIFO FULL
        //================================================

        $display("");
        $display("========================================");
        $display("TEST 4 : FIFO FULL");
        $display("========================================");

        reset_fifo;

        for (i = 0; i < DEPTH; i = i + 1) begin

            @(negedge wr_clk);

            din = i;
            wr_en = 1;

            @(posedge wr_clk);

        end

        @(negedge wr_clk);
        wr_en = 0;

        // Allow full flag to settle.
        repeat(3)
            @(posedge wr_clk);

        if (full == 1'b1)
            $display("PASS : FIFO reached FULL");
        else begin
            $display("FAIL : FIFO did not reach FULL");
            errors = errors + 1;
        end


        //================================================
        // TEST 5 : FIFO EMPTY
        //================================================

        $display("");
        $display("========================================");
        $display("TEST 5 : FIFO EMPTY");
        $display("========================================");

        reset_fifo;

        write_word(8'h55);

        repeat(4)
            @(posedge rd_clk);

        read_word;

        repeat(3)
            @(posedge rd_clk);

        if (empty == 1'b1)
            $display("PASS : FIFO returned to EMPTY");
        else begin
            $display("FAIL : FIFO did not become EMPTY");
            errors = errors + 1;
        end


        //================================================
        // TEST 6 : ECC SINGLE BIT ERROR
        //================================================

        $display("");
        $display("========================================");
        $display("TEST 6 : ECC SINGLE BIT ERROR");
        $display("========================================");

        reset_fifo;

        // Capture the address before performing the write.
        @(negedge wr_clk);

        write_address = dut.wr_bin[ADDR_WIDTH-1:0];

        din = 8'h3C;
        wr_en = 1;

        @(posedge wr_clk);

        @(negedge wr_clk);
        wr_en = 0;

        $display("Data 3C written at memory address %0d",
                 write_address);

        // Wait for the write pointer to reach
        // the read clock domain.
        repeat(4)
            @(posedge rd_clk);

        // Corrupt exactly one ECC bit.
        dut.mem_inst.mem[write_address][5] =
            ~dut.mem_inst.mem[write_address][5];

        $display("One ECC bit corrupted");

        read_word;

        $display("DOUT = %h", dout);
        $display("SINGLE ERROR = %b", ecc_single_error);
        $display("DOUBLE ERROR = %b", ecc_double_error);

        if ((dout == 8'h3C) &&
            (ecc_single_error == 1'b1) &&
            (ecc_double_error == 1'b0)) begin

            $display("PASS : Single-bit error corrected");

        end
        else begin

            $display("FAIL : Single-bit ECC test");
            errors = errors + 1;

        end


        //================================================
        // TEST 7 : ECC DOUBLE BIT ERROR
        //================================================

        $display("");
        $display("========================================");
        $display("TEST 7 : ECC DOUBLE BIT ERROR");
        $display("========================================");

        reset_fifo;

        @(negedge wr_clk);

        write_address = dut.wr_bin[ADDR_WIDTH-1:0];

        din = 8'h55;
        wr_en = 1;

        @(posedge wr_clk);

        @(negedge wr_clk);
        wr_en = 0;

        $display("Data 55 written at memory address %0d",
                 write_address);

        repeat(4)
            @(posedge rd_clk);

        // Corrupt two different ECC bits.
        dut.mem_inst.mem[write_address][5] =
            ~dut.mem_inst.mem[write_address][5];

        dut.mem_inst.mem[write_address][8] =
            ~dut.mem_inst.mem[write_address][8];

        $display("Two ECC bits corrupted");

        read_word;

        $display("DOUT = %h", dout);
        $display("SINGLE ERROR = %b", ecc_single_error);
        $display("DOUBLE ERROR = %b", ecc_double_error);

        if ((ecc_single_error == 1'b0) &&
            (ecc_double_error == 1'b1)) begin

            $display("PASS : Double-bit error detected");

        end
        else begin

            $display("FAIL : Double-bit ECC test");
            errors = errors + 1;

        end


        //================================================
        // FINAL RESULT
        //================================================

        $display("");
        $display("========================================");

        if (errors == 0) begin
            $display("ALL TESTS PASSED");
        end
        else begin
            $display("TESTS FAILED : %0d error(s)", errors);
        end

        $display("========================================");
        $display("");

        #20;

        $finish;

    end

endmodule