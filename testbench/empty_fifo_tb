`timescale 1ns/1ps

module empty_fifo_tb;

    reg clk;
    reg rst;
    reg wr_en;
    reg rd_en;
    reg [7:0] din;

    wire [7:0] dout;
    wire full;
    wire empty;
    wire almost_full;
    wire almost_empty;
    wire prog_full;
    wire prog_empty;

  
    sync_fifo uut (
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

  
    always #5 clk = ~clk;

    initial begin

        // Initial values
        clk   = 0;
        rst   = 1;
        wr_en = 0;
        rd_en = 0;
        din   = 0;

        // Reset
        #20;
        rst = 0;

      
        wr_en = 1;

        din = 8'hAA;
        #10;

        din = 8'hBB;
        #10;

        din = 8'hCC;
        #10;

        wr_en = 0;

     
        #10;
        rd_en = 1;

        #30;

       
        #30;

        rd_en = 0;

        #20;

        $finish;

    end

endmodule
