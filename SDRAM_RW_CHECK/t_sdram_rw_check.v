//
// SDRAM Write/Read testbench for Anlogic EG4S20
// 2020/08/30
// @shibatchii
//
module t_sdram_rw_check;

  reg   refclk;
  reg   reset_n;
  reg   sw;
  wire  clk0_out;
  wire  extlock;
  wire  error;
  wire  stop_led;
  wire  write;
  wire  read;
  wire  init;

sdram_wr_check sdram_wr_check(
  .refclk   (     refclk  ),
  .reset_n  (    reset_n  ),
  .sw       (         sw  ),
  .clk0_out (   clk0_out  ),
  .extlock  (    extlock  ),
  .error    (      error  ),
  .stop_led (   stop_led  ),
  .write    (      write  ),
  .read     (       read  ),
  .init     (       init  )
);

  initial begin
    forever begin
      refclk = 1'b0;
      #50;
      refclk = 1'b1;
      #50;
    end
  end

  initial begin
    reset_n = 1'b0;
    sw = 1'b1;
    repeat(10) @(negedge refclk);
    reset_n = 1'b1;
    repeat(1500000) @(negedge refclk);
    sw = 1'b0;
    repeat(1) @(negedge refclk);
    sw = 1'b1;
    repeat(1500000) @(negedge refclk);
    $stop;
  end

endmodule
