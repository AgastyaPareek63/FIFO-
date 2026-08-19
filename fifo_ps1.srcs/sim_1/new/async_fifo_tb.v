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

//--------------------------------------------------
// DUT
//--------------------------------------------------

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

//--------------------------------------------------
// Clock Generation
//--------------------------------------------------

initial wr_clk = 0;
always #5 wr_clk = ~wr_clk;

initial rd_clk = 0;
always #7 rd_clk = ~rd_clk;

//--------------------------------------------------
// Monitor
//--------------------------------------------------

initial begin

$monitor(
"Time=%0t WR_BIN=%0d RD_BIN=%0d DIN=%h DOUT=%h FULL=%b EMPTY=%b",
$time,
dut.wr_bin,
dut.rd_bin,
din,
dout,
full,
empty
);

end

//--------------------------------------------------
// Test
//--------------------------------------------------

initial begin

    wr_rst = 1;
    rd_rst = 1;
    wr_en  = 0;
    rd_en  = 0;
    din    = 0;

    #20;

    wr_rst = 0;
    rd_rst = 0;

    //--------------------------------------------------
    // Test 1 : Normal FIFO
    //--------------------------------------------------

    $display("\n========== TEST 1 ==========");

    @(posedge wr_clk);
    wr_en = 1;
    din = 8'hA5;

    @(posedge wr_clk);
    wr_en = 0;

    repeat(3) @(posedge rd_clk);

    @(posedge rd_clk);
    rd_en = 1;

    @(posedge rd_clk);
    rd_en = 0;

    #20;

    $display("Expected = A5");
    $display("Received = %h",dout);

    //--------------------------------------------------
    // Test 2 : Single Bit Error
    //--------------------------------------------------

    $display("\n========== TEST 2 ==========");

    @(posedge wr_clk);
    wr_en = 1;
    din = 8'h3C;

    @(posedge wr_clk);
    wr_en = 0;

    // Flip one bit inside FIFO memory
    #2;
    dut.mem_inst.mem[1][5] = ~dut.mem_inst.mem[1][5];

    repeat(3) @(posedge rd_clk);

    @(posedge rd_clk);
    rd_en = 1;

    @(posedge rd_clk);
    rd_en = 0;

    #20;

    $display("Expected = 3C");
    $display("Received = %h",dout);

    //--------------------------------------------------
    // Test 3 : Double Bit Error
    //--------------------------------------------------

    $display("\n========== TEST 3 ==========");

    @(posedge wr_clk);
    wr_en = 1;
    din = 8'h55;

    @(posedge wr_clk);
    wr_en = 0;

    #2;

    dut.mem_inst.mem[2][5] = ~dut.mem_inst.mem[2][5];
    dut.mem_inst.mem[2][8] = ~dut.mem_inst.mem[2][8];

    repeat(3) @(posedge rd_clk);

    @(posedge rd_clk);
    rd_en = 1;

    @(posedge rd_clk);
    rd_en = 0;

    #20;

    $display("Expected Double Error Detection");
    $display("Received = %h",dout);

    #50;

    $finish;

end

endmodule