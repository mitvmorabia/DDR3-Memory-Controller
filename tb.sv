`timescale 1ns/10ps;

module tb();
  wire  ck, ck_neg, rst, rst_neg, cs, cke, ras, cas, we, ba, a, odt,mr0, mr1, mr2, mr3;
  reg clock, reset;
  
  controller C1(clock, reset, ck, ck_neg, rst, rst_neg, cs, cke, ras, cas, we, ba, a,odt,mr0, mr1, mr2, mr3);
  
  wire[18:0] mr0, mr1, mr2, mr3;  
  wire  [15:0] a;
  wire [2:0] ba;
  wire  ck, ck_neg, rst, rst_neg, cs, cke, ras, cas, we;
  wire  odt;
  
  reg clock;
  reg reset;
  
  initial begin
    reset <= 0;
    forever #1 clock = !clock;
  end
  
  initial begin
    $dumpvars(0,tb);
    $dumpfile("controller.vcd");
  end
endmodule 
       