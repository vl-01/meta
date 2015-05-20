module evx.meta.match;

/* get the first item in a list of zero-parameter templates (patterns) which successfully compiles
	if all patterns fail, the final pattern is forcibly instantiated
	thus it can be useful to have a fallback or diagnostic in the final position
*/
template Match (patterns...)
	{/*...}*/
		alias Instantiate (alias symbol, Args...) = symbol!Args;

		static if (__traits(compiles, Instantiate!(patterns[0])))
			alias Match = Instantiate!(patterns[0]);
		else static if (patterns.length == 1)
			{pragma(msg, Instantiate!(patterns[$-1]));}
		else alias Match = Match!(patterns[1..$]);
	}
