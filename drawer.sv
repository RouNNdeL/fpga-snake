module drawer (
	input clk,
	input rst,
	input [3:0] mov,
	input [8:0] x,
	input [8:0] y,
	output wire [15:0] pixel_data,
	output [7:0] dbg
);

logic [15:0] data_next;
reg [15:0] data_reg;

assign pixel_data = data_reg;

assign new_draw_clk60 = y == 0;

reg [6:0] frame_counter;
wire new_frame_clk1 = frame_counter == 0;

wire [5:0] gridX = x[8:3];
wire [5:0] gridY = y[8:3];
reg [4:0] playerX;
reg [4:0] playerY;
reg dead;
reg dead_frame;
reg [1:0] mov_dir;

assign dbg = {mov[3], 2'b0, mov_dir};

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
		
		if(playerX == 0 || playerX == 29)
			dead = 1;
		if(playerY == 0 || playerY == 29)
			dead = 1;

		if(dead)
			dead_frame = !dead_frame;
	end
end

always @* begin
	data_next = 0;
	
	if(dead) begin
		if(dead_frame) begin
			if(gridX == 0)
				data_next = 16'hffff;
			if(gridY == 0 && gridX < 30)
				data_next = 16'hffff;
			if(gridX == 29)
				data_next = 16'hffff;
			if(gridY == 29 && gridX < 30)
				data_next = 16'hffff;
		end else begin
			if(gridX == 0)
				data_next = 16'h7c00;
			if(gridY == 0 && gridX < 30)
				data_next = 16'h7c00;
			if(gridX == 29)
				data_next = 16'h7c00;
			if(gridY == 29 && gridX < 30)
				data_next = 16'h7c00;
		end 
	end else begin
		if(gridX == 0)
			data_next = 16'hffff;
		if(gridY == 0 && gridX < 30)
			data_next = 16'hffff;
		if(gridX == 29)
			data_next = 16'hffff;
		if(gridY == 29 && gridX < 30)
			data_next = 16'hffff;
			
		if(gridX == playerX && gridY == playerY)
			data_next = 16'hde2;
	end
end 

always @(posedge new_draw_clk60) begin
	frame_counter <= frame_counter + 1;
		if(frame_counter >= 120)
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