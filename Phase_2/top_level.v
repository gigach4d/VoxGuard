`timescale 1ns / 1ps

module top_level (
    input wire clk,           
    input wire rst_n,         
    input wire push_to_talk,  

    // Audio Physical Pins
    output wire i2s_bclk,
    output wire i2s_lrclk,
    input  wire i2s_sdata_in, 
    output wire i2s_sdata_out,
    output wire i2s_mclk,     

    // Radio SPI Pins
    inout  wire spi_sclk_pin,
    inout  wire spi_sdio_pin,

    // DEBUG LEDS
    output wire [3:0] led
);

    wire rst = !rst_n; // Standardize Active High internally

    // ------------------------------------------------------------------
    // PRE-DECLARE ALL WIRES (Fixes implicit declaration warnings)
    // ------------------------------------------------------------------
    wire [15:0] adc_data, dac_data;
    wire adc_valid, dac_ready;
    
    wire tx_fifo_empty, tx_fifo_full, rx_fifo_empty, rx_fifo_full;
    wire tx_fifo_rd_en, rx_fifo_wr_en;
    wire [15:0] tx_fifo_dout, rx_fifo_din;
    
    wire [7:0] spi_tx_data, spi_rx_data;
    wire spi_tx_start, spi_tx_busy, spi_rx_done;

    // --- 1. Audio Interface (I2S) ---
    i2s_controller #( .SYS_CLK_FREQ(12000000) ) i2s_inst (
        .clk(clk), .rst(rst),
        .dac_data_in(dac_data), .dac_data_valid(!rx_fifo_empty), .dac_ready(dac_ready),
        .adc_data_out(adc_data), .adc_data_valid(adc_valid),
        .i2s_bclk(i2s_bclk), .i2s_lrclk(i2s_lrclk),
        .i2s_sdata_in(i2s_sdata_in), .i2s_sdata_out(i2s_sdata_out)
    );
    assign i2s_mclk = clk;

    // --- 2. The Shock Absorbers (FIFOs) ---
    // Mic -> TX FIFO
    fwft_fifo #(.DEPTH(256)) tx_fifo (
        .clk(clk), .rst(rst),
        .wr_en(adc_valid && !tx_fifo_full && push_to_talk), // Only record when holding button
        .din(adc_data),
        .rd_en(tx_fifo_rd_en), .dout(tx_fifo_dout),
        .empty(tx_fifo_empty), .full(tx_fifo_full)
    );

    // RX FIFO -> Speaker
    fwft_fifo #(.DEPTH(256)) rx_fifo (
        .clk(clk), .rst(rst),
        .wr_en(rx_fifo_wr_en && !push_to_talk), // Only play when button is released
        .din(rx_fifo_din),
        .rd_en(dac_ready && !rx_fifo_empty), // Auto-pop when Speaker is ready
        .dout(dac_data),
        .empty(rx_fifo_empty), .full(rx_fifo_full)
    );

    // --- 3. The Brain (Packet Manager & Crypto) ---
    packet_manager pkt_mgr (
        .clk(clk), .rst(rst), .push_to_talk(push_to_talk),
        
        .tx_fifo_dout(tx_fifo_dout), .tx_fifo_empty(tx_fifo_empty), .tx_fifo_rd_en(tx_fifo_rd_en),
        .rx_fifo_din(rx_fifo_din), .rx_fifo_wr_en(rx_fifo_wr_en), .rx_fifo_full(rx_fifo_full),
        
        .spi_tx_start(spi_tx_start), .spi_tx_data(spi_tx_data), .spi_tx_busy(spi_tx_busy),
        .spi_rx_data(spi_rx_data), .spi_rx_done(spi_rx_done)
    );

    // --- 4. The Radio Interface (SPI) ---
    spi_transceiver #( .CLK_DIV(4) ) spi_inst (
        .clk(clk), .rst(rst),
        .is_master_mode(push_to_talk), // TX = Master, RX = Slave
        
        .tx_start(spi_tx_start), .tx_data(spi_tx_data), .tx_busy(spi_tx_busy),
        .rx_data(spi_rx_data), .rx_done_tick(spi_rx_done),
        
        .spi_sclk_pin(spi_sclk_pin), .spi_sdio_pin(spi_sdio_pin)
    );

    // --- 5. Debug LEDs ---
    assign led[0] = push_to_talk;         // TX Mode indicator
    assign led[1] = !tx_fifo_empty;       // TX Data queued
    assign led[2] = !rx_fifo_empty;       // RX Data playing
    assign led[3] = spi_tx_busy;          // Radio Transmitting indicator

endmodule