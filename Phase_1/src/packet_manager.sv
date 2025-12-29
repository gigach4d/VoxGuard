// src/packet_manager.sv
// Manages the overall state (transmit/receive) and data flow.
// CORRECTED VERSION with proper registered logic.
module packet_manager (
    input logic clk,
    input logic rst,
    input logic push_to_talk, // 1 = Transmit, 0 = Receive
    
    // Interface to I2S Controller
    output logic [15:0] dac_data_out,
    output logic dac_data_valid,
    input  logic dac_ready,
    input  logic [15:0] adc_data_in,
    input  logic adc_data_valid,
    
    // Interface to SPI Controller
    output logic spi_start,
    output logic [7:0] spi_data_in,
    input  logic [7:0] spi_data_out,
    input  logic spi_busy,
    
    // Interface to Encrypt/Decrypt
    output logic [15:0] encrypt_data_out,
    input  logic [15:0] decrypt_data_in,
    
    // Interface to Key Generator
    output logic next_key_en,
    output logic sync_en,
    output logic [31:0] sync_state_out
);

    typedef enum {IDLE, TX_SEND_SYNC, RX_LISTEN, RX_READ_DATA} state_t;
    
    // --- Registered Signals ---
    state_t state;
    logic [15:0] audio_buffer; // This is now a register

    // --- Combinational Signals ---
    state_t next_state;

    // --- Registered Logic (Stateful) ---
    // This block handles all signals that need to hold their state over time.
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            audio_buffer <= 16'b0;
        end else begin
            state <= next_state;
            // Latch the incoming audio data when instructed by the FSM
            if (next_state == TX_SEND_SYNC) begin
                audio_buffer <= adc_data_in;
            end
        end
    end

    // --- Combinational Logic (Instantaneous) ---
    // This block calculates the next state and the outputs based on
    // the current state and inputs.
    always_comb begin
        // Default assignments for all outputs
        next_state = state;
        dac_data_out = '0;
        dac_data_valid = 1'b0;
        spi_start = 1'b0;
        spi_data_in = '0;
        next_key_en = 1'b0;
        sync_en = 1'b0;
        sync_state_out = '0;
        encrypt_data_out = audio_buffer; // Read from the register
        
        case (state)
            IDLE: begin
                if (push_to_talk) begin
                    if (adc_data_valid) begin
                        // Just need to set the next state; the always_ff block
                        // will handle capturing the data.
                        next_state = TX_SEND_SYNC;
                    end
                end else begin
                    next_state = RX_LISTEN; 
                end
            end
            
            TX_SEND_SYNC: begin
                // In a real system, this would be a multi-step FSM.
                next_state = IDLE;
            end
            
            RX_LISTEN: begin
                if (!push_to_talk) begin
                    if (decrypt_data_in != 16'b0) begin 
                         next_state = RX_READ_DATA;
                    end
                end else begin
                    next_state = IDLE;
                end
            end
            
            RX_READ_DATA: begin
                dac_data_out = decrypt_data_in;
                dac_data_valid = 1'b1;
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
        
        // Tell the key generator to advance when there's valid audio
        next_key_en = adc_data_valid;
    end

endmodule