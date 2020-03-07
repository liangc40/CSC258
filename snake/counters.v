module time_counter(out, clk, resetn);
	input clk, resetn;
	output reg [19:0] out;

	always@(posedge clk) begin
//	if (!resetn)
//		out <= 20'b11001010011001001000;
//	else if (out == 20'b0)
//		out <= 20'b11001011011100110110;
	if (!resetn)
		out <= 20'b11111111111111111111;
	else if (out == 20'b0)
		out <= 20'b11111111111111111111;
//	else
//		out <= out - 1'b1;
	end
endmodule


module frame_counter(clock,reset_n,enable,q);
	input clock,reset_n,enable;
	output reg [3:0] q;
	
	always @(posedge clock)
	begin
		if(reset_n == 1'b0)
			q <= 4'b0000;
		else if(enable == 1'b1)
		begin
		  if(q == 4'b1111)
			  q <= 4'b0000;
		  else
			  q <= q + 1'b1;
		end
   end
endmodule