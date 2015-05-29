module evx.meta.match;
/*
	Copyright (c) 2015 Vlad Levenfeld

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/* instantiate a template alias with a set of arguments
*/
alias Instantiate (alias symbol, Args...) = symbol!Args;

/* get the first item in a list of zero-parameter templates (patterns) which successfully compiles
	if all patterns fail, the final pattern is forcibly instantiated
	thus it can be useful to have a fallback or diagnostic in the final position
*/
template Match (patterns...)
{
	static if (__traits(compiles, Instantiate!(patterns[0])))
		alias Match = Instantiate!(patterns[0]);
	else static if (patterns.length == 1)
		{pragma(msg, Instantiate!(patterns[$-1]));}
	else alias Match = Match!(patterns[1..$]);
}
