module drawer (
	input clk,
	input rst,
	input [8:0] x,
	input [8:0] y,
	output wire [15:0] dq,
	output wire w_en,
	output [7:0] dbg
);

logic [15:0] data_next;
reg [15:0] data_reg;

logic write_next;
reg write_reg;

logic drawing;
logic ready_to_draw;

assign dq = write_reg ? data_reg : 16'hzzzz;
assign w_en = ~write_reg;


wire new_draw;
assign new_draw = y == 0;

reg [6:0] frame_counter;
wire new_frame = frame_counter == 0;

always @(posedge new_draw) begin
	frame_counter <= frame_counter + 1;
	if(frame_counter >= 60)
		frame_counter <= 0;
end

always @* begin
	data_next = 0;
	if(x == 10) 
		data_next = 16'hffff;
end 

always @(posedge clk, posedge rst) begin
	if(rst) begin
		data_reg <= 0;
		write_reg <= 0;
	end else begin
		data_reg <= data_next;
		
		if(new_frame)
			write_reg <= 1;
		else
			write_reg <= 0;
	end
end 

endmodule 