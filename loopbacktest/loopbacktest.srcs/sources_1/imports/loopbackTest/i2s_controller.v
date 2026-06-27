module i2s_controller #(
    parameter SYS_CLK_FREQ = 12_000_000
) (
    input wire clk,
    input wire rst,
    
    input wire [15:0] dac_data_in,
    input wire dac_data_valid,
    output reg dac_ready,
    
    output reg [15:0] adc_data_out,
    output reg adc_data_valid,
    
    output wire i2s_bclk,
    output wire i2s_lrclk,
    input  wire i2s_sdata_in, 
    output reg i2s_sdata_out
);

    reg [8:0] master_cnt; 
    reg [31:0] tx_shift_reg;
    reg [31:0] rx_shift_reg;

    // 1.5 MHz BCLK and 23.4 kHz LRCLK (Breadboard safe)
    assign i2s_bclk  = master_cnt[2];
    assign i2s_lrclk = master_cnt[8];

    // Edge Detection
    wire bclk_fall = (master_cnt[2:0] == 3'b111);
    wire bclk_rise = (master_cnt[2:0] == 3'b011);

    always @(posedge clk) begin
        if (rst) begin
            master_cnt    <= 0;
            dac_ready     <= 0;
            i2s_sdata_out <= 0;
            adc_data_valid<= 0;
            adc_data_out  <= 0;
            tx_shift_reg  <= 0;
            rx_shift_reg  <= 0;
        end else begin
            master_cnt <= master_cnt + 1;
            adc_data_valid <= 0;
            dac_ready <= 0;

            // -----------------------------------------------------------
            // TX LOGIC (Preserved from successful DAC test)
            // -----------------------------------------------------------
            if (bclk_fall) begin 
                if (master_cnt == 9'd511) begin // End of Right Frame -> Load Left
                    dac_ready <= 1;
                    tx_shift_reg <= dac_data_valid ? {dac_data_in, 16'b0} : 32'b0;
                end else if (master_cnt == 9'd255) begin // End of Left Frame -> Load Right (Silence)
                    tx_shift_reg <= 0;
                end else begin // Shift Left
                    tx_shift_reg <= {tx_shift_reg[30:0], 1'b0};
                end
                i2s_sdata_out <= tx_shift_reg[31];
            end

            // -----------------------------------------------------------
            // RX LOGIC (INMP441 Microphone Capture)
            // -----------------------------------------------------------
            if (bclk_rise) begin
                // ONLY shift the data here. Do not capture.
                rx_shift_reg <= {rx_shift_reg[30:0], i2s_sdata_in};
            end
            
            // At count 255, the Left frame is 100% complete.
            // The shifting has stopped, and the data is perfectly aligned.
            if (master_cnt == 9'd255) begin
                adc_data_out   <= rx_shift_reg[30:15];
                adc_data_valid <= 1;
            end
        end
    end
endmodule