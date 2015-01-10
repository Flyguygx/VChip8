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

//Various utility functions for linking entities together.

//Links two entities together with the given input & output
function LinkIO(oent,output,ient,input = "use",param = "",delay = 0,max = -1)
{
	//addoutput format: addoutput "<output name> <target entity>, <input name>, <parameter>, <delay time>, <max times to fire>"
	
	local kvString = format("%s %s,%s,%s,%f,%d",output,ient.GetName(),input,param,delay,max);
	EntFireByHandle(oent,"addoutput",kvString,0.0,null,null);
}

//Link a table of inputs/outputs together
//Note: Muliple links to one output not yet supported
/*
Format:
Outputs <- {
	<output1> = [<target entity>,<input>,<parameter>,<delay>,<times to fire>]
	<output2> = [<target entity>,<input>,<parameter>,<delay>,<times to fire>]
	...
}
LinkIOTable(<entity name>, Outputs)
*/
function LinkIOTable(oent,connections)
{
	foreach(k,v in connections)
	{
		local kvString = format("%s %s,%s,%s,%f,%d",k,v[0].GetName(),v[1],v[2],v[3],v[4]);
		EntFireByHandle(oent,"addoutput",kvString,0.0,null,null);
	}
}

//Gives the entity a unique name if it doesn't already have a name.
function EnsureHasName(ent)
{
	if(ent.GetName().len() == 0)
	{
		local name = ent.GetClassname()+ "_" + UniqueString();
		EntFireByHandle(ent,"addoutput","targetname "+name,0.0,null,null);
	}
}

//Gives the entity a unique name.
function UniqueName(ent)
{
	local name = ent.GetClassname()+ "_" + UniqueString();
	EntFireByHandle(ent,"addoutput","targetname "+name,0.0,null,null);
}