module drawer (
	input clk,
	input rst,
	input rst_snake,
	input [1:0] game_settings,
	input [3:0] mov,
	input [8:0] x,
	input [8:0] y,
	input clk_vsync,
	input game_start,
	output wire [15:0] pixel_data,
	inout [15:0] sram_dq, 
	output [17:0] sram_addr,
	output sram_we_n,
	output [7:0] dbg
);

`include "config.h"

wire [15:0] pixel_next;
reg [15:0] pixel_reg;

assign pixel_data = pixel_reg;

assign new_draw_clk60 = y == 0;
assign new_grid_clk = y[2:0] == 0 && x[2:0] == 2;

reg [7:0] frame_counter;
wire new_frame_clk1 = frame_counter == 0;

wire [5:0] grid_x = x[8:3];
wire [5:0] grid_y = y[8:3];

wire [1:0] game_state;
wire dead = game_state == GAME_STATE_DEAD;
reg dead_frame;


reg [1:0] mov_dir;
reg [1:0] last_mov_dir;

assign dbg[1:0] = {new_frame_clk1, new_draw_clk60};

//TODO: The (0, 0) pixel is black and blinks on frame refresh, findout why and fix

reg [5:0] grid_x_calc;
reg [5:0] grid_y_calc;
wire [5:0] grid_x_calc_next;
wire [5:0] grid_y_calc_next;

reg [1:0] state;
wire [1:0] state_next;
parameter STATE_LATCH_PIXEL_DATA = 2'b00;
parameter STATE_INCREMENT_CALC_CORDS = 2'b01;
parameter STATE_NOP = 2'b11;

wire [15:0] pixel_next_cord;
wire [1:0] entity;

wire [15:0] next_border_color;

always @* begin
	if(dead)
		next_border_color = dead_frame ? BORDER_COLOR_DEAD_1 : BORDER_COLOR_DEAD_2;
	else
		next_border_color = BORDER_COLOR_NORMAL;
	case(entity) 
		ENTITY_NONE: pixel_next_cord = BACKGROUND_COLOR;
		ENTITY_PLAYER: pixel_next_cord = PLAYER_COLOR;
		ENTITY_OBJECTIVE: pixel_next_cord = OBJECTIVE_COLOR;
		ENTITY_WALL: pixel_next_cord = next_border_color;
	endcase
end

always @* begin
	pixel_next = pixel_reg;
	grid_x_calc_next = grid_x_calc;
	grid_y_calc_next = grid_y_calc;
	state_next = state;
	
	case (state) 
		STATE_LATCH_PIXEL_DATA: begin
			pixel_next = pixel_next_cord;
			state_next = STATE_INCREMENT_CALC_CORDS;
		end
		STATE_INCREMENT_CALC_CORDS: begin
			grid_x_calc_next = grid_x + 1;
			grid_y_calc_next = grid_y;
			if(grid_x_calc >= 39) begin
				grid_x_calc_next = 0;
				grid_y_calc_next = (grid_y + 1) % 30;
			end
			state_next = STATE_NOP;
		end
	endcase
end

always @(posedge clk, posedge rst) begin
	if(rst) begin
		mov_dir <= 2'b00;
		pixel_reg <= 0;
	end else begin
		if(mov[0] & last_mov_dir != 2'b10)
			mov_dir <= 2'b00;
		if(mov[1] & last_mov_dir != 2'b11)
			mov_dir <= 2'b01;
		if(mov[2] & last_mov_dir != 2'b00)
			mov_dir <= 2'b10;
		if(mov[3] & last_mov_dir != 2'b01)
			mov_dir <= 2'b11;
		
		if(game_settings[0] || (x[2:0] != 0 && x[2:0] != 7 &&  y[2:0] != 7 &&  y[2:0] != 0)) begin
			pixel_reg <= pixel_next;
		end else begin
			pixel_reg <= 0;
		end
		
		grid_x_calc <= grid_x_calc_next;
		grid_y_calc <= grid_y_calc_next;
		state <= state_next;
		
		if(x % 8 == 0) 
			state <= STATE_LATCH_PIXEL_DATA;
	end
end

always @(posedge new_frame_clk1, posedge rst) begin
	if(rst) begin 
		dead_frame <= 0;
	end else begin
		last_mov_dir <= mov_dir;

		if(dead) dead_frame = !dead_frame;
	end
end

always @(posedge clk_vsync) begin
	frame_counter <= frame_counter + 1;
		if(frame_counter >= (game_settings[1] ? 20 : 60))
			frame_counter <= 0;
end

wire new_grid_clk_state = state == STATE_INCREMENT_CALC_CORDS;

snake_controller sc0(
	.clk_25_2(clk),
	.clk_1(~dead & new_frame_clk1),
	.clk_grid(new_grid_clk),
	.rst(rst_snake),
	.x(grid_x_calc-5),
	.y(grid_y_calc),
	.mov_dir(mov_dir),
	.sram_dq(sram_dq), 
	.sram_addr(sram_addr),
	.write_enable(sram_we_n),
	.entity_data(entity),
	.game_state(game_state),
	.game_start(game_start)
);

endmodule 