`timescale 1ns/1ps

module fwft_wrapper #(
    parameter DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire rst,

    // FIFO Interface
    input  wire [DATA_WIDTH-1:0] fifo_dout,
    input  wire fifo_empty,
    output reg  fifo_rd_en,

    // User Interface
    output reg [DATA_WIDTH-1:0] dout,
    output wire empty,
    input  wire rd_en
);

// Internal Register
reg valid;

// Empty flag seen by the user
assign empty = ~valid;

// FWFT Logic

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        fifo_rd_en <= 0;
        dout <= 0;
        valid <= 0;
    end
    else
    begin
        fifo_rd_en <= 0;

        // Prefetch first word
        if(!valid && !fifo_empty)
        begin
            fifo_rd_en <= 1;
        end
        
        // Capture FIFO output
        if(fifo_rd_en)
        begin
            dout  <= fifo_dout;
            valid <= 1;
        end

        // Consume current word
        if(rd_en && valid)
        begin
            valid <= 0;
        end
    end
end

endmodule