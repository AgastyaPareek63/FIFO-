`timescale 1ns/1ps

module fwft_wrapper #(
    parameter DATA_WIDTH = 8// width of FIFO data
)(
    input  wire clk,
    input  wire rst,

    // FIFO side
    input  wire [DATA_WIDTH-1:0] fifo_dout,
    input  wire fifo_empty,
    output reg fifo_rd_en,

    // User side
    output reg [DATA_WIDTH-1:0] dout,
    output wire empty,
    input  wire rd_en
);


    // FWFT states 
    
    localparam IDLE = 2'b00;//waiting for data
    localparam WAIT1 = 2'b01;//first cycle after requesting a FIFO read
    localparam WAIT2 = 2'b10;//waiting for the registered FIFO data
    localparam VALID = 2'b11;//data is available at dout

    reg [1:0] state;

    assign empty = (state != VALID);

    // FWFT control state machine
    always @(posedge clk or posedge rst)
    begin

        if (rst)
        begin
            state <= IDLE;
            fifo_rd_en <= 1'b0;
            dout <= {DATA_WIDTH{1'b0}};
        end

        else
        begin
            
            fifo_rd_en <= 1'b0;// only asserted only when a new FIFO word is needed.

            case (state)
                // Wait until the FIFO contains data.
                IDLE:
                begin
                    if (!fifo_empty)
                    begin
                        // Request the first available word.
                        fifo_rd_en <= 1'b1;
                        state <= WAIT1;
                    end
                end

                WAIT1:
                begin
                    state <= WAIT2;
                end

                WAIT2:
                begin
                    dout <= fifo_dout;
                    state <= VALID;
                end

                VALID:
                begin
                    if (rd_en)
                    begin

                        // User consumed the current word.
                        if (!fifo_empty)
                        begin
                            // Request the next FIFO word.
                            fifo_rd_en <= 1'b1;
                            state <= WAIT1;
                        end

                        else
                        begin
                            state <= IDLE; // No more data available.
                        end

                    end
                end


                default: // Return to the idle state if an invalid state is reached.
                begin
                    state <= IDLE;
                    fifo_rd_en <= 1'b0;
                end

            endcase

        end

    end

endmodule