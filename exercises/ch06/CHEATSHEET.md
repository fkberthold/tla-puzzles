# Cheat sheet: Structured Data

## Header

- Chapter number: `06`
- Chapter title: `Structured Data`
- learntla-v2 clone SHA: `09840bfc2ee9a88cdbedb672be77a6c73942fe16`

## Constructs introduced

- Construct: `struct literal`
  Syntax shape: `struct == [a |-> 1, b |-> 2]`, read with `struct["a"]` or `struct.a`
  Section anchor: `functions#struct`

- Construct: `struct set`
  Syntax shape: `Type == [acct: Accounts, amnt: 1..10, type: {"deposit", "withdraw"}]`
  Section anchor: `functions#struct_set`

- Construct: `DOMAIN`
  Syntax shape: `DOMAIN f` is the set of keys, indices, or inputs of `f`
  Section anchor: `functions#DOMAIN`

- Construct: `function literal`
  Syntax shape: `F == [x \in S |-> expr]`, called with `F[x]`
  Section anchor: `functions#function`

- Construct: `:> (singleton function)`
  Syntax shape: `a :> b` is the one element function `[x \in {a} |-> b]`
  Section anchor: `functions#function`

- Construct: `@@ (function merge)`
  Syntax shape: `f @@ g` merges `f` and `g`, keeping `f`'s value on a shared key
  Section anchor: `functions#function`

- Construct: `function set`
  Syntax shape: `[S -> T]` is the set of all functions from `S` to `T`
  Section anchor: `functions#function_set`

## Major themes

- Structs are functions from string keys to values. `[a |-> 1, b |-> 2]` builds one, `struct.a` or `struct["a"]` reads one, and `[key: set, ...]` builds the set of them for a type invariant.
- `DOMAIN` is the one operation that works on sequences, structs, and functions alike. It is the reveal of the chapter. Sequences and structs both turn out to be functions, sequences over `1..n` and structs over a set of strings.
- A function literal `[x \in S |-> expr]` maps `S` to values of `expr`, called with `f[x]`. It reaches past single argument mappings too, `[x, y \in S |-> expr]` and `f[a, b]` both work.
- Function sets `[S -> T]` type a function the way `1..10` types a number. They can be built from filtered or mapped sets to narrow the type further, and their size is `#T` to the power of `#S`.
- `:>` and `@@` build and merge functions piece by piece, without writing a set comprehension.
- The chapter closes on worked examples that put functions to use. `Zip`, `Sort` (via `CHOOSE` over a function set), and a rewrite of the duplicate checker that swaps a hardcoded `\X` chain for a function set, which is what lets its sequence length become a constant (state sweeping).

## Boundary notes

- Model values, like `Accounts` or `NULL`, appear here already in use (`Accounts is a set of model values`, `NULL is a model value`) but are defined in chapter 5.
- Declaring a new `CONSTANT`, such as the `Size` that lets the duplicate checker's sequence length vary, is covered in chapter 5. This chapter only uses constants already declared.
- Nondeterministic selection from a set, `with x \in Set` and `either`/`or`, is covered in chapter 7. This chapter's `CHOOSE x \in S: P(x)` looks similar but is deterministic, it always returns the same value for the same set and predicate.
