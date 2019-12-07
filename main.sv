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

assign reset = SW[0];
assign resetVGA = SW[1];

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
wire [15:0] pixel_buffer;

drawer d0 (
	.clk(vga_clk_252), 
	.x(Coord_X[9:1]), 
	.y(Coord_Y[9:1]), 
	.mov(~KEY),
	.rst(reset), 
	.rst_snake(SW[2]),
	.pixel_data(pixel_buffer),
	.sram_dq(SRAM_DQ),
	.sram_addr(SRAM_ADDR),
	.sram_we_n(SRAM_WE_N),
	.dbg(debug)
);



assign LEDG = {~SRAM_WE_N, debug};
assign LEDR = SRAM_DQ;

assign SRAM_UB_N = 0;
assign SRAM_LB_N = 0;
assign SRAM_CE_N = 0;
assign SRAM_OE_N = 0;

assign  mVGA_R = {pixel_buffer[14:11], pixel_buffer[10] ? 6'b111111 : 6'b0};
assign  mVGA_G = {pixel_buffer[9:6], pixel_buffer[5] ? 6'b111111 : 6'b0};
assign  mVGA_B = {pixel_buffer[4:1], pixel_buffer[0] ? 6'b111111 : 6'b0};

endmodule
