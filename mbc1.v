// MBC1 VERILOG BY ZEPHRAY 2016

module mbc1
(
		//DPDT Switch
		SW,							//	Toggle Switch[17:0]
      //Flash Interface
		FL_DQ,						//	FLASH Data bus 8 Bits
		FL_ADDR,						//	FLASH Address bus 22 Bits
		FL_WE_N,						//	FLASH Write Enable
		FL_RST_N,					//	FLASH Reset
		FL_OE_N,						//	FLASH Output Enable
		FL_CE_N,						//	FLASH Chip Enable
		//SRAM Interface
		SRAM_DQ,						//	SRAM Data bus 16 Bits
		SRAM_ADDR,						//	SRAM Address bus 18 Bits
		SRAM_UB_N,						//	SRAM High-byte Data Mask 
		SRAM_LB_N,						//	SRAM Low-byte Data Mask 
		SRAM_WE_N,						//	SRAM Write Enable
		SRAM_CE_N,						//	SRAM Chip Enable
		SRAM_OE_N,						//	SRAM Output Enable
		//LEDs are awesome
		LEDG,							//	LED Green[8:0]
		LEDR,							//	LED Red[17:0]
		//GameBoy Interface
		GB_DQ,						// GameBoy Data bus 8 Bits
		GB_ADDR,						// GameBoy Address bus 16 Bits
		GB_WR,						// GameBoy Write Enable
		GB_RD,						// GameBoy Read Enable
		GB_CLK,						// GameBoy Clock
		GB_CS,						// GameBoy Chip Select
		GB_RST,						// GameBoy Reset
);

input	 [17:0]	SW;

output [8:0]	LEDG;					//	LED Green[8:0]
output [17:0]	LEDR;					//	LED Red[17:0]

inout	 [7:0]	FL_DQ;				//	FLASH Data bus 8 Bits
output [21:0]	FL_ADDR;				//	FLASH Address bus 22 Bits
output			FL_WE_N;				//	FLASH Write Enable
output			FL_RST_N;			//	FLASH Reset
output			FL_OE_N;				//	FLASH Output Enable
output			FL_CE_N;				//	FLASH Chip Enable

inout	 [15:0]	SRAM_DQ;				//	SRAM Data bus 16 Bits
output [17:0]	SRAM_ADDR;				//	SRAM Address bus 18 Bits
output			SRAM_UB_N;				//	SRAM High-byte Data Mask
output			SRAM_LB_N;				//	SRAM Low-byte Data Mask 
output			SRAM_WE_N;				//	SRAM Write Enable
output			SRAM_CE_N;				//	SRAM Chip Enable
output			SRAM_OE_N;				//	SRAM Output Enable

inout [7:0]	GB_DQ;				// GameBoy Data bus 8 Bits
input  [15:0]	GB_ADDR;				// GameBoy Address bus 16 Bits
input				GB_WR;				// GameBoy Write Enable
input				GB_RD;				// GameBoy Read Enable
input				GB_CLK;				// GameBoy Clock
input				GB_CS;				// GameBoy Chip Select
output			GB_RST;				// GameBoy Reset
//input				GB_RST;

reg [6:0] ROM_BANK = 1;
reg [1:0] RAM_BANK = 0;
reg       BANK_SEL = 0; // Bank Select Mode
reg [3:0] RAM_EN = 0; // RAM Access Enable

wire ROM_BANK_CLK;
wire RAM_BANK_CLK;
wire BANK_SEL_CLK;
wire RAM_EN_CLK;

assign LEDG[8] = BANK_SEL;
assign LEDR[6:0] = ROM_BANK[6:0];
assign LEDG[3:0] = RAM_EN;
assign LEDR[8:7] = RAM_BANK;

wire ROM_ADDR_EN;//RW Address in ROM range
wire RAM_ADDR_EN;//RW Address in RAM range

wire ROM_OE;  //ROM Output Enable
wire RAM_ON;  //RAM Output Enable

wire [6:0] ROM_BANK_MYSTERY; //For MBC1 Bug Emulation

assign ROM_BANK_MYSTERY[6:5] = ROM_BANK[6:5];
assign ROM_BANK_MYSTERY[4:0] = (ROM_BANK[4:0]==0) ? 1 : ROM_BANK[4:0]; 

assign ROM_ADDR_EN =  (GB_ADDR >= 16'h0000)&(GB_ADDR <= 16'h7FFF);
assign RAM_ADDR_EN =  (GB_ADDR >= 16'hA000)&(GB_ADDR <= 16'hBFFF);

assign ROM_BANK_CLK = (GB_ADDR[15:13]==3'b001)&(GB_WR==0) ? 0 : 1;
assign RAM_BANK_CLK = (GB_ADDR[15:13]==3'b010)&(GB_WR==0) ? 0 : 1;
assign BANK_SEL_CLK = (GB_ADDR[15:13]==3'b011)&(GB_WR==0) ? 0 : 1;
assign RAM_EN_CLK   = (GB_ADDR[15:13]==3'b000)&(GB_WR==0) ? 0 : 1;

assign ROM_OE = (((ROM_ADDR_EN)&(GB_RD==0))|(GB_RST==0)) ? 1 : 0;
assign RAM_OE = ((RAM_ADDR_EN)&(GB_RD==0)&(RAM_EN==4'hA)&(GB_RST==1)) ? 1 : 0;
assign DQ_OE = ROM_OE | RAM_OE;

assign GB_DQ = DQ_OE ? (ROM_OE ? FL_DQ : SRAM_DQ[7:0]) : 8'hzz;

assign FL_ADDR[21] = 0;
assign FL_ADDR[20:14] = ((GB_ADDR[14]==0)|(GB_RST==0)) ? 0 : ROM_BANK[6:0];
assign FL_ADDR[13:0] = GB_ADDR[13:0];

assign SRAM_ADDR[14:13] = RAM_BANK;
assign SRAM_ADDR[12:0] = GB_ADDR[12:0];
assign SRAM_DQ[7:0] = RAM_ADDR_EN ? ((GB_RD==0) ? 8'hzz : GB_DQ) : 8'hzz;

assign FL_RST_N = 1;
assign FL_OE_N = 0;
assign FL_WE_N = 1;
assign FL_CE_N = 0;
assign GB_RST = SW[0];

assign SRAM_CE_N = !RAM_OE;
assign SRAM_LB_N = 0;
assign SRAM_UB_N = 0;
assign SRAM_WE_N = RAM_ADDR_EN ? GB_WR : 1;
assign SRAM_OE_N = RAM_ADDR_EN ? GB_RD : 1;

always@(posedge ROM_BANK_CLK, negedge GB_RST)
begin
  if (GB_RST==0)
    ROM_BANK[4:0] <= 1;
  else 
    ROM_BANK[4:0] <= GB_DQ[4:0];
end

always@(posedge RAM_BANK_CLK, negedge GB_RST)
begin
  if (GB_RST==0)
  begin
    RAM_BANK <= 0;
	 ROM_BANK[6:5] <= 0;
  end
  else 
    if (BANK_SEL==0)
      ROM_BANK[6:5] <= GB_DQ[1:0];
	 else
	   RAM_BANK[1:0] <= GB_DQ[1:0];
end

always@(posedge BANK_SEL_CLK, negedge GB_RST)
begin
  if (GB_RST==0)
    BANK_SEL <= 0;
  else 
    BANK_SEL <= GB_DQ[0];
end

always@(posedge RAM_EN_CLK, negedge GB_RST)
begin
  if (GB_RST==0)
    RAM_EN <= 0;
  else 
    RAM_EN[3:0] <= GB_DQ[3:0];
end

endmodule
