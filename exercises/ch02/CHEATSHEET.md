# Chapter 02 cheat sheet: Operators and Values

## Header

- Chapter number: `02`
- Chapter title: `Operators and Values`
- learntla-v2 clone SHA: `09840bfc2ee9a88cdbedb672be77a6c73942fe16`

## Constructs introduced

- Construct: `Operator definition`
  Syntax shape: `Name(a, b) == expr` (or `Name == expr` with no arguments)
  Section anchor: `operators § Operators`

- Construct: `IF-THEN-ELSE`
  Syntax shape: `IF cond THEN a ELSE b`
  Section anchor: `operators#if_tla`

- Construct: `Equality and inequality`
  Syntax shape: `a = b`, `a # b`
  Section anchor: `operators § Values`

- Construct: `EXTENDS (module import)`
  Syntax shape: `EXTENDS Integers, Sequences`
  Section anchor: `operators#integer`

- Construct: `Integers`
  Syntax shape: `123`, `-4`, needs `EXTENDS Integers` for arithmetic
  Section anchor: `operators#integer`

- Construct: `Strings`
  Syntax shape: `"double quoted text"`
  Section anchor: `operators#string`

- Construct: `Booleans and logical operators`
  Syntax shape: `TRUE`, `FALSE`, `/\` (and), `\/` (or), `~` (not)
  Section anchor: `operators#boolean`

- Construct: `Bullet-point boolean notation`
  Syntax shape: stacked `/\` / `\/` lines, indentation is meaningful
  Section anchor: `operators#boolean`

- Construct: `Implication`
  Syntax shape: `A => B`
  Section anchor: `operators#=>`

- Construct: `Sequences`
  Syntax shape: `<<a, b, c>>`, indexed with `seq[n]`, 1-indexed
  Section anchor: `operators § Sequences`

- Construct: `Sequence module operators`
  Syntax shape: `Append(S, x)`, `Head(S)`, `Tail(S)`, `Len(S)`, `SubSeq(S, i, j)`, `S \o T`, needs `EXTENDS Sequences`
  Section anchor: `operators § Sequences`

- Construct: `Sets`
  Syntax shape: `{1, 2, 3}`, unordered and unique
  Section anchor: `operators § Sets`

- Construct: `Set relational and algebraic operators`
  Syntax shape: `x \in set`, `x \notin set`, `s1 \subseteq s2`, `s1 \union s2`, `s1 \intersect s2`, `s1 \ s2`
  Section anchor: `operators#set_operators`

- Construct: `Cardinality`
  Syntax shape: `Cardinality(set)`, needs `EXTENDS FiniteSets`
  Section anchor: `operators#Cardinality`

- Construct: `BOOLEAN and integer interval as sets`
  Syntax shape: `BOOLEAN`, `a..b`
  Section anchor: `operators#sets_of_values`

- Construct: `Cartesian product`
  Syntax shape: `S \X T`
  Section anchor: `operators#\X`

- Construct: `SUBSET (powerset)`
  Syntax shape: `SUBSET S`
  Section anchor: `operators#SUBSET`

- Construct: `Set map`
  Syntax shape: `{expr: x \in S}`
  Section anchor: `operators#map`

- Construct: `Set filter`
  Syntax shape: `{x \in S: P(x)}`
  Section anchor: `operators#filter`

- Construct: `CHOOSE`
  Syntax shape: `CHOOSE x \in S: P(x)`
  Section anchor: `operators#CHOOSE`

- Construct: `LET-IN`
  Syntax shape: `LET x == expr IN body`, can define several suboperators at once
  Section anchor: `operators#LET`

## Major themes

- Operators are defined with `==`, take a fixed number of arguments, and use `IF-THEN-ELSE` and `LET-IN` to structure the logic inside them.
- Boolean logic uses math style symbols (`/\`, `\/`, `~`, `=>`) instead of programming keywords, plus a bullet-point layout for nested conditions.
- TLA+ is untyped, but the checker still recognizes primitive types like integers, strings, and booleans. `=` and `#` are the only operators that work across types, and most other operators need an `EXTENDS` line first.
- Sequences are ordered, 1-indexed value lists, with a small module of helper operators (`Append`, `Head`, `Tail`, `Len`, `SubSeq`, `\o`).
- Sets are unordered collections of unique values, with membership, subset, and algebraic operators, plus a way to generate the full set of values for every type (`a..b`, `BOOLEAN`, `S \X T`, `SUBSET S`).
- `CHOOSE`, map, and filter let you pull or transform values out of a set instead of constructing a result by hand.

## Boundary notes

- `Higher-order operators, recursive operators, and lambdas` is covered in chapter `10` instead.
- `Model values` is covered in chapter `5` instead.
- `Structures and functions` is covered in chapter `6` instead.
- `Invariants` is covered in chapter `4` instead.
- `PlusCal algorithm syntax and state updates` is covered in chapter `3` instead.
- `Running specs and the scratch file setup` is covered in chapter `1` instead.
- `LOCAL, INSTANCE, and the named and parameterized instance forms, the other ways to import a module` is covered in chapter `13` instead.
