module write_ptr_handler #(parameter ptr_width = 3)
    (
    input logic w_clk , w_rst, w_en,
    input logic [ptr_width : 0] g_r_ptr,
    output logic full , 
    output logic [ptr_width : 0] w_ptr , 
    output logic [ptr_width : 0] g_w_ptr
    );

logic [ptr_width : 0] w_ptr_next ;
logic [ptr_width : 0] g_w_ptr_next ;

assign w_ptr_next = w_ptr + (w_en & ~full) ;
assign g_w_ptr_next = (w_ptr_next >> 1) ^ w_ptr_next ;

always_ff @(posedge w_clk or posedge w_rst) begin
    if(w_rst) begin
        w_ptr <= 0;
        g_w_ptr <= 0;
    end
    else begin
        w_ptr <= w_ptr_next ;
        g_w_ptr <= g_w_ptr_next;
    end
end

// FIXED: full logic needs to evaluate every cycle and reset to 0
always_ff @(posedge w_clk or posedge w_rst) begin   
    if(w_rst) 
        full <= 0;
    else 
        full <= (g_w_ptr_next == {~g_r_ptr[ptr_width : ptr_width - 1], g_r_ptr[ptr_width-2 : 0]});
end
endmodule
