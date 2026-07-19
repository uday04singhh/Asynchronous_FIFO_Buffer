module read_ptr_handler #(parameter ptr_width = 3)
    (
    input logic r_rst , r_en , r_clk, 
    input logic [ptr_width : 0] g_w_ptr ,
    output logic empty , 
    output logic [ptr_width : 0] r_ptr , 
    output logic [ptr_width : 0] g_r_ptr
    );

logic [ptr_width : 0] r_ptr_next;
logic [ptr_width : 0] g_r_ptr_next;
   
assign r_ptr_next = r_ptr + (r_en && ~empty);
assign g_r_ptr_next = (r_ptr_next >> 1) ^ (r_ptr_next);

always_ff @(posedge r_clk or posedge r_rst) begin 
    if(r_rst) begin
        r_ptr <= 0;
        g_r_ptr <= 0;
    end
    else begin
        r_ptr <= r_ptr_next;
        g_r_ptr <= g_r_ptr_next;
    end
end

// FIXED: empty should be 1 on reset and update every cycle
always_ff @(posedge r_clk or posedge r_rst) begin    
    if(r_rst) 
        empty <= 1;
    else 
        empty <= (g_r_ptr_next == g_w_ptr);
end

endmodule
