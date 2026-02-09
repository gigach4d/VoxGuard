`timescale 1ns / 1ps

module top_level (
    input wire clk,           // 12 MHz System Clock
    input wire rst_n,         // Active Low Reset (Button 0)
    input wire push_to_talk,  // Button 1 (Unused in Loopback, but kept for pinout)

    // Audio Physical Pins
    output wire i2s_bclk,
    output wire i2s_lrclk,
    input  wire i2s_sdata_in, 
    output wire i2s_sdata_out,
    output wire i2s_mclk,     

    // Radio Pins (Kept to prevent "Floating Pin" errors)
    inout  wire spi_sclk_pin,
    inout  wire spi_sdio_pin,

    // DEBUG LEDS
    output wire [3:0] led
);

    // 1. Reset Logic
    wire rst;
    assign rst = rst_n; // Active High Reset (Press = Reset)

    // 2. Internal Wires
    wire [15:0] adc_data;
    wire        adc_valid;
    wire        dac_ready;

    // ------------------------------------------------------------------
    // 3. THE LATCH LOGIC (Fixed Priority)
    // ------------------------------------------------------------------
    reg [15:0] latched_audio = 0;
    reg        latched_valid = 0;

    always @(posedge clk) begin
        if (rst) begin
            latched_audio <= 0;
            latched_valid <= 0;
        end else begin
            // 1. Default: If Speaker took data, clear the flag.
            if (dac_ready) latched_valid <= 0;

            // 2. Priority Override: If NEW data arrived, set it!
            // (This ensures we don't drop a sample if Read/Write happen same cycle)
            if (adc_valid) begin
                latched_audio <= adc_data;
                latched_valid <= 1;
            end
        end
    end
    
    // 4. Audio Controller Instantiation
    // Note: We use the LATCHED registers for the DAC input!
    i2s_controller #( .SYS_CLK_FREQ(12000000) ) i2s_inst (
        .clk(clk), 
        .rst(rst),
        
        // Speaker Side (Inputs from Latch)
        .dac_data_in(latched_audio),       
        .dac_data_valid(latched_valid),   
        .dac_ready(dac_ready),
        
        // Mic Side (Outputs to Latch)
        .adc_data_out(adc_data),
        .adc_data_valid(adc_valid),
        
        // Physical Pins
        .i2s_bclk(i2s_bclk), 
        .i2s_lrclk(i2s_lrclk),
        .i2s_sdata_in(i2s_sdata_in), 
        .i2s_sdata_out(i2s_sdata_out)
    );
    
    // 5. Hardwire MCLK (Unused but good practice)
    assign i2s_mclk = clk;

    // 6. DEBUG LEDS
    assign led[0] = adc_valid;       // Toggles when Mic sends data
    assign led[1] = latched_valid;   // Toggles when Latch has data (NO MORE Z!)
    assign led[2] = dac_ready;       // Toggles when Speaker requests data
    assign led[3] = (latched_audio > 16'h0500); // Flashes on loud sounds (NO MORE X!)

endmodule