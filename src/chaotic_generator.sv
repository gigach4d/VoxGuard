// chaotic_generator.sv
// Implements the logistic map using Q-format fixed-point arithmetic.
module chaotic_generator #(
    parameter DATA_WIDTH = 32, // Total bits for fixed-point numbers
    parameter FRAC_BITS  = 30  // Fractional bits for 'x' (Q2.30 format)
) (
    input logic clk,
    input logic rst,
    input logic next_key_en,      // Enable to generate the next key
    input logic sync_en,          // Enable to load a sync state
    input logic [DATA_WIDTH-1:0] sync_state_in, // State for re-sync
    output logic [DATA_WIDTH-1:0] key_out       // The generated chaotic key
);

    // Fixed-point representation for r = 4.0 (in Q4.28 format)
    localparam [DATA_WIDTH-1:0] R_PARAM = 32'h40000000; 
    // Fixed-point representation for 1.0 (in Q2.30 format)
    localparam [DATA_WIDTH-1:0] ONE = 32'h40000000;

    // Internal state register for x(n)
    logic [DATA_WIDTH-1:0] x_reg;

    assign key_out = x_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            // Initial secret seed x(0) = 0.1234 (in Q2.30 format)
            x_reg <= 32'h0F9ADD3F; 
        end else if (sync_en) begin
            // Force state from external sync word
            x_reg <= sync_state_in;
        end else if (next_key_en) begin
            // Calculate x_next = r * x * (1 - x) using fixed-point math
            logic [DATA_WIDTH-1:0] one_minus_x = ONE - x_reg;
            logic [2*DATA_WIDTH-1:0] product1 = R_PARAM * x_reg;
            logic [DATA_WIDTH-1:0] r_times_x = product1[DATA_WIDTH + FRAC_BITS - 1 : FRAC_BITS];
            logic [2*DATA_WIDTH-1:0] product2 = r_times_x * one_minus_x;
            x_reg <= product2[2*DATA_WIDTH-1 : DATA_WIDTH];
        end
    end

endmodule