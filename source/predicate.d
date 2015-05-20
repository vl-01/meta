module meta.predicate;

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
	{/*...}*/
		bool not (T)(T value)
			{/*...}*/
				return !value;
			}
	}
template not (alias predicate)
	{/*...}*/
		bool not (Args...)(Args args)
			if (is(typeof(predicate (args) == true)))
			{/*...}*/
				return !(predicate (args));
			}

		bool not (Args...)()
			if (is(typeof(predicate == true)))
			{/*...}*/
				return !predicate;
			}

		bool not (Args...)()
			if (__traits(compiles, {enum x = predicate!Args;}))
			{/*...}*/
				return !(predicate!Args);
			}
	}
