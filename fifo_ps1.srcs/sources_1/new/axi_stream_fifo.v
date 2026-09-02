`timescale 1ns/1ps

module axi_stream_fifo#(
        parameter DATA_WIDTH = 8
        )(
        //SLAVE (INPUT) SIDE
        input wire clk,rst,
        input wire [DATA_WIDTH-1:0] s_data,
        input wire s_valid,
        output wire s_ready,
        //MASTER (OUTPUT) SIDE
        output wire [DATA_WIDTH-1:0] m_data,
        output wire m_valid,
        input wire m_ready
        
        );
        
    wire [DATA_WIDTH-1:0] fifo_din;
    wire [DATA_WIDTH-1:0] fifo_dout;

    wire fifo_full;
    wire fifo_empty;

    wire fifo_almost_full;
    wire fifo_almost_empty;

    wire fifo_prog_full;
    wire fifo_prog_empty;

    wire fifo_ecc_single_error;
    wire fifo_ecc_double_error;

    wire fifo_wr_en;
    wire fifo_rd_en;
    
    //INPUT SIDE
    assign s_ready = !fifo_full;

    // FIFO write happens only when both VALID and READY are asserted
    assign fifo_wr_en = s_valid && s_ready;

    assign fifo_din = s_data;
    
    //OUTPUTSIDE
    
    // Data is valid whenever the FIFO is not empty.
    assign m_valid = !fifo_empty;

    assign m_data = fifo_dout;
    
    assign fifo_rd_en = m_valid && m_ready;
    
    
    
    //Initiating FIFO_SYSTEM
    
    fifo_system #(.DATA_WIDTH(DATA_WIDTH))
        fifo_inst(
            
            .wr_clk(clk),
            .wr_rst(rst),
            .wr_en(fifo_wr_en),
            .din(fifo_din),
            
            .rd_clk(clk),
            .rd_rst(rst),
            .rd_en(fifo_rd_en),
            .dout(fifo_dout),
            
            .full(fifo_full),
            .empty(fifo_empty),
            .almost_full(fifo_almost_full),
            .almost_empty(fifo_almost_empty),
            .prog_full(fifo_prog_full),
            .prog_empty(fifo_prog_empty),

            .ecc_single_error(fifo_ecc_single_error),
            .ecc_double_error(fifo_ecc_double_error)
    );
            
            
        
            

        
endmodule       
       
        