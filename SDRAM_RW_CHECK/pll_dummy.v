module pll(refclk,
    reset,
    extlock,
    clk0_out);

  input refclk;
  input reset;
  output extlock;
  output clk0_out;

  assign  clk0_out = refclk;
  assign  extlock = ~reset;

endmodule
