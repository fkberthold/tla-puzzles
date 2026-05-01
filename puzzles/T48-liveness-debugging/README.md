# T48: Liveness Debugging ⭐⭐

## Lesson: Reading a Liveness Counterexample

Liveness violations look different from invariant violations:

- **Invariant violation**: TLC found a state in which the predicate is false. The trace ends at that state.
- **Liveness violation**: TLC found an INFINITE behavior in which the property fails. Since infinite behaviors can't be printed, TLC reports a **lasso**: a finite prefix followed by something that repeats forever. Often the cycle is just a single "Stuttering" state — meaning the system stops doing anything new.

Reading a liveness counterexample, your job is to figure out:

1. **Where does the cycle start?** TLC marks the back-edge (often `Back to state N` or `State N: Stuttering`). Everything from state N onward repeats.
2. **What's stuck inside the cycle?** Some action that should have fired never does. The trace shows the cycle taking other actions instead, or no action at all.
3. **Why isn't fairness sufficient?** Two diagnoses to start with:
   - **`process` (no fairness)** — TLC is allowed to ignore that process forever. Fix: change to `fair process`.
   - **`fair process` (WF) when the action's enabledness flickers** — TLC sees the action repeatedly disabled, so WF doesn't apply (WF only fires actions that are CONTINUOUSLY enabled). Fix: change to `fair+ process` (SF).

The first diagnosis is what most beginners hit. The trace looks like "system runs once or twice, then stutters forever" — a process that should keep working has no fairness annotation, and TLC is happy to schedule it zero times.

**Worked example — a courier and a loading dock.**

A spec to fix:

```
(*--algorithm Delivery {
  variables waiting = FALSE, delivered = 0;

  define {
    KeepsDelivering == []<>(delivered > 0)
    TypeOK == waiting \in BOOLEAN /\ delivered \in 0..3
  }

  fair process (sender = "Sender") {
    s:
      while (TRUE) {
        await ~waiting;
        waiting := TRUE;
      }
  }

  process (courier = "Courier") {       \* BUG: no `fair`!
    pickup:
      while (TRUE) {
        await waiting;
        delivered := (delivered + 1) % 4;
        waiting := FALSE;
      }
  }
}*)
```

Run TLC. It reports a temporal-property violation. The lasso looks something like:

```
State 1: waiting = FALSE, delivered = 0     (initial)
State 2: <sender fires>  waiting = TRUE
State 3: Stuttering
```

Reading the lasso: the sender fired, set `waiting = TRUE`, and then the world stopped. Why? The courier's `pickup` action has the right precondition (`waiting`) but it never fires. Looking at the source, the courier is declared `process` (no fairness) — TLC is allowed to never schedule it.

The fix: change `process (courier ...)` to `fair process (courier ...)`. Re-translate (`tlc -pcal`), re-run (`tlc`). The property now holds.

The mechanical change in the generated TLA+ is small but visible: at the bottom of the file, the `Spec ==` block gains a new `WF_vars(courier)` conjunct. Open the file before and after to see the diff.

When `fair process` (WF) IS NOT enough, the next step up is `fair+ process` (SF — see T47). For most "I forgot fairness" bugs, WF is the answer.

## Setup

A robot vacuum charges at a dock. The dock cycles between unavailable (some other consumer is using power) and available; the robot waits and tops up its battery whenever the dock is available. We want the robot to keep charging — `[]<>(charged > 0)` — meaning the battery doesn't sit at zero forever.

The starting spec below (`Vacuum.tla` in the 🔒 spoiler) has a deliberate fairness bug. Run TLC; you'll see a liveness violation with a 2- or 3-state lasso. Find the bug, fix it, verify.

## Task

1. **First, run TLC on the broken spec:**
   ```
   cd solution
   tlc -pcal Vacuum.tla
   tlc Vacuum
   ```
   Read the lasso. Identify which process is "stuck" in the trace.

2. **Fix the spec.** Edit `Vacuum.tla`. Change EXACTLY ONE keyword on ONE process declaration. Don't touch the algorithm, the variables, or the property.

3. **Re-translate and re-verify:**
   ```
   tlc -pcal Vacuum.tla
   tlc Vacuum
   ```
   TLC should report "No error has been found."

4. **Inspect the diff in the generated TLA+.** Open `Vacuum.tla` and scroll to the `Spec ==` block at the bottom. Note what the change you made added or removed. (Hint: a fairness conjunct.)

In `Vacuum.cfg`:

```
SPECIFICATION Spec
INVARIANT TypeOK
PROPERTY Charges
CHECK_DEADLOCK FALSE
```

`CHECK_DEADLOCK FALSE` because both processes loop forever; we're not modeling shutdown.

## Check

1. **Before the fix**: TLC reports a temporal-property violation. Trace under 5 states.
2. **After the fix**: TLC reports "No error." `Charges` (`[]<>(charged > 0)`) holds.

## Expected Result

- Broken-spec output: a short lasso ending in "Stuttering," roughly 3 states. The robot is the missing actor.
- Fixed-spec output: TLC reports `No error has been found`. The canonical solution explores 8 distinct states; your spec may produce more if you split any action into multiple labels — that's fine, the behavior is what matters.
- The fix: `process (robot = "Robot")` → `fair process (robot = "Robot")`. WF is sufficient here. The action `work` is enabled exactly while `available` is TRUE, and only the robot's own firing makes `available` FALSE — between "available becomes TRUE" and "robot fires," the action is continuously enabled. WF says: take it.
- After the fix, the bottom of `Vacuum.tla` should contain `WF_vars(robot)` in the `Spec ==` definition, where the broken version had no fairness conjunct for the robot.

## Hints

??? hint "💡 Hint 1 — Reading the lasso"
    When you see "Stuttering" at the end of the trace, that means the system stopped doing anything new. Which process should have fired but didn't? Look at the `pc` (program counter) values to see which process is stuck waiting.

??? hint "💡 Hint 2 — The fairness diagnosis"
    The puzzle says "change EXACTLY ONE keyword on ONE process declaration." That keyword is either `fair` or `fair+`. The lasso will show you which process is starved. Is it the dock or the robot?

??? hint "💡 Hint 3 — Continuous vs. repeated enablement"
    Ask yourself: when this action fires, does it disable itself? Or does it stay enabled until something else disables it? If it disables itself, you might need `fair+` (SF); if not, `fair` (WF) is enough.
