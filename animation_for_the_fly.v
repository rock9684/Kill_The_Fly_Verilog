/*
* Given an address give the designated x and y along the along the path
* Making the assumption that the fly is a 4x4 black square
* Takes in a value to start
* It takes in a 2-bit address
* clock is the CLOCK_50 clock
* Give out the x, y coordinates and the plot signal
* And it should be returning a signal to tell that the process has finished
*/
module flyIn(start, address, clock, x, y, colour, plot, over);
	input start;
	input [1:0]address;
	input clock;
	output [8:0]x; // Haven't specify the size of it yet
	output [7:0]y;
	output [2:0]colour;
	output plot;
	output over;
	wire [3:0]plotcounter;
	wire [3:0]plotcounter2;
	wire [25:0]delaycounter;
	wire valid;
	wire [3:0]currentstate;
	controlFlyIn flyInControl(start, clock, plotcounter, plotcounter2, delaycounter, valid, currentstate);
	dataFlyIn flyInData(currentstate, address, clock, x, y, colour, plot, over, valid, plotcounter, plotcounter2, delaycounter);
	
endmodule

/*
* The control path for a single animation
* start is the signal to trigger the animation
* address is the target fruit the fly will be landed on
* plotcounter is for drawing and erasing the "fly"
* delaycounter hold the image for a while
* currentstate is the signal to datapath
* validness is for checking whether the fly has reached the destination
*/

module controlFlyIn(start, clock, plotcounter, plotcounter2, delaycounter, validness, currentstate);

	input start;
	input clock;
	input [3:0]plotcounter;
	input [3:0]plotcounter2;
	input [25:0]delaycounter;
	input validness;
	output reg [3:0]currentstate;
	
parameter [3:0] starting = 4'b0000, draw = 4'b0001, hold = 4'b0010, erase = 4'b0011, update = 4'b0100, checkvalid = 4'b0101, terminate = 4'b0110;
	
	wire [25:0]dummyCount;
	delayCNT dummydummy(clock, currentstate == hold, dummyCount);
	
	reg [3:0]nextstate;
	//State update always block
	always @ (*)
	begin
		case(currentstate[3:0])
		//starting
		starting:
					begin
						//if(start==1)
							nextstate = draw;
					end
		//draw
		draw:
					begin
						if (plotcounter == 4'd15)
							nextstate = hold;
						else
							nextstate = draw;
					end
		
		//hold
		hold:
					begin
						//Hold for a short period of time
						//Making the travelling time from the leftmost to the rightmost roughly 0.5 seconds 
						if (dummyCount == 26'd150000) 
							nextstate = checkvalid;
						else 
							nextstate = hold;
					end
		
		
		
		//checkvalid
		checkvalid:
					begin
						if (validness)
							nextstate = terminate;
						else
							nextstate = erase;
					end
					
		//erase
		erase:
					begin
						if (plotcounter2 == 4'd15)
							nextstate = update;
						else
							nextstate = erase;
					end
		
		//update
		update:
					begin
						nextstate = draw;
					end
		
		//terminate
		terminate:
					nextstate = terminate;
		
					
		//default:
			//		nextstate = starting;
		endcase
		
end
	
	//State Flip-Flop
	always @ (posedge clock)
	begin 
		if (start == 1)
			currentstate <= nextstate;
		else
			currentstate <= starting;
	end
	
endmodule

/*
* The data path for a single animation
* currentstate is the passed in through the control path
* clock is the CLOCK_50
* x is the x-coordinate to be drawn onto the VGA
* y is the y-coordinate to be drawn onto the VGA
* plot is the signal depicting whether it shall be drawn
*/
module dataFlyIn(currentstate, address, clock, x, y, colour, plot, over, valid, counter, counter2, delaycounter);
	input [3:0]currentstate;
	input [1:0]address;
	input clock;
	output reg [8:0]x;
	output reg [7:0]y;
	output reg [2:0]colour;
	output reg plot;
	output reg over;
	output reg valid;
	
	
parameter [3:0] starting = 4'b0000, draw = 4'b0001, hold = 4'b0010, erase = 4'b0011, update = 4'b0100, checkvalid = 4'b0101, terminate = 4'b0110;

	//Wires representing each state behaviour
	reg a, b, c, d, e, f, g;
	
	always@(*)
	
	begin
		case(currentstate[3:0])
			starting: 
			begin
				a = 1;
				b = 0;
				c = 0;
				d = 0;
				e = 0;
				f = 0;
				g = 0;
			end
			
			draw: 
			begin
				a = 0;
				b = 1;
				c = 0;
				d = 0;
				e = 0;
				f = 0;
				g = 0;
			end
			
			hold: 
			begin
				a = 0;
				b = 0;
				c = 1;
				d = 0;
				e = 0;
				f = 0;
				g = 0;
			end
			
			erase: 
			begin
				a = 0;
				b = 0;
				c = 0;
				d = 1;
				e = 0;
				f = 0;
				g = 0;
			end
			
			update: 
			begin
				a = 0;
				b = 0;
				c = 0;
				d = 0;
				e = 1;
				f = 0;
				g = 0;
			end
			
			checkvalid: 
			begin
				a = 0;
				b = 0;
				c = 0;
				d = 0;
				e = 0;
				f = 1;
				g = 0;
			end
			
			terminate: //Though this state is kinda trivial 
			begin
				a = 0;
				b = 0;
				c = 0;
				d = 0;
				e = 0;
				f = 0;
				g = 1;
			end
		endcase
	end
	
	//Need two counter for the process
	output [3:0]counter;
	output [3:0]counter2;
	output [25:0]delaycounter;
	wire [2:0]colour2;
	wire writeEn;
	wire [2:0]trivialData;
	assign writeEn = 0;
	reg [10:0] dum;
	always@(*)begin
		if(counter2[3:2] == 2'b00)
			dum = 11'd0;
		else
			dum = 11'd3;
	end
	
	
	basiccounter myBasicCounter(clock, b, counter);
	basiccounter myBasicCounter2(clock, d, counter2);
	delayCNT myDelayCNT(clock, c, delaycounter);
	backgroundFlyIn mybackgroud((counter2[3:2] * 11'd320 + x - dum), clock, trivialData, writeEn, colour2[2:0]);
	
	
	
	wire [8:0]xInput;
	wire [7:0]yInput;
	//Update the address in the update state
	updateCord updateX(clock, a, e, xInput, yInput);
	
	
	
parameter [9:0] a_address = 10'b0000110010, b_address = 10'b0001111101, c_address = 10'd200, d_address = 10'd275;
	
	
	always @ (*)
	begin
		/*
		//Starting
		if(a == 1)
		begin
			xInput[8:0] = 9'b000000000;
			yInput[8:0] = 9'b010100000;
		end
		*/
		
		//Draw
		if (b == 1)
		begin
			x = xInput + counter[1:0];
			y = yInput + counter[3:2];
			colour[2:0] = 3'b000;
		end
		
		//Erase	
		if (d == 1)
		begin
			x = xInput + counter2[1:0];
			y = yInput + counter2[3:2];
			colour[2:0] = colour2[2:0];
		end
		
		/*
		//Update	
		if (e == 1)
		begin
			xInput = xInput + 1'b1;
			yInput = yInput;
		end
		*/
		
		//Check validness
		if (f == 1)
		begin
			case(address)
				2'b00:
					if ({1'b0, xInput} == a_address)
						valid = 1;
					else
						valid = 0;
				2'b01:
					if ({1'b0, xInput} == b_address)
						valid = 1;
					else
						valid = 0;
				2'b10:
					if ({1'b0, xInput} == c_address)
						valid = 1;
					else
						valid = 0;
				2'b11:
					if ({1'b0, xInput} == d_address)
						valid = 1;
					else
						valid = 0;
			endcase
			
		end
		
		//Information to the big FSM
		if (g == 1)
			over = 1;
		else
			over = 0;
			
		//When should we update the graphics on the VGA.
		//There are 1. draw state 2. erase state
		if (b | d == 1)
			plot = 1;
		else 
			plot = 0;
	end
	
	
	
endmodule

module updateCord(clock, initialize, enable, xOutput, yOutput);
	input clock;
	input initialize;
	input enable;
	output reg [8:0]xOutput;
	output reg [7:0]yOutput;
	
	always @ (posedge clock)
	begin
	
		if (enable)
		begin
			xOutput <= xOutput + 1'b1;
			yOutput <= yOutput;
		end
		
		if (initialize)
		begin
			xOutput <= 9'b000000000;
			yOutput <= 8'd165;
		end
		
	end
endmodule





