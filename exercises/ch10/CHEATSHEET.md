# Chapter 10 cheat sheet: More Operators

## Header

- Chapter number: `10`
- Chapter title: `More Operators`
- learntla-v2 clone SHA: `09840bfc2ee9a88cdbedb672be77a6c73942fe16`

## Constructs introduced

- Construct: `RECURSIVE`
  Syntax shape: `RECURSIVE Op(_)` before `Op(x) == ...`, lets `Op` reference itself
  Section anchor: `advanced-operators#recursive`

- Construct: `Higher-order operator parameter`
  Syntax shape: `Name(Op(_), arg) == ... Op(x) ...`, takes another operator as an argument
  Section anchor: `advanced-operators § Higher-order Operators`

- Construct: `LAMBDA`
  Syntax shape: `LAMBDA x: expr`, builds an anonymous operator inline
  Section anchor: `advanced-operators § Higher-order Operators`

- Construct: `Custom binary operator`
  Syntax shape: `a ++ b == expr`, defines a new infix operator from TLA+'s fixed symbol set
  Section anchor: `advanced-operators § Binary operators`

- Construct: `Bracket function definition`
  Syntax shape: `Name[x \in S] == expr`, sugar for `Name == [x \in S |-> expr]`
  Section anchor: `advanced-operators § Function Operators`

- Construct: `Recursive function definition`
  Syntax shape: `Name[x \in S] == expr` where `expr` calls `Name` again, no `RECURSIVE` keyword needed
  Section anchor: `advanced-operators § Function Operators`

- Construct: `CASE`
  Syntax shape: `CASE cond1 -> val1 [] cond2 -> val2 [] OTHER -> valN`
  Section anchor: `advanced-operators#CASE`

## Major themes

- Recursive operators need an explicit `RECURSIVE` declaration up front before they can call themselves. There is no built in check that the recursion ends, so an unbounded call chain crashes TLC with a stack overflow.
- Recursion on a set needs `CHOOSE` to pick one element to peel off. That choice is deterministic, TLC always picks the lowest value when several elements satisfy the predicate, so an order sensitive result needs a unique selection predicate instead.
- Higher-order operators take another operator as a parameter, written `Op(_)`, and `LAMBDA` builds a quick anonymous one instead of naming it separately. The two features do not combine, an operator cannot be both recursive and higher-order.
- TLA+ only lets you define new operators using its fixed set of built in symbols, like `++` or `--`, not arbitrary names. The chapter treats this as a feature to use sparingly, since it can make a spec harder to read.
- Functions can be defined directly with `Name[x \in S] == expr`. This bracket form supports recursion on its own with no `RECURSIVE` keyword required, unlike operator recursion.
- `CASE` picks a branch by testing conditions in order, similar in spirit to a chain of `IF-THEN-ELSE`. It raises an error at check time if nothing matches and there is no `OTHER` clause, and picks the first match if more than one condition is true.

## Boundary notes

- `CHOOSE` itself is covered in chapter `02` instead. This chapter only uses it, to pick a single element out of a set during recursion.
- Function literal syntax (`[x \in S |-> expr]`) and structs are covered in chapter `06` instead. This chapter only adds the named bracket-definition sugar on top of it.
- `IF-THEN-ELSE`, the two branch conditional that `CASE` generalizes to many branches, is covered in chapter `02` instead.
