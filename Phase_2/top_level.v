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
    //output wire i2s_mclk,     

    // nRF24L01 Physical Pins
    output wire radio_ce,
    output wire radio_csn,
    output wire radio_sck,
    output wire radio_mosi,
    input  wire radio_miso,
    input  wire radio_irq,

    // DEBUG LEDS
    output wire [3:0] led
);

    // 1. Reset Logic (Active High internal)
    wire rst = rst_n; 
    //assign i2s_mclk = clk;

    // 2. Audio Wires
    wire [15:0] adc_data, dac_data;
    wire adc_valid, dac_ready;
    
    // 3. FIFO Wires
    wire tx_fifo_empty, tx_fifo_full, rx_fifo_empty, rx_fifo_full;
    wire tx_fifo_rd_en, rx_fifo_wr_en;
    wire [15:0] tx_fifo_dout, rx_fifo_din;
    
    // 4. Radio Packet Wires (New!)
    wire [255:0] tx_pkt, rx_pkt;
    wire start_tx, tx_done, rx_ready;

    // --- MODULE INSTANTIATIONS ---

    // A. Audio Controller
    i2s_controller #( .SYS_CLK_FREQ(12000000) ) i2s_inst (
        .clk(clk), .rst(rst),
        .dac_data_in(dac_data), .dac_data_valid(!rx_fifo_empty), .dac_ready(dac_ready),
        .adc_data_out(adc_data), .adc_data_valid(adc_valid),
        .i2s_bclk(i2s_bclk), .i2s_lrclk(i2s_lrclk),
        .i2s_sdata_in(i2s_sdata_in), .i2s_sdata_out(i2s_sdata_out)
    );

    // B. TX FIFO (Mic -> Buffer)
    fwft_fifo #(.DEPTH(256)) tx_fifo (
        .clk(clk), .rst(rst),
        .wr_en(adc_valid && !tx_fifo_full && push_to_talk), 
        .din(adc_data),
        .rd_en(tx_fifo_rd_en), .dout(tx_fifo_dout),
        .empty(tx_fifo_empty), .full(tx_fifo_full)
    );

    // C. RX FIFO (Buffer -> Speaker)
    fwft_fifo #(.DEPTH(256)) rx_fifo (
        .clk(clk), .rst(rst),
        .wr_en(rx_fifo_wr_en), // Packet Manager controls write
        .din(rx_fifo_din),
        .rd_en(dac_ready && !rx_fifo_empty), 
        .dout(dac_data),
        .empty(rx_fifo_empty), .full(rx_fifo_full)
    );

    // D. The Packet Manager (Logic Glue)
    packet_manager pkt_mgr (
        .clk(clk), .rst(rst), .push_to_talk(push_to_talk),
        
        // FIFO connections
        .tx_fifo_dout(tx_fifo_dout), .tx_fifo_empty(tx_fifo_empty), .tx_fifo_rd_en(tx_fifo_rd_en),
        .rx_fifo_din(rx_fifo_din), .rx_fifo_wr_en(rx_fifo_wr_en), 
        
        // Radio Driver connections
        .start_tx(start_tx), .nrf_tx_data(tx_pkt), .tx_done(tx_done),
        .rx_ready(rx_ready), .nrf_rx_data(rx_pkt)
    );

    wire [3:0] radio_state;
    
    // E. The Radio Driver (Physical Layer)
    nrf24_driver radio (
        .clk(clk), .rst(rst), .tx_en(push_to_talk),
        
        // Logic Connections
        .start_tx(start_tx), .tx_data(tx_pkt), .tx_done(tx_done),
        .rx_ready(rx_ready), .rx_data(rx_pkt), //.debug_state(radio_state),
        
        // Physical Pins
        .ce(radio_ce), .csn(radio_csn), .sck(radio_sck),
        .mosi(radio_mosi), .miso(radio_miso), .irq(radio_irq)
    );

    // --- Debug LEDs ---
    assign led[0] = push_to_talk;   // ON = Transmitting
    assign led[1] = !tx_fifo_empty; // ON = Audio in TX Buffer
    assign led[2] = !rx_fifo_empty; // ON = Audio in RX Buffer
    assign led[3] = !radio_irq;     // FLASH = Radio Activity (TX or RX)
    
    //assign led = radio_state;
endmodule