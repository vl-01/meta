module evx.meta.transform;
/*
	Copyright (c) 2015 Vlad Levenfeld

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

private
{//imports
	import std.traits;
	import evx.meta.match;
}

/* identity template
*/
alias Identity (T...) = T[0]; 

/* identity function
*/
auto ref identity (T)(auto ref T x)
{
	return x;
}

/* get the type of a single-symbol expression
*/
template ExprType (alias symbol)
{
	 alias ExprType = typeof(symbol.identity);
}

/* remove qualifiers from a type
*/
alias Unqual = std.traits.Unqual;

/* extract the underlying type of a unary template type
*/
template Unwrapped (T)
{
	static if (is (T == W!U, alias W, U))
		alias Unwrapped = U;
	else alias Unwrapped = T;
}
unittest {
	static struct T {}
	static struct U (T) {}

	alias V = U!T;
	alias W = U!(U!T);

	static assert (is (Unwrapped!T == T));
	static assert (is (Unwrapped!V == T));
	static assert (is (Unwrapped!W == V));
	static assert (is (Unwrapped!(Unwrapped!W) == T));
}

/* extract the deepest underlying type of a nested series of unary templates
*/
template InitialType (T)
{
	static if (is (T == W!U, alias W, U))
		alias InitialType = InitialType!U;
	else alias InitialType = T;
}
unittest {
	static struct T {}
	static struct U (T) {}

	alias V = U!T;
	alias W = U!(U!T);

	static assert (is (InitialType!T == T));
	static assert (is (InitialType!V == T));
	static assert (is (InitialType!W == T));
}

/* compose a list of templates into a single template
*/
template Compose (Templates...)
{
	static if (Templates.length > 1)
	{
		alias T = Templates[0];
		alias U = Compose!(Templates[1..$]);

		alias Compose (Args...) = T!(U!(Args));
	}
	else alias Compose = Templates[0];
}
unittest {
	import std.range: ElementType;

	alias ArrayOf (T) = T[];
	alias Const (T) = const(T);

	alias C0 = Compose!(ElementType, ArrayOf);
	alias C1 = Compose!(ArrayOf, ElementType);
	alias C2 = Compose!(ElementType, Const, C0);
	alias C3 = Compose!(ArrayOf, Unqual, C2);

	alias T = int[5];

	static assert (is (C0!T == int[5]));
	static assert (is (C1!T == int[]));
	static assert (is (C2!T == const(int)));
	static assert (is (C3!T == int[]));
}

/* mixin a zero-parameter template
	(useful for mixing in templates from a list)
*/
template Mixin (alias mix)
{
	mixin mix;
}
