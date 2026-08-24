`timescale 1ns/1ps

module fifo_memory #(
    parameter DATA_WIDTH = 8,// Width of each stored data word
    parameter DEPTH = 16,// Number of memory locations
    parameter ADDR_WIDTH = $clog2(DEPTH)// Number of bits required for address
)(
    // Write Port
    input  wire wr_clk,
    input  wire wr_en,
    input  wire [ADDR_WIDTH-1:0] wr_addr,
    input  wire [DATA_WIDTH-1:0] wr_data,

    // Read Port
    input  wire rd_clk,
    input  wire rd_en,
    input  wire [ADDR_WIDTH-1:0] rd_addr,
    output reg  [DATA_WIDTH-1:0] rd_data
);

    // Memory Array

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];// Stores DEPTH number of DATA_WIDTH-bit words.

    // Write Logic

    always @(posedge wr_clk)
    begin
        if (wr_en)
            mem[wr_addr] <= wr_data;// write data when wr_en = 1
    end

    // Read Logic

    always @(posedge rd_clk)
    begin
        if (rd_en)
            rd_data <= mem[rd_addr];// read data when rd_en = 1
    end

endmodule