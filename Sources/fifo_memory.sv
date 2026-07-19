`timescale 1ns / 1ps

module fifo_memory #(
    parameter depth = 8, 
    parameter ptr_width = 3,
    parameter width = 64  // Added parameter to match top module
)(
    input logic w_en, r_en, w_clk, r_clk, r_rst, // Added r_rst
    input logic full, empty,
    input logic [ptr_width : 0] w_ptr, r_ptr,   // Fixed syntax error
    input logic [width-1:0] data_in,            // Parameterized width
    output logic [width-1:0] data_out           // Parameterized width
);

logic [width-1:0] fifo_mem [depth-1 : 0];

// Write Logic
always_ff @(posedge w_clk) begin 
    if (w_en && ~full) begin 
        fifo_mem[w_ptr[ptr_width-1 : 0]] <= data_in;
    end
end

// Read Logic - FIXED: Added reset and handled 'read disabled' state
always_ff @(posedge r_clk or posedge r_rst) begin
    if (r_rst) begin
        data_out <= 0; // This removes the XX at the beginning
    end 
    else if (r_en && ~empty) begin 
        data_out <= fifo_mem[r_ptr[ptr_width-1 : 0]];
    end
    // Optional: if you want data_out to go to 0 when read is disabled (r_en=0):
    // else if (!r_en) begin
    //     data_out <= 0;
    // end
end
    
endmodule
