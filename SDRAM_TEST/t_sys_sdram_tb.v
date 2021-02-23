//
// SDRAM Test Bench TOP for Anlogic EG4S20
// 2020/08/02
// @shibatchii
//
`timescale 1 ns / 100 ps
module t_sys_sdram_tb();

reg clk_in;
reg zusr_key;

sys_sdram_tb sys_sdram_tb(
    .clk_in  (clk_in),
    .zusr_key(zusr_key)
);

// clock
initial begin
  clk_in = 0;
  forever begin
    #2.5;
    clk_in = ~clk_in;
  end
end

initial begin
  zusr_key = 0; // reset on
  #10;
  zusr_key = 1; // reset off
  #100000;
  $stop;
end

// wave dump
initial begin
  $dumpvars;
end

endmodule

