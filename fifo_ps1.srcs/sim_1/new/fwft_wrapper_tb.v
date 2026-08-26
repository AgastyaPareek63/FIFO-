`timescale 1ns/1ps

module fwft_wrapper_tb;

    parameter DATA_WIDTH = 8;
    parameter DEPTH      = 4;

    reg clk;
    reg rst;

    // FIFO side
    reg  [DATA_WIDTH-1:0] fifo_dout;
    wire                  fifo_empty;
    wire                  fifo_rd_en;

    // User side
    reg                   rd_en;
    wire [DATA_WIDTH-1:0] dout;
    wire                  empty;


    // DUT

    fwft_wrapper #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk        (clk),
        .rst        (rst),

        .fifo_dout  (fifo_dout),
        .fifo_empty (fifo_empty),
        .fifo_rd_en (fifo_rd_en),

        .dout       (dout),
        .empty      (empty),

        .rd_en      (rd_en)
    );


    // Clock

    initial
        clk = 1'b0;

    always #5 clk = ~clk;


    // Simple FIFO model

    reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];

    integer rd_ptr;
    integer fifo_count;

    assign fifo_empty = (fifo_count == 0);


    // Registered FIFO read

    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            rd_ptr     <= 0;
            fifo_count <= 0;
            fifo_dout  <= 0;
        end
        else
        begin
            if (fifo_rd_en && fifo_count != 0)
            begin
                fifo_dout <= fifo_mem[rd_ptr];

                if (rd_ptr == DEPTH-1)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1;

                fifo_count <= fifo_count - 1;
            end
        end
    end


    // Check output

    task check_output;

        input [DATA_WIDTH-1:0] expected_data;
        input                  expected_empty;

        begin

            if ((dout === expected_data) &&
                (empty === expected_empty))
            begin
                $display(
                    "PASS: time=%0t | DOUT=%h | EMPTY=%b",
                    $time,
                    dout,
                    empty
                );
            end
            else
            begin
                $display(
                    "FAIL: time=%0t | Expected DOUT=%h EMPTY=%b | Got DOUT=%h EMPTY=%b",
                    $time,
                    expected_data,
                    expected_empty,
                    dout,
                    empty
                );
            end

        end

    endtask


    // Test sequence

    initial
    begin

        rst = 1'b1;
        rd_en = 1'b0;

        fifo_dout  = 0;
        rd_ptr     = 0;
        fifo_count = 0;

        #20;
        rst = 1'b0;


        // Load test data
        fifo_mem[0] = 8'hA5;
        fifo_mem[1] = 8'h3C;
        fifo_mem[2] = 8'h55;

        fifo_count = 3;


        $display("");
        $display("========================================");
        $display("       FWFT FIFO VERIFICATION");
        $display("========================================");


        // TEST 1

        $display("");
        $display("TEST 1: FIRST WORD");

        wait(empty == 1'b0);
        wait(dout == 8'hA5);

        check_output(8'hA5, 1'b0);


        // TEST 2

        $display("");
        $display("TEST 2: SECOND WORD");

        @(negedge clk);
        rd_en = 1'b1;

        @(negedge clk);
        rd_en = 1'b0;

        wait(dout == 8'h3C);

        check_output(8'h3C, 1'b0);


        // TEST 3

        $display("");
        $display("TEST 3: THIRD WORD");

        @(negedge clk);
        rd_en = 1'b1;

        @(negedge clk);
        rd_en = 1'b0;

        wait(dout == 8'h55);

        check_output(8'h55, 1'b0);


        // TEST 4

        $display("");
        $display("TEST 4: FINAL WORD");

        @(negedge clk);
        rd_en = 1'b1;

        @(negedge clk);
        rd_en = 1'b0;

        wait(empty == 1'b1);

        if (empty)
            $display("PASS: FIFO output is empty");
        else
            $display("FAIL: FIFO output is not empty");


        // TEST 5

        $display("");
        $display("TEST 5: EMPTY FIFO");

        #1;

        if (fifo_rd_en == 1'b0 && empty == 1'b1)
            $display("PASS: No unnecessary read");
        else
            $display("FAIL: Unexpected read request");


        // TEST 6

        $display("");
        $display("TEST 6: REFILL");

        fifo_mem[3] = 8'hF0;
        fifo_count = 1;

        wait(empty == 1'b0);
        wait(dout == 8'hF0);

        check_output(8'hF0, 1'b0);


        #20;

        $display("");
        $display("========================================");
        $display("       FWFT VERIFICATION COMPLETE");
        $display("========================================");

        $finish;

    end

endmodule