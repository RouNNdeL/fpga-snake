module drawer (
	input clk,
	input rst,
	input rst_snake,
	input [3:0] mov,
	input [8:0] x,
	input [8:0] y,
	output wire [15:0] pixel_data,
	inout [15:0] sram_dq, 
	output [17:0] sram_addr,
	output sram_we_n,
	output [7:0] dbg
);

`include "config.h"

logic [15:0] data_next;
reg [15:0] data_reg;

assign pixel_data = data_reg;

assign new_draw_clk60 = y == 100;
assign new_grid_clk = y[2:0] == 1 && x[2:0] == 1;

reg [7:0] frame_counter;
wire new_frame_clk1 = frame_counter == 0;

wire [5:0] gridX = x[8:3];
wire [5:0] gridY = y[8:3];
reg [4:0] playerX;
reg [4:0] playerY;
reg dead;
reg dead_frame;
reg [1:0] mov_dir;

assign dbg = {new_frame_clk1, frame_counter};

reg [15:0] entities;

snake_controller sc0(
	.clk_25_2(clk),
	.clk_1(new_frame_clk1),
	.clk_grid(new_grid_clk),
	.rst(rst_snake),
	.x(gridX),
	.y(gridY),
	.mov_dir(mov_dir),
	.sram_dq(sram_dq), 
	.sram_addr(sram_addr),
	.write_enable(sram_we_n),
	.entity_data(entities)
);

//TODO: The (0, 0) pixel is black and blinks on frame refresh, findout why and fix

always @(posedge clk, posedge rst) begin
	if(rst)
		mov_dir <= 2'b00;
	else begin
		if(mov[0])
			mov_dir <= 2'b00;
		if(mov[1])
			mov_dir <= 2'b01;
		if(mov[2])
			mov_dir <= 2'b10;
		if(mov[3])
			mov_dir <= 2'b11;
		end
end

always @(posedge new_frame_clk1, posedge rst) begin
	if(rst) begin 
		playerX <= 15;
		playerY <= 15;
		dead <= 0;
		dead_frame <= 0;
	end else begin
		case(mov_dir) 
			2'b00: playerX <= playerX + 1; // Right
			2'b01: playerY <= playerY + 1; // Down
			2'b10: playerX <= playerX - 1; // Left
			2'b11: playerY <= playerY - 1; // Up
		endcase

		if(dead)
			dead_frame = !dead_frame;
	end
end

always @* begin
	data_next = BACKGROUND_COLOR;
	
	if(dead) begin
		if(dead_frame) begin
			if(gridX == 0)
				data_next = BORDER_COLOR_DEAD_1;
			if(gridY == 0 && gridX < 30)
				data_next = BORDER_COLOR_DEAD_1;
			if(gridX == 29)
				data_next = BORDER_COLOR_DEAD_1;
			if(gridY == 29 && gridX < 30)
				data_next = BORDER_COLOR_DEAD_1;
		end else begin
			if(gridX == 0)
				data_next = BORDER_COLOR_DEAD_2;
			if(gridY == 0 && gridX < 30)
				data_next = BORDER_COLOR_DEAD_2;
			if(gridX == 29)
				data_next = BORDER_COLOR_DEAD_2;
			if(gridY == 29 && gridX < 30)
				data_next = BORDER_COLOR_DEAD_2;
		end 
	end else begin
		data_next = entities;
	end
end 

always @(posedge new_draw_clk60) begin
	frame_counter <= frame_counter + 1;
		if(frame_counter >= 30)
			frame_counter <= 0;
end

always @(posedge clk, posedge rst) begin
	if(rst) begin
		data_reg <= 0;
	end else begin
		data_reg <= data_next;
	end
end 

endmodule 