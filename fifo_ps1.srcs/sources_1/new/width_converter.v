`timescale 1ns/1ps

module width_converter #(
    parameter IN_WIDTH  = 8,
    parameter OUT_WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst,

    input  wire                  valid_in,
    input  wire [IN_WIDTH-1:0]   data_in,

    output reg                   valid_out,
    output reg [OUT_WIDTH-1:0]   data_out,

    output wire                  ready_in
);

    // --------------------------------------------------
    // Width relationship
    // --------------------------------------------------

    localparam WIDER_RATIO =
        (OUT_WIDTH / IN_WIDTH);

    localparam NARROW_RATIO =
        (IN_WIDTH / OUT_WIDTH);

    localparam COUNT_WIDTH =
        (WIDER_RATIO > NARROW_RATIO) ?
        ((WIDER_RATIO <= 1) ? 1 : $clog2(WIDER_RATIO)) :
        ((NARROW_RATIO <= 1) ? 1 : $clog2(NARROW_RATIO));


    // --------------------------------------------------
    // Buffer and counter
    // --------------------------------------------------

    reg [OUT_WIDTH-1:0] buffer;

    reg [IN_WIDTH-1:0] narrow_buffer;

    reg [COUNT_WIDTH-1:0] count;

    reg busy;


    // --------------------------------------------------
    // Input ready
    //
    // For widening:
    // Always able to accept another input word.
    //
    // For narrowing:
    // Can accept a new word only when the previous
    // word has completely been converted.
    // --------------------------------------------------

    assign ready_in =
        (OUT_WIDTH >= IN_WIDTH) ? 1'b1 :
        !busy;


    // --------------------------------------------------
    // Parameter checks
    // --------------------------------------------------

    initial begin

        if (IN_WIDTH <= 0 || OUT_WIDTH <= 0)
            $error("ERROR: IN_WIDTH and OUT_WIDTH must be > 0");

        if ((OUT_WIDTH > IN_WIDTH) &&
            ((OUT_WIDTH % IN_WIDTH) != 0))
            $error("ERROR: OUT_WIDTH must be an integer multiple of IN_WIDTH");

        if ((IN_WIDTH > OUT_WIDTH) &&
            ((IN_WIDTH % OUT_WIDTH) != 0))
            $error("ERROR: IN_WIDTH must be an integer multiple of OUT_WIDTH");

    end


    // ==================================================
    // WIDENING
    //
    // Example:
    //
    // IN_WIDTH  = 32
    // OUT_WIDTH = 64
    //
    // First input  = AAAAAAAA
    // Second input = 55555555
    //
    // Output = 55555555AAAAAAAA
    // ==================================================

    generate

        if (OUT_WIDTH > IN_WIDTH) begin : GEN_WIDEN

            always @(posedge clk or posedge rst)
            begin

                if (rst)
                begin
                    buffer    <= 0;
                    count     <= 0;
                    data_out  <= 0;
                    valid_out <= 0;
                end

                else
                begin

                    // valid_out is a one-cycle pulse
                    valid_out <= 0;

                    if (valid_in)
                    begin

                        // Last word needed to complete
                        // the wider output.
                        if (count == WIDER_RATIO-1)
                        begin

                            data_out <=
                                buffer |
                                (data_in << (count * IN_WIDTH));

                            valid_out <= 1;

                            buffer <= 0;
                            count  <= 0;
                        end

                        else
                        begin

                            // Store current input word in
                            // its appropriate position.
                            buffer <=
                                buffer |
                                (data_in << (count * IN_WIDTH));

                            count <= count + 1'b1;

                        end

                    end

                end

            end

        end

    endgenerate


    // ==================================================
    // NARROWING
    //
    // Example:
    //
    // IN_WIDTH  = 64
    // OUT_WIDTH = 32
    //
    // Input = 55555555AAAAAAAA
    //
    // Output sequence:
    //
    // 1st cycle = AAAAAAAA
    // 2nd cycle = 55555555
    // ==================================================

    generate

        if (IN_WIDTH > OUT_WIDTH) begin : GEN_NARROW

            always @(posedge clk or posedge rst)
            begin

                if (rst)
                begin
                    narrow_buffer <= 0;
                    count         <= 0;
                    data_out      <= 0;
                    valid_out     <= 0;
                    busy          <= 0;
                end

                else
                begin

                    // Default: no output unless
                    // a conversion piece is ready.
                    valid_out <= 0;


                    // ----------------------------------
                    // Accept a new wide word
                    // ----------------------------------

                    if (valid_in && !busy)
                    begin

                        narrow_buffer <= data_in;

                        // Output the first/lower portion
                        // immediately.
                        data_out <= data_in[OUT_WIDTH-1:0];

                        valid_out <= 1;

                        // More portions remain.
                        busy  <= 1;
                        count <= 1;

                    end


                    // ----------------------------------
                    // Output remaining portions
                    // ----------------------------------

                    else if (busy)
                    begin

                        data_out <=
                            narrow_buffer[
                                count * OUT_WIDTH +:
                                OUT_WIDTH
                            ];

                        valid_out <= 1;


                        // Last portion
                        if (count == NARROW_RATIO-1)
                        begin
                            busy  <= 0;
                            count <= 0;
                        end

                        else
                        begin
                            count <= count + 1'b1;
                        end

                    end

                end

            end

        end

    endgenerate


    // ==================================================
    // SAME WIDTH
    //
    // Example:
    //
    // 32 -> 32
    // ==================================================

    generate

        if (IN_WIDTH == OUT_WIDTH) begin : GEN_SAME

            always @(posedge clk or posedge rst)
            begin

                if (rst)
                begin
                    data_out  <= 0;
                    valid_out <= 0;
                end

                else
                begin

                    valid_out <= valid_in;

                    if (valid_in)
                        data_out <= data_in;

                end

            end

        end

    endgenerate


endmodule