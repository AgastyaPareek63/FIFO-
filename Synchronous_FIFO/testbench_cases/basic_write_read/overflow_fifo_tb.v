`timescale 1ns/1ps

module overflow_fifo_tb;

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

     
        clk   = 0;
        rst   = 1;
        wr_en = 0;
        rd_en = 0;
        din   = 0;

      
        #20;
        rst = 0;

        
        wr_en = 1;

        din = 8'h01; #10;
        din = 8'h02; #10;
        din = 8'h03; #10;
        din = 8'h04; #10;
        din = 8'h05; #10;
        din = 8'h06; #10;
        din = 8'h07; #10;
        din = 8'h08; #10;
        din = 8'h09; #10;
        din = 8'h0A; #10;
        din = 8'h0B; #10;
        din = 8'h0C; #10;
        din = 8'h0D; #10;
        din = 8'h0E; #10;
        din = 8'h0F; #10;
        din = 8'h10; #10;

        
        din = 8'hAA; #10;
        din = 8'hBB; #10;
        din = 8'hCC; #10;

        wr_en = 0;

        #20;

        $finish;

    end

endmodule
