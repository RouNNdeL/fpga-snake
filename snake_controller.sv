module snake_controller(
	input clk_25_2,
	input clk_1,
	input clk_grid,
	input rst,
	input [5:0] x,
	input [5:0] y,
	inout [15:0] sram_dq, 
	output [17:0] sram_addr,
	output write_enable,
	output [15:0] entity_data,
	output [7:0] dbg
);

reg [4:0] objective_x;
reg [4:0] objective_y;

reg [4:0] player_x;
reg [4:0] player_y;
reg [9:0] player_length;

wire [15:0] entity_next;
reg [15:0] entity_reg;

wire write_next;
reg write_reg;

assign write_enable = ~write_reg;
assign sram_dq = write_reg ? sram_buffer_reg : 16'hzzzz;

assign sram_addr = {x, y};
assign entity_data = entity_reg;

wire [1:0] state_next;
reg [1:0] state_reg;

reg eval_reg;

wire [15:0] sram_buffer_next;
reg [15:0] sram_buffer_reg;

parameter STATE_READ = 2'b01;
parameter STATE_WRITE = 2'b10;
parameter STATE_NOP = 2'b11;

parameter BORDER_VALUE = 16'hffff;

assign dbg = player_length;
	
always @(posedge clk_1, posedge rst) begin
	if(rst) begin
			player_x <= 3;
			player_y <= 3;
			player_length <= 1;
	end else begin
		player_x <= player_x + 1;
		player_length <= player_length + 1;
	end
end 
	
always @(posedge clk_25_2, posedge rst) begin
	if(rst) begin
		write_reg <= 1;
		sram_buffer_reg <= 16'h0;
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
		entity_reg <= entity_next;
		sram_buffer_reg <= sram_buffer_next;
		write_reg <= write_next;
	end
end

always @* begin
	state_next = state_reg;
	sram_buffer_next = sram_dq;
	write_next = 0;
	entity_next = 0;
	
	if (eval_reg) begin
		case(state_reg) 
			STATE_READ: begin
				state_next = STATE_WRITE;
			end
			STATE_WRITE: begin
				if(sram_buffer_reg > 0 && sram_buffer_reg != BORDER_VALUE) begin
					entity_next = 16'hde2;
					write_next = 1;
					sram_buffer_next = (sram_buffer_reg + 1) % (player_length + 1);
				end 
				if(sram_buffer_reg == 0 && x == player_x && y == player_y) begin
					entity_next = 16'hde2;
					write_next = 1;
					sram_buffer_next = 1;
				end 
					
				state_next = STATE_NOP;
			end
			STATE_NOP: state_next = STATE_NOP;
		endcase
	end else begin
		sram_buffer_next = sram_dq;
		if(sram_buffer_reg > 0 && sram_buffer_reg != BORDER_VALUE)
			entity_next = 16'hde2;
		if(sram_buffer_reg == BORDER_VALUE)
			entity_next = 16'hffff;
	end 
end

endmodule 