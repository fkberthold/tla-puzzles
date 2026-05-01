# T40: Procedures and `call`/`return` ⭐⭐

## Lesson: Reusable Code Blocks with Their Own Variables

PlusCal lets you define a PROCEDURE — a named block of labeled code that you `call` from a process. The procedure can take parameters, has its own local variables, and returns to wherever called it.

**Syntax:**

```
procedure NAME(param1 = default, param2 = default)
variables localvar = init;
{
  L1:
    statements;
  L2:
    return;
}
```

The procedure is a TOP-LEVEL block (it sits beside processes, not inside one). To call it from a process: `call NAME(arg1, arg2);`. After `return`, control resumes at the next label in the caller. Multiple calls and recursion are allowed — PlusCal models the call stack explicitly with a `stack` variable in the translation.

**Why use a procedure?** Three reasons:
1. **Reuse** — multiple call sites use the same labeled body.
2. **Parameters** — captures variation, like a function call.
3. **Local state** — the procedure's local variables get pushed/popped per call (so recursion works).

**Worked example — a piggy bank with deposit/withdraw helpers.**

A piggy bank has a balance. Two helper procedures — `deposit(n)` and `withdraw(n)` — manipulate it. A single saver process makes a sequence of calls.

```
(*--algorithm Piggy {
  variables balance = 0;

  procedure deposit(amount = 0) {
    addStep:
      balance := balance + amount;
      return;
  }

  procedure withdraw(amount = 0) {
    subStep:
      balance := balance - amount;
      return;
  }

  fair process (saver = "Saver") {
    s1: call deposit(5);
    s2: call deposit(10);
    s3: call withdraw(3);
    s4: skip;
  }
}*)
```

Each call:
1. Translates to a `pc' = ...` step that jumps INTO the procedure's first label.
2. Pushes the return address (next label in the caller — `s2`, `s3`, `s4`) onto a hidden `stack` variable.
3. Runs the procedure body.
4. `return;` pops the stack and jumps back to the saved label.

After the saver runs all three calls, `balance = 12`. TLC steps through call/return as ordinary atomic steps; the stack is just another part of the state.

**A subtle thing.** Each call creates a FRESH copy of the procedure's parameters and local variables. If `deposit` had a local variable, two concurrent callers would each get their own. This is what makes procedures composable across processes.

**When to inline vs use a procedure.** If you call a code block from one place once, inline it. If you call it from multiple sites — or want to pass different arguments — use a procedure. Procedures are NOT free: they add labels, stack variables, and state-space size. Reach for them when the reuse pays for the overhead.

## Setup

A scoreboard for a two-team match has separate scores for the home and away teams. Two referees independently award points. Each referee makes two calls to a shared `award(team, points)` procedure during the game.

We want to verify that the total awarded matches what was added, no matter how the calls interleave.

## Task

Write a PlusCal spec with:

- `EXTENDS Integers, Sequences` (`Sequences` is needed because PlusCal models the call stack as a sequence)
- Variables `homeScore = 0, awayScore = 0`
- A procedure `award(team = "home", pts = 0)` that, in one labeled atomic step, adds `pts` to `homeScore` if `team = "home"` else to `awayScore`, then returns.
- A `refA = "RefA"` process that calls `award("home", 3)` then `award("away", 2)`.
- A `refB = "RefB"` process that calls `award("home", 2)` then `award("away", 3)`.
- Invariants: `TypeOK`, `BoundedScores`, and `FinalState` (defined in the Check section below)

After both refs finish, both scores reflect the touchdowns awarded by all four calls.

## Check

1. **TypeOK**: `homeScore \in 0..10 /\ awayScore \in 0..10`
2. **BoundedScores**: `homeScore <= 5 /\ awayScore <= 5`
3. **FinalState**: `(\A p \in {"RefA","RefB"}: pc[p] = "Done") => (homeScore = 5 /\ awayScore = 5)`

## Expected Result

- All invariants PASS regardless of interleaving — each procedure body is one atomic label, so adds compose correctly.
- TLC should report `No error has been found`. The canonical solution explores around 25 distinct states; your spec may produce more if you split actions into multiple labels — that's fine, the behavior is what matters.

## Hint

Here's the procedure shape:

```
procedure award(team = "home", pts = 0) {
  awardStep:
    if (team = "home") {
      homeScore := homeScore + pts;
    } else {
      awayScore := awayScore + pts;
    };
    return;
}
```

A referee process looks like:

```
fair process (refA = "RefA") {
  a1: call award("home", 3);
  a2: call award("away", 2);
}
```

Each `call` ends an atomic step (the next step JUMPS into the procedure). Each `return` ends an atomic step (the next step JUMPS back). You don't manage the stack yourself — pcal does it for you.

## Hints

??? hint "💡 Hint 1 — A procedure is a named block you call from a process"
    A procedure sits OUTSIDE the process, at the top level. It has its own labeled code, parameters, local variables, and a `return` statement. When a process executes `call award(team, pts)`, control jumps INTO the procedure's first label, runs the body, and on `return`, control jumps back to the next label in the caller. PlusCal manages the call stack invisibly.

??? hint "💡 Hint 2 — Parameters are fresh copies per call"
    Each `call award("home", 3)` sets up fresh local copies of the procedure's parameters (`team = "home"`, `pts = 3`). If two processes call the procedure concurrently, each gets its own copies — they don't interfere. That's why procedures are composable: the procedure body doesn't have to worry about what OTHER calls might have set the parameters.

??? hint "💡 Hint 3 — The procedure's labeled body is where interleaving happens"
    The body of `award` has a label `awardStep`. When `refA` calls `award`, control jumps to `awardStep`, does the work, and returns. Between any two labels — even though `awardStep` is inside the procedure — another process can interleave. That's why `FinalState` holds: even though `refA` and `refB` call the same procedure in different orders, all four calls eventually run, and the scores add up correctly.

