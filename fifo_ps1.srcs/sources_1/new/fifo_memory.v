`timescale 1ns/1ps

module fifo_memory #(
    parameter DATA_WIDTH = 8,// width of data
    parameter DEPTH = 16,// FIFO entries
    parameter ADDR_WIDTH = $clog2(DEPTH)// bits required for address
)(
    // Write side
    input wire wr_clk,
    input wire wr_en,
    input wire [ADDR_WIDTH-1:0] wr_addr,
    input wire [DATA_WIDTH-1:0] wr_data,

    // Read side
    input wire rd_clk,
    input wire rd_en,
    input wire [ADDR_WIDTH-1:0] rd_addr,
    output reg [DATA_WIDTH-1:0] rd_data
);

    // FIFO memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];// stores DEPTH number of DATA_WIDTH-bit words.


    // Write
    // Data is stored at the current write address.
    always @(posedge wr_clk)
    begin
        if (wr_en)
            mem[wr_addr] <= wr_data;
    end


    // Read
    // Data is read from the current read address.
    always @(posedge rd_clk)
    begin
        if (rd_en)
            rd_data <= mem[rd_addr];
    end

endmodule