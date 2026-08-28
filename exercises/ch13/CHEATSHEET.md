# Chapter 13 cheat sheet: Modules

## Header

- Chapter number: `13`
- Chapter title: `Modules`
- learntla-v2 clone SHA: `09840bfc2ee9a88cdbedb672be77a6c73942fe16`

## Constructs introduced

- Construct: `LOCAL` (definition modifier)
  Syntax shape: `LOCAL Op == "definition"`, keeps `Op` out of any spec that extends this module
  Section anchor: `modules § EXTENDS`

- Construct: `INSTANCE`
  Syntax shape: `INSTANCE Sequences` on a line of its own, drops the module into the file namespace
  Section anchor: `modules#INSTANCE`

- Construct: `LOCAL INSTANCE`
  Syntax shape: `LOCAL INSTANCE Integers`, the module is available here but its operators are not passed on to a spec that imports this one
  Section anchor: `modules#INSTANCE`

- Construct: named instance
  Syntax shape: `Foo == INSTANCE Sequences`, binds the module to a name instead of the file namespace
  Section anchor: `modules § Namespacing`

- Construct: `!` (namespace lookup)
  Syntax shape: `Foo!Append(seq, 1)` in place of `Append(seq, 1)`
  Section anchor: `modules § Namespacing`

- Construct: `INSTANCE ... WITH` (`<-` constant substitution)
  Syntax shape: `Origin == INSTANCE Point WITH X <- 0, Y <- 0`, supplies the imported module's constants
  Section anchor: `modules#with_tla`

- Construct: partial parameterization
  Syntax shape: `XAxis(X) == INSTANCE Point WITH Y <- 0`, then called as `XAxis(2)!Add(x, y)`
  Section anchor: `modules § Partial Parameterization`

## Major themes

- Modules matter less for specs than they do for code. The chapter comes last for that reason, since most specs run under about 300 lines and sit in one file without trouble. An abstract library like `LinkedLists`, or invariants kept in their own file, are the cases that pay for a split.
- Shared TLA+ files belong in the same folder as the spec that uses them. The toolbox can also read modules from one shared directory, set under TLA+ Preferences.
- `EXTENDS` and `INSTANCE` both drop a module into the file namespace, so the whole chapter is about the ways they differ. A spec gets one `EXTENDS` line and as many `INSTANCE` lines as it likes, and only `INSTANCE` can be made local, named, or parameterized.
- `LOCAL` marks a definition as private to its module. `LOCAL INSTANCE` marks a whole import that way, so the imported operators stop at this module instead of travelling on to whoever imports it. `Sequences.tla` uses the second form on `Naturals`.
- Namespacing is what makes `INSTANCE` worth the trouble. `Foo == INSTANCE Sequences` keeps the operators behind `Foo!`, an instance can be bound inside a `LET`, and one module can be instantiated twice under two names.
- Two names for one module only earns its keep once the module has constants. `WITH` rewrites the imported operators to use the values you pass, so `Origin!Add(x, y)` comes out as `<<0 + x, 0 + y>>`. A constant the two modules share by name is passed through by default, and a `WITH` clause overrides that.
- Partial parameterization leaves a constant open and takes it at the call site. `XAxis(X) == INSTANCE Point WITH Y <- 0` turns the instance itself into an operator, called as `XAxis(2)!Add(x, y)`.
- The chapter is unfinished in places, and an exercise author should know where. Three `.. todo::` markers sit in the source, at `modules.rst:100`, `:137` and `:166`. The one at `:137` holds the parameterize-over-a-variable technique, so actions imported from a module are named but never taught.

## Boundary notes

- `EXTENDS` itself, including the rule that a spec gets only one `EXTENDS` line, is covered in chapter `02` instead. This chapter adds only what `LOCAL` does to it.
- The module file boilerplate, `---- MODULE Name ----` through `====` and the rule that the name matches the filename, is covered in chapter `01` instead.
- `CONSTANTS` and `ASSUME`, both used by the `Point` module this chapter instantiates, are covered in chapter `05` instead. This chapter only fills the constants in from outside.
- `LET ... IN`, which the chapter wraps around an instance in a tip, is covered in chapter `02` instead.
- The `Sequences` module and its operators, `Append` above all, are covered in chapter `02` instead. They are the stand-in import throughout this chapter and are never re-explained.
