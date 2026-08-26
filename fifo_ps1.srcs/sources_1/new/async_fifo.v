`timescale 1ns/1ps

module async_fifo #(
    parameter DATA_WIDTH  = 8,
    parameter PARITY_BITS = 4,
    parameter ECC_WIDTH   = DATA_WIDTH + PARITY_BITS + 1,

    parameter DEPTH       = 16,
    parameter ADDR_WIDTH  = $clog2(DEPTH),

    parameter SYNC_STAGES = 2,

    parameter AFULL_LEVEL  = DEPTH-2,
    parameter AEMPTY_LEVEL = 2,
    parameter PFULL_LEVEL  = DEPTH-4,
    parameter PEMPTY_LEVEL = 4
)(
    // --------------------------------------------------------
    // Write side
    // --------------------------------------------------------

    input wire                  wr_clk,
    input wire                  wr_rst,
    input wire                  wr_en,
    input wire [DATA_WIDTH-1:0] din,

    // --------------------------------------------------------
    // Read side
    // --------------------------------------------------------

    input wire                  rd_clk,
    input wire                  rd_rst,
    input wire                  rd_en,
    output wire [DATA_WIDTH-1:0] dout,

    // --------------------------------------------------------
    // Status
    // --------------------------------------------------------

    output wire full,
    output wire empty,

    output wire almost_full,
    output wire almost_empty,

    output wire prog_full,
    output wire prog_empty,

    // --------------------------------------------------------
    // ECC status
    // --------------------------------------------------------

    output wire ecc_single_error,
    output wire ecc_double_error
);


    // --------------------------------------------------------
    // FIFO pointers
    // --------------------------------------------------------

    reg [ADDR_WIDTH:0] wr_bin;
    reg [ADDR_WIDTH:0] rd_bin;

    reg [ADDR_WIDTH:0] wr_gray;
    reg [ADDR_WIDTH:0] rd_gray;


    wire [ADDR_WIDTH:0] wr_bin_next;
    wire [ADDR_WIDTH:0] rd_bin_next;

    wire [ADDR_WIDTH:0] wr_gray_next;
    wire [ADDR_WIDTH:0] rd_gray_next;


    // --------------------------------------------------------
    // Synchronized pointers
    // --------------------------------------------------------

    wire [ADDR_WIDTH:0] wr_gray_sync;
    wire [ADDR_WIDTH:0] rd_gray_sync;

    wire [ADDR_WIDTH:0] wr_bin_sync;
    wire [ADDR_WIDTH:0] rd_bin_sync;


    // --------------------------------------------------------
    // FIFO occupancy
    // --------------------------------------------------------

    wire [ADDR_WIDTH:0] wr_used;
    wire [ADDR_WIDTH:0] rd_used;


    // --------------------------------------------------------
    // Registered full/empty flags
    // --------------------------------------------------------

    reg full_reg;
    reg empty_reg;

    assign full  = full_reg;
    assign empty = empty_reg;


    // --------------------------------------------------------
    // ECC signals
    // --------------------------------------------------------

    wire [ECC_WIDTH-1:0] mem_wr_data;
    wire [ECC_WIDTH-1:0] mem_rd_data;

    wire [DATA_WIDTH-1:0] decoded_data;

    assign dout = decoded_data;


    // --------------------------------------------------------
    // Gray to binary
    // --------------------------------------------------------

    function [ADDR_WIDTH:0] gray2bin;

        input [ADDR_WIDTH:0] gray;

        integer i;

        begin

            gray2bin[ADDR_WIDTH] = gray[ADDR_WIDTH];

            for (i = ADDR_WIDTH-1;
                 i >= 0;
                 i = i - 1)
            begin
                gray2bin[i] =
                    gray2bin[i+1] ^ gray[i];
            end

        end

    endfunction


    assign wr_bin_sync = gray2bin(wr_gray_sync);
    assign rd_bin_sync = gray2bin(rd_gray_sync);


    // --------------------------------------------------------
    // Occupancy
    // --------------------------------------------------------

    assign wr_used = wr_bin - rd_bin_sync;
    assign rd_used = wr_bin_sync - rd_bin;


    // --------------------------------------------------------
    // Next pointer logic
    // --------------------------------------------------------

    assign wr_bin_next =
        wr_bin + ((wr_en && !full) ? 1'b1 : 1'b0);

    assign rd_bin_next =
        rd_bin + ((rd_en && !empty) ? 1'b1 : 1'b0);


    assign wr_gray_next =
        wr_bin_next ^ (wr_bin_next >> 1);

    assign rd_gray_next =
        rd_bin_next ^ (rd_bin_next >> 1);


    // --------------------------------------------------------
    // Write pointer and FULL flag
    // --------------------------------------------------------

    always @(posedge wr_clk or posedge wr_rst)
    begin

        if (wr_rst)
        begin
            wr_bin   <= 0;
            wr_gray  <= 0;
            full_reg <= 0;
        end

        else
        begin

            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;

            full_reg <=
                (wr_gray_next ==
                {
                    ~rd_gray_sync[ADDR_WIDTH],
                    ~rd_gray_sync[ADDR_WIDTH-1],
                     rd_gray_sync[ADDR_WIDTH-2:0]
                });

        end

    end


    // --------------------------------------------------------
    // Read pointer and EMPTY flag
    // --------------------------------------------------------

    always @(posedge rd_clk or posedge rd_rst)
    begin

        if (rd_rst)
        begin
            rd_bin    <= 0;
            rd_gray   <= 0;
            empty_reg <= 1'b1;
        end

        else
        begin

            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;

            empty_reg <=
                (wr_gray_sync == rd_gray_next);

        end

    end


    // --------------------------------------------------------
    // Synchronize write pointer into read domain
    // --------------------------------------------------------

    synchronizer #(
        .WIDTH(ADDR_WIDTH+1),
        .SYNC_STAGES(SYNC_STAGES)
    ) wr_sync_inst (
        .clk  (rd_clk),
        .rst  (rd_rst),
        .din  (wr_gray),
        .dout (wr_gray_sync)
    );


    // --------------------------------------------------------
    // Synchronize read pointer into write domain
    // --------------------------------------------------------

    synchronizer #(
        .WIDTH(ADDR_WIDTH+1),
        .SYNC_STAGES(SYNC_STAGES)
    ) rd_sync_inst (
        .clk  (wr_clk),
        .rst  (wr_rst),
        .din  (rd_gray),
        .dout (rd_gray_sync)
    );


    // --------------------------------------------------------
    // ECC encoder
    // --------------------------------------------------------

    ecc_encoder #(
        .DATA_WIDTH(DATA_WIDTH),
        .PARITY_BITS(PARITY_BITS)
    ) encoder_inst (

        .data_in(din),
        .code_out(mem_wr_data)

    );


    // --------------------------------------------------------
    // FIFO memory
    // --------------------------------------------------------

    fifo_memory #(
        .DATA_WIDTH(ECC_WIDTH),
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) mem_inst (

        .wr_clk (wr_clk),
        .wr_en  (wr_en && !full),
        .wr_addr(wr_bin[ADDR_WIDTH-1:0]),
        .wr_data(mem_wr_data),

        .rd_clk (rd_clk),
        .rd_en  (rd_en && !empty),
        .rd_addr(rd_bin[ADDR_WIDTH-1:0]),
        .rd_data(mem_rd_data)

    );


    // --------------------------------------------------------
    // ECC decoder
    // --------------------------------------------------------

    ecc_decoder #(
        .DATA_WIDTH(DATA_WIDTH),
        .PARITY_BITS(PARITY_BITS)
    ) decoder_inst (

        .code_in      (mem_rd_data),
        .data_out     (decoded_data),
        .single_error (ecc_single_error),
        .double_error (ecc_double_error)

    );


    // --------------------------------------------------------
    // Threshold flags
    // --------------------------------------------------------

    assign almost_full =
        (wr_used >= AFULL_LEVEL);

    assign prog_full =
        (wr_used >= PFULL_LEVEL);

    assign almost_empty =
        (rd_used <= AEMPTY_LEVEL);

    assign prog_empty =
        (rd_used <= PEMPTY_LEVEL);


endmodule