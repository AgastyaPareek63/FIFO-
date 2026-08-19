`timescale 1ns/1ps

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH),
    parameter AFULL_LEVEL = DEPTH-2,
    parameter AEMPTY_LEVEL = 2,
    parameter PFULL_LEVEL = DEPTH-4,
    parameter PEMPTY_LEVEL = 4
)(
    input  wire clk,
    input  wire rst,

    input  wire wr_en,
    input  wire rd_en,

    input  wire [DATA_WIDTH-1:0]  din,
    output reg  [DATA_WIDTH-1:0]  dout,

    output wire full,
    output wire empty,
    output wire almost_full,
    output wire almost_empty,
    output wire prog_full,
    output wire prog_empty
);

    // FIFO memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Address pointers
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    // Number of valid entries
    reg [ADDR_WIDTH:0] count;

    // Accepted operations
    wire read_fire;
    wire write_fire;

    assign read_fire = rd_en && !empty;
    assign write_fire = wr_en && (!full || read_fire);

    // --------------------------------------------------
    // Status flags
    // --------------------------------------------------

    assign empty = (count == 0);
    assign full = (count == DEPTH);

    assign almost_full = (count >= AFULL_LEVEL);
    assign almost_empty = (count <= AEMPTY_LEVEL);

    assign prog_full = (count >= PFULL_LEVEL);
    assign prog_empty = (count <= PEMPTY_LEVEL);

    // --------------------------------------------------
    // Write
    // --------------------------------------------------

    always @(posedge clk) begin
        if (write_fire)
            mem[wr_ptr] <= din;
    end

    // --------------------------------------------------
    // Read
    // --------------------------------------------------

    always @(posedge clk or posedge rst) begin
        if (rst)
            dout <= 0;
        else if (read_fire)
            dout <= mem[rd_ptr];
    end

    // --------------------------------------------------
    // Pointer and count update
    // --------------------------------------------------

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
        end
        else begin

            // Write pointer
            if (write_fire) begin
                if (wr_ptr == DEPTH-1)
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            // Read pointer
            if (read_fire) begin
                if (rd_ptr == DEPTH-1)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            // Occupancy count
            case ({write_fire, read_fire})

                2'b10:
                    count <= count + 1'b1;

                2'b01:
                    count <= count - 1'b1;

                2'b11:
                    count <= count;

                2'b00:
                    count <= count;

            endcase
        end
    end

endmodule
