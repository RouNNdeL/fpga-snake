module snake_controller(
	input clk_25_2,
	input clk_1,
	input clk_grid,
	input rst,
	input [5:0] x,
	input [5:0] y,
	input [1:0] mov_dir,
	input game_start,
	inout [15:0] sram_dq,
	output [17:0] sram_addr,
	output write_enable,
	output [1:0] entity_data,
	output [1:0] game_state,
	output dbg
);

`include "config.h"

reg [4:0] objective_x;
reg [4:0] objective_y;

reg [4:0] player_x;
reg [4:0] player_y;
reg [9:0] player_length;

wire [1:0] entity_next;
reg [1:0] entity_reg;

reg [1:0] game_state_reg;
reg [1:0] game_state_next;

wire write_next;
reg write_reg;

assign write_enable = ~write_reg;
assign sram_dq = write_reg ? sram_buffer_reg : 16'hzzzz;

assign sram_addr = {x, y};
assign entity_data = entity_reg;
assign game_state = game_state_reg;

wire [3:0] state_next;
reg [3:0] state_reg;

reg eval_reg;

wire [15:0] sram_buffer_next;
reg [15:0] sram_buffer_reg;

parameter STATE_READ = 3'b000;
parameter STATE_READ2 = 3'b001;
parameter STATE_WRITE = 3'b010;
parameter STATE_WRITE2 = 3'b011;
parameter STATE_NOP = 3'b100;

parameter BORDER_VALUE = 16'hffff;
parameter OBJECTIVE_VALUE = 16'hfffe;

assign dbg = eval_reg;

random10 r0Y(
	.clk(clk_25_2),
	.rst(seed_rst),
	.seed(seed_counter),
	.out(randomY)
);

random10 r0X(
	.clk(clk_25_2),
	.rst(seed_rst),
	.seed(seed_counter + 200),
	.out(randomX)
);

reg game_running;
reg seed_rst;
reg [31:0] seed_counter;
reg [9:0] randomY;
reg [9:0] randomX;

always @(posedge clk_1, posedge rst) begin
	if(rst) begin
			player_x <= 14;
			player_y <= 14;
			player_length <= 4;
			objective_x <= (randomX) % 28 + 1;
			objective_y <= (randomY) % 28 + 1;
	end else begin
		if(game_running) begin
			if(objective_x == player_x && objective_y == player_y) begin
				player_length <= player_length + 1;
				objective_x <= (randomX) % 28 + 1;
				objective_y <= (randomY) % 28 + 1;
			end
		
			player_x <= next_x;
			player_y <= next_y;
			//player_length <= player_length + 1;
		end
	end
end 
	
always @(posedge clk_25_2, posedge rst) begin
	if(rst) begin
		write_reg <= 1;
		sram_buffer_reg <= 16'h0;
		game_state_reg <= GAME_STATE_ALIVE;
		game_running <= 0;
		if(x == 0)
			sram_buffer_reg <= BORDER_VALUE;
		if(y == 0 && x < 30)
			sram_buffer_reg <= BORDER_VALUE;
		if(x == 29)
			sram_buffer_reg <= BORDER_VALUE;
		if(y == 29 && x < 30)
			sram_buffer_reg <= BORDER_VALUE;
	end else begin
		if(clk_1) begin
			eval_reg <= 1;
		end else 
			eval_reg <= 0;
		if(clk_grid) 
			state_reg <= STATE_READ;
		else 
			state_reg <= state_next;
			
		game_state_reg <= game_state_next;
		entity_reg <= entity_next;
		sram_buffer_reg <= sram_buffer_next;
		write_reg <= write_next;
		seed_counter <= seed_counter + 1;
		if(game_start && !game_running) begin
			seed_rst <= 1;
			game_running <= 1;
		end
		if(seed_rst) begin
			seed_rst <= 0;
		end
	end
end

wire [4:0] next_x;
wire [4:0] next_y;

always @* begin
	state_next = state_reg;
	sram_buffer_next = sram_dq;
	write_next = 0;
	entity_next = entity_reg;
	game_state_next = game_state_reg;
	
	next_x = player_x;
	next_y = player_y;
	
	case(mov_dir) 
		2'b00: next_x = player_x + 1; // Right
		2'b01: next_y = player_y + 1; // Down
		2'b10: next_x = player_x - 1; // Left
		2'b11: next_y = player_y - 1; // Up
	endcase
	
	if (eval_reg) begin
		case(state_reg) 
			STATE_READ: begin
				state_next = STATE_WRITE;
			end
			STATE_WRITE: begin
				if(x == player_x && y == player_y) begin
					if(sram_buffer_reg > 1 && sram_buffer_reg != OBJECTIVE_VALUE) begin
						state_next = STATE_NOP;
						game_state_next = GAME_STATE_DEAD;
					end else if(x == player_x && y == player_y) begin
						write_next = 1;
						sram_buffer_next = 1;
					end
				end else if(sram_buffer_reg > 0 && sram_buffer_reg < OBJECTIVE_VALUE) begin
					write_next = 1;
					sram_buffer_next = sram_buffer_reg + 1;
					sram_buffer_next = sram_buffer_next % (player_length * 2 + 1);
				end else if(sram_buffer_reg == 0 && x == objective_x && y == objective_y) begin
					write_next = 1;
					sram_buffer_next = OBJECTIVE_VALUE;
				end 
					
				state_next = STATE_WRITE2;
			end
			STATE_WRITE2: begin
				sram_buffer_next = sram_buffer_reg;
				write_next = 1;
				state_next = STATE_NOP;
			end
			STATE_NOP: begin
				if(sram_buffer_reg > 0 && sram_buffer_reg < OBJECTIVE_VALUE)
					entity_next = ENTITY_PLAYER;
				else if(sram_buffer_reg == BORDER_VALUE)
					entity_next = ENTITY_WALL;
				else if(sram_buffer_reg == OBJECTIVE_VALUE && game_running)
					entity_next = ENTITY_OBJECTIVE;
				else 
					entity_next = ENTITY_NONE;
			end
		endcase
	end else begin
		sram_buffer_next = sram_dq;
		if(sram_buffer_reg > 0 && sram_buffer_reg < OBJECTIVE_VALUE)
			entity_next = ENTITY_PLAYER;
		else if(sram_buffer_reg == BORDER_VALUE)
			entity_next = ENTITY_WALL;
		else if(sram_buffer_reg == BORDER_VALUE)
			entity_next = ENTITY_WALL;
		else if(sram_buffer_reg == OBJECTIVE_VALUE && game_running)
			entity_next = ENTITY_OBJECTIVE;
		else 	
			entity_next = ENTITY_NONE;
	end 
end

endmodule 