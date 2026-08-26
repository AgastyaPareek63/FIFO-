`timescale 1ns/1ps

module tb_sync_fifo;

    parameter DATA_WIDTH = 8;// width of data
    parameter DEPTH = 16;// no. of FIFO entries

    reg clk;
    reg rst;

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


    // DUT

    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .AFULL_LEVEL(DEPTH-2),
        .AEMPTY_LEVEL(2),
        .PFULL_LEVEL(DEPTH-4),
        .PEMPTY_LEVEL(4)
    ) dut (
        .clk(clk),
        .rst(rst),

        .wr_en(wr_en),
        .rd_en(rd_en),

        .din(din),
        .dout(dout),

        .full(full),
        .empty(empty),

        .almost_full(almost_full),
        .almost_empty(almost_empty),

        .prog_full(prog_full),
        .prog_empty(prog_empty)
    );


    // Clock

    // 10 ns clock period.
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    // Tests

    integer i;

    initial begin

        rst = 1;
        wr_en = 0;
        rd_en = 0;
        din = 0;


        // Reset FIFO before starting the tests.
        repeat (2) @(posedge clk);
        rst = 0;

        $display("Starting FIFO Test");

        // TEST 1: Check EMPTY after reset

        @(negedge clk);

        if (empty)
            $display("PASS: FIFO is EMPTY after reset");
        else
            $display("FAIL: FIFO is not EMPTY after reset");


        // TEST 2: Write 8 values

        for (i = 0; i < 8; i = i + 1) begin

            @(negedge clk);

            wr_en = 1;
            din = 8'h10 + i;

        end

        @(negedge clk);

        wr_en = 0;
        din = 0;

        $display("PASS: Wrote 8 values");

        // TEST 3: Read the 8 values

        for (i = 0; i < 8; i = i + 1) begin

            @(negedge clk);

            rd_en = 1;

            @(posedge clk);
            #1;

            if (dout == (8'h10 + i))
                $display("PASS: Read %h", dout);
            else
                $display("FAIL: Expected %h, got %h",(8'h10 + i), dout);

        end

        @(negedge clk);
        rd_en = 0;

        // TEST 4: Check EMPTY after reading everything

        @(posedge clk);
        #1;

        if (empty)
            $display("PASS: FIFO is EMPTY after reads");
        else
            $display("FAIL: FIFO is not EMPTY");

        // TEST 5: Fill FIFO completely

        for (i = 0; i < DEPTH; i = i + 1) begin

            @(negedge clk);

            wr_en = 1;
            din = i;

        end

        @(negedge clk);

        wr_en = 0;
        din = 0;

        @(posedge clk);
        #1;

        if (full)
            $display("PASS: FIFO is FULL");
        else
            $display("FAIL: FIFO did not become FULL");

        // TEST 6: Attempt WRITE while FULL

        @(negedge clk);

        wr_en = 1;
        rd_en = 0;
        din = 8'hFF;

        @(posedge clk);
        #1;

        @(negedge clk);

        wr_en = 0;

        if (full)
            $display("PASS: FIFO remains FULL");
        else
            $display("FAIL: FIFO no longer FULL");

        // TEST 7: Simultaneous READ + WRITE while FULL

        @(negedge clk);

        wr_en = 1;
        rd_en = 1;
        din = 8'hAA;

        @(posedge clk);
        #1;

        @(negedge clk);

        wr_en = 0;
        rd_en = 0;

        if (full)
            $display("PASS: FIFO remains FULL after simultaneous READ/WRITE");
        else
            $display("FAIL: FIFO should remain FULL");

        // TEST 8: Read FIFO completely

        // Read all remaining entries from the FIFO.
        for (i = 0; i < DEPTH; i = i + 1) begin

            @(negedge clk);

            rd_en = 1;

            @(posedge clk);
            #1;

            $display("Read data = %h", dout);

        end

        @(negedge clk);

        rd_en = 0;

        // TEST 9: Check EMPTY at the end

        @(posedge clk);
        #1;

        if (empty)
            $display("PASS: FIFO is EMPTY at end");
        else
            $display("FAIL: FIFO is not EMPTY at end");

        // Finish
        
        $display("FIFO Test Completed");
      
        #20;
        $finish;

    end

endmodule