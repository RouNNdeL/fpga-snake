module lfsr32(
  input clk,
  output out,
  input rst,
  input [31:0] rst_vector
);
  
  reg [31:0]r;
  
  assign out = r[31];
  
  always@(posedge clk, posedge rst) begin
    if(rst)
      r <= rst_vector;
    else begin
      r[31:1] <= r[30:0];
      r[0] = r[30] ^~ r[27];
    end
  end

endmodule