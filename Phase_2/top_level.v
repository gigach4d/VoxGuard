module top_level (
    input wire clk,
    input wire rst_n,
    input wire push_to_talk,

    // Audio
    output wire i2s_bclk,
    output wire i2s_lrclk,
    input  wire i2s_sdata_in, 
    output wire i2s_sdata_out,
    output reg  i2s_mclk,     

    // Radio
    inout  wire  spi_sclk_pin,
    inout  wire  spi_sdio_pin,
    
    // Debug
    // Debug Output (Maps to the 8 LEDs on your board)
    output wire [7:0] leds
);

    wire rst;
    assign rst = rst_n;

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

    // MCLK Generation
    reg [1:0] mclk_counter;
    always @(posedge clk) begin
        if (rst) begin 
            mclk_counter <= 0; 
            i2s_mclk <= 0; 
        end else begin 
            mclk_counter <= mclk_counter + 1; 
            i2s_mclk <= mclk_counter[1]; 
        end
    end

    // Instantiations
    i2s_controller #( .SYS_CLK_FREQ(50000000) ) i2s_inst (
        .clk(clk), .rst(rst),
        .dac_data_in(dac_data), .dac_data_valid(dac_valid), .dac_ready(dac_ready),
        .adc_data_out(adc_data), .adc_data_valid(adc_valid),
        .i2s_bclk(i2s_bclk), .i2s_lrclk(i2s_lrclk),
        .i2s_sdata_in(i2s_sdata_in), .i2s_sdata_out(i2s_sdata_out)
    );

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

    assign encrypted_tx_word = (tx_payload_data == 16'hCAFE) ? tx_payload_data : (tx_payload_data ^ key_stream[27:12]);
    assign final_decrypted_audio = rx_payload_data ^ key_stream[27:12];

    chaotic_generator cg_inst (
        .clk(clk), .rst(rst),
        .next_key_en(next_key_en), .sync_en(sync_en), .sync_state_in(sync_state),
        .key_out(key_stream)
    );

    spi_transceiver #( .CLK_DIV(4) ) spi_inst (
        .clk(clk), .rst(rst),
        .is_master_mode(push_to_talk),
        .tx_start(pm_tx_start), .tx_data(pm_tx_data), .tx_busy(pm_tx_busy),
        .rx_data(pm_rx_data), .rx_done_tick(pm_rx_done),
        .spi_sclk_pin(spi_sclk_pin),
        .spi_sdio_pin(spi_sdio_pin)
    );
	 // =========================================================================
    // VISUAL DEBUG LOGIC (Pulse Stretchers)
    // =========================================================================
    
    // 1. Heartbeat Counter (Blinks LED 0 to prove Clock is running)
    // 23 bits count to ~8 million. At 12MHz, bit 23 toggles every ~0.7 seconds.
    reg [23:0] heartbeat_cnt;
    always @(posedge clk) begin
        heartbeat_cnt <= heartbeat_cnt + 1;
    end

    // 2. Sync Pulse Stretcher (Makes LED 2 flash visibly when 0xCAFE is found)
    reg [22:0] sync_timer;
    always @(posedge clk) begin
        if (sync_en) 
            sync_timer <= 23'h7FFFFF; // Load max value (flash for ~0.3s)
        else if (sync_timer > 0) 
            sync_timer <= sync_timer - 1;
    end

    // 3. Audio Activity Stretcher (Makes LED 3 flash when audio packets arrive)
    reg [22:0] audio_timer;
    always @(posedge clk) begin
        if (adc_valid || dac_valid) 
            audio_timer <= 23'h7FFFFF;
        else if (audio_timer > 0) 
            audio_timer <= audio_timer - 1;
    end

    // --- LED MAPPING ---
    // LED 0: Heartbeat (Should blink slowly ALWAYS)
    assign leds[0] = heartbeat_cnt[23]; 
    
    // LED 1: PTT Status (Lights up when you press button)
    assign leds[1] = push_to_talk;      
    
    // LED 2: Sync Detected (Flashes when RX hears "Hello")
    assign leds[2] = (sync_timer > 0);  
    
    // LED 3: Audio Moving (Flashes when talking/receiving)
    assign leds[3] = (audio_timer > 0); 
    
    // LED 4: Error/Reset Indicator (Lights up if Reset is held)
    assign leds[4] = rst;

    assign leds[7:5] = 0; // Unused
endmodule
