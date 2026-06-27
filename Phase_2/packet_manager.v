`timescale 1ns / 1ps

module packet_manager(
    input wire clk, rst, push_to_talk,
    
    // Audio FIFO
    input  wire [15:0] tx_fifo_dout,
    input  wire tx_fifo_empty,
    output reg  tx_fifo_rd_en,
    output reg [15:0] rx_fifo_din,
    output reg  rx_fifo_wr_en,
    
    // nRF24 Driver Interface
    output reg  start_tx,
    output reg  [255:0] nrf_tx_data,
    input  wire tx_done,
    input  wire rx_ready,
    input  wire [255:0] nrf_rx_data
);

    // Chaos & Buffer
    reg [255:0] buffer;
    reg [3:0] sample_cnt;
    wire [31:0] chaos_key; 

    // Instantiate Chaos Generator
    chaotic_generator cipher (
        .clk(clk),
        .rst(rst),
        .next_key_en(tx_fifo_rd_en || rx_fifo_wr_en), 
        .sync_en(0), 
        .sync_state_in(32'h01F97414),
        .key_out(chaos_key)
    );

    // Edge Detectors for Cross-Module Timing
    reg tx_done_prev, rx_ready_prev;
    always @(posedge clk) begin
        if (rst) begin
            tx_done_prev <= 0;
            rx_ready_prev <= 0;
        end else begin
            tx_done_prev <= tx_done;
            rx_ready_prev <= rx_ready;
        end
    end
    wire tx_done_edge = tx_done && !tx_done_prev;
    wire rx_ready_edge = rx_ready && !rx_ready_prev;
    
    // TX LOGIC
    always @(posedge clk) begin
        if (rst) begin
            sample_cnt <= 0;
            start_tx <= 0;
            tx_fifo_rd_en <= 0;
        end else if (push_to_talk) begin
            // 1. Fill Buffer
            if (!tx_fifo_empty && sample_cnt < 15) begin
                tx_fifo_rd_en <= 1;
                buffer <= {buffer[239:0], tx_fifo_dout ^ chaos_key[15:0]}; 
                sample_cnt <= sample_cnt + 1;
            end else begin
                tx_fifo_rd_en <= 0;
            end
            
            // 2. Buffer Full? Add Preamble and Send!
            if (sample_cnt == 15 && !start_tx) begin
                nrf_tx_data <= {16'hCAFE, buffer[239:0]}; 
                start_tx <= 1;
            end
            
            // 3. Reset after Send
            if (tx_done_edge) begin
                start_tx <= 0;
                sample_cnt <= 0;
            end
        end else begin
             start_tx <= 0;
             sample_cnt <= 0;
             tx_fifo_rd_en <= 0;
        end
    end

    // RX LOGIC
    reg [255:0] rx_latch;
    reg [3:0] rx_ptr;
    
    always @(posedge clk) begin
        if (rst) begin
            rx_ptr <= 0;
            rx_fifo_wr_en <= 0;
        end else begin
            if (rx_ready_edge) begin
                // Check Preamble to ensure it's a valid Voxguard packet
                if (nrf_rx_data[255:240] == 16'hCAFE) begin
                    rx_latch <= nrf_rx_data << 16; 
                    rx_ptr <= 15; 
                end
            end 
            
            if (rx_ptr > 0) begin
                // Unpack and Decrypt Audio
                rx_fifo_din <= rx_latch[255:240] ^ chaos_key[15:0];
                rx_fifo_wr_en <= 1;
                rx_latch <= rx_latch << 16;
                rx_ptr <= rx_ptr - 1;
            end else begin
                rx_fifo_wr_en <= 0;
            end
        end
    end
endmodule