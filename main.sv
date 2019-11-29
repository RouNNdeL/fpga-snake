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
	output [9:0] VGA_B
);

wire VGA_CTRL_CLK;
wire DLY_RST;
wire [9:0] mVGA_R;
wire [9:0] mVGA_G;
wire [9:0] mVGA_B;
wire [9:0] Coord_X;
wire [9:0] Coord_Y;
wire		reset;

VGA_PLL	p0 (
	.inclk0 ( CLOCK_27 ),
	.c0 ( VGA_CTRL_CLK ),
	.c2 ( VGA_CLK )
);

assign reset = SW[0];

reset_delay			r0	(	.iCLK(CLOCK_50), .oRESET(DLY_RST)	);

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
							.iCLK(VGA_CTRL_CLK),
							.iRST_N(DLY_RST ^ reset)	);
							
assign SRAM_ADDR = {Coord_X[9:1],Coord_Y[9:1]} ;

wire f;
wire [7:0] DEBUG;
frame_gen f0 (.clk(CLOCK_50), .frame(f));

wire step_frame = (f & SW[1]) ^ ~KEY[0];

drawer d0 (
	.clk(VGA_CTRL_CLK), 
	.frame(step_frame), 
	.x(Coord_X[9:1]), 
	.y(Coord_Y[9:1]), 
	.rst(reset), 
	.dq(SRAM_DQ),
	.w_en(SRAM_WE_N),
	.dbg(DEBUG)
);

assign LEDG = DEBUG;

assign SRAM_UB_N = 0;
assign SRAM_LB_N = 0;
assign SRAM_CE_N = 0;
assign SRAM_OE_N = 0;	

assign  mVGA_R = {SRAM_DQ[15:12], SRAM_DQ[11] ? 6'b111111 : 6'b0};
assign  mVGA_G = {SRAM_DQ[10:7], SRAM_DQ[6] ? 6'b111111 : 6'b0};
assign  mVGA_B = {SRAM_DQ[5:2], SRAM_DQ[1] ? 6'b111111 : 6'b0};
	
endmodule
