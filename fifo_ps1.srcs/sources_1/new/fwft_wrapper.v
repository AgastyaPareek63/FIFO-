`timescale 1ns/1ps

module fwft_wrapper #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,

    // FIFO side
    input  wire [DATA_WIDTH-1:0] fifo_dout,
    input  wire                  fifo_empty,
    output reg                   fifo_rd_en,

    // User side
    output reg  [DATA_WIDTH-1:0] dout,
    output wire                  empty,
    input  wire                  rd_en
);

    // FWFT control states
    localparam IDLE  = 2'b00;
    localparam WAIT1 = 2'b01;
    localparam WAIT2 = 2'b10;
    localparam VALID = 2'b11;

    reg [1:0] state;

    // Output is available only when we have captured a FIFO word.
    assign empty = (state != VALID);


    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            state      <= IDLE;
            fifo_rd_en <= 1'b0;
            dout       <= {DATA_WIDTH{1'b0}};
        end
        else
        begin
            // Read request is normally kept low.
            fifo_rd_en <= 1'b0;

            case (state)

                // ------------------------------------------
                // Wait for data to become available.
                // ------------------------------------------
                IDLE:
                begin
                    if (!fifo_empty)
                    begin
                        // Ask the FIFO for the next word.
                        fifo_rd_en <= 1'b1;
                        state      <= WAIT1;
                    end
                end


                // ------------------------------------------
                // FIFO has a registered read.
                // First wait cycle.
                // ------------------------------------------
                WAIT1:
                begin
                    state <= WAIT2;
                end


                // ------------------------------------------
                // Second wait cycle.
                // fifo_dout now contains the requested word.
                // ------------------------------------------
                WAIT2:
                begin
                    dout  <= fifo_dout;
                    state <= VALID;
                end


                // ------------------------------------------
                // A valid word is available to the user.
                // ------------------------------------------
                VALID:
                begin
                    if (rd_en)
                    begin
                        if (!fifo_empty)
                        begin
                            // Current word is consumed.
                            // Request the next word.
                            fifo_rd_en <= 1'b1;
                            state      <= WAIT1;
                        end
                        else
                        begin
                            // No more FIFO data.
                            state <= IDLE;
                        end
                    end
                end


                default:
                begin
                    state      <= IDLE;
                    fifo_rd_en <= 1'b0;
                end

            endcase
        end
    end

endmodule