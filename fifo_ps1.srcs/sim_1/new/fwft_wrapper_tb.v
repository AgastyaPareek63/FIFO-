`timescale 1ns/1ps

module fwft_wrapper_tb;

parameter DATA_WIDTH = 8;
parameter DEPTH = 4;

reg clk;
reg rst;

reg [DATA_WIDTH-1:0] fifo_dout;
reg fifo_empty;

wire fifo_rd_en;

reg rd_en;

wire [DATA_WIDTH-1:0] dout;
wire empty;


//--------------------------------------------------
// DUT
//--------------------------------------------------

fwft_wrapper #(
    .DATA_WIDTH(DATA_WIDTH)
) dut (
    .clk(clk),
    .rst(rst),

    .fifo_dout(fifo_dout),
    .fifo_empty(fifo_empty),
    .fifo_rd_en(fifo_rd_en),

    .dout(dout),
    .empty(empty),

    .rd_en(rd_en)
);


//--------------------------------------------------
// Clock
//--------------------------------------------------

initial
    clk = 0;

always #5 clk = ~clk;


//--------------------------------------------------
// Simple FIFO Model
//--------------------------------------------------

reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];

integer rd_ptr;
integer fifo_count;


//--------------------------------------------------
// FIFO Model
//
// fifo_dout changes one clock after fifo_rd_en.
// This matches the registered read behavior of
// our fifo_memory module.
//--------------------------------------------------

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        rd_ptr     <= 0;
        fifo_count <= 0;
        fifo_dout  <= 0;
        fifo_empty <= 1;
    end
    else
    begin

        if(fifo_rd_en && fifo_count != 0)
        begin
            fifo_dout <= fifo_mem[rd_ptr];

            if(rd_ptr == DEPTH-1)
                rd_ptr <= 0;
            else
                rd_ptr <= rd_ptr + 1;

            fifo_count <= fifo_count - 1;
        end

        if(fifo_count == 0)
            fifo_empty <= 1;
        else
            fifo_empty <= 0;

    end
end


//--------------------------------------------------
// Main Test
//--------------------------------------------------

initial
begin

    rst = 1;
    rd_en = 0;

    fifo_dout = 0;
    fifo_empty = 1;

    rd_ptr = 0;
    fifo_count = 0;

    #20;

    rst = 0;


    //------------------------------------------------
    // Put three words into FIFO model
    //------------------------------------------------

    fifo_mem[0] = 8'hA5;
    fifo_mem[1] = 8'h3C;
    fifo_mem[2] = 8'h55;

    fifo_count = 3;
    fifo_empty = 0;


    //------------------------------------------------
    // TEST 1 : First Word Fall Through
    //------------------------------------------------

    $display("\n====================================");
    $display("TEST 1 : FIRST WORD FALL THROUGH");
    $display("====================================");

    wait(empty == 0);

    repeat(3)
        @(posedge clk);

    $display("DOUT = %h", dout);
    $display("EMPTY = %b", empty);

    if(dout == 8'hA5 && empty == 0)
        $display("TEST 1 PASSED");
    else
        $display("TEST 1 FAILED");


    //------------------------------------------------
    // TEST 2 : Read First Word
    //------------------------------------------------

    $display("\n====================================");
    $display("TEST 2 : READ FIRST WORD");
    $display("====================================");

    @(negedge clk);

    rd_en = 1;

    @(negedge clk);

    rd_en = 0;

    repeat(2)
        @(posedge clk);

    $display("DOUT = %h", dout);
    $display("EMPTY = %b", empty);


    //------------------------------------------------
    // TEST 3 : Next Word
    //------------------------------------------------

    $display("\n====================================");
    $display("TEST 3 : NEXT WORD");
    $display("====================================");

    repeat(3)
        @(posedge clk);

    $display("DOUT = %h", dout);
    $display("EMPTY = %b", empty);

    if(dout == 8'h3C && empty == 0)
        $display("TEST 3 PASSED");
    else
        $display("TEST 3 FAILED");


    //------------------------------------------------
    // TEST 4 : Read Second Word
    //------------------------------------------------

    @(negedge clk);

    rd_en = 1;

    @(negedge clk);

    rd_en = 0;

    repeat(3)
        @(posedge clk);


    //------------------------------------------------
    // TEST 5 : Third Word
    //------------------------------------------------

    $display("\n====================================");
    $display("TEST 5 : THIRD WORD");
    $display("====================================");

    $display("DOUT = %h", dout);
    $display("EMPTY = %b", empty);

    if(dout == 8'h55 && empty == 0)
        $display("TEST 5 PASSED");
    else
        $display("TEST 5 FAILED");


    //------------------------------------------------
    // Finish
    //------------------------------------------------

    #20;

    $display("\n====================================");
    $display("FWFT TEST COMPLETE");
    $display("====================================");

    $finish;

end

endmodule