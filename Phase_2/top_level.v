module top_level (
    input wire clk,           // 12 MHz
    input wire rst_n,         // Active Low
    input wire push_to_talk,  // Active High

    // Audio
    output wire i2s_bclk,
    output wire i2s_lrclk,
    input  wire i2s_sdata_in, 
    output wire i2s_sdata_out,
    output wire i2s_mclk,     

    // Radio
    inout  wire  spi_sclk_pin,
    inout  wire  spi_sdio_pin
);

    wire rst;
    assign rst = ~rst_n; 

    // Internal Signals
    wire [15:0] dac_data;
    wire        dac_valid, dac_ready;
    wire [15:0] adc_data;
    wire        adc_valid;
    
    wire        pm_tx_start, pm_tx_busy;
    wire [7:0]  pm_tx_data;
    wire [7:0]  pm_rx_data;
    wire        pm_rx_done;
    
    wire [15:0] tx_payload_data, rx_payload_data;
    wire [15:0] final_decrypted_audio;
    wire [15:0] encrypted_tx_word;
    
    wire [31:0] key_stream;
    wire        next_key_en, sync_en;
    wire [31:0] sync_state;

    // 1. Pass 12MHz Clock to DAC
    assign i2s_mclk = clk; 

    // 2. Audio Controller
    i2s_controller #( .SYS_CLK_FREQ(12000000) ) i2s_inst (
        .clk(clk), .rst(rst),
        .dac_data_in(dac_data), .dac_data_valid(dac_valid), .dac_ready(dac_ready),
        .adc_data_out(adc_data), .adc_data_valid(adc_valid),
        .i2s_bclk(i2s_bclk), .i2s_lrclk(i2s_lrclk),
        .i2s_sdata_in(i2s_sdata_in), .i2s_sdata_out(i2s_sdata_out)
    );

    // 3. Packet Manager
    packet_manager pm_inst (
        .clk(clk), .rst(rst), .push_to_talk(push_to_talk),
        .dac_data_out(dac_data), .dac_data_valid(dac_valid), .dac_ready(dac_ready),
        .adc_data_in(adc_data), .adc_data_valid(adc_valid),
        .spi_tx_start(pm_tx_start), .spi_tx_data(pm_tx_data), .spi_tx_busy(pm_tx_busy),
        .spi_rx_data(pm_rx_data), .spi_rx_done(pm_rx_done),
        .encrypt_data_out(tx_payload_data), 
        .tx_data_in(encrypted_tx_word),
        .spi_rx_assembled(rx_payload_data), 
        .decrypt_data_in(final_decrypted_audio),
        .next_key_en(next_key_en), .sync_en(sync_en), .sync_state_out(sync_state)
    );

    // 4. Crypto Logic
    assign encrypted_tx_word = (tx_payload_data == 16'hCAFE) ? tx_payload_data : (tx_payload_data ^ key_stream[27:12]);
    assign final_decrypted_audio = rx_payload_data ^ key_stream[27:12];

    // 5. Chaotic Generator
    chaotic_generator cg_inst (
        .clk(clk), .rst(rst),
        .next_key_en(next_key_en), .sync_en(sync_en), .sync_state_in(sync_state),
        .key_out(key_stream)
    );

    // 6. SPI Radio (1.5 MHz)
    spi_transceiver #( .CLK_DIV(4) ) spi_inst (
        .clk(clk), .rst(rst),
        .is_master_mode(push_to_talk),
        .tx_start(pm_tx_start), .tx_data(pm_tx_data), .tx_busy(pm_tx_busy),
        .rx_data(pm_rx_data), .rx_done_tick(pm_rx_done),
        .spi_sclk_pin(spi_sclk_pin),
        .spi_sdio_pin(spi_sdio_pin)
    );

endmodule