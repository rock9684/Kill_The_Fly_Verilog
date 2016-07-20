

/*
* The state for game over display
* gameStart: when it is one, erase the part
* gameOver: when it is one, draw the game over picture
*/

module gameOverDisplay(gameOver, reset, clock, x, y, colour, plot, eraseCount);
	input reset;
	input gameOver;
	input clock;
	
	//Wires needed for signals between control path and data path
	wire [12:0]drawCount;
	output [12:0]eraseCount;
	wire [2:0]currentstate;
	controlOver gameOverControl(gameOver, reset, drawCount, eraseCount, clock, currentstate);
	
	output [8:0]x;
	output [7:0]y;
	output [2:0]colour;
	output plot;
	dataOver gameOverData(currentstate, clock, x, y, colour, plot, drawCount, eraseCount, eraseOver);

endmodule

/*****Game Over Image Control*****/
module controlOver(gameOver, reset, drawCount, eraseCount, clock, currentstate);
	input gameOver;
	input reset;
	input [12:0]drawCount;
	input [12:0]eraseCount;
	input clock;

parameter [2:0] erase = 3'b000, draw = 3'b001, done1 = 3'b010, done2 = 3'b011;
	
	reg [2:0]nextstate;
	always @ (*)
	begin
		case(currentstate)
			erase:
			begin
				if (eraseCount == 13'b1111111111111)
					nextstate = done1;
				else
					nextstate = erase;
			end
			draw:
			begin
				if (drawCount == 13'b1111111111111)
					nextstate = done2;
				else
					nextstate = draw;
			end
			done1:
				if(gameOver == 1)
					nextstate = draw;
				else
					nextstate = done1;
			
			done2:
					nextstate = done2;
		endcase
	end
	
	output reg [2:0]currentstate;
	//State Flip-flop
	always @ (posedge clock)
	begin
		if (reset == 1)
			currentstate <= erase;
		else
			currentstate <= nextstate;
	end
endmodule

/*****Game Over Image Data*****/
module dataOver(currentstate, clock, x, y, colour, plot, drawCount, eraseCount, eraseOver);
	input clock;
	input [2:0]currentstate;
	output reg [8:0]x;
	output reg [7:0]y;
	output reg [2:0]colour;
	output reg plot;
	output [12:0]drawCount;
	output [12:0]eraseCount;
	output reg eraseOver;
	
parameter [2:0] erase = 3'b000, draw = 3'b001, done1 = 3'b010, done2 = 3'b011;
	
	reg drawStart;
	reg eraseStart;
	//Output logic
	always @ (*)
	begin
		case(currentstate)
			erase:
			begin
				eraseOver = 0;
				drawStart = 0;
				eraseStart = 1;
			end
			draw:
			begin
				eraseOver = 0;
				drawStart = 1;
				eraseStart = 0;
			end
			done1:
			begin
				eraseOver = 1;
				drawStart = 0;
				eraseStart = 0;
			end
			done2:
			begin
				eraseOver = 0;
				drawStart = 0;
				eraseStart = 0;
			end
			
			default:
			begin
				eraseOver = 0;
				drawStart = 0;
				eraseStart = 0;
			end
		endcase
	end
	
	always @ (*)
	begin
		if (drawStart == 1)
		begin
			x = 9'd100 + drawCount[6:0];
			y = 8'd55 + drawCount[12:7];
			colour = q;
			plot = 1;
		end
		else if (eraseStart == 1)
		begin
			x = 9'd100 + eraseCount[6:0];
			y = 8'd55 + eraseCount[12:7];
			colour = 3'b111;
			plot = 1;
		end
		else
			plot = 0;
	end
	
	wire [2:0]data;
	wire wren;
	assign wren = 0;
	wire [2:0]q;
	GameOver (drawCount[12:0], clock, data, wren, q);
	drawOverCounter myDraw(drawStart, clock, drawCount);
	eraseOverCounter myErawe(eraseStart, clock, eraseCount);
endmodule


/***Draw Counter***/
module drawOverCounter(trigger, clock, counting);
	input trigger;
	input clock;
	output reg [12:0]counting;
	
	always @ (posedge clock)
	begin
		if (trigger == 1)
			counting <= counting + 1'b1;
		else
			counting <= 13'b0;
	end
endmodule

/***Erase Counter***/
module eraseOverCounter(trigger, clock, counting);
	input trigger;
	input clock;
	output reg [12:0]counting;
	
	always @ (posedge clock)
	begin
		if (trigger == 1)
			counting <= counting + 1'b1;
		else
			counting <= 13'b0;
	end
endmodule











