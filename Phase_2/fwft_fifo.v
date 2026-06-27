`timescale 1ns / 1ps

module fwft_fifo #(
    parameter DEPTH = 256,
    parameter W = 16
) (
    input wire clk,
    input wire rst,
    
    input  wire wr_en,
    input  wire [W-1:0] din,
    
    input  wire rd_en,
    output wire [W-1:0] dout,
    
    output wire empty,
    output wire full
);

    reg [W-1:0] mem [0:DEPTH-1];
    reg [7:0] wr_ptr;
    reg [7:0] rd_ptr;
    reg [8:0] count;

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: begin // Write only
                    mem[wr_ptr] <= din;
                    wr_ptr <= wr_ptr + 1;
                    count  <= count + 1;
                end
                2'b01: begin // Read only
                    rd_ptr <= rd_ptr + 1;
                    count  <= count - 1;
                end
                2'b11: begin // Read and Write simultaneously
                    mem[wr_ptr] <= din;
                    wr_ptr <= wr_ptr + 1;
                    rd_ptr <= rd_ptr + 1;
                    // Count remains the same
                end
            endcase
        end
    end

    // FWFT Magic: Data is always instantly available on the output.
    // rd_en simply acknowledges it and moves the pointer to the next item.
    assign dout = mem[rd_ptr];
    assign empty = (count == 0);
    assign full = (count == DEPTH);

endmodule