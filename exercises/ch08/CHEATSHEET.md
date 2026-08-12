# Cheat sheet: learntla core ch.8

## Header

- Chapter number: `08`
- Chapter title: `Concurrency`
- learntla-v2 clone SHA: `09840bfc2ee9a88cdbedb672be77a6c73942fe16`

## Constructs introduced

- Construct: `process` (single)
  Syntax shape: `process writer = 1 begin AddToQueue: queue := Append(queue, 1); end process;`
  Section anchor: `concurrency#process`

- Construct: `pc[...]` (multi-process pc)
  Syntax shape: `pc[0]`, `pc` becomes a function from process values to labels once a spec has more than one process
  Section anchor: `concurrency § pc`

- Construct: process-local variable
  Syntax shape: `process writer = 1 variables i = 0; begin ... end process;`, invisible outside the process and in `define` blocks
  Section anchor: `concurrency § local variables`

- Construct: process set
  Syntax shape: `process writer \in Writers begin ... end process;`, one process per element of `Writers`
  Section anchor: `concurrency § Process Sets`

- Construct: `self`
  Syntax shape: `queue := Append(queue, self);`, the current process's own value inside a process set
  Section anchor: `concurrency#self`

- Construct: `await`
  Syntax shape: `await queue = <<>>;`, blocks the label until the expression is true
  Section anchor: `concurrency#await`

- Construct: deadlock (checking)
  Syntax shape: no PlusCal keyword, TLC reports "deadlock" when no process has an enabled next action. Turned off from the model configuration, not from spec text
  Section anchor: `concurrency#deadlock`

- Construct: `procedure`
  Syntax shape: `procedure Name(arg1, ...) variables var1 = ... begin Label1: ... Label2: ... return; end procedure;`
  Section anchor: `concurrency#procedure`

- Construct: `call`
  Syntax shape: `call Name(val1, ...);`, must be followed by a `goto`, a label, or another `return`
  Section anchor: `concurrency#procedure`

- Construct: `return`
  Syntax shape: `return;` ends the procedure and hands control back to the caller. TLC errors if a procedure ends without reaching one
  Section anchor: `concurrency#procedure`

## Major themes

- `process` blocks are the base unit of concurrency in PlusCal. TLC explores every legal interleaving of their labeled steps, and the count of orderings grows factorially with the number of independent actions.
- An action that only makes sense in some states, like reading from an empty queue, crashes TLC with a runtime exception unless the spec says what should happen instead. Guarding it with `if`, wrapping it in `await`, or defining a fallback are all valid choices, and the model checker is what surfaces the missing decision.
- `await` blocks a label until its condition holds. If every process is blocked at once, the model deadlocks and TLC reports it, unless deadlock checking is turned off for that run.
- Local variables hold per-process bookkeeping state, like loop counters or thread-local temporaries, at the cost of being invisible to `define` blocks and to other processes.
- The reader-writer and threads examples both show that splitting one action across two labels is what creates a race. An atomic action can't interleave with another process's steps. A nonatomic one can.
- Procedures extend macros with labels and a call stack, so they need `EXTENDS Sequences`, and they must be defined after any macros and before any processes.

## Boundary notes

- Liveness properties, needed to say the system always reaches the correct result no matter how the processes interleave (the `AllDone` invariant only catches a wrong result, not a spec that stalls forever), are covered in chapter `09` instead. (`concurrency.rst:313-317`)
- Nondeterministic `with x \in set`, including why it blocks on an empty set the same way `await` does, is covered in chapter `07` instead. (`concurrency.rst:202`)
