module evx.meta.predicate;
/*
	Copyright (c) 2015 Vlad Levenfeld

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

private {//imports
	import std.typetuple;
}

/* string-mixin-based anonymous templates
*/
template LambdaCapture ()
{
	static template Λ (string op)
	{
		mixin(q{
			alias Λ } ~ op ~ q{;
		});
	}
	static template λ (string op)
	{
		mixin(q{
			enum λ } ~ op ~ q{;
		});
	}
}

/* mixin captures local symbols
*/
mixin LambdaCapture;

/* predicate combinators
*/
alias And = templateAnd;
alias Or  = templateOr;

/* predicate inversion
*/
static template Not (alias predicate)
{
	enum Not (Args...) = !predicate!Args;
}

/* named logical not operator (!)
*/
template not ()
{
	bool not (T)(T value)
	{
		return !value;
	}
}
template not (alias predicate)
{
	bool not (Args...)(Args args)
	if (is(typeof(predicate (args) == true)))
	{
		return !(predicate (args));
	}

	bool not (Args...)()
	if (is(typeof(predicate == true)))
	{
		return !predicate;
	}

	bool not (Args...)()
	if (__traits(compiles, {enum x = predicate!Args;}))
	{
		return !(predicate!Args);
	}
}
