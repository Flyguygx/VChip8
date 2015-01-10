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

class Keypad
{
	KeyEnts = array(16);
	Keys = array(16);
	CurrentKey = null;
	
	constructor(self, Buttons)
	{
		KeyEnts = Buttons;
		
		for(local k = 0x0;k <= 0xF;k++) //Initialize the buttons
		{
			Keys[k] = false;
			
			LinkIO(Buttons[k],"OnIn",self,"RunScriptCode","cpu.Input.KeyPressed(" + k + ")",0,-1); //OnIn calls the KeyPressed function with the button's key code.
			LinkIO(Buttons[k],"OnOut",self,"RunScriptCode","cpu.Input.KeyReleased(" + k + ")",0,-1); //OnOut calls the KeyReleased function with the button's key code.
		}
	}
	
	function GetCurrentKey()
	{
		return CurrentKey;
	}
	
	function GetKeyState(key)
	{
		if(key <= 0x0F)
		{
			return Keys[key & 0x0F];
		}
		else
		{
			return false;
		}
	}
	
	function KeyPressed(key)
	{		
		CurrentKey = key;
		Keys[key] = true;		
	}
	
	function KeyReleased(key)
	{		
		Keys[key] = false;
		if(key == CurrentKey)
		{
			CurrentKey = null;
		}
	}	
	
}