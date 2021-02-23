//
// SDRAM model 2Mwordx32bit for Anlogic EG4S20
// 2020/08/30
// @shibatchii
//
module EG_PHY_SDRAM_2M_32(
    clk,
    ras_n,
    cas_n,
    we_n,
    addr,
    ba,
    dq,
    cs_n,
    dm0,
    dm1,
    dm2,
    dm3,
    cke
);
    input         clk;
    input         ras_n;
    input         cas_n;
    input         we_n;
    input [10:0]  addr;
    input [1:0]   ba;
    inout [31:0]  dq;
    input         cs_n;
    input         dm0;
    input         dm1;
    input         dm2;
    input         dm3;
    input         cke;

    reg   [10:0]  r_ras;
    reg   [31:0]  mem [0:1048575]; 
    reg   [31:0]  r_dq;
    reg           r_re_dly1;
    reg           r_re_dly2;
    reg           r_re_dly3;

    event         e_wr;
    event         e_rd;
    event         e_ra;
    event         e_ca;

  always @(posedge clk)begin
    // ras
    if((cs_n==0)&&(ras_n==0)&&(cas_n==1)&&(we_n==1))begin
      r_ras[10:0] <= addr[10:0];
      -> e_ra;
    end
    // nop
    else
    begin
      r_ras[10:0] <= r_ras[10:0];
    end
  end

  always @(posedge clk)begin
    // read
    if((cs_n==0)&&(ras_n==1)&&(cas_n==0)&&(we_n==1))begin    
      r_re_dly1 <= 1'b1;
      r_re_dly2 <= 1'b0;
      r_re_dly3 <= 1'b0;
    end
    // read latency
    else
    begin
      r_re_dly1 <= 1'b0;
      r_re_dly2 <= r_re_dly1;
      r_re_dly3 <= r_re_dly2;
    end
  end

  always @(posedge clk)begin
    // write
    if((cs_n==0)&&(ras_n==1)&&(cas_n==0)&&(we_n==0))begin    
      mem[{r_ras[10:0],addr[7:0],ba[1:0]}] <= dq;
      -> e_wr;
    end
  end

  always @(posedge clk)begin
    // read
    if(r_re_dly2==1'b1)begin
      r_dq <= mem[{r_ras[10:0],addr[7:0],ba[1:0]}];
      -> e_rd;
    end
  end

  assign dq = (r_re_dly3 == 1) ? r_dq : 32'hz;

endmodule
