module i2s_controller #(
    parameter SYS_CLK_FREQ = 50_000_000, 
    parameter SAMPLE_RATE  = 44_100,     
    parameter DATA_WIDTH   = 16
) (
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] dac_data_in,
    input wire dac_data_valid,
    output reg dac_ready,
    output reg [DATA_WIDTH-1:0] adc_data_out,
    output reg adc_data_valid,
    output reg i2s_bclk,
    output reg i2s_lrclk,
    input  wire i2s_sdata_in,
    output reg i2s_sdata_out
);
    localparam BCLK_DIV = (SYS_CLK_FREQ / (SAMPLE_RATE * 2 * DATA_WIDTH)) / 2;
    reg [7:0] bclk_counter;
    
    reg [DATA_WIDTH*2-1:0] tx_shift_reg;
    reg [DATA_WIDTH*2-1:0] rx_shift_reg;
    reg [5:0] bit_counter;

    // Edge Detection for BCLK
    reg i2s_bclk_prev;
    wire i2s_bclk_rise;

    // Generate BCLK (Toggle)
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

    // Detect Rising Edge of BCLK to synchronize logic
    always @(posedge clk) begin
        i2s_bclk_prev <= i2s_bclk;
    end
    assign i2s_bclk_rise = (i2s_bclk && !i2s_bclk_prev);

    // Main I2S Logic (Runs once per BCLK rising edge)
    always @(posedge clk) begin
        if (rst) begin
            bit_counter <= 0;
            i2s_lrclk <= 0;
            dac_ready <= 0;
            adc_data_valid <= 0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            i2s_sdata_out <= 0;
            adc_data_out <= 0;
        end else if (i2s_bclk_rise) begin  // <--- FIXED: Only run on rising edge
            if (bit_counter == (DATA_WIDTH * 2) - 1) begin
                i2s_lrclk <= ~i2s_lrclk;
                bit_counter <= 0;
                dac_ready <= 1; 
                if (dac_data_valid) begin
                    tx_shift_reg <= {dac_data_in, dac_data_in};
                    dac_ready <= 0;
                end
            end else begin
                bit_counter <= bit_counter + 1;
            end
            
            // Output data (MSB first)
            i2s_sdata_out <= tx_shift_reg[DATA_WIDTH*2-1];
            tx_shift_reg <= tx_shift_reg << 1;
            
            // Input data (Shift in)
            rx_shift_reg <= {rx_shift_reg[DATA_WIDTH*2-2:0], i2s_sdata_in};
            
            // Capture ADC word when complete
            if (bit_counter == (DATA_WIDTH*2)-2) begin
                 adc_data_out <= rx_shift_reg[DATA_WIDTH-1:0];
                 adc_data_valid <= 1;
            end else begin
                 adc_data_valid <= 0;
            end
        end
    end
endmodule
