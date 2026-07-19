`include "Two_FF_Sync.sv"
`include "write_ptr_handler.sv"
`include "read_ptr_handler.sv"
`include "fifo_memory.sv"

module Asynch_FIFO #(parameter depth = 8 , width = 64) (
    input logic w_clk , r_clk , w_rst , r_rst , w_en , r_en ,
    input logic [width - 1 : 0] data_in,
    output logic [width -1 : 0] data_out,
    output logic full , empty 
    );

parameter ptr_width_2 = $clog2(depth); 

logic [ptr_width_2 : 0] g_w_ptr_sync ;
logic [ptr_width_2 : 0] g_r_ptr_sync ;
logic [ptr_width_2 : 0] r_ptr , w_ptr ;
logic [ptr_width_2 : 0] g_r_ptr , g_w_ptr ;

// Write pointer synchronisation with read clock 
Two_FF_Sync #(ptr_width_2) synchroniser_w (.sync_ip(g_w_ptr) , .clk(r_clk) , .rst(r_rst) , .q2(g_w_ptr_sync));

// Read pointer synchronisation with write clock - FIXED: Pass g_r_ptr, not r_ptr
Two_FF_Sync #(ptr_width_2) synchroniser_r (.sync_ip(g_r_ptr) , .clk(w_clk) , .rst(w_rst) , .q2(g_r_ptr_sync));
   
write_ptr_handler #(ptr_width_2) write_ptr_handler_top ( .w_clk(w_clk) , .w_rst(w_rst) , .w_en(w_en) ,
                   .g_r_ptr(g_r_ptr_sync) , .w_ptr(w_ptr) , .g_w_ptr(g_w_ptr) , .full(full)) ;

read_ptr_handler #(ptr_width_2) read_ptr_handler_top (.r_rst(r_rst) , .r_en(r_en) , .r_clk(r_clk) , 
                   .g_w_ptr(g_w_ptr_sync) , .empty(empty) , .r_ptr(r_ptr) , .g_r_ptr(g_r_ptr)) ;

fifo_memory #(depth , ptr_width_2) fifo_mem_top(.w_en(w_en) , .r_en(r_en) , .w_clk(w_clk) , .r_clk(r_clk) , .full(full) ,
             .empty(empty) ,.w_ptr(w_ptr) , .r_ptr(r_ptr) , .data_in(data_in) , .data_out(data_out)) ;

endmodule