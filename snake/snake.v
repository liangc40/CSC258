`include "vga/vga_adapter/vga_adapter.v"
`include "vga/vga_adapter/vga_address_translator.v"
`include "vga/vga_adapter/vga_controller.v"
`include "vga/vga_adapter/vga_pll.v"

`include "hexdecoder.v"
// We will use KEY[3:0] in a "vim" style way:
//
//  h - LEFT
//  j - DOWN
//  k - UP
//  l - RIGHT


module snake
(
    CLOCK_50,						//	On Board 50 MHz
    // Your inputs and outputs here
    KEY,
    SW,
    HEX0,
    HEX1,
    HEX4,
    HEX5,
	 LEDR,
    // The ports below are for the VGA output.  Do not change.
    VGA_CLK,   						//	VGA Clock
    VGA_HS,							//	VGA H_SYNC
    VGA_VS,							//	VGA V_SYNC
    VGA_BLANK_N,					//	VGA BLANK
    VGA_SYNC_N,						//	VGA SYNC
    VGA_R,   						//	VGA Red[9:0]
    VGA_G,	 						//	VGA Green[9:0]
    VGA_B   						//	VGA Blue[9:0]
    );

    input			CLOCK_50;				//	50 MHz
    input   [9:0]   SW;
    input   [3:0]   KEY;
    output  [6:0]   HEX0, HEX1, HEX4, HEX5;
	 output [9:0] LEDR;

    // Declare your inputs and outputs here
    // Do not change the following outputs
    output			VGA_CLK;   				//	VGA Clock
    output			VGA_HS;					//	VGA H_SYNC
    output			VGA_VS;					//	VGA V_SYNC
    output			VGA_BLANK_N;			//	VGA BLANK
    output			VGA_SYNC_N;				//	VGA SYNC
    output	[9:0]	VGA_R;   				//	VGA Red[9:0]
    output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
    output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

    wire resetn;
    // We will use the 9th switch as an active-low reset
    assign resetn = SW[9];
	 assign LEDR[9] = SW[9];
	 
	 assign clk = CLOCK_50;

    // KEY[3:0] will be our direction buttons, like in Vim

    // 0000 is no direction
    // 0001 is right
    // 0010 is up
    // 0100 is down
    // 1000 is left
    wire [3:0] direction = {~KEY[3], ~KEY[2], ~KEY[1], ~KEY[0]};
	 assign LEDR[3:0] = direction;

    // Create the colour, x, y and writeEn wires that are inputs to the controller.
    wire [2:0] colour;
    wire [7:0] x;
    wire [6:0] y;
    wire writeEn;

    wire done1, go1;
    wire [7:0] snake_x;
    wire [6:0] snake_y;

    // Create an Instance of a VGA controller - there can be only one!
    // Define the number of colours as well as the initial background
    // image file (.MIF) for the controller.
    vga_adapter VGA(
        .resetn(resetn),
        .clock(CLOCK_50),
        .colour(colour),
        .x(x),
        .y(y),
		  .plot(writeEn),
        /* Signals for the DAC to drive the monitor. */
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS),
        .VGA_BLANK(VGA_BLANK_N),
        .VGA_SYNC(VGA_SYNC_N),
        .VGA_CLK(VGA_CLK));
    defparam VGA.RESOLUTION = "160x120";
    defparam VGA.MONOCHROME = "FALSE";
    defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
    defparam VGA.BACKGROUND_IMAGE = "black.mif";

	 wire [2:0] snake_c;

    // Put your code here. Your code should produce signals x,y,colour and writeEn/plot
    // for the VGA controller, in addition to any other functionality your design may require.

    // in this part, let's just show 0 in both HEX4 and HEX5
	 // trying to display X in HEX5 and HEX4
    hexdecoder hex5(x[7:4], HEX5);
    hexdecoder hex4(x[3:0], HEX4);
	 
	 // display Y in HEX1 and HEX 0
	 hexdecoder hex1({1'b0, y[6:4]}, HEX1);
    hexdecoder hex0(y[3:0], HEX0);
    // snake_object snake1(clk, resetn, direction, x_in, y_in, x, y, colour);

	 wire [19:0] tout;
	 time_counter tcounter(tout, clk, resetn);
	 wire enable_1 = (tout == 20'b0) ? 1'b1 : 1'b0;
	 assign LEDR[8] = enable_1;

	// Wait while we draw (we need 0 -> 1111 (15) before we increment)
    // wire [3:0] fout;
    // frame_counter fcounter(clk, resetn, 1'b1, fout);
    // wire enable_1 = (fout == 4'b1111) ? 1 : 0;

	 // outputs its coordinates and colour, and increases its coordinates everytime "16" has passed
    snake_object snek(enable_1, resetn, direction, snake_x, snake_y, snake_c);

    // force writing on for now
    assign writeEn = 1'b1;

    // Instansiate datapath
    // datapath d0(...);
    datapath_top datapath(clk, resetn, snake_x, snake_y, snake_c, go1, done1, x, y, colour);

    // Instansiate FSM control
    // control c0(...);
    control_top control(clk, resetn, enable_1, done1, go1);

endmodule

module snake_object(clk, resetn, direction, x_out, y_out, colour);
    input clk;
    input resetn;
    input [3:0] direction;

    output reg [7:0] x_out;
    output reg [6:0] y_out;
    output [2:0] colour;

    reg [3:0] past_dir;

    assign colour = 3'b111; // assign the snake white initially

    always @(posedge clk, negedge resetn) begin
        if (~resetn) begin
            x_out <= 7'b0;
            y_out <= 6'b0;
            past_dir <= 4'b1;
        end
        // let's just draw the square at 0, 0 first
        else begin
            if (direction == 4'b0) begin
                if (past_dir == 4'b0001) begin
                    x_out <= x_out + 1;
                    y_out <= y_out;
                end else if (past_dir == 4'b0010) begin
                    x_out <= x_out;
                    y_out <= y_out - 1;
                end else if (past_dir == 4'b0100) begin
                    x_out <= x_out;
                    y_out <= y_out + 1;
                end else if (past_dir == 4'b1000) begin
                    x_out <= x_out - 1;
                    y_out <= y_out;
                end
            end else if (direction == 4'b0001) begin
                x_out <= x_out + 1;
                y_out <= y_out;
                past_dir <= direction;
            end else if (direction == 4'b0010) begin
                x_out <= x_out;
                y_out <= y_out - 1;
                past_dir <= direction;
            end else if (direction == 4'b0100) begin
                x_out <= x_out;
                y_out <= y_out + 1;
                past_dir <= direction;
            end else if (direction == 4'b1000) begin
                x_out <= x_out - 1;
                y_out <= y_out;
                past_dir <= direction;
            end
        end
    end
endmodule

module control_top(clk, resetn, go, done1, go1);
	input clk, resetn, go, done1;
	output reg go1;

	reg [3:0] current_state, next_state;

	localparam	G_START = 4'd0,
			    G_DRAW_1 = 4'd1,
			    G_END = 4'd11;

	always@(*)
	begin: state_table
		case (current_state)
		G_START: next_state = go ? G_DRAW_1: G_START;
		G_DRAW_1: next_state = done1 ? G_END: G_DRAW_1;
		G_END: next_state = G_START;
		default: next_state = G_START;
		endcase
	end

	always @(*)
	begin: enable_signals
		go1 = 1'b0;
		case (current_state)
		G_DRAW_1: go1 = 1'b1;
        default: go1 = 1'b0;
		endcase
	end

	// current_state registers
	always@(posedge clk)
	begin: state_FFs
		if(!resetn)
			current_state <= G_START;
		else
			current_state <= next_state;
	end
endmodule

module datapath_top(clk, resetn, snake_x, snake_y, snake_c, go1, done1, x, y, colour);

	input clk, resetn, go1;
	input [7:0] snake_x;
	input [6:0] snake_y;
	input [2:0] snake_c;

	output reg [7:0] x;
	output reg [6:0] y;
	output reg [2:0] colour;
	output reg done1;

	wire wren1;
	wire [7:0] a1x;
	wire [6:0] a1y;
	wire [2:0] a1c;

	always@(posedge clk) begin
		if (!resetn) begin
			x <= 8'b0;
			y <= 7'b0;
			colour <= 3'b100;
            done1 <= 1'b0;
		end else if (go1) begin
			x <= snake_x;
			y <= snake_y;
			colour <= snake_c;
            done1 <= 1'b0;
		end else begin
			x <= x;
            y <= y;
            done1 <= 1'b1;
		end
	end
endmodule

module time_counter(out, clk, resetn);
	input clk, resetn;
	output reg [19:0] out;

	always@(posedge clk, negedge resetn) begin
	if (!resetn)
		out <= 20'b11111111111111111111;
	else if (out == 20'b0)
		out <= 20'b11111111111111111111;
	else
		out <= out - 1'b1;
	end
endmodule

module snake_test_module
(
    CLOCK_50,						//	On Board 50 MHz
    // Your inputs and outputs here
    KEY,
    SW,
    HEX0,
    HEX1,
    HEX4,
    HEX5
    );

    input			CLOCK_50;				//	50 MHz
    input   [9:0]   SW;
    input   [3:0]   KEY;
    output  [6:0]   HEX0, HEX1, HEX4, HEX5;


    wire resetn;
    // We will use the 9th switch as an active-low reset
    assign resetn = SW[9];

    // KEY[3:0] will be our direction buttons, like in Vim

    // 0000 is no direction
    // 0001 is right
    // 0010 is up
    // 0100 is down
    // 1000 is left
    wire [3:0] direction = {~KEY[3], ~KEY[2], ~KEY[1], ~KEY[0]};

    // Create the colour, x, y and writeEn wires that are inputs to the controller.
    wire [2:0] colour;
    wire [7:0] x;
    wire [6:0] y;
    wire writeEn;

    wire done1, go1;
    wire [7:0] snake_x;
    wire [6:0] snake_y;

	 wire [2:0] snake_c;

    // Put your code here. Your code should produce signals x,y,colour and writeEn/plot
    // for the VGA controller, in addition to any other functionality your design may require.

    // in this part, let's just show 0 in both HEX4 and HEX5
	 // trying to display X in HEX5 and HEX4
    hexdecoder hex5(x[7:4], HEX5);
    hexdecoder hex4(x[3:0], HEX4);
	 
	 // display Y in HEX1 and HEX 0
	 hexdecoder hex1({1'b0, y[6:4]}, HEX1);
    hexdecoder hex0(y[3:0], HEX0);
    // snake_object snake1(clk, resetn, direction, x_in, y_in, x, y, colour);

	 wire [19:0] tout;
	 time_counter tcounter(tout, clk, resetn);
	 wire enable_1 = (tout == 20'b0) ? 1'b1 : 1'b0;

	 // outputs its coordinates and colour, and increases its coordinates everytime "16" has passed
    snake_object snek(enable_1, resetn, direction, snake_x, snake_y, snake_c);

    // force writing on for now
    assign writeEn = 1'b1;

    // Instansiate datapath
    // datapath d0(...);
    datapath_top datapath(clk, resetn, snake_x, snake_y, snake_c, go1, done1, x, y, colour);

    // Instansiate FSM control
    // control c0(...);
    control_top control(clk, resetn, enable_1, done1, go1);

endmodule