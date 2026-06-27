module i2s_controller #(
    parameter SYS_CLK_FREQ = 12_000_000
) (
    input wire clk,
    input wire rst,
    
    // Internal Interface
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

    // Master Counter: 0..255 (Defines the entire I2S Frame)
    reg [7:0] master_cnt; 
    reg [31:0] tx_shift_reg;
    reg [31:0] rx_shift_reg;

    always @(posedge clk) begin
        if (rst) begin
            master_cnt    <= 0;
            i2s_bclk      <= 1;
            i2s_lrclk     <= 0;
            dac_ready     <= 0;
            i2s_sdata_out <= 0;
            adc_data_valid<= 0;
            adc_data_out  <= 0;
            tx_shift_reg  <= 0;
            rx_shift_reg  <= 0;
        end else begin
            master_cnt <= master_cnt + 1;

            // 1. CLOCK GENERATION
            i2s_bclk  <= master_cnt[1]; // Toggle every 2 ticks (3MHz)
            i2s_lrclk <= master_cnt[7]; // Toggle every 128 ticks (46.8kHz)

            // -----------------------------------------------------------
            // 2. TRANSMITTER (TX) - Drives on Falling Edge (Count ends in 11)
            // -----------------------------------------------------------
            if (master_cnt[1:0] == 2'b11) begin 
                // Frame Synchronization
                if (master_cnt == 8'd255) begin // End of Right Frame -> Load Left
                    dac_ready <= 1;
                    if (dac_data_valid) tx_shift_reg <= {dac_data_in, 16'b0};
                    else tx_shift_reg <= 0;
                end 
                else if (master_cnt == 8'd127) begin // End of Left Frame -> Load Right (Zero)
                    tx_shift_reg <= 0;
                    dac_ready <= 0;
                end 
                else begin // Shift
                    dac_ready <= 0;
                    tx_shift_reg <= {tx_shift_reg[30:0], 1'b0};
                end
                i2s_sdata_out <= tx_shift_reg[31];
            end

            // -----------------------------------------------------------
            // 3. RECEIVER (RX) - Samples on Rising Edge (Count ends in 01)
            // -----------------------------------------------------------
            if (master_cnt[1:0] == 2'b01) begin
                rx_shift_reg <= {rx_shift_reg[30:0], i2s_sdata_in};
            end
    
            // -----------------------------------------------------------
            // 4. RX CAPTURE - THE FIX
            // -----------------------------------------------------------
            // We capture at Count 128 (The very first instant of the RIGHT Frame).
            // This guarantees the Left Frame shift is fully complete and stable.
            if (master_cnt == 8'd128) begin
                // DATA ALIGNMENT:
                // After 32 shifts, rx_shift_reg contains: [DelayBit, MSB, ..., LSB]
                // We want [MSB...]. This is located at indices [30:15].
                adc_data_out   <= rx_shift_reg[30:15];
                adc_data_valid <= 1;
            end else begin
                adc_data_valid <= 0;
            end
        end
    end
endmodule