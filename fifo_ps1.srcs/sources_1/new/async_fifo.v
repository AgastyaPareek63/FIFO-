`timescale 1ns/1ps

module async_fifo #(
// Width of the actual user data entering and leaving the FIFO.
    parameter DATA_WIDTH  = 8,
// Total width of the encoded data stored in the FIFO memory.
// DATA_WIDTH + 5 is used here because the ECC implementation
// requires additional parity bits along with the
// original data bits.
    parameter ECC_WIDTH   = DATA_WIDTH + 5,
// Number of data entries that can be stored in the FIFO.
    parameter DEPTH       = 16,
// Number of address bits required to address all memory locations.
    parameter ADDR_WIDTH  = $clog2(DEPTH),// $clog2(16) = 4
// Number of flip-flop stages used by the clock-domain synchronizer.
    parameter SYNC_STAGES = 2,
// Threshold parameters:
    parameter AFULL_LEVEL  = DEPTH-2,
    parameter AEMPTY_LEVEL = 2,
    parameter PFULL_LEVEL  = DEPTH-4,
    parameter PEMPTY_LEVEL = 4
)(
    // Write interface
    input  wire                  wr_clk,
    input  wire                  wr_rst,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] din,

    // Read interface
    input  wire                  rd_clk,
    input  wire                  rd_rst,
    input  wire                  rd_en,
    output wire [DATA_WIDTH-1:0] dout,

    // Status flags
    output wire full,
    output wire empty,
    output wire almost_full,
    output wire almost_empty,
    output wire prog_full,
    output wire prog_empty,

    // ECC status
    output wire ecc_single_error,
    output wire ecc_double_error
);

    // Binary pointers
    
// ADDR_WIDTH = 4
// Pointer width = 5 bits
// Lower 4 bits -> memory address
// MSB -> wrap-around information
    reg [ADDR_WIDTH:0] wr_bin;
    reg [ADDR_WIDTH:0] rd_bin;

    // Gray-code pointers

    reg [ADDR_WIDTH:0] wr_gray;// Gray coded write pointer synced into the read clock domain.
    reg [ADDR_WIDTH:0] rd_gray;// Gray coded read pointer synced into the write clock domain.


    // Next pointer values

    wire [ADDR_WIDTH:0] wr_bin_next;// pointer advances when wr_en = 1 and FIFO is not full.
    wire [ADDR_WIDTH:0] rd_bin_next;// pointer advances when rd_en = 1 and FIFO is not empty.

    wire [ADDR_WIDTH:0] wr_gray_next;
    wire [ADDR_WIDTH:0] rd_gray_next;

    // Synchronized Gray-code pointers

// These are the Gray-coded pointers after they have crossed the corresponding clock-domain boundary through a synchronizer.
// These values are used for generating FULL and EMPTY flags

    wire [ADDR_WIDTH:0] wr_gray_sync;// Write pointer sync into the READ clock domain.
    wire [ADDR_WIDTH:0] rd_gray_sync;// Read pointer sync into the WRITE clock domain.

    // Binary versions of synchronized pointers

// These values are useful for calculating the approx no. of occupied locations in the FIFO and for generating threshold flags.
    wire [ADDR_WIDTH:0] wr_bin_sync;
    wire [ADDR_WIDTH:0] rd_bin_sync;

    // FIFO occupancy



    wire [ADDR_WIDTH:0] wr_used;// Approximate number of entries currently occupied, calculated from the wr_bin and the rd_gray_sync
    wire [ADDR_WIDTH:0] rd_used;// Approximate number of entries available for reading, calculated from the wr_gray_sync and the rd_ptr


    // Registered status flags

    reg full_reg;
    reg empty_reg;

    assign full  = full_reg;
    assign empty = empty_reg;


    // ECC signals

    wire [ECC_WIDTH-1:0] mem_wr_data; // encoded data written into the memory.
    wire [ECC_WIDTH-1:0] mem_rd_data;// encoded data read from the meemory 

    wire [DATA_WIDTH-1:0] decoded_data;// Original DATA_WIDTH-bit data recovered  

    assign dout = decoded_data;// externally visible data

    // Gray to binary conversion


    function [ADDR_WIDTH:0] gray2bin;

        input [ADDR_WIDTH:0] gray;

        integer j;

        begin
            // The binary MSB is identical to Gray-code's MSB
            gray2bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
            
            // lower binary bit is obtained by XORing the next higher binary bit with the corresponding Gray-code bit.
            for(j = ADDR_WIDTH-1; j >= 0; j = j-1)
                gray2bin[j] = gray2bin[j+1] ^ gray[j];

        end

    endfunction


    assign wr_bin_sync = gray2bin(wr_gray_sync);
    assign rd_bin_sync = gray2bin(rd_gray_sync);


    // FIFO occupancy calculation

    assign wr_used = wr_bin - rd_bin_sync;// Represents the number of entries that have been written but not yet consumed from the perspective of the write clock domain.
    assign rd_used = wr_bin_sync - rd_bin;// Represents the number of entries available to the read side.

    // Next pointer logic

    assign wr_bin_next =
        wr_bin + (wr_en && !full); // wr_en = 1 and FIFO is not full

    assign rd_bin_next =
        rd_bin + (rd_en && !empty);// rd_en = 1 and FIFO not empty


    // Binary to Gray conversion

// Before transferring pointers between clock domains, the binary pointer is converted to Gray code
    assign wr_gray_next =
        wr_bin_next ^ (wr_bin_next >> 1);

    assign rd_gray_next =
        rd_bin_next ^ (rd_bin_next >> 1);


    // Write pointer and FULL flag

    always @(posedge wr_clk or posedge wr_rst)
    begin

        if(wr_rst)
        begin
            // Reset the write pointer.
            wr_bin   <= 0;
            // Reset the Gray-coded pointer.
            wr_gray  <= 0;
            // FIFO is not full after reset.
            full_reg <= 0;
        end

        else
        begin
            // update the binary write pointer.
            wr_bin  <= wr_bin_next;
            // update gray coded write pointer.
            wr_gray <= wr_gray_next;

            // In an asynchronous FIFO, the FIFO becomes full when the next
            // write pointer reaches the read pointer after accounting for
            // the required pointer wrap-around.
            //
            // The Gray-coded read pointer has its two most significant bits
            // inverted for the FULL comparison. This distinguishes the FULL
            // condition from the EMPTY condition, where both pointers can
            // have identical Gray-code values.
            full_reg <=
                (wr_gray_next ==
                {
                    ~rd_gray_sync[ADDR_WIDTH],
                    ~rd_gray_sync[ADDR_WIDTH-1],
                     rd_gray_sync[ADDR_WIDTH-2:0]
                });
        end

    end


    // Read pointer and EMPTY flag


    always @(posedge rd_clk or posedge rd_rst)
    begin

        if(rd_rst)
        begin
            // Reset the read pointer to the beginning of the FIFO.
            rd_bin    <= 0;
            // Reset the Gray-coded read pointer.
            rd_gray   <= 0;
            // empty FIFO after reset
            empty_reg <= 1;
        end

        else
        begin
            // Update binary read pointer.
            rd_bin  <= rd_bin_next;
            // Update gray read pointer 
            rd_gray <= rd_gray_next;

            // FIFO becomes empty when the next read pointer
            // catches up with the synchronized write pointer.
            empty_reg <=
                (wr_gray_sync == rd_gray_next);
        end

    end


    // Synchronize WRITE pointer into READ clock domain

    synchronizer #(
        .WIDTH(ADDR_WIDTH+1),
        .SYNC_STAGES(SYNC_STAGES)
    ) wr_sync (

        .clk(rd_clk),
        .rst(rd_rst),
        .din(wr_gray),
        .dout(wr_gray_sync)

    );


    // Synchronize READ pointer into WRITE clock domain

    synchronizer #(
        .WIDTH(ADDR_WIDTH+1),
        .SYNC_STAGES(SYNC_STAGES)
    ) rd_sync (

        .clk(wr_clk),
        .rst(wr_rst),
        .din(rd_gray),
        .dout(rd_gray_sync)

    );


    // FIFO memory

    fifo_memory #(
        .DATA_WIDTH(ECC_WIDTH),
        .DEPTH(DEPTH)
    ) mem_inst (
    
        .wr_clk(wr_clk),
        .wr_en(wr_en && !full),// write when wr_en = 1 and FIFO is not full
        .wr_addr(wr_bin[ADDR_WIDTH-1:0]),// The lower bits of the binary write pointer select the memory the additional pointer bit represents wrap-around info.
        .wr_data(mem_wr_data),//ECC encoded data is written into the memory

        .rd_clk(rd_clk),
        .rd_en(rd_en && !empty),// read when rd-en = 1 and FIFO is not empty
        .rd_addr(rd_bin[ADDR_WIDTH-1:0]),// the lower bits select the memory location
        .rd_data(mem_rd_data)// encoded data is returned from the memory

    );


    // Threshold flags

    assign almost_full =
        (wr_used >= AFULL_LEVEL);

    assign prog_full =
        (wr_used >= PFULL_LEVEL);

    assign almost_empty =
        (rd_used <= AEMPTY_LEVEL);

    assign prog_empty =
        (rd_used <= PEMPTY_LEVEL);


    // ECC Encoder

    ecc_encoder encoder (
        
        // Original data supplied by the user.
        .data_in(din),
        // ECC encoded codeword given to the memory
        .code_out(mem_wr_data)

    );


    // ECC Decoder

    ecc_decoder decoder (
        
        // ECC codeword from FIFO memory.
        .code_in(mem_rd_data),
        // Original data reconstructed by the ECC decoder.
        .data_out(decoded_data),
         // Indicates detection/correction of a single-bit error
        .single_error(ecc_single_error),
        // Indicates detection of double-bit error
        .double_error(ecc_double_error)

    );


endmodule