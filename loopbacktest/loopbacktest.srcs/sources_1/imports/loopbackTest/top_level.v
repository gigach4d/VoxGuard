`timescale 1ns / 1ps

module top_level (
    input wire clk,           // 12 MHz
    input wire rst,           // Active-High Reset (Button 0)
    input wire push_to_talk,  // Active-High PTT (Button 1)

    // Audio Physical Pins
    output wire i2s_bclk,
    output wire i2s_lrclk,
    input  wire i2s_sdata_in, 
    output wire i2s_sdata_out,
    output wire i2s_mclk,     

    // NRF24L01+ RF Pins
    output wire radio_ce,
    output wire radio_csn,
    output wire radio_sck,
    output wire radio_mosi,
    input  wire radio_miso,
    input  wire radio_irq,

    // DEBUG LEDS
    output wire [3:0] led
);

    // 1. Internal Interface Wires
    (*mark_debug = "true" *) wire [15:0] adc_data;
    wire        adc_valid;
    wire        dac_ready;

    // ------------------------------------------------------------------
    // 2. THE DEBOUNCER & SYNCHRONIZATION LOGIC
    // ------------------------------------------------------------------
    reg [19:0] ptt_timer = 0;
    reg clean_ptt = 0;

    // 10ms Low-Pass Filter
    always @(posedge clk) begin
        if (push_to_talk == clean_ptt) begin
            ptt_timer <= 0; 
        end else begin
            ptt_timer <= ptt_timer + 1;
            if (ptt_timer == 20'd120_000) begin 
                clean_ptt <= push_to_talk; 
            end
        end
    end

    // TX Sync: Stagger the signals to prevent race conditions
    reg ptt_prev1 = 0;
    reg ptt_prev2 = 0;
    always @(posedge clk) begin
        ptt_prev1 <= clean_ptt;
        ptt_prev2 <= ptt_prev1;
    end

    // Fires exactly ONE time when the clean PTT goes high
    wire tx_sync_pulse = ptt_prev1 && !ptt_prev2;
    
    // RX Auto-Sync: Fires a reset pulse when the first RF packet arrives after silence
    wire rx_packet_valid; 
    reg [19:0] rx_timeout = 0;
    reg rx_active = 0;
    reg rx_active_prev = 0;

    always @(posedge clk) begin
        rx_active_prev <= rx_active;
        if (rx_packet_valid) begin
            // THE FIX: 5 millisecond timeout (kills static the moment PTT is released)
            rx_timeout <= 20'd60_000; 
            rx_active <= 1;
        end else if (rx_timeout > 0) begin
            rx_timeout <= rx_timeout - 1;
        end else begin
            rx_active <= 0;
        end
    end
    wire rx_sync_pulse = rx_active && !rx_active_prev;

    // ------------------------------------------------------------------
    // 3. THE CRYPTOGRAPHIC PIPELINE
    // ------------------------------------------------------------------
    wire tx_audio_valid = adc_valid & ptt_prev2; 
    wire [15:0] encrypted_tx_data;
    wire        encrypted_tx_valid;

    stream_cipher tx_crypto (
        .clk(clk),
        .rst(rst),
        .sync_reset(tx_sync_pulse),
        .data_in(adc_data),
        .data_valid(tx_audio_valid),
        .data_out(encrypted_tx_data),
        .valid_out(encrypted_tx_valid)
    );

    wire [15:0] rx_audio_data; 
    wire        rx_audio_valid;
    wire [15:0] decrypted_rx_data;
    wire        decrypted_rx_valid;

    stream_cipher rx_crypto (
        .clk(clk),
        .rst(rst),
        .sync_reset(rx_sync_pulse),
        .data_in(rx_audio_data),
        .data_valid(rx_audio_valid),
        .data_out(decrypted_rx_data),
        .valid_out(decrypted_rx_valid)
    );
    
    // ------------------------------------------------------------------
    // 4. THE LATCH LOGIC (Zero-Order Hold & Local Monitor)
    // ------------------------------------------------------------------
    reg [15:0] latched_audio = 0;
    reg        latched_valid = 0;

    always @(posedge clk) begin
        if (rst) begin
            latched_audio <= 0;
            latched_valid <= 0;
        end else begin
            if (clean_ptt) begin
                if (adc_valid) begin
                    latched_audio <= 16'd0; 
                    latched_valid <= 1; 
                end
            end 
            else begin
                if (decrypted_rx_valid) begin
                    // Active Mute: Only output audio to the DAC if the RF stream is alive
                    latched_audio <= rx_active ? decrypted_rx_data : 16'd0;
                    latched_valid <= rx_active; 
                end
            end
        end
    end
    
    // ------------------------------------------------------------------
    // 5. I2S INSTANTIATION
    // ------------------------------------------------------------------
    i2s_controller #( .SYS_CLK_FREQ(12000000) ) i2s_inst (
        .clk(clk), 
        .rst(rst),
        .dac_data_in(latched_audio),       
        .dac_data_valid(latched_valid),   
        .dac_ready(dac_ready),
        .adc_data_out(adc_data),
        .adc_data_valid(adc_valid),
        .i2s_bclk(i2s_bclk), 
        .i2s_lrclk(i2s_lrclk),
        .i2s_sdata_in(i2s_sdata_in), 
        .i2s_sdata_out(i2s_sdata_out)
    );
    assign i2s_mclk = clk; 

    // ------------------------------------------------------------------
    // 6. AUDIO ACCUMULATOR & UNPACKER LOGIC
    // ------------------------------------------------------------------
    reg [255:0] tx_payload_buffer = 0;
    reg [3:0]   tx_frame_count = 0;
    reg         tx_fire_packet = 0;
    wire        radio_tx_busy;
    wire        radio_tx_ack; 

    // TX Accumulator
    always @(posedge clk) begin
        if (rst) begin
            tx_frame_count <= 0;
            tx_fire_packet <= 0;
            tx_payload_buffer <= 0;
        end else begin
            // THE CRITICAL ALIGNMENT FIX: 
            // Force the packet boundary to restart the nanosecond PTT is pressed.
            if (tx_sync_pulse) begin
                tx_frame_count <= 0;
                tx_payload_buffer <= 0;
            end else if (encrypted_tx_valid) begin
                tx_payload_buffer <= {tx_payload_buffer[239:0], encrypted_tx_data};
                tx_frame_count <= tx_frame_count + 1;
                
                if (tx_frame_count == 4'd15) tx_fire_packet <= 1;
            end
            
            if (radio_tx_ack) begin
                tx_fire_packet <= 0;
            end
        end
    end

    // RX Unpacker
    wire [255:0] rx_payload_buffer;
    reg [255:0]  rx_shift_register = 0;
    reg          rx_audio_valid_reg = 0;
    reg [15:0]   current_rx_frame = 0; 
    
    assign rx_audio_valid = rx_audio_valid_reg;
    assign rx_audio_data = current_rx_frame; 

    reg last_lrclk = 0;
    always @(posedge clk) begin
        last_lrclk <= i2s_lrclk;
        rx_audio_valid_reg <= 0;

        // When a new valid RF packet arrives, load it instantly
        if (rx_packet_valid) begin
            rx_shift_register <= rx_payload_buffer; 
        end
        
        // Every time I2S starts a new cycle AND we are actively receiving an RF stream
        if (i2s_lrclk && !last_lrclk && rx_active) begin 
            rx_audio_valid_reg <= 1;
            current_rx_frame <= rx_shift_register[255:240]; 
            rx_shift_register <= {rx_shift_register[239:0], 16'b0}; 
        end
    end
    
    // ------------------------------------------------------------------
    // 7. NRF24 INSTANTIATION
    // ------------------------------------------------------------------
    nrf24_core radio_inst (
        .clk(clk),
        .rst(rst),
        .tx_mode(clean_ptt), 
        
        .tx_payload(tx_payload_buffer),
        .tx_trigger(tx_fire_packet),
        .tx_busy(radio_tx_busy),
        .tx_ack(radio_tx_ack),  
        
        .rx_payload(rx_payload_buffer),
        .rx_valid(rx_packet_valid),
        
        .ce(radio_ce),
        .csn(radio_csn),
        .sck(radio_sck),
        .mosi(radio_mosi),
        .miso(radio_miso),
        .irq(radio_irq)
    );
    
    // ------------------------------------------------------------------
    // 8. SPI & RF DIAGNOSTIC LEDS
    // ------------------------------------------------------------------
    assign led[0] = clean_ptt;        
    assign led[1] = !radio_tx_busy;   
    assign led[2] = !radio_csn;       
    assign led[3] = !radio_irq;       

endmodule