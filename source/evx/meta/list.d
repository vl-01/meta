module evx.meta.list;

private {//imports
	import std.typetuple;
	import std.typecons;

	import evx.meta.predicate;
}

/**
    construct a list, which automatically flattens
*/
alias Cons (T...) = T;

/**
    generate a sequence of contiguous natural numbers
*/
alias Iota (size_t n) = staticIota!(0,n);
/**
    ditto
*/
alias Iota (size_t l, size_t r) = staticIota!(l,r);
///
unittest {
    static assert (Iota!4 == Cons!(0,1,2,3));
    static assert (Iota!(2,6) == Cons!(2,3,4,5));
}

/**
    repeat an argument a given number of times
*/
alias Repeat (size_t n, T...) = Cons!(T, Repeat!(n-1, T));
/**
    ditto
*/
alias Repeat (size_t n : 0, T...) = Cons!();
///
unittest {
    static assert (Repeat!(4, 1) == Cons!(1,1,1,1));
    static assert (is (Repeat!(3, int, char) == Cons!(int, char, int, char, int, char)));
}

/** 
    reverse the order of a list
*/
alias Reverse = std.typetuple.Reverse;
///
unittest {
    static assert (Reverse!(1,2,3) == Cons!(3,2,1));
}

/**
    swap the two elements in a compile-time list indexed by i and j
*/
template Swap (uint i, uint j, T...)
{
    import std.algorithm: min, max;

    enum a = min (i,j);
    enum b = max (i,j);

    alias Swap = Cons!(T[0..a], T[b], T[a+1..b], T[a], T[b+1..$]);
}
///
unittest {
    static assert (is (Swap!(0,3, int, bool, char, byte) == Cons!(byte, bool, char, int)));
    static assert (Swap!(0,3, 0,1,2,3) == Cons!(3,1,2,0));
}

////
/**
    map a template over a list
*/
template Map (alias F, T...)
{
	static if (T.length == 0)
	{
		alias Map = Cons!();
	}
	else
	{
		alias Map = Cons!(F!(Unpack!(T[0])), Map!(F, T[1..$]));
	}
}
///
unittest {
    alias ArrayOf (T) = T[];

    static assert (is (Map!(ArrayOf, int, char, string) == Cons!(int[], char[], string[])));
    static assert (Map!(Iota, 1, 2, 3) == Cons!(0, 0,1, 0,1,2));
}

/**
    map each element of a list to its position in the list
*/
alias Ordinal (T...) = Iota!(T.length);
///
unittest {
    static assert (Ordinal!(Cons!(int, char, string)) == Cons!(0,1,2));
}

/**
    pair each element's position in the list with the element
*/
alias Enumerate (T...) = Zip!(Pack!(Ordinal!T), Pack!T);
///
unittest {
    static assert (is (Enumerate!('a', 'b', 'c') == Cons!(Pack!(0, 'a'), Pack!(1, 'b'), Pack!(2, 'c'))));
}

/**
    sort a list by <
*/
template Sort (T...)
{
	alias less_than (T...) = First!(T[0] < T[1]);

	alias Sort = SortBy!(less_than, T);
}
///
unittest {
	static assert (Sort!(5,4,2,7,4,3,1) == Cons!(1,2,3,4,4,5,7));
}
/** sort a list by a custom comparison
*/
template SortBy (alias compare, T...)
{
	static if (T.length > 1)
	{
		alias Remaining = Cons!(T[0..$/2], T[$/2 +1..$]);
		enum is_before (U...) = compare!(U[0], T[$/2]);

		alias SortBy = Cons!(
			SortBy!(compare, Filter!(is_before, Remaining)),
			T[$/2],
			SortBy!(compare, Filter!(Not!is_before, Remaining)),
		);
	}
	else alias SortBy = T;
}
///
unittest {
	static assert (is (
        SortBy!(λ!q{(T,U) = T.sizeof < U.sizeof},
            int, char, long, short
        ) == Cons!(
            char, short, int, long
        )
    ));
}

////
/**
    evaluates true if all items in the list satisfy the condition
*/
template All (alias cond, T...)
{
	static if (T.length == 0)
	{
		enum All = true;
	}
	else
	{
		enum All = cond!(Unpack!(T[0])) && All!(cond, T[1..$]);
	}
}
///
unittest {
    import std.traits : isIntegral;

    static assert (All!(isIntegral, int, long, short));
    static assert (not (All!(isIntegral, int, float, short)));
}

/**
    evaluates true if any items in the list satisfy the condition
*/
template Any (alias cond, T...)
{
	static if (T.length == 0)
	{
		enum Any = false;
	}
	else
	{
		enum Any = cond!(Unpack!(T[0])) || Any!(cond, T[1..$]);
	}
}
///
unittest {
    import std.traits : isIntegral;

    static assert (Any!(isIntegral, float, long, string));
    static assert (not (Any!(isIntegral, string, float, void)));
}

/**
    from a given list, produce a new list containing only items which satisfy a condition
*/
template Filter (alias cond, T...)
{
	static if (T.length == 0)
	{
		alias Filter = Cons!();
	}
	else
	{
		static if (cond!(Unpack!(T[0])))
			alias Filter = Cons!(T[0], Filter!(cond, T[1..$]));
		else alias Filter = Filter!(cond, T[1..$]);
	}
}
///
unittest {
    import std.traits: isIntegral;

    static assert (is (Filter!(isIntegral, float, int, string, short) == Cons!(int, short)));
}

/** from a given list, produce a new list containing only unique items
*/
alias NoDuplicates = std.typetuple.NoDuplicates;
///
unittest {
    static assert (is (NoDuplicates!(int, char, int, string, int) == Cons!(int, char, string)));
}

/** reduce a list to a single item using a binary template
*/
template Reduce (alias f, T...)
{
	static if (T.length == 2)
		alias Reduce = f!T;
	else 
		alias Reduce = f!(T[0], Reduce!(f, T[1..$]));
}
///
unittest {
    import std.traits: Select;

    alias Smallest (T,U) = Select!(T.sizeof < U.sizeof, T, U);

    static assert (is (Reduce!(Smallest, int, short, double, byte, string) == byte));
}

/** from a given list, produce a list of all partial reductions, sweeping from left to right
*/
template Scan (alias f, T...)
{
	template Sweep (size_t i)
	{
		static if (i == 0)
			alias Sweep = Cons!(T[i]);
		else
			alias Sweep = Reduce!(f, T[0..i+1]);
	}

	alias Scan = Map!(Sweep, Ordinal!T);
}
///
unittest {
	static assert (Scan!(Sum, 0,1,2,3,4,5) == Cons!(0,1,3,6,10,15));
}

/**
    sum a list
*/
alias Sum (T...) = Reduce!(λ!q{(long a, long b) = a + b}, T);
///
unittest {
	static assert (Sum!(0,1,2,3,4,5) == 15);
}

////
/**
    find the index of the first occurence of an item in a list, or -1
*/
alias IndexOf = staticIndexOf;
///
unittest {
    static assert (IndexOf!(2, 1,2,3) == 1);
}

/**
    evaluates true if a list contains a given item
*/
enum Contains (T...) = IndexOf!(T[0], T[1..$]) > -1;
///
unittest {
    static assert (Contains!(1, 0,1,2,3));
    static assert (not (Contains!(1, 7,8,9,'A')));
}

////
/**
    from a list of n packs of length m, produce a list of m packs of length n
*/
template Zip (Packs...)
{
	enum n = Packs.length;
	enum length = Packs[0].length;

	enum CheckLength (uint i) = Packs[i].length == Packs[0].length;

	static assert (All!(Map!(CheckLength, Iota!n)));

	template ToPack (uint i)
	{
		alias ExtractAt (uint j) = Cons!(Packs[j].Unpack[i]);

		alias ToPack = Pack!(Map!(ExtractAt, Iota!n));
	}

	alias Zip = Map!(ToPack, Iota!length);
}
///
unittest {
    static assert (is (
        Zip!(
            Pack!(  0,  1,  2 ),
            Pack!( 'a','b','c' ),
        ) == Cons!(
            Pack!( 0, 'a' ),
            Pack!( 1, 'b' ), 
            Pack!( 2, 'c' )
        )
    ));
    
    // Map and Filter automatically unpack Packs before passing them through to predicates
    enum Binary (T,U) = T.stringof ~ U.stringof;

    static assert (
        Map!(Binary, Zip!(
            Pack!( int, string, char ),
            Pack!( string, int, char ),
        )) == Cons!(
            `intstring`, `stringint`, `charchar`
        )
    );

    enum binary (T,U) = is (T == U);

    static assert (is (
        Filter!(binary,
            Zip!(
                Pack!( int, string, char ),
                Pack!( int, string, bool ),
            )
        ) == Cons!(
            Pack!(int, int),
            Pack!(string, string)
        )
    ));
}

/**
    a pack is a list which doesn't automatically flatten
*/
struct Pack (T...)
{
	alias Unpack = T;
	alias Unpack this;
	enum length = T.length;
}
///
unittest {
    static assert (
        Cons!(
            Cons!(1,2), Cons!(3)
        )
        == Cons!(1,2,3)
    );

    static assert (is (
        Pack!(
            Pack!(1,2), Pack!(3)
        )
        == Pack!(
            Pack!(1,2), Pack!(3)
        )
    ));
}

/**
    unpack a packed list, and pass non-pack parameters through unmodified
*/
template Unpack (T...)
{
	static if (is (T[0] == Pack!U, U...))
		alias Unpack = Cons!(T[0].Unpack);
	else
		alias Unpack = T;
}
///
unittest {
    static assert (Unpack!(Pack!(1,2)) == Cons!(1,2));
    static assert (Unpack!(1,2) == Cons!(1,2));
}

/**
    get the first element of a list
*/
template First (T...)
{
	static if (is (typeof((){enum U = T[0];})))
		enum First = T[0];
	else 
		alias First = T[0];
}
///
unittest {
    static assert (First!('a', 'b', 'c') == 'a');
}

/**
    get the second element of a list
*/
template Second (T...)
{
	static if (is (typeof((){enum U = T[1];})))
		enum Second = T[1];
	else
		alias Second = T[1];
}
///
unittest {
    static assert (Second!('a', 'b', 'c') == 'b');
}

/**
    split a list into n-lists and interleave their items into a new list
*/
template InterleaveNLists (uint n, T...)
if (T.length % n == 0)
{
	template Group (uint i)
	{
		alias Item (uint j) = Cons!(T[($/n)*j + i]);

		alias Group = Map!(Item, Iota!n);
	}

	alias InterleaveNLists = Map!(Group, Iota!(T.length/n));
}
///
unittest {
	static assert (InterleaveNLists!(2, 0,1,2,3,4,5) == Cons!(0,3,1,4,2,5));
	static assert (InterleaveNLists!(3, 0,1,2,3,4,5) == Cons!(0,2,4,1,3,5));
}

/**
    partition a list into equivalence classes of each element's order modulo n
*/
alias DeinterleaveNLists (uint n, T...) = InterleaveNLists!(T.length/n, T);
///
unittest {
	static assert (DeinterleaveNLists!(2, 0,3,1,4,2,5) == Cons!(0,1,2,3,4,5));
	static assert (DeinterleaveNLists!(3, 0,2,4,1,3,5) == Cons!(0,1,2,3,4,5));
}

/**
    shorthand for (de)interleaving templates
*/
alias Interleave (T...) = InterleaveNLists!(2,T);
/**
    ditto
*/
alias Deinterleave (T...) = DeinterleaveNLists!(2,T);

/**
    map each item in a list to the given member in each item
*/
template Extract (string member, T...)
{
	static if (T.length == 0)
		alias Extract = Cons!();
	else mixin(q{
		alias Extract = Cons!(T[0].}~(member)~q{, Extract!(member, T[1..$]));
	});
}
///
unittest {
    static assert (Extract!(`sizeof`, byte, short, int, long) == Cons!(1,2,4,8));
}

/**
    get all items in a list of zero-parameter templates which successfully compiles
*/
template MatchAll (patterns...)
{
	template compiles (alias pattern)
	{
		void attempt ()()
		{
			alias attempt = pattern!();
		}

		enum compiles = is (typeof(attempt ()));
	}

	alias MatchAll = Filter!(compiles, patterns);
}
///
unittest {
    void a ()() {NONSENSE;}
    byte b ()() {return 0;}
    char c ()() {}
    long d ()() {int x; ++x; return x;}

    static assert (MatchAll!(a,b,c,d).stringof == q{tuple(b()(), d()())});
}
