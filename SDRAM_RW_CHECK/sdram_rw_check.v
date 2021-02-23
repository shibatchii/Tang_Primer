//
// SDRAM Write/Read check for Anlogic EG4S20
// 2020/08/30
// @shibatchii
//
module sdram_wr_check(
  refclk,
  reset_n,
  sw,
  clk0_out,
  extlock,
  error,
  stop_led,
  write,
  read,
  init
);

  parameter P_PWAIT = 4'd0;
  parameter P_INIT  = 4'd1;
  parameter P_WRITE = 4'd2;
  parameter P_WWAIT = 4'd3;
  parameter P_INC   = 4'd4;
  parameter P_CCLR  = 4'd5;
  parameter P_READ  = 4'd6;
  parameter P_RWAIT = 4'd7;
  parameter P_LATCH = 4'd8;
  parameter P_STOP  = 4'd9;

  input   refclk;
  input   reset_n;
  input   sw;
  output  clk0_out;
  output  extlock;
  output  error;
  output  stop_led;
  output  write;
  output  read;
  output  init;

  reg   [15:0]  r_cnt;
  reg   [3:0]   r_st;
  reg           r_sw;
  reg           r_swd;
  reg           r_error;
  reg           r_stop;
  reg           r_write;
  reg           r_read;
  reg           r_init;

  reg   [3:0]   w_st;
  wire          w_clk0_out;
  wire          w_extlock;
  reg           w_dec_valid;
  reg           w_dec_cnt;
  reg           w_dec_stop;
  reg   [3:0]   w_wstrb;
  wire  [31:0]  w_addr;
  wire  [31:0]  w_wdata;
  wire          w_ready;
  wire  [31:0]  w_rdata;
  wire          w_cmp;
  reg           w_dec_cmp;
  reg           w_dec_write;
  reg           w_dec_read;
  reg           w_dec_init;

  pll pll(
    .refclk   ( refclk      ),
    .reset    ( ~reset_n    ),
    .clk0_out ( w_clk0_out  ),
    .extlock  ( w_extlock   )
  );

  always @(posedge w_clk0_out or negedge reset_n)begin
    if(reset_n == 1'b0)begin
      r_sw  <= 1'b1;
      r_swd <= 1'b1;
    end
    else
    begin
      r_sw  <= sw;
      r_swd <= r_sw;
    end
  end

  always @(posedge w_clk0_out or negedge reset_n)begin
    if(reset_n == 1'b0)
      r_st[3:0] <= P_PWAIT;
    else
      r_st[3:0] <= w_st[3:0];
  end

  always @(
    r_st or
    r_swd or
    w_extlock or
    w_ready or
    r_cnt
  )begin
    case(r_st)
      P_PWAIT:
        if(w_extlock == 1'b1)
          w_st[3:0] = P_INIT;
        else
          w_st[3:0] = r_st[3:0];
      P_INIT:
        if(w_ready == 1'b1)
          w_st[3:0] = P_WRITE;
        else
          w_st[3:0] = r_st[3:0];
      P_WRITE:
        if(w_ready == 1'b1)
          w_st[3:0] = P_WWAIT;
        else
          w_st[3:0] = r_st[3:0];
      P_WWAIT:
        if(w_ready == 1'b0)
          w_st[3:0] = P_INC;
        else
          w_st[3:0] = r_st[3:0];
      P_INC:
        if(r_cnt[15:0]==16'hffff)
          w_st[3:0] = P_CCLR;
        else
          w_st[3:0] = P_WRITE;
      P_CCLR:
          w_st[3:0] = P_READ;
      P_READ:
        if(w_ready==1'b1)
          w_st[3:0] = P_RWAIT;
        else
          w_st[3:0] = r_st[3:0];
      P_RWAIT:
        if(w_ready==1'b0)
          w_st[3:0] = P_LATCH;
        else
          w_st[3:0] = r_st[3:0];
      P_LATCH:
        if(r_cnt[15:0]==16'hffff)
          w_st[3:0] = P_STOP;
        else
          w_st[3:0] = P_READ;
      P_STOP:
        if(r_swd==1'b0)
          w_st[3:0] = P_WRITE;
        else
          w_st[3:0] = r_st[3:0];
      default:
          w_st[3:0] = P_PWAIT;
    endcase
  end

  always @(r_st)begin
    case(r_st)
      P_WRITE,P_READ:
        w_dec_valid = 1'b1;
      default:
        w_dec_valid = 1'b0;
    endcase
  end

  always @(r_st)begin
    case(r_st)
      P_WRITE,P_WWAIT,P_INC:
        w_wstrb[3:0] = 4'b1111;
      default:
        w_wstrb[3:0] = 4'b0000;
    endcase
  end

  always @(r_st)begin
    case(r_st)
      P_INC,P_LATCH:
        w_dec_cnt = 1'b1;
      default:
        w_dec_cnt = 1'b0;
    endcase
  end

  always @(posedge w_clk0_out or negedge reset_n)begin
    if(reset_n == 1'b0)
      r_cnt[15:0] <= 16'd0;
    else
      case(r_st[3:0])
        P_PWAIT:
          r_cnt[15:0] <= 16'd0;
        P_INC,P_LATCH:
          r_cnt[15:0] <= r_cnt[15:0] + 16'd1;
        default:
          r_cnt[15:0] <= r_cnt[15:0];
      endcase
  end

  assign  w_addr[31:0]  = {12'd0,r_cnt[15:0],4'd0};
  assign  w_wdata[31:0] = {~(r_cnt[15:0]),r_cnt[15:0]};

  sys_sdram sys_sdram(
    .clk      ( w_clk0_out    ),
    .rst_n    ( reset_n       ),
    .i_valid  ( w_dec_valid   ),
    .o_ready  ( w_ready       ),
    .i_addr   ( w_addr[31:0]  ),
    .i_wdata  ( w_wdata[31:0] ),
    .i_wstrb  ( w_wstrb[3:0]  ),
    .o_rdata  ( w_rdata[31:0] )
  );

  always @(r_st)begin
    case(r_st)
      P_LATCH:
        w_dec_cmp = 1'b1;
      default:
        w_dec_cmp = 1'b0;
    endcase
  end

  always @(r_st)begin
    case(r_st)
      P_WRITE,P_WWAIT,P_INC:
        w_dec_write = 1'b1;
      default:
        w_dec_write = 1'b0;
    endcase
  end

  always @(r_st)begin
    case(r_st)
      P_READ,P_RWAIT,P_LATCH:
        w_dec_read = 1'b1;
      default:
        w_dec_read = 1'b0;
    endcase
  end

  always @(r_st)begin
    case(r_st)
      P_PWAIT,P_INIT:
        w_dec_init = 1'b1;
      default:
        w_dec_init = 1'b0;
    endcase
  end

  always @(r_st)begin
    case(r_st)
      P_STOP:
        w_dec_stop = 1'b1;
      default:
        w_dec_stop = 1'b0;
    endcase
  end

assign  w_cmp = (w_rdata[31:0]!={~(r_cnt[15:0]),r_cnt[15:0]});

  always @(posedge w_clk0_out or negedge reset_n)begin
    if(reset_n == 1'b0)
      r_error <= 1'b0;
    else
      case(r_st)
        P_PWAIT:
          r_error <= 1'b0;
        P_LATCH:
          r_error <= r_error | w_cmp;
        default:
          r_error <= r_error;
      endcase
  end

  always @(posedge w_clk0_out or negedge reset_n)begin
    if(reset_n == 1'b0)begin
      r_write <= 1'b0;
      r_read  <= 1'b0;
      r_init  <= 1'b0;
      r_stop  <= 1'b0;
    end
    else
    begin
      r_write <= w_dec_write;
      r_read  <= w_dec_read;
      r_init  <= w_dec_init;
      r_stop  <= w_dec_stop;
    end
  end

  assign  clk0_out  = w_clk0_out;
  assign  extlock   = w_extlock;
  assign  error     = r_error;
  assign  stop_led  = r_stop;
  assign  write     = r_write;
  assign  read      = r_read;
  assign  init      = r_init;

endmodule
