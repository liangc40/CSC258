module square_coord(x_in, y_in, colour, resetn, CLOCK_50, go, writeEn, done, x, y, c);
	input [7:0] x_in;
	input [6:0] y_in;
	input [2:0] colour;
	input resetn, CLOCK_50, go;
	
	output wire writeEn, done;
	output wire [7:0] x;
	output wire [6:0] y;
	output wire [2:0] c;
	
	wire draw_fin, ld, draw;
	
	
	control c0(CLOCK_50, resetn, go, draw_fin, ld, draw, writeEn, done);
	datapath d0(x_in, y_in, colour, CLOCK_50, resetn, ld, draw, draw_fin, x, y, c);
endmodule
	
module control(clk, resetn, go, draw_fin, ld, draw, writeEn, done);

	input clk, resetn, go, draw_fin;
	
	output reg ld, draw, writeEn, done;
	
	reg [2:0] current_state, next_state;
	
	localparam 	S_LOAD = 3'd0,
					S_LOAD_WAIT = 3'd1,
					S_DRAW = 3'd2,
					S_DRAW_WAIT = 3'd3,
					S_DONE = 3'd4;
					
	// Next state logic aka state table
	always@(*)
	begin: state_table
		case (current_state)
			S_LOAD: next_state = go? S_LOAD_WAIT: S_LOAD;
			S_LOAD_WAIT: next_state = S_DRAW;
			S_DRAW: next_state = draw_fin ? S_DRAW_WAIT: S_DRAW;
			S_DRAW_WAIT: next_state = S_DONE;
			S_DONE: next_state = S_LOAD;
			default: next_state = S_LOAD;
		endcase
	end
	
	always @(*)
	begin: enable_signals
		ld = 1'b0;
		draw = 1'b0;
		writeEn = 1'b0;
		done = 1'b0;
		
		case (current_state)
			S_LOAD_WAIT: begin
				ld = 1'b1;
				end
			S_DRAW: begin
				draw = 1'b1;
				writeEn = 1'b1;
				end
			S_DRAW_WAIT: writeEn = 1'b1;
			S_DONE: done = 1'b1;
		endcase
	end
	
	// current_state registers
	always@(posedge clk)
	begin: state_FFs
		if(!resetn)
			current_state <= S_LOAD;
		else
			current_state <= next_state;
	end
endmodule

module datapath(x_in, y_in, c_in, clk, resetn, ld, draw, draw_fin, x, y, c);

	input clk, resetn, ld, draw;
	input [7:0] x_in;
	input [6:0] y_in;
	input [2:0] c_in;
	
	output draw_fin;
	output reg [7:0] x;
	output reg [6:0] y;
	output reg [2:0] c;

	wire [3:0] p;
	reg [7:0] x_org;
	reg [6:0] y_org;
	reg [2:0] c_org;

	up_counter u0(p, clk, resetn, draw);

	always@(posedge clk) begin
		if (!resetn) begin
			x_org <= 8'b0;
			y_org <= 7'b0;
			c_org <= 2'b0;
		end
		else if (ld) begin
			x_org <= x_in;
			y_org <= y_in;
			c_org <= c_in;
		end
		else begin
			x_org <= x_org;
			y_org <= y_org;
			c_org <= c_org;
		end
	end
	
	always@(posedge clk) begin
		if (!resetn) begin
			x <= 8'b0;
			y <= 7'b0;
			c <= 3'b0;
		end else if (draw) begin
			x <= x_org + p[1:0];
			y <= y_org + p[3:2];
			c <= c_org;
		end else begin
			x <= x;
			y <= y;
			c <= c;
		end
	end
	
	assign draw_fin = (p == 3'b0);
	
endmodule

module up_counter(out, clk, resetn, enable);
	input clk, resetn, enable;
	output reg [3:0] out;

	always@(posedge clk) begin
	if (!resetn) 
		out <= 4'b0;
	else if (out == 4'b1111) 
		out <= 4'b0;
	else if (enable)
		out <= out + 1'b1;
	else
		out <= out;
	end
endmodule
		
	
