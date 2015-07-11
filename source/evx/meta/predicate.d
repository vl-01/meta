module evx.meta.predicate;

private {//imports
	import std.typetuple: templateAnd, templateOr;
    import std.functional: compose, adjoin;
    import std.algorithm: all, any;
}

/** 
    string-mixin-based anonymous templates.
    mixing this in allows the λ/Λ definitions reference symbols in the mixed-in scope
*/
template LambdaCapture ()
{
    /**
        Λ is an alias
    */
	static template Λ (string op)
	{
		mixin(q{
			alias Λ } ~ op ~ q{;
		});
	}
    /**
        λ is an enum
    */
	static template λ (string op)
	{
		mixin(q{
			enum λ } ~ op ~ q{;
		});
	}
}
///
unittest {
    import std.typetuple: Map = staticMap, Cons = TypeTuple;

    static assert (
        Map!(λ!q{(T) = T.sizeof},
            int, bool, long
        ) == Cons!(
            4,1,8
        )
    );
    static assert (is (
        Map!(Λ!q{(T) = T[]},
            int, bool, long
        ) == Cons!(
            int[], bool[], long[]
        )
    ));
}

/* mixin captures local symbols
*/
mixin LambdaCapture;

/** 
    combine several template predicates with a logical conjunctive
*/
alias And = templateAnd;
/**
    ditto
*/
alias Or  = templateOr;

/**
    invert a template predicate
*/
static template Not (alias predicate)
{
	enum Not (Args...) = !predicate!Args;
}

/**
    named logical not operator (!),
    runtime predicate inversion,
    and boolean symbol inversion
*/
template not ()
{
	bool not (T)(T value)
	{
		return !value;
	}
}
/**
    ditto
*/
template not (alias predicate)
{
	bool not (Args...)(Args args)
	if (is(typeof(predicate (args) == true)))
	{
		return !(predicate (args));
	}

	bool not (Args...)()
	if (is(typeof(predicate == true)) && !(is(typeof(predicate(Args.init)))))
	{
		return !predicate;
	}

	bool not (Args...)()
	if (__traits(compiles, {enum x = predicate!Args;}))
	{
		return !(predicate!Args);
	}
}
///
unittest {
    assert (not (false));
    assert (not!false);

    auto a = false;

    assert (not (a));
    assert (not!a);

    enum b = false;
    assert (not (b));
    assert (not!b);

    auto c () {return false;}

    assert (not (c));
    assert (not!c);

    auto d (int x){return x == 1;}

    assert (not (d(0)));
    assert (not!d (0));

    alias e = not!d;

    assert (e(0));
    assert (not!e (1));

    assert (not!(x => x % 2 == 0)(1));
}

template funcs_to_list (funcs...)
{
    import std.range: only;

    alias funcs_to_list = compose!(result => result.expand.only, adjoin!funcs);
}

/**
    combine several runtime predicates with a logical conjunctive
*/
alias and (funcs...) = compose!(all, funcs_to_list!funcs);
/**
    ditto
*/
alias or  (funcs...) = compose!(any, funcs_to_list!funcs);
///
unittest {
    static f (int x){return x > 5;}
    static g (int x){return x < 10;}
    static h (int x){return x == 7;}

    alias q = and!(f,g,h);
    alias p = or!(f,g,h);

    assert (q(5) == false);
    assert (q(6) == false);
    assert (q(7) == true);
    assert (q(10) == false);

    assert (p(5) == true);
    assert (p(6) == true);
    assert (p(7) == true);
    assert (p(10) == true);
}
