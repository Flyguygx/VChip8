/*
The MIT License (MIT)

Copyright (c) 2015 Flyguy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

class Cpu
{
	MEMORY_SIZE = 4096; //Maximum useable memory. (limited to ~4kb due to 12-bit addresses)
	STACK_SIZE = 16; //Size of the address stack.
	NUM_REGISTERS = 16; //Size of the address stack.
	PROGRAM_START = 512; //Where to load and start programs from.
	DISPLAY_WIDTH = 64; //Display width in pixels.
	DISPLAY_HEIGHT = 32; //Display height in pixels.
	
	FontSet = //4x5 hexadecimal (0-9,A-F) font
	[ 
	  0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
	  0x20, 0x60, 0x20, 0x20, 0x70, // 1
	  0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
	  0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
	  0x90, 0x90, 0xF0, 0x10, 0x10, // 4
	  0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
	  0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
	  0xF0, 0x10, 0x20, 0x40, 0x40, // 7
	  0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
	  0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
	  0xF0, 0x90, 0xF0, 0x90, 0x90, // A
	  0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
	  0xF0, 0x80, 0x80, 0x80, 0xF0, // C
	  0xE0, 0x90, 0x90, 0x90, 0xE0, // D
	  0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
	  0xF0, 0x80, 0xF0, 0x80, 0x80  // F
	];
	
	Instructions = {};
	Program = [];
	Memory = [];
	V = [];
	Stack = [];
	Gfx = [];
	
	PC = 0;
	SP = 0;
	I = 0;
	
	Opcode = 0;
	
	Delay = 0;
	Sound = 0;
	
	Error = false;
	Wait = false;
	
	Input = null;
	
	constructor(rom,keypad)
	{
		Memory = array(MEMORY_SIZE);
		Stack = array(STACK_SIZE);
		V = array(NUM_REGISTERS);
		Gfx = array(DISPLAY_WIDTH * DISPLAY_HEIGHT);
		
		PC = PROGRAM_START;
		SP = STACK_SIZE;
		
		Input = keypad;
		
		Program = rom;
		
		InitInstructions();
		
		Reset();
	}
	
	//Resets the cpu and memory.
	function Reset()
	{
		PC = PROGRAM_START;
		SP = STACK_SIZE;
		I = 0;
		
		//Reset registers and the stack.
		for(local i = 0;i < NUM_REGISTERS;i++)
		{
			V[i] = 0;
			Stack[i] = 0;
		}
		
		//Clear the memory and load the font set and current program.
		for(local i = 0;i < MEMORY_SIZE;i++)
		{
			Memory[i] = 0;
			if(i < FontSet.len())
			{
				Memory[i] = FontSet[i];
			}
			if(Program != null && i >= PROGRAM_START && (i - PROGRAM_START) < Program.len())
			{
				Memory[i] = Program[i - PROGRAM_START];
			}
		}
		
		//Clear the display.
		for(local i = 0;i < DISPLAY_WIDTH * DISPLAY_HEIGHT;i++)
		{
			Gfx[i] = 0;
		}	
		
		Error = false;
	}
	
	//Set the program to the given rom and reset the cpu.
	function LoadRom(rom)
	{
		Program = rom;
		Reset();
	}
	
	//Step forward to the next instruction.
	function Step()
	{
		PC = PC + 2;
	}
	
	//Run the current instruction.
	function Cycle()
	{
		if(PC < MEMORY_SIZE)
		{
			this.Opcode = (Memory[PC] << 8) | Memory[PC + 1];
			
			local idx = this.Opcode & 0xF000;
			
			if(idx in Instructions)
			{
				Instructions[idx](this,this.Opcode);
			}
			else
			{
				this.Error = true;
				printl("Unknown Opcode (" + format("0x%02x",Opcode) + ") at " + PC + "!");
			}
		}
		else
		{
				this.Error = true;
				printl("PC passed end of memory!");
		}
	}
	
	//Define the cpu's instructions in the instruction table.
	function InitInstructions()
	{
		Instructions[0x0000] <- function(Cpu,Opcode) //(00NN) Misc
		{
			local nn = Opcode & 0x00FF;
			
			switch(nn)
			{
				case(0x00): //No Operation
					Cpu.Step();
				break;
				case(0xE0): //Clear screen
					for(local i = 0;i < Cpu.DISPLAY_WIDTH * Cpu.DISPLAY_HEIGHT;i++)
					{
						Cpu.Gfx[i] = 0;
					}
					Cpu.Step();
				break;
				case(0xEE): //Return from subroutine
					Cpu.PC = Cpu.Stack[Cpu.SP];
					Cpu.SP = Cpu.SP + 1;
					Cpu.Step();
				break;
			}
		}
		
		Instructions[0x1000] <- function(Cpu,Opcode) //(1NNN) PC = NNN (Jump to adress)
		{
			local address = Opcode & 0x0FFF
			
			if(Cpu.PC == address) //Infinite loop
			{
				Cpu.Error = true;
				printl("Infinite loop at " + Cpu.PC + "! Stopping.");
			}
			
			Cpu.PC = address;
		}
		
		Instructions[0x2000] <- function(Cpu,Opcode) //(2NNN) Stack[SP] = PC, PC = NNN (Call subroutine)
		{
			Cpu.SP = Cpu.SP - 1;
			Cpu.Stack[Cpu.SP] = Cpu.PC;
			Cpu.PC = Opcode & 0x0FFF;
			//Cpu.Step();
		}
		
		Instructions[0x3000] <- function(Cpu,Opcode) //(3XNN) Skip if VX = NN
		{
			local vx = (Opcode & 0x0F00) >> 8;
			local nn = Opcode & 0x00FF;
			
			if(Cpu.V[vx] == nn)
			{
				Cpu.Step();
			}	
			Cpu.Step();
		}
		
		Instructions[0x4000] <- function(Cpu,Opcode) //(4XNN) Skip if VX != NN
		{
			local vx = (Opcode & 0x0F00) >> 8;
			local nn = Opcode & 0x00FF;
			
			if(Cpu.V[vx] != nn)
			{
				Cpu.Step();
			}	
			Cpu.Step();
		}
		
		Instructions[0x5000] <- function(Cpu,Opcode) //(5XY0) Skip if VX = VY
		{
			local vx = (Opcode & 0x0F00) >> 8;
			local vy = (Opcode & 0x00F0) >> 4;
			
			if(Cpu.V[vx] == Cpu.V[vy])
			{
				Cpu.Step();
			}	
			Cpu.Step();
		}
		
		Instructions[0x6000] <- function(Cpu,Opcode) //(6XNN) VX = NN
		{
			local vx = (Opcode & 0x0F00) >> 8;
			local nn = Opcode & 0x00FF;
			
			Cpu.V[vx] = nn;
			
			Cpu.Step();
		}
		
		Instructions[0x7000] <- function(Cpu,Opcode) //(7XNN) VX = VX + NN
		{
			local vx = (Opcode & 0x0F00) >> 8;
			local nn = Opcode & 0x00FF;
			
			Cpu.V[vx] = (Cpu.V[vx] + nn).tointeger() & 0xFF;
			
			Cpu.Step();
		}
		
		Instructions[0x8000] <- function(Cpu,Opcode) //(8XYN) Math Operations
		{
			local vx = (Opcode & 0x0F00) >> 8;
			local vy = (Opcode & 0x00F0) >> 4;
			local n = (Opcode & 0x000F);
			
			switch(n)
			{
				case(0x0): //VX = VY
					Cpu.V[vx] = Cpu.V[vy];
				break;
				
				case(0x1): //VX = VX or VY
					Cpu.V[vx] = Cpu.V[vx] | Cpu.V[vy];
				break;
				
				case(0x2): //VX = VX and VY
					Cpu.V[vx] = Cpu.V[vx] & Cpu.V[vy];
				break;
				
				case(0x3): //VX = VX xor VY
					Cpu.V[vx] = Cpu.V[vx] ^ Cpu.V[vy];
				break;
				
				case(0x4): //VX = VX + VY
					if((Cpu.V[vx] + Cpu.V[vy]) > 255)
					{
						Cpu.V[0xF] = 1;
					}
					else
					{
						Cpu.V[0xF] = 0;
					}
					Cpu.V[vx] = (Cpu.V[vx] + Cpu.V[vy]).tointeger() & 0xFF;
				break;
				
				case(0x5): //VX = VX - VY not borrow
					if(Cpu.V[vx] > Cpu.V[vy])
					{
						Cpu.V[0xF] = 1;
					}
					else
					{
						Cpu.V[0xF] = 0;
					}
					Cpu.V[vx] = (Cpu.V[vx] - Cpu.V[vy]).tointeger() & 0xFF;
				break;
				
				case(0x6): //VX = VX >> 1 (Shift right by 1)
					//Cpu.V[0xF] = Cpu.V[vx] & 0x01;
					Cpu.V[vx] = (Cpu.V[vx] >> 1) & 0xFF;
					Cpu.V[0xF] = Cpu.V[vx] & 0x01;
				break;
				
				case(0x7): //VX = VY - VX not borrow
					if(Cpu.V[vy] > Cpu.V[vx])
					{
						Cpu.V[0xF] = 1;
					}
					else
					{
						Cpu.V[0xF] = 0;
					}
					Cpu.V[vx] = (Cpu.V[vy] - Cpu.V[vx]).tointeger() & 0xFF;
				break;
				
				case(0xE): //VX = VX << 1 (Shift bits left by 1)
					//Cpu.V[0xF] = (Cpu.V[vx] & 0x80) >> 7;
					Cpu.V[vx] = (Cpu.V[vx] << 1) & 0xFF;
					Cpu.V[0xF] = (Cpu.V[vx] & 0x80) >> 7;
				break;
				
				default:
					Cpu.Error = true;
					printl("Unknown Opcode (" + format("0x%02x",Opcode) + ") at " + Cpu.PC + "!");	
				break;
			}
			
			Cpu.Step();
		}
		
		Instructions[0x9000] <- function(Cpu,Opcode) //(9XY0) Skip if VX != VY
		{
			local vx = (Opcode & 0x0F00) >> 8;
			local vy = (Opcode & 0x00F0) >> 4;
			
			if(Cpu.V[vx] != Cpu.V[vy])
			{
				Cpu.Step();
			}	
			Cpu.Step();
		}
		
		Instructions[0xA000] <- function(Cpu,Opcode) //(ANNN) I = NNN
		{
			Cpu.I = Opcode & 0x0FFF;
			Cpu.Step();
		}
		
		Instructions[0xB000] <- function(Cpu,Opcode) //(BNNN) PC = NNN + V0
		{
			Cpu.PC = (Opcode & 0x0FFF) + Cpu.V[0x0];
		}
		
		Instructions[0xC000] <- function(Cpu,Opcode) //(CXNN) VX = Random(0,255) & NN
		{
			local vx = (Opcode & 0x0F00) >> 8;
			local mask = Opcode & 0x00FF;
			
			Cpu.V[vx] = (rand()&0xFF) & mask;
			Cpu.Step();
		}
		
		Instructions[0xD000] <- function(Cpu,Opcode) //(DXYN) Draw 8xN sprite at VX, VY
		{
			local vx = (Opcode & 0x0F00) >> 8;
			local vy = (Opcode & 0x00F0) >> 4;
			local n = (Opcode & 0x000F);
			
			local sx = Cpu.V[vx];
			local sy = Cpu.V[vy];
			local px = 0;
			local py = 0;
			
			local lpx = 0;
			local cpx = 0;
			
			Cpu.V[0xF] = 0;
			
			for(local y = 0;y < n;y++)
			{
				for(local x = 0;x < 8;x++)
				{
					px = (sx + x) % Cpu.DISPLAY_WIDTH;
					py = (sy + y) % Cpu.DISPLAY_HEIGHT;
					
					local idx = px + py * Cpu.DISPLAY_WIDTH;
					
					lpx = Cpu.Gfx[idx];
					
					Cpu.Gfx[idx] = Cpu.Gfx[idx] ^ ((Cpu.Memory[Cpu.I + y] << x) & 0x80) >> 7;
					
					cpx = Cpu.Gfx[idx];
					
					Cpu.V[0xF] = Cpu.V[0xF] | ((cpx ^ lpx) & lpx);
				}
			}	
			Cpu.Step();
		}
		
		Instructions[0xE000] <- function(Cpu,Opcode) //(EXNN) Key Skip
		{
			local vx = (Opcode & 0x0F00) >> 8;
			local mode = Opcode & 0x00FF;
			
			local state = Cpu.Input.GetKeyState(Cpu.V[vx]);
			
			switch(mode)
			{
				case(0x9E): //Skip if pressed
					if(state)
					{
						Cpu.Step();
					}
				break;

				case(0xA1): //Skip if not pressed
					if(!state)
					{
						Cpu.Step();
					}
				break;
			}
			Cpu.Step();
		}
		
		Instructions[0xF000] <- function(Cpu,Opcode) //(FXNN) IO Operations
		{
			local vx = (Opcode & 0x0F00) >> 8;
			local nn = (Opcode & 0x00FF);
			
			switch(nn)
			{
				case(0x07): //(FX07) VX = Delay Timer
					Cpu.V[vx] = Cpu.Delay & 0xFF;
					Cpu.Step();
				break;
				
				case(0x0A): //(FX0A) Wait for input then place input in VX
					if(Cpu.Input.CurrentKey != null)
					{
						Cpu.V[vx] = Cpu.Input.CurrentKey;
						Cpu.Input.CurrentKey = null;
						Cpu.Step();
					}
				break;
				
				case(0x15): //(FX15) Delay Timer = VX
					Cpu.Delay = Cpu.V[vx];
					Cpu.Step();
				break
				
				case(0x18): //(FX15) Sound Timer = VX
					Cpu.Sound = Cpu.V[vx];
					Cpu.Step();
				break;
				
				case(0x1E): //(FX1E) I = I + VX
					Cpu.I = Cpu.I + Cpu.V[vx];
					Cpu.Step();
				break;
				
				case(0x29): //(FX29) Set I to the sprite index for the digit in VX
					Cpu.I = Cpu.V[vx] * 5; //Number sprites are 5 bytes in size
					Cpu.Step();
				break;
				
				case(0x33): //(FX33) Store the BCD of VX in I, I+1, I+2
					local hundred = floor(Cpu.V[vx] / 100);
					local ten = floor((Cpu.V[vx] - hundred * 100) / 10);
					local one = floor(Cpu.V[vx] - hundred * 100 - ten * 10);
		
					Cpu.Memory[Cpu.I + 0] = hundred;
					Cpu.Memory[Cpu.I + 1] = ten;
					Cpu.Memory[Cpu.I + 2] = one;
					
					Cpu.Step();
				break;
				
				case(0x55): //(FX55) Write V0 - Vx into memory Starting at I
					for(local i = 0;i <= vx;i++)
					{
						Cpu.Memory[Cpu.I + i] = Cpu.V[i];
					}
					//Cpu.I = Cpu.I + vx + 1
					Cpu.Step();
				break;
				
				case(0x65): //(FX65) Read V0 - Vx from memory Starting at I
					for(local i = 0;i <= vx;i++)
					{
						Cpu.V[i] = Cpu.Memory[Cpu.I + i];
					}
					//Cpu.I = Cpu.I + vx + 1
					Cpu.Step();
				break;
				
				default:
					Cpu.Error = true;
					printl("Unknown Opcode (" + format("0x%02x",Opcode) + ") at " + Cpu.PC + "!");
					foreach(k,v in Cpu.UsedInstructions)
					{
						printl(format("0x%02x",k));
					}
				break;
			}
		}	
	}	
}



