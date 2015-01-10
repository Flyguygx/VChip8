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

DoIncludeScript("chip8/emulator/IOUtil.nut",null);
DoIncludeScript("chip8/emulator/cpu.nut",null);
DoIncludeScript("chip8/emulator/keypad.nut",null);
DoIncludeScript("chip8/roms/roms.nut",null);

displayOrigin <- Vector(0,0,0);
cpu <- null;
keypad <- null;

currentTime <- 0;
prevTime <- 0;
deltaTime <- 0;
paused <- false;

timerRate <- 60.0; 
screenUnitWidth <- 384.0;
screenUnitHeight <- 192.0;

function OnPostSpawn()
{
	local Buttons = array(16);
	
	for(local key = 0x0;key <= 0xF;key++) //Loop though all 16 keys and insert them into the button array if they are found.
	{
		Buttons[key] = Entities.FindByName(null,"key_"+format("%01x",key)) //Find the button for this key
		
		if(Buttons[key] == null)
		{
			printl("*** Could not find entity key_" + format("%01x",key) + "!");
		}
		else
		{
			printl("Found entity key_" + format("%01x",key) + ".");
		}
	}
	
	displayOrigin = Entities.FindByName(null,"display_origin").GetOrigin();
	
	keypad = Keypad(self,Buttons);
	cpu = Cpu(Roms.Ibm,keypad);
	
	printl("===Chip-8 Loaded===");
}

function Think()
{
	local offset = Vector(0,0,0);
	
	currentTime = Time();
	
	deltaTime = currentTime-prevTime;
	
	if(!cpu.Error && cpu != null && !paused)
	{
		for(local i = 0;i < 100 && !cpu.Error;i++)
		{
			cpu.Cycle();
		}
		
		if(cpu.Delay > 0)
		{
			cpu.Delay = cpu.Delay - (deltaTime * timerRate).tointeger();
			
			if(cpu.Delay < 0)
			{	
				cpu.Delay = 0;
			}
		}
		
		if(cpu.Sound > 0)
		{
			cpu.Sound = cpu.Sound - (deltaTime * timerRate).tointeger();
			if(cpu.Sound == 1)
			{
				//beep
			}
		}
	}
	DrawDisplay();
	
	prevTime = currentTime;
}

//Draws the display using DebugDrawBox (simple but very inefficient)
function DrawDisplay()
{
	//Scale the pixels so the screen fits within the set unit size.
	local pxWidth = screenUnitWidth/cpu.DISPLAY_WIDTH;
	local pxHeight = screenUnitHeight/cpu.DISPLAY_HEIGHT;
	
	//Loop through all the pixels and draw flat white boxes for pixels that are on.
	for( local x = 0; x < cpu.DISPLAY_WIDTH; x++)
	{
		for( local y = 0; y < cpu.DISPLAY_HEIGHT; y++)
		{
			if(cpu.Gfx[x + (cpu.DISPLAY_HEIGHT-y-1) * cpu.DISPLAY_WIDTH] == 1)
			{
				DebugDrawBox(displayOrigin + Vector(x*pxWidth,0,y*pxHeight),Vector(0,0,0), Vector(pxWidth,0,pxHeight), 255, 255, 255, 255, 0.11);
			}
		}
	}
}



