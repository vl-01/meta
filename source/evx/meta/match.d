module evx.meta.match;

/** 
    instantiate a template alias with a set of arguments
*/
alias Instantiate (alias symbol, Args...) = symbol!Args;
///
unittest {
    struct T (uint i, uint j, uint k){}

    static assert (is (Instantiate!(T, 1,2,3) == T!(1,2,3)));
}

/**
    get the first item in a list of zero-parameter templates (patterns) which successfully compiles
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
///
unittest {
    byte a ()() {return NOT_EXISTS;}
    long b ()() {}
    bool c ()() {return true;}

    static assert (is (typeof(Match!(a,b,c)()) == bool));
}
