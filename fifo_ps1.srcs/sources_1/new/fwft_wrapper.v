`timescale 1ns/1ps

module fwft_wrapper #(
    parameter DATA_WIDTH = 8// FIFO width
)(
    input wire clk,
    input wire rst,

    // FIFO side
    input wire [DATA_WIDTH-1:0] fifo_dout,// data received from FIFO
    input wire fifo_empty,// FIFO has no data
    output reg fifo_rd_en,// read request to FIFO

    // User side
    output reg [DATA_WIDTH-1:0] dout,// Data available to user
    output wire empty,// no output data
    input wire rd_en// user read request
);

reg valid;// dout has valid data
reg read_pending;// data is expected after read request

assign empty = !valid;// empty when there is no valid data

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        //reset all signals
        fifo_rd_en <= 0;
        read_pending <= 0;
        valid <= 0;
        dout <= 0;
    end
    else
    begin
        fifo_rd_en <= 0;// default

        // Capture data from a previous FIFO read if read is pending from previous cycle
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

        // Request another word when output register is empty no read pending and no valid data us present
        if(!valid && !read_pending && !fifo_empty)
        begin
            fifo_rd_en <= 1;
            read_pending <= 1;
        end
    end
end

endmodule