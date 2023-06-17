`timescale 1ns/1ps

module main (
  input clk,
  input btnTop, // password setting
  input btnBottom,  //password entering
  input btnCenter,  //it compares two passwords and prints whether it is pass or not
  input btnLeft, //each clock time, it completes 1digit(4bit) numbers.
  input [15:0] sw,
  output [3:0] ssSel,
  output [7:0] ssDisp
);
  parameter arg0_str = 16'b1100110010111010;   //pass
  parameter arg1_str = 16'b1111111011101101;   //Error
  parameter zero_str = 16'b1111111111111111;

  reg [3:0] set, com;
  reg [3:0] set_buf1, set_buf2, set_buf3, set_buf4;
  reg [3:0] com_buf1, com_buf2, com_buf3, com_buf4;
  reg [31:0] counter;
  reg [15:0] graphicbuffer;
  wire [3:0] res;
  wire c_out;
  reg [1:0]state;
  reg clockCounter;
  reg [3:0] keypadOutput;
  reg [3:0] pressCount;
  reg [23:0] passwordSet;   //to set
  reg [23:0] passwordSetBuf;
  reg [23:0] passwordComBuf;
  reg [23:0] passwordCom;   //to compare

  initial begin
    counter <= 0;
    graphicbuffer <= 16'b1111111111111111;
    state <= 0;
    clockCounter <= 0;
    set_buf1 <=0;
    set_buf2 <=0;
    set_buf3 <=0;
    set_buf4 <=0;
    com_buf1 <=0;
    com_buf2 <=0;
    com_buf3 <=0;
    com_buf4 <=0;
  end

  always @(posedge clk) begin
    counter = counter + 1;
    if (counter == 100000000) begin
      counter <= 0;
      clockCounter <= !clockCounter;
    end
    if (btnTop && state != 0) begin   //password setting
      state   <= 0;
      counter <= 0;
      clockCounter <= 0;
    end else if (btnBottom && state != 1) begin   //password enter
      state   <= 1;
      counter <= 0;
      clockCounter <= 0;
    end else if (btnCenter && state != 2) begin    //complete button
      state   <= 2;
      counter <= 0;
      clockCounter <= 0;
    end
  end
    
always @(posedge clk) begin
    case (state)
      0: 
      if (state == 0) begin
        set_buf4 <=set_buf3;
        set_buf3 <= set_buf2;
        set_buf2 <= set_buf1;
        set_buf1 <= sw[3:0];
      end
      1: 
      if (state == 1) begin
        com_buf4 <=com_buf3;
        com_buf3 <= com_buf2;
        com_buf2 <= com_buf1;
        com_buf1 <= sw[7:4];
      end
    endcase
  end
  segmentDisplay display (
      .displayGraphic(graphicbuffer),
      .clk(clk),
      .segSel(ssSel),
      .seg(ssDisp)
  );

   always @(posedge clk) begin
      if (btnLeft) begin
        if (state == 0) begin
          set <= set_buf1;
          passwordSetBuf <= passwordSet;
          passwordSet <= {set, passwordSetBuf[19:0]}; // shift the current passwordSet and append new 4 bits
        end else if (state == 1) begin
          com <= com_buf1;
          passwordComBuf <= passwordCom;
          passwordCom <= {com, passwordComBuf[19:0]}; // shift the current passwordCom and append new 4 bits
      end
    end
   end


  always @(posedge clk) begin
    case (state)
      0:    //password setting
      if (clockCounter) begin
        graphicbuffer[3:0]   <= set_buf1;
        graphicbuffer[7:4]   <= set_buf2;
        graphicbuffer[11:8]  <= set_buf3;
        graphicbuffer[15:12] <= set_buf4;
      end else begin
       graphicbuffer <= zero_str;
      end
      1:    //password enter(compare)
      if (clockCounter) begin
        graphicbuffer[3:0]   <= com_buf1;
        graphicbuffer[7:4]   <= com_buf2;
        graphicbuffer[11:8]  <= com_buf3;
        graphicbuffer[15:12] <= com_buf4;
      end else begin
      graphicbuffer <= zero_str;
     end
      2:    //password complete button(both case)
      if (clockCounter) begin
        if (passwordSet[23:0] == passwordCom[23:0]) begin   //PASS
            graphicbuffer <= arg0_str;
        end
      end else if (passwordSet[23:0] != passwordCom[23:0]) begin      //Error
        graphicbuffer <= arg1_str;   
      end
    endcase
  end
endmodule

module segmentDisplay (
    input [15:0] displayGraphic,
    input clk,
    output reg [3:0] segSel,
    output reg [7:0] displaySegment
);
  integer counter;
  wire [7:0] res0, res1, res2, res3;

  initial begin
    counter <= 0;
    segSel <= 14;
    displaySegment <= 8'b11111111;
  end

  bcd_to_7seg pos0 (
      .bcd(displayGraphic[3:0]),
      .displaySegment(res0)
  );
  bcd_to_7seg pos1 (
      .bcd(displayGraphic[7:4]),
      .displaySegment(res1)
  );
  bcd_to_7seg pos2 (
      .bcd(displayGraphic[11:8]),
      .displaySegment(res2)
  );
  bcd_to_7seg pos3 (
      .bcd(displayGraphic[15:12]),
      .displaySegment(res3)
  );

  always @(posedge clk) begin
    counter <= counter + 1;
    if (counter == 100000) begin
      counter <= 0;
      case (segSel)
        14: begin
          segSel <= 13;
          displaySegment <= res1;
        end
        13: begin
          segSel <= 11;
          displaySegment <= res2;
        end
        11: begin
          segSel <= 7;
          displaySegment <= res3;
        end
        7: begin
          segSel <= 14;
          displaySegment <= res0;
        end
      endcase
    end
  end
endmodule

module bcd_to_7seg (
    input [3:0] bcd,
    output reg [7:0] displaySegment
);

  always @(*) begin
    // dot, center, tl, bl, b, br, tr, t
    case (bcd)
      4'b0000: displaySegment = 8'b11000000;  // 0
      4'b0001: displaySegment = 8'b11111001;  // 1
      4'b0010: displaySegment = 8'b10100100;  // 2
      4'b0011: displaySegment = 8'b10110000;  // 3
      4'b0100: displaySegment = 8'b10011001;  // 4
      4'b0101: displaySegment = 8'b10010010;  // 5
      4'b0110: displaySegment = 8'b10000010;  // 6
      4'b0111: displaySegment = 8'b11111000;  // 7
      4'b1000: displaySegment = 8'b10000000;  // 8
      4'b1001: displaySegment = 8'b10010000;  // 9
      4'b1010: displaySegment = 8'b10001100;  // P
      4'b1011: displaySegment = 8'b10001000;  // A
      4'b1100: displaySegment = 8'b10010010;  // S
      4'b1101: displaySegment = 8'b10000110;  // E
      4'b1110: displaySegment = 8'b10101111;  // r
      4'b1111: displaySegment = 8'b11111111;  // off
      default: displaySegment = 8'b11111111;
    endcase
  end
endmodule