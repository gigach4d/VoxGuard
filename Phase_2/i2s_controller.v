module i2s_controller #(
    parameter SYS_CLK_FREQ = 12_000_000, 
    parameter SAMPLE_RATE  = 46_875,     // Changed to fit 12MHz integer math
    parameter DATA_WIDTH   = 32          // FIXED: Must be 32 for INMP441
) (
    input wire clk,
    input wire rst,
    
    // Internal Interface (Still 16-bit for your logic)
    input wire [15:0] dac_data_in,
    input wire dac_data_valid,
    output reg dac_ready,
    output reg [15:0] adc_data_out,
    output reg adc_data_valid,
    
    // Physical I2S Interface
    output reg i2s_bclk,
    output reg i2s_lrclk,
    input  wire i2s_sdata_in, 
    output reg i2s_sdata_out
);

    // BCLK Generation
    // 12MHz / (46875 * 64) = 4.0 exactly. 
    // We toggle every 2 system clocks.
    localparam BCLK_DIV = 2; 
    reg [7:0] bclk_counter;

    reg [31:0] tx_shift_reg;
    reg [31:0] rx_shift_reg;
    reg [5:0]  bit_counter;

    // Edge Detection
    reg i2s_bclk_prev;
    wire i2s_bclk_fall;
    wire i2s_bclk_rise;

    // 1. Generate BCLK (3.0 MHz)
    always @(posedge clk) begin
        if (rst) begin
            bclk_counter <= 0;
            i2s_bclk <= 0;
        end else begin
            if (bclk_counter == BCLK_DIV - 1) begin
                bclk_counter <= 0;
                i2s_bclk <= ~i2s_bclk;
            end else begin
                bclk_counter <= bclk_counter + 1;
            end
        end
    end

    // 2. Detect Edges
    always @(posedge clk) i2s_bclk_prev <= i2s_bclk;
    assign i2s_bclk_fall = (!i2s_bclk && i2s_bclk_prev); // 1->0 (Drive TX)
    assign i2s_bclk_rise = (i2s_bclk && !i2s_bclk_prev); // 0->1 (Sample RX)

    // 3. TX Logic (Standard I2S: 1-cycle delay, MSB first)
    always @(posedge clk) begin
        if (rst) begin
            bit_counter <= 0;
            i2s_lrclk <= 1; 
            dac_ready <= 0;
            tx_shift_reg <= 0;
            i2s_sdata_out <= 0;
        end else if (i2s_bclk_fall) begin
            // I2S Standard: WS changes on falling edge
            if (bit_counter == 31) begin
                bit_counter <= 0;
                i2s_lrclk <= ~i2s_lrclk; // Flip Channel
                
                // Load Data for NEXT channel
                dac_ready <= 1; 
                // We put 16-bit data into the TOP of the 32-bit slot
                // Padding low bits with 0
                if (dac_data_valid) 
                    tx_shift_reg <= {dac_data_in, 16'b0}; 
                else
                    tx_shift_reg <= 0;

            end else begin
                bit_counter <= bit_counter + 1;
                dac_ready <= 0;
                // Shift: I2S data starts on the *second* clock cycle
                // The MSB is shifted out after the 1-cycle delay
                tx_shift_reg <= tx_shift_reg << 1;
            end
            
            // Output the MSB of the shift register
            // Note: In standard I2S, the first bit after WS change is "garbage" or LSB of prev.
            // Valid data starts on bit_counter = 0 relative to new WS
            i2s_sdata_out <= tx_shift_reg[31];
        end
    end

    // 4. RX Logic (Sample on RISING Edge)
    always @(posedge clk) begin
        if (rst) begin
            adc_data_out <= 0;
            adc_data_valid <= 0;
            rx_shift_reg <= 0;
        end else if (i2s_bclk_rise) begin
            // Shift In
            rx_shift_reg <= {rx_shift_reg[30:0], i2s_sdata_in};

            // Capture at end of frame (Bit 30 is the last bit of standard I2S data)
            // INMP441 puts MSB at bit 1 (after WS change).
            if (bit_counter == 31) begin
                // Take top 16 bits of the received 24-bit word
                adc_data_out <= rx_shift_reg[30:15];
                adc_data_valid <= 1;
            end else begin
                adc_data_valid <= 0;
            end
        end
    end
endmodule