// i2s_controller.sv
// Simplified I2S Master Controller for audio codecs.
module i2s_controller #(
    parameter SYS_CLK_FREQ = 50_000_000, // 50 MHz system clock
    parameter SAMPLE_RATE  = 44_100,     // 44.1 kHz audio
    parameter DATA_WIDTH   = 16
) (
    input logic clk,
    input logic rst,
    
    // Data to be sent to the DAC
    input logic [DATA_WIDTH-1:0] dac_data_in,
    input logic dac_data_valid,
    output logic dac_ready,
    
    // Data received from the ADC
    output logic [DATA_WIDTH-1:0] adc_data_out,
    output logic adc_data_valid,
    
    // I2S physical interface
    output logic i2s_bclk,
    output logic i2s_lrclk,
    input  logic i2s_sdata_in,
    output logic i2s_sdata_out
);

    // BCLK = 64 * LRCLK (Sample Rate)
    localparam BCLK_DIV = (SYS_CLK_FREQ / (SAMPLE_RATE * 2 * DATA_WIDTH)) / 2;
    
    logic [$clog2(BCLK_DIV)-1:0] bclk_counter;
    logic [DATA_WIDTH*2-1:0] tx_shift_reg;
    logic [DATA_WIDTH*2-1:0] rx_shift_reg;
    logic [5:0] bit_counter;

    // Generate BCLK
    always_ff @(posedge clk) begin
        if (rst) begin
            bclk_counter <= '0;
            i2s_bclk <= 1'b0;
        end else begin
            if (bclk_counter == BCLK_DIV - 1) begin
                bclk_counter <= '0;
                i2s_bclk <= ~i2s_bclk;
            end else begin
                bclk_counter <= bclk_counter + 1;
            end
        end
    end

    // I2S Main State Machine
    always_ff @(posedge clk) begin
        if (rst) begin
            bit_counter <= '0;
            i2s_lrclk <= 1'b0;
            dac_ready <= 1'b0;
            adc_data_valid <= 1'b0;
            tx_shift_reg <= '0;
        end else if (i2s_bclk) begin // Operate on rising edge of BCLK
            if (bit_counter == (DATA_WIDTH * 2) - 1) begin
                i2s_lrclk <= ~i2s_lrclk;
                bit_counter <= '0;
                dac_ready <= 1'b1; // Ready for next sample
                if (dac_data_valid) begin
                    // Load L and R channel data (we'll just use the same data for both)
                    tx_shift_reg <= {dac_data_in, dac_data_in}; 
                    dac_ready <= 1'b0;
                end
            end else begin
                bit_counter <= bit_counter + 1;
            end

            // Shift out data on falling edge of system clock when BCLK is high
            i2s_sdata_out <= tx_shift_reg[DATA_WIDTH*2-1];
            tx_shift_reg <= tx_shift_reg << 1;

            // Shift in data on rising edge of system clock when BCLK is high
            rx_shift_reg <= {rx_shift_reg[DATA_WIDTH*2-2:0], i2s_sdata_in};
            
            // Check if a full sample has been received
            if (bit_counter == (DATA_WIDTH*2)-2) begin
                 adc_data_out <= rx_shift_reg[DATA_WIDTH-1:0]; // Use left channel data
                 adc_data_valid <= 1'b1;
            end else begin
                 adc_data_valid <= 1'b0;
            end
        end
    end

endmodule