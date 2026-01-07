module packet_manager (
    input wire clk,
    input wire rst,
    input wire push_to_talk, 
    
    // I2S Interface
    output reg [15:0] dac_data_out,
    output reg dac_data_valid,
    input  wire dac_ready,
    input  wire [15:0] adc_data_in,
    input  wire adc_data_valid,
    
    // SPI Transceiver Interface
    output reg spi_tx_start,
    output reg [7:0] spi_tx_data,
    input  wire spi_tx_busy,   
    input  wire [7:0] spi_rx_data,
    input  wire spi_rx_done,      
    
    // Encryption/Decryption Interface
    output reg [15:0] encrypt_data_out, 
    input  wire [15:0] tx_data_in,       
    
    output wire [15:0] spi_rx_assembled, 
    input  wire [15:0] decrypt_data_in,  
    
    // Chaotic Generator Interface
    output reg next_key_en,
    output reg sync_en,
    output reg [31:0] sync_state_out
);
    // State Encoding
    localparam IDLE = 0,
               TX_PREPARE_PREAMBLE = 1,
               TX_PREPARE_AUDIO = 2,
               TX_SEND_HIGH = 3,
               TX_WAIT_HIGH = 4,
               TX_SEND_LOW = 5,
               TX_WAIT_LOW = 6,
               // RX States
               RX_WAIT_AUDIO_HIGH = 7,
               RX_WAIT_AUDIO_LOW = 8,
               RX_SAVE_AUDIO = 9; 

    reg [3:0] state, next_state;
    reg [15:0] tx_latch;
    reg [15:0] rx_assembly;
    reg        tx_is_preamble;
    reg [15:0] raw_audio_latch;

    localparam [15:0] SYNC_WORD = 16'hCAFE;
    localparam [31:0] RESET_SEED = 32'h01F97414;

    assign spi_rx_assembled = rx_assembly;

    // --- State Sequencer ---
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            tx_latch <= 0;
            rx_assembly <= 0;
            tx_is_preamble <= 0;
            raw_audio_latch <= 0;
        end else begin
            state <= next_state;

            // Latch Raw Audio for TX
            if (state == IDLE && adc_data_valid) 
                raw_audio_latch <= adc_data_in;

            // Latch Encrypted TX Data
            if (state == TX_PREPARE_PREAMBLE || state == TX_PREPARE_AUDIO) begin
                tx_latch <= tx_data_in;
                if (state == TX_PREPARE_PREAMBLE) tx_is_preamble <= 1;
                else tx_is_preamble <= 0;
            end

            // RX Sliding Window: Shift in bytes whenever they arrive
            if (!push_to_talk) begin
                if (spi_rx_done) begin
                    rx_assembly <= {rx_assembly[7:0], spi_rx_data};
                end
            end
        end
    end

    // --- Combinatorial Logic ---
    always @(*) begin
        next_state = state;
        spi_tx_start = 0;
        spi_tx_data = 0;
        sync_en = 0;
        sync_state_out = RESET_SEED;
        encrypt_data_out = 0; 
        next_key_en = 0;

        case (state)
            IDLE: begin
                if (push_to_talk) begin
                    // TX LOGIC
                    if (adc_data_valid) begin
                        encrypt_data_out = SYNC_WORD; 
                        sync_en = 1'b1; 
                        next_state = TX_PREPARE_PREAMBLE;
                    end
                end else begin
                    // RX LOGIC: Check Sliding Window
                    if (rx_assembly == SYNC_WORD) begin
                        sync_en = 1; // Found Header
                        next_state = RX_WAIT_AUDIO_HIGH; 
                    end
                end
            end

            // --- TX STATES ---
            TX_PREPARE_PREAMBLE: begin
                encrypt_data_out = SYNC_WORD;
                next_state = TX_SEND_HIGH;
            end
            TX_PREPARE_AUDIO: begin
                encrypt_data_out = raw_audio_latch;
                next_state = TX_SEND_HIGH;
            end
            TX_SEND_HIGH: begin
                spi_tx_data = tx_latch[15:8];
                spi_tx_start = 1;
                next_state = TX_WAIT_HIGH;
            end
            TX_WAIT_HIGH: if (!spi_tx_busy) next_state = TX_SEND_LOW;
            TX_SEND_LOW: begin
                spi_tx_data = tx_latch[7:0];
                spi_tx_start = 1;
                next_state = TX_WAIT_LOW;
            end
            TX_WAIT_LOW: begin
                if (!spi_tx_busy) begin
                    if (tx_is_preamble) next_state = TX_PREPARE_AUDIO;
                    else next_state = IDLE;
                end
            end

            // --- RX STATES ---
            RX_WAIT_AUDIO_HIGH: begin
                if (spi_rx_done) next_state = RX_WAIT_AUDIO_LOW;
            end

            RX_WAIT_AUDIO_LOW: begin
                if (spi_rx_done) begin
                    // Wait 1 cycle for Low Byte to shift into rx_assembly
                    next_state = RX_SAVE_AUDIO; 
                end
            end

            RX_SAVE_AUDIO: begin
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

    // --- Audio Output Latch ---
    always @(posedge clk) begin
        if (rst) begin
            dac_data_out   <= 0;
            dac_data_valid <= 0;
        end else begin
            // Update output ONLY when data is fully assembled (Save State)
            if (state == RX_SAVE_AUDIO) begin
                dac_data_out   <= decrypt_data_in; 
                dac_data_valid <= 1; 
            end
        end
    end
endmodule