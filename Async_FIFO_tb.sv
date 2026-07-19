module Async_FIFO_tb;

  parameter DATA_WIDTH = 8;
  parameter FIFO_DEPTH = 16;

  logic [DATA_WIDTH-1:0] data_out;
  logic full;
  logic empty;
  logic [DATA_WIDTH-1:0] data_in;
  logic w_en, w_clk, w_rst;
  logic r_en, r_clk, r_rst;

  // Reference Queue (Golden Model)
  logic [DATA_WIDTH-1:0] wdata_q[$];
  logic [DATA_WIDTH-1:0] expected_data;

  //------------------------------------------
  // DUT
  //------------------------------------------
  Asynch_FIFO #(.depth(FIFO_DEPTH), .width(DATA_WIDTH)) as_fifo (
      .w_clk(w_clk),
      .w_rst(w_rst),
      .r_clk(r_clk),
      .r_rst(r_rst),
      .w_en(w_en),
      .r_en(r_en),
      .data_in(data_in),
      .data_out(data_out),
      .full(full),
      .empty(empty)
  );

  //------------------------------------------
  // Clock Generation
  //------------------------------------------
  // 50 MHz write clock
  always #10ns w_clk = ~w_clk;

  // ~28.5 MHz read clock (different domain)
  always #17.5ns r_clk = ~r_clk;

  //------------------------------------------
  // WRITE DOMAIN PROCESS
  //------------------------------------------
  initial begin : write_process
    w_clk = 0;
    w_en  = 0;
    data_in = 0;
    w_rst = 1;

    // Hold reset
    repeat(5) @(posedge w_clk);
    w_rst = 0;

    @(posedge w_clk);

    // Random Writes
    for (int i = 0; i < 30; i++) begin
      @(posedge w_clk);

      if (!full && ($urandom_range(0,2) > 0)) begin
        w_en    <= 1'b1;
        data_in <= $urandom;
        wdata_q.push_back(data_in);

        $display("Time=%0t [WRITE] Data=%h  QueueSize=%0d",
                 $time, data_in, wdata_q.size());
      end
      else begin
        w_en <= 1'b0;
      end
    end

    w_en <= 0;

    // Wait until everything is read
    wait (wdata_q.size() == 0);

    #200ns;
    $finish;
  end

  //------------------------------------------
  // READ DOMAIN PROCESS  (CDC-SAFE)
  //------------------------------------------
  initial begin : read_process
    r_clk = 0;
    r_en  = 0;
    r_rst = 1;

    // Hold reset
    repeat(5) @(posedge r_clk);
    r_rst = 0;

    @(posedge r_clk);

    //--------------------------------------
    // Wait until FIFO becomes NON-EMPTY
    // Sampled synchronously to r_clk
    //--------------------------------------
    do begin
      @(posedge r_clk);
    end while (empty !== 1'b0);

    //--------------------------------------
    // Allow pointer synchronization latency
    //--------------------------------------
    repeat (2) @(posedge r_clk);

    //--------------------------------------
    // Start Reading
    //--------------------------------------
    forever begin
      @(posedge r_clk);

      if (!empty && (wdata_q.size() > 0) && ($urandom_range(0,2) > 0)) begin
        r_en <= 1'b1;

        // Expected data from model
        expected_data = wdata_q.pop_front();

        // FIFO output valid next cycle
        @(posedge r_clk);
        r_en <= 1'b0;

        if (data_out !== expected_data) begin
          $error("Time=%0t [FAIL] Expected=%h Got=%h",
                  $time, expected_data, data_out);
        end
        else begin
          $display("Time=%0t [PASS] Data=%h  Remaining=%0d",
                   $time, expected_data, wdata_q.size());
        end
      end
      else begin
        r_en <= 1'b0;
      end
    end
  end

  //------------------------------------------
  // Waveform Dump
  //------------------------------------------
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, Async_FIFO_tb);
  end

endmodule
