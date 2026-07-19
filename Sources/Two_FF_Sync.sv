module Two_FF_Sync #(parameter width = 3)
    (
    input logic [width : 0] sync_ip, 
    input logic clk, rst, // FIXED: Changed from [width:0] to single bit
    output logic [width : 0] q2
    );

logic [width : 0] q1;

always_ff @(posedge rst or posedge clk) begin 
    if(rst) begin
        q1 <= 0;
        q2 <= 0;
    end
    else begin
        q1 <= sync_ip;
        q2 <= q1;
    end
end
 
endmodule
