module drawer (
	input frame,
	input clk,
	input rst,
	input [8:0] x,
	input [8:0] y,
	output wire [15:0] dq,
	output wire w_en,
	output [7:0] dbg
);

logic [8:0] counter_next;
logic [8:0] counter_reg;

logic [15:0] data_next;
reg [15:0] data_reg;

logic write_next;
reg write_reg;

logic drawing;
logic ready_to_draw;

assign dq = write_reg ? data_reg : 16'hzzzz;
assign w_en = ~write_reg;

always @* begin
	if(frame) begin
		ready_to_draw = 1;
	end 
	
	if(y == 0 && ready_to_draw) begin
		ready_to_draw = 0;
		drawing = 1;
	end 
	
	if(drawing) begin
		write_next = 1;
		if(x == counter_reg) begin
			data_next = 16'hf800;
		end else begin
			data_next = 16'h0000;
		end
			
		if(y == 0 || y == 239 || x == 0 || x == 319) 
			data_next = 16'hff0f;
			
		if(y >= 239)
			drawing = 0;
	end else begin 
		write_next = 0;
	end 
end 

always @(posedge clk, posedge rst) begin
	if(rst) begin
		data_reg <= 0;
		write_reg <= 0;
	end else begin
		data_reg <= data_next;
		write_reg <= write_next;
	end
end 

endmodule 