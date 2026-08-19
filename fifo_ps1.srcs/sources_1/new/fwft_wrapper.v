`timescale 1ns/1ps

module fwft_wrapper #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,

    // FIFO side
    input wire [DATA_WIDTH-1:0] fifo_dout,
    input wire fifo_empty,
    output reg fifo_rd_en,

    // User side
    output reg [DATA_WIDTH-1:0] dout,
    output wire empty,
    input wire rd_en
);

reg valid;
reg read_pending;

assign empty = !valid;

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        fifo_rd_en  <= 0;
        read_pending <= 0;
        valid       <= 0;
        dout        <= 0;
    end
    else
    begin
        fifo_rd_en <= 0;

        // Capture data from a previous FIFO read
        if(read_pending)
        begin
            dout <= fifo_dout;
            valid <= 1;
            read_pending <= 0;
        end

        // User consumes the current word
        if(rd_en && valid)
        begin
            valid <= 0;
        end

        // Request another word when output register is empty
        if(!valid && !read_pending && !fifo_empty)
        begin
            fifo_rd_en <= 1;
            read_pending <= 1;
        end
    end
end

endmodule