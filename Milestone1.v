`include "animation_for_the_fly.v"
`include "fly_animation_up.v"
`include "fly_animation_down.v"
`include "Keyboard.v"
`include "gameOverAnimation.v"
module Milestone1(SW, KEY, CLOCK_50, LEDR, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, colour, x, y, plot, PS2_CLK, PS2_DAT); 
/*
* Will use SW[9] as the reset
* SW[8] will trigger the game to start
* LEDR[3:0] to represent the "mole"
* SW[3:0] to be the corresponding key
* HEX display the time remaining and score you get
**********Update feature: HEX5:4 used to display the time remaining, HEX3:0 used to count the score**********
*/
	input [9:0]SW;
	input [3:0]KEY;
	input CLOCK_50;
	output [9:0]LEDR;
	output [6:0]HEX5;
	output [6:0]HEX4;
	output [6:0]HEX3;
	output [6:0]HEX2;
	output [6:0]HEX1;
	output [6:0]HEX0;
	output [8:0]x;
	output [7:0]y;
	output plot;
	output [2:0]colour;
	wire gameOver; 
	gameTime GameCountDown(CLOCK_50, Space, gameOver, HEX5, HEX4);//Variables changed
	wire delaySignal;
	wire generated;
	wire hit;
	wire [3:0]currentstate;
	wire inOver;
	wire upOver;
	wire downOver;
	wire [12:0]eraseCount;
	wire [15:0]currentscore;
	wire wrong;
	//ControlPath
	controlPath myControl(Space, CLOCK_50, generated, hit, delaySignal, gameOver, currentstate[3:0], inOver, upOver, downOver, currentscore, wrong, eraseCount);
	
	//datapath
	datapath mydatapath(A[3:0], Space, gameOver, CLOCK_50, currentstate[3:0], delaySignal, generated, hit, LEDR[9:0], HEX3, HEX2, HEX1, HEX0, x, y, colour, plot, inOver, upOver, downOver, currentscore, wrong, eraseCount);
	
	inout PS2_CLK;
	inout PS2_DAT;
	wire Space;
	wire [3:0]A;
	Keyboard myKeyboard(CLOCK_50, PS2_CLK, PS2_DAT, A[3:0], Space);
endmodule

/*
* This part controls the score accumulation
* Everytime a signal is on(indicating the item has been hit) the score goes up by one.
* clock is CLOCK_50
* reset is the reset of the game
* hit is the signal being generated when the target has been hit
*/
/*************Will update a score deduction feature*************/
/*************There is a way to make the thing run faster than the game starts in the first place*************/
/*Output the score, when the score is bigger than 20 (just an assumption), use another hold counter instead of one second counter*/
/*Right now the hiearchy of the program is not very good for this feature.*/
module scoreCounter(clock, hit, wrong, reset, HEX3, HEX2, HEX1, HEX0, counter);
  
  input clock;
  input hit;
  input wrong;
  input reset;
  output [6:0]HEX3;
  output [6:0]HEX2;
  output [6:0]HEX1;
  output [6:0]HEX0;
  output reg [15:0]counter;
  
  
  always @ (posedge clock)
  begin
   //Resetting the counter
   if (reset == 1)
		counter <= 16'b00000000;
	
	//Counting the score process
	if(counter[15:0] == 16'b0000000000000000)begin
		if(hit == 1)
			counter <= counter + 1'b1;
		else if(wrong == 1)
			counter <= counter;
	end
	else if(hit == 1)
		counter <= counter + 1'b1;
	else if (wrong == 1)
		counter <= counter - 1'b1;
 
   //Add one to tenth
   if (counter[3:0] == 4'b1010)
		begin
			counter[3:0] <= 4'b0000;
			counter[7:4] <= counter[7:4] + 4'b0001;
		end
	else if(counter[3:0] == 4'b1111)
		begin
			counter[3:0] <= 4'b1001;
		end
	//Add one to hundredth
	if (counter[7:4] == 4'b1010)
		begin
			counter[7:4] <= 4'b0000;
			counter[11:8] <= counter[11:8] + 4'b0001;
		end
	else if(counter[7:4] == 4'b1111)
		begin
			counter[7:4] <= 4'b1001;
		end
  end
  
  //Display the score on the board
  hex_display scoreThousandth(counter[15:12], HEX3);
  hex_display scoreHundredth(counter[11:8], HEX2);
  hex_display scoreTenth(counter[7:4], HEX1);
  hex_display scoreOnes(counter[3:0], HEX0);
endmodule


/*The gaming top module's datapath*/
module datapath(A, reset, gameOver, clock, currentstate, delaySignal, generated, hit, LEDR, HEXthree, HEXtwo, HEXone, HEXzero, x, y, colour, plot, inOver, upOver, downOver, currentscore, wrong, eraseCount);
	input [3:0]A;
	input reset;
	input clock;
	input gameOver;
	input[3:0]currentstate;
	
	output reg [9:0]LEDR;
	output [6:0]HEXthree;
	output [6:0]HEXtwo;
	output [6:0]HEXone;
	output [6:0]HEXzero;

	output reg delaySignal;
	output reg generated;
	output reg hit;
	
	wire [7:0]randomNum;
	parameter start = 4'b0000, generation = 4'b0001,show = 4'b0011, hold = 4'b0100, delay = 4'b0111, over = 4'b1000, reset_s=4'b1001;
	//Continuously generating a random number
	reg randomLocation;
	
	//Signal the scoreCounter to do a score deduction. Does not infringe with other animation.
	//Signal stays within the module
	output reg wrong;
	reg beingWrong;
	wire signal;
	reg resetn;
	reg beingHit;
	output [15:0]currentscore;
	scoreCounter myScore(clock, beingHit, beingWrong, reset, HEXthree, HEXtwo, HEXone, HEXzero, currentscore);
	
	output reg [8:0]x;
	output reg [7:0]y;
	output reg [2:0]colour;
	output reg plot;
	
	wire [1:0]location;
	randomLocationModule RL(clock, randomLocation, reset, location[1:0]);
	/*The above module used to be called randomLocation, which is the same
	name as the wire randomLocation. So I changed the module name to be 
	randomLocationModule*/
	
	//Given each state, execute the corresponding behaviours
	always @ (*)
	begin
		//Start state
		case(currentstate[3:0])
		reset_s:begin
			beingHit = 0;
			beingWrong = 0;
			LEDR[9:0] = 10'b0000000000;
			x = x4;
			y = y4;
			colour = colour4;
			plot = writeEn4;
		end
		start:begin
			LEDR[8] = 1;
			hit = 0;
			wrong = 0;
			randomLocation = 1;
		end
		
		//Generate a random location
		generation:
		begin
			randomLocation = 0;
			delaySignal = 0;
			generated = 1;
		end
		
		//Display the location onto the LED
		/*In the latest version, the LED is no longer needed. Instead, we 
		used the VGA display to demonstrate the fly*/
		show:
		begin
			
			generated = 0;
			x = x1;
			y = y1;
			plot = writeEn1;
			colour = colour1;
			case(location[1:0])//This case is now trivial.
				2'b00: LEDR[3] = 0;
				2'b01: LEDR[2] = 0;
				2'b10: LEDR[1] = 1;
				2'b11: LEDR[0] = 0;
			endcase
		end
		
		/*After the fly-in animation of the fly, hold sometime for the player to react*/
		hold:
		begin
			//While in the state of holding the fly is being hit, the switch off the light
			/*The Reseting operation for the LED is now trivial. When the LED is not lit and the key is pressed,
			Then trigger the signal, wrong, to do the score reduction accordingly.*/
			case (location[1:0])
				2'b11: 
				begin
					if (A[0] == 1 || A[1] == 1 || A[2] == 1)begin
						wrong = 1;
						beingWrong = 1;
					end
					else if (A[3] == 1)
					begin
						LEDR[0] = 0;
						hit=1;
						beingHit = 1;
					end
				end
				2'b10: 
				begin
				if (A[0] == 1 || A[1] == 1 || A[3] == 1)begin
						wrong = 1;
						beingWrong = 1;
					end
				else if (A[2] == 1)
					begin
						LEDR[1] = 1;
						hit=1;
						beingHit = 1;
					end
					
				end
				2'b01:
				begin
					if (A[0] == 1 || A[2] == 1 || A[3] == 1)begin
						wrong = 1;
						beingWrong = 1;
					end
					else if (A[1] == 1)
					begin
						LEDR[2] = 0;
						hit=1;
						beingHit = 1;
					end
					
				end
				2'b00: 
				begin
					if (A[1] == 1 || A[2] == 1 || A[3] == 1)begin
						wrong = 1;
						beingWrong = 1;
					end
					else if (A[0] == 1)
					begin
						LEDR[3] = 0;
						hit=1;
						beingHit = 1;
					end
				end
			endcase
		end
		
		//Delay the program for 1 second for later operation
		delay:
		begin
			beingWrong = 0;
			beingHit = 0;
			LEDR[3:0] = 4'b0000;
			if(hit)begin
				x = x3;
				y = y3;
				plot = writeEn3;
				colour = colour3;
			end
			else if(hit == 0)begin
				x = x2;
				y = y2;
				plot = writeEn2;
				colour = colour2;
			end
		end
		
		over:
		begin
			x = x4;
			y = y4;
			plot = writeEn4;
			colour = colour4;
		end
	endcase
	end
	
	/*The signal wires to carry out the animation. Choice of animation is
	determined in the according state(in datapath). The animationModule acts
	as a submodule of the datapath.*/
	wire [8:0]x1;
	wire [8:0]x2;
	wire [8:0]x3;
	wire [8:0]x4;
	wire [7:0]y1;
	wire [7:0]y2;
	wire [7:0]y3;
	wire [7:0]y4;
	wire [2:0]colour1;
	wire [2:0]colour2;
	wire [2:0]colour3;
	wire [2:0]colour4;
	wire writeEn1;
	wire writeEn2;
	wire writeEn3;
	wire writeEn4;
	output inOver, upOver, downOver;
	output [12:0]eraseCount;
	//Pass the information to an animation module 
	animationModule myAnimation(clock, currentstate, location, hit, x1, y1, x2, y2, x3, y3, colour1, colour2, colour3, writeEn1, writeEn2, writeEn3, inOver, upOver, downOver);
	gameOverDisplay myGanmeOverDisplay(gameOver, reset, clock, x4, y4, colour4, writeEn4, eraseCount);
	
endmodule

/*
* Animation submodule
* Notice: The drawing state is not completed. The module is just generating the information need for display.
			 The actual drawing process is in the very upper level VGA
* x123 & y123: The coordinates to be drawn
* colour123: The colour to be drawn. (Some of which is determined by the stored .mif file)
* writeEn123: The permitance of drawing on VGA.
*/
module animationModule(clock, currentstate, location, hit, x1, y1, x2, y2, x3, y3, colour1, colour2, colour3, writeEn1, writeEn2, writeEn3, inOver, upOver, downOver);
	input clock;
	input [3:0]currentstate;
	input [1:0]location;
	input hit;
	
	output [8:0]x1;
	output [7:0]y1;
	output [8:0]x2;
	output [7:0]y2;
	output [8:0]x3;
	output [7:0]y3;
	
	output writeEn1;
	output writeEn2;
	output writeEn3;

	output [2:0]colour1;
	output [2:0]colour2;
	output [2:0]colour3;
	
	output inOver;
	output upOver;
	output downOver;
	
	reg inStart, upStart, downStart;
	always @ (*)
	begin
		case(currentstate)
			4'b0011:
			begin
				inStart = 1;
			end
			4'b0111:
			begin
				if (hit == 1)
					downStart = 1;
				else
					upStart = 1;
			end
			default:
			begin
				inStart = 0;
				upStart = 0;
				downStart = 0;
			end
		endcase
	end
	
	flyIn myIn(inStart, location, clock, x1, y1, colour1, writeEn1, inOver);
	fly_animation_up myUp(upStart, location, clock, x2, y2, colour2, writeEn2, upOver);
	fly_animation_down myDown(downStart, location, clock, x3, y3, colour3, writeEn3, downOver);
	
endmodule



/*
* The overall top module for the game to be executed.
* generated: is on upon finishing the generation of a random location of the fly
* delaySignal: delay for 1 second after the fly is hit or missed
					This state is now trivial because the fly will immediately fly in 
					when hit.
* timer: The gameOver signal. 
* hit: the fly is hit in the holding state
*/

module controlPath(reset, clock, generated, hit, delaySignal, timer, presentstate, inOver, upOver, downOver, currentscore, wrong, eraseCount);
	input reset, clock, generated, delaySignal, timer, hit, inOver, upOver, downOver, wrong;
	input [12:0]eraseCount;
	input [15:0]currentscore;
	output reg [3:0]presentstate;
parameter start = 4'b0000, generation = 4'b0001,show = 4'b0011, hold = 4'b0100, delay = 4'b0111, over = 4'b1000, reset_s=4'b1001;
	reg [3:0]nextstate;
	wire signal;
	wire signal1;
	reg continue;
	reg startd;
	wire [25:0]delaycount;
	
	
	delayCNT myDelay(clock, startd, delaycount);
	//State transformation
	always @ (*)
	begin
		//The beginning of the game
		case(presentstate)
		reset_s:
			if(eraseCount == 13'b1111111111111)
				nextstate = start;
		//The beginning of the game
		start:
				nextstate = generation;
		
		//Generate the place where the fly appears
		generation:
			if(generated)
				nextstate = show;
		
		//Start the animation of showing up the fly
		show:begin
			startd = 0;
			if(inOver)
				nextstate = hold;
		end
		//Let the image hold for a few moments	
		hold:
		begin
			startd = 1;
			if (hit == 1 || wrong == 1)
				nextstate = delay;
			if(currentscore < 16'd15)begin
				if(delaycount == 26'd50000000)
					nextstate = delay;
			end
			if(currentscore >= 16'd15 && currentscore < 16'd30)begin
				if(delaycount == 26'd25000000)
					nextstate = delay;
			end
			if(currentscore >= 16'd30)begin
				if(delaycount == 26'd12500000)
					nextstate = delay;
			end
		end
		
		//Hold it for a while before appearing the next appearance of the next fly
		delay:
		begin
			if(upOver || downOver)
				nextstate = start;
		end
		
		//When the game is over, wait for the reset state to restart the game 
		over:
			nextstate = over;
		
		default:
			nextstate = reset_s;
	
		endcase
	end
	
	//The state flip flop
	always @ (posedge clock)
	begin //State flip-flops
		if (timer == 1)//Running out of time
			presentstate[3:0] = over;
		else if(reset == 1)
			presentstate[3:0] = reset_s;
		else
			presentstate[3:0] = nextstate;
	end
	
	
endmodule

/*
* Module for generating random numbers
* clock is supposed to be the clock with 50M Hz
* When reset is triggered, start a new cycle
* The output randomEightBits is a random 8-bit binary number
* Note: the final output array may be longer than just size 8
* This is only a prototype. Use modelsim to test its functionality
*/

module randomLocationModule(input clock, input enable, input reset, output reg[1:0]location);
	reg [7:0]randomEightBitsBits;
	always @ (posedge clock) 
	begin
		if (reset == 1)
			randomEightBitsBits <= 8'b1;
		else if (enable) //Starts a basic left shift with small features added
		begin
			randomEightBitsBits[7] <= randomEightBitsBits[6];
			randomEightBitsBits[6] <= randomEightBitsBits[4] ^ randomEightBitsBits[2];
			randomEightBitsBits[5] <= randomEightBitsBits[4];
			randomEightBitsBits[4] <= randomEightBitsBits[3] ^ randomEightBitsBits[1];
			randomEightBitsBits[3] <= randomEightBitsBits[2] ^ randomEightBitsBits[7];
			randomEightBitsBits[2] <= randomEightBitsBits[1];
			randomEightBitsBits[1] <= randomEightBitsBits[0] ^ randomEightBitsBits[4];
			randomEightBitsBits[0] <= randomEightBitsBits[7] ^ randomEightBitsBits[6];
		end
	end
	always@(posedge clock)
		if(enable==1)
			location[1:0]=randomEightBitsBits[3:2];
endmodule

/*
* Counter counting 1 second
* clock is supposed to be the clock with 50M Hz
* When reset is triggered, start a new cycle
* Signal will be set to one every second
*/
module oneSecond(input clock, input reset, output reg signal);
	//The counter that counts
	reg [25:0]counter;
	always @ (posedge clock)
	begin
		if (reset || counter == 26'd50000000)
			counter <= 26'b0;
		else
			counter <= counter + 1;
	end
	//When the counter hits 50M set the signal to 1. All the other senario, signal 0!
	always @ (*)
	begin
		signal = (counter == 26'd50000000) ? 1:0;
	end
endmodule

/*Create a sub module to give signal to half second display(Or is it needed)*/


/*
* The timer that counts if the game is over.
* It counts down from 45 seconds
* When the time is up, it will have the signal gameOver changing from 0 to 1
* clock is supposed to be CLOCK_50
* reset it the first initialization of the program
*/
module gameTime(clock, reset, gameOver, HEXtwo, HEXone);
	input clock, reset;
	output reg gameOver;
	output [6:0]HEXtwo;
	output [6:0]HEXone;
	wire enable;
	oneSecond gameCounter(clock, reset, enable);
	
	//Counting down from 45 second
	reg [7:0]countDown;
	always @ (posedge clock)
	begin
		
		if (countDown[3:0]==4'b1111)
			countDown[3:0] <=4'b1001;
		if (reset == 1)
			countDown <= 8'b01000101;
		else if (countDown[7:0] == 8'b00000000)
			countDown <= 8'b00000000;
		else if (enable)
			countDown <= countDown - 1'b1;
		
	end
	
	
	//Display the time onto the HEX display

	
	hex_display tenth(countDown[7:4], HEXtwo);
	hex_display oneth(countDown[3:0], HEXone);
	
	//Give the gameOver signal
	always @ (*)
	begin
		if (countDown == 8'b00000000)
			gameOver = 1;
		else
			gameOver = 0;
	end
	
endmodule


module hex_display(input [3:0]signal, output [6:0]display); // Get the 4-bit signal and output 7 signal used as hex display
  wire [15:0]W;
  //Below are all the minterm
  assign W[0] = ~signal[3] & ~signal[2] & ~signal[1] & ~signal[0];
  assign W[1] = ~signal[3] & ~signal[2] & ~signal[1] & signal[0];
  assign W[2] = ~signal[3] & ~signal[2] & signal[1] & ~signal[0];
  assign W[3] = ~signal[3] & ~signal[2] & signal[1] & signal[0];
  assign W[4] = ~signal[3] & signal[2] & ~signal[1] & ~signal[0];
  assign W[5] = ~signal[3] & signal[2] & ~signal[1] & signal[0];
  assign W[6] = ~signal[3] & signal[2] & signal[1] & ~signal[0];
  assign W[7] = ~signal[3] & signal[2] & signal[1] & signal[0];
  assign W[8] = signal[3] & ~signal[2] & ~signal[1] & ~signal[0];
  assign W[9] = signal[3] & ~signal[2] & ~signal[1] & signal[0];
  assign W[10] = signal[3] & ~signal[2] & signal[1] & ~signal[0];
  assign W[11] = signal[3] & ~signal[2] & signal[1] & signal[0];
  assign W[12] = signal[3] & signal[2] & ~signal[1] & ~signal[0];
  assign W[13] = signal[3] & signal[2] & ~signal[1] & signal[0];
  assign W[14] = signal[3] & signal[2] & signal[1] & ~signal[0];
  assign W[15] = signal[3] & signal[2] & signal[1] & signal[0];
  //For each output assign the corresponding minterm
  assign display[0] = W[1] | W[4] | W[11] | W[13];
  assign display[1] = W[5] | W[6] | W[11] | W[12] | W[14] | W[15];
  assign display[2] = W[2] | W[12] | W[14] | W[15];
  assign display[3] = W[1] | W[4] | W[7] | W[10] | W[15];
  assign display[4] = W[1] | W[3] | W[4] | W[5] | W[7] | W[9];
  assign display[5] = W[1] | W[2] | W[3] | W[7] | W[13];
  assign display[6] = W[0] | W[1] | W[7] | W[12];
endmodule
