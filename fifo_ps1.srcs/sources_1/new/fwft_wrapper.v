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

    // --------------------------------------------------
    // FWFT states
    // --------------------------------------------------

    localparam IDLE        = 2'b00;
    localparam READ_WAIT   = 2'b01;
    localparam OUTPUT_VALID = 2'b10;

    reg [1:0] state;


    // --------------------------------------------------
    // From the user's point of view, the output is empty
    // whenever we do not have a valid word available.
    // --------------------------------------------------

    assign empty = (state != OUTPUT_VALID);


    // --------------------------------------------------
    // Main FWFT controller
    // --------------------------------------------------

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
            // Read request is only asserted for one cycle.
            fifo_rd_en <= 1'b0;

            case (state)

                // --------------------------------------------------
                // IDLE
                //
                // No word is currently available to the user.
                // If the FIFO contains data, request the first word.
                // --------------------------------------------------

                IDLE:
                begin
                    if (!fifo_empty)
                    begin
                        fifo_rd_en <= 1'b1;
                        state      <= READ_WAIT;
                    end
                end


                // --------------------------------------------------
                // READ_WAIT
                //
                // The FIFO read has already been requested.
                //
                // Because fifo_rd_en is registered and the FIFO
                // memory also has a registered read, we wait here
                // until fifo_dout contains the requested word.
                // --------------------------------------------------

                READ_WAIT:
                begin
                    dout  <= fifo_dout;
                    state <= OUTPUT_VALID;
                end


                // --------------------------------------------------
                // OUTPUT_VALID
                //
                // dout contains a valid word.
                //
                // The user can consume it by asserting rd_en.
                // After consumption, request the next word if
                // the FIFO still contains data.
                // --------------------------------------------------

                OUTPUT_VALID:
                begin
                    if (rd_en)
                    begin
                        if (!fifo_empty)
                        begin
                            // Current word is consumed and another
                            // word is waiting in the FIFO.
                            fifo_rd_en <= 1'b1;
                            state      <= READ_WAIT;
                        end
                        else
                        begin
                            // No more data is available.
                            state <= IDLE;
                        end
                    end
                end


                // --------------------------------------------------
                // Safety fallback
                // --------------------------------------------------

                default:
                begin
                    state      <= IDLE;
                    fifo_rd_en <= 1'b0;
                end

            endcase
        end
    end

endmodule