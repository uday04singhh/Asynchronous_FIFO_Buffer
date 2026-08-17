// fifo_coverage.sv
// Functional coverage bound into Asynch_FIFO scope, same pattern as fifo_assertions.sv.
// Does NOT modify any existing design or testbench file.
// Uses explicit "previous cycle" registers instead of $past() inside covergroups,
// since $past() clocking inference inside coverpoint expressions is unreliable in XSIM.

module fifo_coverage (
    input logic w_clk, r_clk, w_rst, r_rst, w_en, r_en,
    input logic full, empty
);

    // -----------------------------------------------------------
    // Explicit "previous cycle" tracking (avoids $past() in covergroups)
    // -----------------------------------------------------------
    logic w_en_prev, r_en_prev;
    logic w_started, r_started;   // used to detect "reset mid-operation" vs reset-at-start

    always_ff @(posedge w_clk or posedge w_rst) begin
        if (w_rst) begin
            w_en_prev <= 1'b0;
            w_started <= 1'b0;
        end else begin
            w_en_prev <= w_en;
            if (w_en) w_started <= 1'b1;
        end
    end

    always_ff @(posedge r_clk or posedge r_rst) begin
        if (r_rst) begin
            r_en_prev <= 1'b0;
            r_started <= 1'b0;
        end else begin
            r_en_prev <= r_en;
            if (r_en) r_started <= 1'b1;
        end
    end

    // -----------------------------------------------------------
    // Write-domain coverage - sampled every posedge w_clk
    // -----------------------------------------------------------
    covergroup cg_write @(posedge w_clk);
        option.per_instance = 1;

        cp_full: coverpoint full {
            bins full_asserted   = {1};
            bins full_deasserted = {0};
        }

        cp_w_en: coverpoint w_en {
            bins en_high = {1};
            bins en_low  = {0};
        }

        // Did we ever actually attempt a write WHILE full?
        // (Your current TB avoids this on purpose - this bin will show 0 hits
        //  until you add a stimulus case that pushes against the full boundary)
        cross_w_en_full: cross cp_w_en, cp_full;

        cp_w_back_to_back: coverpoint {w_en, w_en_prev} {
            bins back_to_back_write = {2'b11};
            bins other              = {2'b00, 2'b01, 2'b10};
        }

        // Reset that occurs AFTER at least one write has already happened
        cp_w_rst_mid_op: coverpoint w_rst {
            bins reset_after_activity = {1} iff (w_started);
        }
    endgroup

    // -----------------------------------------------------------
    // Read-domain coverage - sampled every posedge r_clk
    // -----------------------------------------------------------
    covergroup cg_read @(posedge r_clk);
        option.per_instance = 1;

        cp_empty: coverpoint empty {
            bins empty_asserted   = {1};
            bins empty_deasserted = {0};
        }

        cp_r_en: coverpoint r_en {
            bins en_high = {1};
            bins en_low  = {0};
        }

        // Did we ever attempt a read WHILE empty?
        cross_r_en_empty: cross cp_r_en, cp_empty;

        cp_r_back_to_back: coverpoint {r_en, r_en_prev} {
            bins back_to_back_read = {2'b11};
            bins other             = {2'b00, 2'b01, 2'b10};
        }

        cp_r_rst_mid_op: coverpoint r_rst {
            bins reset_after_activity = {1} iff (r_started);
        }
    endgroup

    cg_write cg_write_inst = new();
    cg_read  cg_read_inst  = new();

endmodule

bind Asynch_FIFO fifo_coverage u_fifo_coverage (.*);