module chaotic_generator #(
    parameter DATA_WIDTH = 32, 
    parameter FRAC_BITS  = 28 
) (
    input  wire clk,
    input  wire rst,
    input  wire next_key_en,       
    input  wire sync_en,           
    input  wire [DATA_WIDTH-1:0] sync_state_in, 
    output wire [DATA_WIDTH-1:0] key_out     
);
    localparam [DATA_WIDTH-1:0] ONE     = 32'h10000000;
    localparam [DATA_WIDTH-1:0] P_PARAM = 32'h07333333; 
    localparam [DATA_WIDTH-1:0] MULT_1  = 32'h238E38E3;
    localparam [DATA_WIDTH-1:0] MULT_2  = 32'h1D1745D1;
    localparam SLICE_TOP = DATA_WIDTH + FRAC_BITS - 1;
    localparam SLICE_BOT = FRAC_BITS;

    reg [DATA_WIDTH-1:0] x_reg, x_next_raw, x_next_perturbed;
    
    reg [DATA_WIDTH-1:0] branch1_res;
    reg [DATA_WIDTH-1:0] branch2_sub;
    reg [DATA_WIDTH-1:0] branch2_res;
    
    reg [2*DATA_WIDTH-1:0] mult_res_1;
    reg [2*DATA_WIDTH-1:0] mult_res_2;
    
    reg [15:0] lfsr_reg;
    reg        lfsr_feedback;

    assign key_out = x_reg;

    always @(*) begin
        mult_res_1  = x_reg * MULT_1;
        branch1_res = mult_res_1[SLICE_TOP : SLICE_BOT];

        branch2_sub = ONE - x_reg;
        mult_res_2  = branch2_sub * MULT_2;
        branch2_res = mult_res_2[SLICE_TOP : SLICE_BOT];

        if (x_reg < P_PARAM) begin
            x_next_raw = branch1_res;
        end else begin
            x_next_raw = branch2_res;
        end

        x_next_perturbed = x_next_raw ^ {16'b0, lfsr_reg};
        
        if (x_next_perturbed >= ONE) 
            x_next_perturbed = x_next_perturbed & (ONE - 1);
    end

    always @(posedge clk) begin
        if (rst) begin
            x_reg <= 32'h01F97414;
            lfsr_reg <= 16'hACE1;
        end else if (sync_en) begin
            x_reg <= sync_state_in;
            lfsr_reg <= 16'hACE1;
        end else if (next_key_en) begin
            x_reg <= x_next_perturbed;
            lfsr_feedback = lfsr_reg[0] ^ lfsr_reg[2] ^ lfsr_reg[3] ^ lfsr_reg[5];
            lfsr_reg <= {lfsr_feedback, lfsr_reg[15:1]};
        end
    end
endmodule