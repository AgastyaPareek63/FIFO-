`timescale 1ns/1ps

module fwft_wrapper_tb;

parameter DATA_WIDTH = 8;

reg clk;
reg rst;

reg [DATA_WIDTH-1:0] fifo_dout;
reg fifo_empty;

wire fifo_rd_en;

wire [DATA_WIDTH-1:0] dout;
wire empty;

reg rd_en;

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

initial clk = 0;
always #5 clk = ~clk;

//--------------------------------------------------
// Test
//--------------------------------------------------

initial
begin

    rst = 1;
    fifo_empty = 1;
    fifo_dout = 0;
    rd_en = 0;

    #20;

    rst = 0;

    //--------------------------------------------------
    // FIFO receives first word
    //--------------------------------------------------

    fifo_empty = 0;
    fifo_dout = 8'hA5;

    #20;

    $display("FWFT Output = %h", dout);

    //--------------------------------------------------
    // User reads data
    //--------------------------------------------------

    rd_en = 1;

    #10;

    rd_en = 0;

    //--------------------------------------------------
    // Next word
    //--------------------------------------------------

    fifo_dout = 8'h3C;

    #20;

    $display("Next Output = %h", dout);

    #20;

    $finish;

end

endmodule