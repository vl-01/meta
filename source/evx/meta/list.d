module evx.meta.list;

private {//imports
	import std.typetuple;
	import std.typecons;

	import evx.meta.predicate;
}

/* construct a list, which automatically flattens
*/
alias Cons = TypeTuple;

/* generate a sequence of contiguous natural numbers
*/
alias Iota (size_t n) = staticIota!(0,n);
alias Iota (size_t l, size_t r) = staticIota!(l,r);

/* repeat an argument a given number of times
*/
alias Repeat (size_t n, T...) = Cons!(T, Repeat!(n-1, T));
alias Repeat (size_t n : 0, T...) = Cons!();

/* reverse the order of a list
*/
alias Reverse = std.typetuple.Reverse;

////
/* map a template over a list
*/
template Map (alias F, T...)
{
	static if (T.length == 0)
	{/*...}*/
		alias Map = Cons!();
	}
	else
	{/*...}*/
		alias Map = Cons!(F!(Unpack!(T[0])), Map!(F, T[1..$]));
	}
}

/* map each element of a list to its position in the list
*/
alias Ordinal (T...) = Iota!(T.length);

/* pair each element's position in the list with the element
*/
alias Enumerate (T...) = Zip!(Pack!(Ordinal!T), Pack!T);

/* sort a list by <
*/
template Sort (T...)
{
	alias less_than (T...) = First!(T[0] < T[1]);

	alias Sort = SortBy!(less_than, T);
}
/* sort a list by a custom comparison
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
unittest {
	static assert (SortBy!(λ!q{(T...) = T[0] < T[1]}, 5,4,2,7,4,3,1) == Cons!(1,2,3,4,4,5,7));
	static assert (Sort!(5,4,2,7,4,3,1) == Cons!(1,2,3,4,4,5,7));
}

////
/* evaluates true if all items in the list satisfy the condition
*/
template All (alias cond, T...)
{
	static if (T.length == 0)
	{/*...}*/
		enum All = true;
	}
	else
	{
		enum All = cond!(Unpack!(T[0])) && All!(cond, T[1..$]);
	}
}
/* evaluates true if any items in the list satisfy the condition
*/
template Any (alias cond, T...)
{
	static if (T.length == 0)
	{
		enum Any = false;
	}
	else
	{/*...}*/
		enum Any = cond!(Unpack!(T[0])) || Any!(cond, T[1..$]);
	}
}

/* from a given list, produce a new list containing only items which satisfy a condition
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

/* from a given list, produce a new list containing only unique items
*/
alias NoDuplicates = std.typetuple.NoDuplicates;

/* reduce a list to a single item using a binary template
*/
template Reduce (alias f, T...)
{
	static if (T.length == 2)
		alias Reduce = f!T;
	else 
		alias Reduce = f!(T[0], Reduce!(f, T[1..$]));
}

/* from a given list, produce a list of all partial reductions, sweeping from left to right
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
unittest {
	static assert (Scan!(Sum, 0,1,2,3,4,5) == Cons!(0,1,3,6,10,15));
}

/* sum a list
*/
alias Sum (T...) = Reduce!(λ!q{(long a, long b) = a + b}, T);
unittest {
	static assert (Sum!(0,1,2,3,4,5) == 15);
}

////
/* find the index of the first occurence of an item in a list, or -1
*/
alias IndexOf = staticIndexOf;

/* evaluates true if a list contains a given item
*/
enum Contains (T...) = IndexOf!(T[0], T[1..$]) > -1;

////
/* from a list of n packs of length m, produce a list of m packs of length n
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

/* a pack is a list which doesn't automatically flatten
*/
struct Pack (T...)
{
	alias Unpack = T;
	alias Unpack this;
	enum length = T.length;
}

/* unpack a packed list, and pass non-pack parameters through unmodified
*/
template Unpack (T...)
{
	static if (is (T[0] == Pack!U, U...))
		alias Unpack = Cons!(T[0].Unpack);
	else
		alias Unpack = T;
}

/* get the first element of a list
*/
template First (T...)
{
	static if (is (typeof((){enum U = T[0];})))
		enum First = T[0];
	else 
		alias First = T[0];
}
/* get the second element of a list
*/
template Second (T...)
{
	static if (is (typeof((){enum U = T[1];})))
		enum Second = T[1];
	else
		alias Second = T[1];
}

/* split a list into n-lists and interleave their items into a new list
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
unittest {
	static assert (InterleaveNLists!(2, 0,1,2,3,4,5) == Cons!(0,3,1,4,2,5));
	static assert (InterleaveNLists!(3, 0,1,2,3,4,5) == Cons!(0,2,4,1,3,5));
}

/* partition a list into equivalence classes of each element's order modulo n
*/
alias DeinterleaveNLists (uint n, T...) = InterleaveNLists!(T.length/n, T);
unittest {
	static assert (DeinterleaveNLists!(2, 0,3,1,4,2,5) == Cons!(0,1,2,3,4,5));
	static assert (DeinterleaveNLists!(3, 0,2,4,1,3,5) == Cons!(0,1,2,3,4,5));
}

/* shorthand for (de)interleaving templates
*/
alias Interleave (T...) = InterleaveNLists!(2,T);
alias Deinterleave (T...) = DeinterleaveNLists!(2,T);

/* map each item in a list to the given member in each item
*/
template Lens (string member, T...)
{
			static if (T.length == 0)
				alias Lens = Cons!();
			else mixin(q{
				alias Lens = Cons!(T[0].} ~member~ q{, Lens!(member, T[1..$]));
			});
		}

/* get all items in a list of zero-parameter templates which successfully compiles
*/
template MatchAll (patterns...)
{
	template compiles (alias pattern)
	{
		void attempt ()()
		{
			alias attempt = Instantiate!pattern;
		}

		enum compiles = is (typeof(attempt));
	}

	alias MatchAll = Filter!(compiles, patterns);
}
