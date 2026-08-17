// fifo_assertions.sv
// Bound into Asynch_FIFO scope - checks internal signals directly by name.
// Does NOT modify Asynch_FIFO.sv, write_ptr_handler.sv, or read_ptr_handler.sv.

module fifo_assertions #(parameter ptr_width_2 = 3) (
    input logic w_clk, r_clk, w_rst, r_rst, w_en, r_en,
    input logic full, empty,
    input logic [ptr_width_2 : 0] w_ptr, r_ptr,
    input logic [ptr_width_2 : 0] g_w_ptr, g_r_ptr,
    input logic [ptr_width_2 : 0] g_w_ptr_sync, g_r_ptr_sync
);

    // ---------------------------------------------------------
    // 1. Never write when full
    // ---------------------------------------------------------
    property no_write_when_full;
        @(posedge w_clk) disable iff (w_rst)
        full |-> !w_en;
    endproperty
    assert property (no_write_when_full)
        else $error("[SVA] FIFO OVERFLOW: w_en asserted while full, time=%0t", $time);

    // ---------------------------------------------------------
    // 2. Never read when empty
    // ---------------------------------------------------------
    property no_read_when_empty;
        @(posedge r_clk) disable iff (r_rst)
        empty |-> !r_en;
    endproperty
    assert property (no_read_when_empty)
        else $error("[SVA] FIFO UNDERFLOW: r_en asserted while empty, time=%0t", $time);

    // ---------------------------------------------------------
    // 3. Gray-code write pointer: at most 1 bit changes per update
    //    (fires only on cycles where g_w_ptr actually changed)
    // ---------------------------------------------------------
    function automatic int count_bit_diff(logic [ptr_width_2:0] a, logic [ptr_width_2:0] b);
        return $countones(a ^ b);
    endfunction

    property gray_single_bit_change_wr;
        @(posedge w_clk) disable iff (w_rst)
        (g_w_ptr != $past(g_w_ptr)) |-> (count_bit_diff(g_w_ptr, $past(g_w_ptr)) == 1);
    endproperty
    assert property (gray_single_bit_change_wr)
        else $error("[SVA] g_w_ptr changed more than 1 bit: prev=%0h new=%0h time=%0t",
                     $past(g_w_ptr, 1, , @(posedge w_clk)), g_w_ptr, $time);

    // ---------------------------------------------------------
    // 4. Gray-code read pointer: same check, read domain
    // ---------------------------------------------------------
    property gray_single_bit_change_rd;
        @(posedge r_clk) disable iff (r_rst)
        (g_r_ptr != $past(g_r_ptr)) |-> (count_bit_diff(g_r_ptr, $past(g_r_ptr)) == 1);
    endproperty
    assert property (gray_single_bit_change_rd)
        else $error("[SVA] g_r_ptr changed more than 1 bit: prev=%0h new=%0h time=%0t",
                     $past(g_r_ptr, 1, , @(posedge r_clk)), g_r_ptr, $time);

    // ---------------------------------------------------------
    // 5. Reset check - write domain: pointer must be 0 immediately after
    //    reset deasserts (async reset, so check on first w_clk edge post-reset)
    // ---------------------------------------------------------
    property reset_state_wr;
        @(posedge w_clk)
        $fell(w_rst) |-> (w_ptr == 0 && g_w_ptr == 0);
    endproperty
    assert property (reset_state_wr)
        else $error("[SVA] w_ptr/g_w_ptr not reset correctly, time=%0t", $time);

    // ---------------------------------------------------------
    // 6. Reset check - read domain
    // ---------------------------------------------------------
    property reset_state_rd;
        @(posedge r_clk)
        $fell(r_rst) |-> (r_ptr == 0 && g_r_ptr == 0);
    endproperty
    assert property (reset_state_rd)
        else $error("[SVA] r_ptr/g_r_ptr not reset correctly, time=%0t", $time);

    // ---------------------------------------------------------
    // 7. Synchronizer sanity: synced write pointer (in read domain)
    //    must always equal SOME value g_w_ptr previously held -
    //    i.e. it can't show a value that never existed on the source side.
    //    (Loose CDC sanity check, not a full metastability model.)
    // ---------------------------------------------------------
    // Left as commented reference - requires a small history queue to implement
    // properly; mention this verbally in interviews as an advanced check you're
    // aware of but scoped out given time constraints.

endmodule

// ---------------------------------------------------------
// Bind statement - put this in a separate file (e.g. fifo_bind.sv)
// or at the bottom of this file. .* auto-connects by matching names
// in Asynch_FIFO's scope (w_clk, w_rst, g_w_ptr, etc. all match directly).
// ---------------------------------------------------------
bind Asynch_FIFO fifo_assertions #(.ptr_width_2($clog2(depth))) u_fifo_assertions (.*);