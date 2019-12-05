module main(
	input CLOCK_50,
	input CLOCK_27,
	
	input [17:0] SW,
	input [3:0] KEY,
	output [8:0] LEDG,
	output [17:0] LEDR,
	
	inout [15:0] SRAM_DQ,
	output [17:0] SRAM_ADDR,
	output SRAM_UB_N,
	output SRAM_LB_N,
	output SRAM_WE_N,
	output SRAM_CE_N,
	output SRAM_OE_N,
	
	output VGA_CLK,
	output VGA_HS,
	output VGA_VS,
	output VGA_BLANK,
	output VGA_SYNC,
	output [9:0] VGA_R,
	output [9:0] VGA_G,
	output [9:0] VGA_B,
	
	inout [15:0] DRAM_DQ,
	output [11:0] DRAM_ADDR,
	output DRAM_BA_0,
	output DRAM_BA_1,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	output DRAM_LDQM,
	output DRAM_UDQM,
	output DRAM_RAS_N,
	output DRAM_WE_N
);

assign reset = SW[0];
assign resetVGA = SW[1];

wire clk_sdram_166;
sdram_pll sdram_pll_inst (
	.inclk0 (CLOCK_50),
	.c0 (clk_sdram_166)
);

assign DRAM_CLK = clk_sdram_166;

wire [11:0] sdram_w_addr;
wire sdram_w_enable;
wire [15:0] sdram_w_data;

wire [11:0] sdram_r_addr;
wire [15:0] sdram_r_data;
wire sdram_r_ready;
wire sdram_r_enable;

wire sdram_busy;

sdram_controller sdram0(
	/* HOST SIDE - INTERFACE */
	.wr_addr(sdram_r_addr),
	.wr_data(sdram_w_data),
	.wr_enable(sdram_w_enable),
	
	.rd_addr(sdram_r_addr),
	.rd_data(sdram_r_data),
	.rd_ready(sdram_r_ready),
	.rd_enable(sdram_r_enable),
	
	.busy(sdram_busy),
	.rst_n(~reset),
	.clk(clk_sdram_166),
	
	/* SDRAM SIDE - PINOUT */
	.addr(DRAM_ADDR),
	.bank_addr({DRAM_BA_0, DRAM_BA_1}),
	.data(DRAM_DQ),
	.clock_enable(DRAM_CKE),
	.cs_n(DRAM_CS_N),
	.ras_n(DRAM_RAS_N),
	.cas_n(DRAM_CAS_N),
	.we_n(DRAM_WE_N),
	.data_mask_low(DRAM_LDQM),
	.data_mask_high(DRAM_UDQM)
);

wire vga_clk_252_90deg;
wire vga_clk_252;

wire [9:0] mVGA_R;
wire [9:0] mVGA_G;
wire [9:0] mVGA_B;
wire [9:0] Coord_X;
wire [9:0] Coord_Y;

VGA_PLL	p0 (
	.inclk0 ( CLOCK_27 ),
	.c0 ( vga_clk_252_90deg ),
	.c2 ( vga_clk_252 )
);

assign VGA_CLK = vga_clk_252;

assign LEDR = {sdram_r_data};
assign sdram_r_addr = SW[5:3];
assign sdram_w_data = SW[17:6];
assign sdram_r_enable = SW[2];
assign sdram_w_enable = SW[1];

VGA_Controller		u1	(	//	Host Side
							.iCursor_RGB_EN(4'b0111),
							.oCoord_X(Coord_X),
							.oCoord_Y(Coord_Y),
							.iRed(mVGA_R),
							.iGreen(mVGA_G),
							.iBlue(mVGA_B),
							//	VGA Side
							.oVGA_R(VGA_R),
							.oVGA_G(VGA_G),
							.oVGA_B(VGA_B),
							.oVGA_H_SYNC(VGA_HS),
							.oVGA_V_SYNC(VGA_VS),
							.oVGA_SYNC(VGA_SYNC),
							.oVGA_BLANK(VGA_BLANK),
							//	Control Signal
							.iCLK(vga_clk_252_90deg),
							.iRST_N(~resetVGA)	);

wire [7:0] debug;

drawer d0 (
	.clk(vga_clk_252), 
	.x(Coord_X[9:1]), 
	.y(Coord_Y[9:1]), 
	.mov(~KEY),
	.rst(reset), 
	.dq(SRAM_DQ),
	.w_en(SRAM_WE_N),
	.dbg(debug)
);

assign LEDG = {sdram_r_ready, debug};

assign SRAM_UB_N = 0;
assign SRAM_LB_N = 0;
assign SRAM_CE_N = 0;
assign SRAM_OE_N = 0;

assign SRAM_ADDR = {Coord_X[9:1],Coord_Y[9:1]} ;

assign  mVGA_R = {SRAM_DQ[14:11], SRAM_DQ[10] ? 6'b111111 : 6'b0};
assign  mVGA_G = {SRAM_DQ[9:6], SRAM_DQ[5] ? 6'b111111 : 6'b0};
assign  mVGA_B = {SRAM_DQ[4:1], SRAM_DQ[0] ? 6'b111111 : 6'b0};
	
endmodule
