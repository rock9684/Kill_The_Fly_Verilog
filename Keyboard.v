`include "PS2_Controller.v"
//This is a module to get inputs from keyboard

module Keyboard(CLOCK_50, PS2_CLK, PS2_DAT, A[3:0], Space);
	input CLOCK_50;
	output reg Space;
	output reg [3:0]A;
	wire [7:0]info;
	wire enable;
	inout PS2_CLK;
	inout PS2_DAT;
	wire resetk;
	assign resetk = 0;
	PS2_Controller PS2( //Keyboard controller
		.CLOCK_50(CLOCK_50), 
		.reset(resetk),
		.PS2_CLK(PS2_CLK),
		.PS2_DAT(PS2_DAT),
		.received_data(info[7:0]),
		.received_data_en(enable)
	);
	
	reg [1:0]counter;
	always@ (posedge enable)begin
		if(info == 8'hF0)
			counter <= 2'b00;
		else
			counter <= counter + 1'b1;
	end
	
	always@ (posedge CLOCK_50)begin
		if(counter == 2'b10)begin
			if(info == 8'h1C)
				A[0] = 1;
			if(info == 8'h1B)
				A[1] = 1;
			if(info == 8'h23)
				A[2] = 1;
			if(info == 8'h2B)
				A[3] = 1;
			if(info == 8'h29)
				Space = 1;
		end
		if(info == 8'hF0)begin
			A[3:0] = 0;
			Space = 0;
		end
	end
	
	
endmodule
