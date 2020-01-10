module random10(
	input clk,
	input rst,
	input [31:0] seed,
	output [9:0] out
);

lfsr32 r0(
	.clk(clk),
	.rst(rst),
	.out(out[0]),
	.rst_vector(seed)
);

lfsr32 r1(
	.clk(clk),
	.rst(rst),
	.out(out[1]),
	.rst_vector(seed+9)
);

lfsr32 r2(
	.clk(clk),
	.rst(rst),
	.out(out[2]),
	.rst_vector(seed+3)
);

lfsr32 r3(
	.clk(clk),
	.rst(rst),
	.out(out[3]),
	.rst_vector(seed+7)
);

lfsr32 r4(
	.clk(clk),
	.rst(rst),
	.out(out[4]),
	.rst_vector(seed+92)
);

lfsr32 r5(
	.clk(clk),
	.rst(rst),
	.out(out[5]),
	.rst_vector(seed+123)
);

lfsr32 r6(
	.clk(clk),
	.rst(rst),
	.out(out[6]),
	.rst_vector(seed+321)
);

lfsr32 r7(
	.clk(clk),
	.rst(rst),
	.out(out[7]),
	.rst_vector(seed+432)
);

lfsr32 r8(
	.clk(clk),
	.rst(rst),
	.out(out[8]),
	.rst_vector(seed+112)
);

lfsr32 r9(
	.clk(clk),
	.rst(rst),
	.out(out[9]),
	.rst_vector(seed+100)
);
endmodule
