# T44: `~>` Leads-To ⭐⭐⭐

## Lesson: `P ~> Q` — Whenever P, eventually Q

`~>` is "leads to." It is shorthand for the temporal formula

```
P ~> Q   ==   [](P => <>Q)
```

Read aloud: "in every state, IF `P` holds there, then EVENTUALLY (from that state on) `Q` will hold."

`<>` alone is a one-shot: "at SOME point in the behavior, `Q` is true." `~>` is REPEATED: every time `P` becomes true, `Q` must follow. If `P` becomes true, gets answered, and then becomes true again, `Q` must follow AGAIN.

This is the right shape for request/response, signal/acknowledgment, lock-acquired/lock-released, and most "and-then" obligations in concurrent systems.

**Why it's tricky.** Beginners often write

```
PendingMeansEventuallyServed == pending => <>served
```

and then `PROPERTY PendingMeansEventuallyServed`. That formula is a STATE predicate — it talks only about the initial state. It doesn't say "in every state where pending holds." For that you need `[]` outside, which is exactly `pending ~> served`.

**Worked example — pushing an elevator button.**

Each floor has a call button. When pressed, the elevator must eventually arrive at that floor. After it arrives, the button can be pressed again, and the cycle repeats.

```
(*--algorithm Elevator {
  variables called = FALSE, here = TRUE;

  define {
    \* Whenever the button is pressed, the elevator eventually arrives.
    CallEventuallyServed == called ~> here

    TypeOK == called \in BOOLEAN /\ here \in BOOLEAN
  }

  fair process (rider = "Rider") {
    press:
      while (TRUE) {
        await ~called;
        \* Step out (elevator leaves) and call it back.
        here := FALSE;
        called := TRUE;
      }
  }

  fair process (car = "Car") {
    serve:
      while (TRUE) {
        await called;
        here := TRUE;
        called := FALSE;
      }
  }
}*)
```

The cycle: rider sets `called = TRUE` (button pressed), car sets `here = TRUE` (arrives) and clears `called`. With weak fairness on the car, every press is followed by an arrival. The leads-to property `called ~> here` holds.

If you remove `fair` from the car's process: TLC reports a leads-to violation. The trace shows the rider pressing the button and the car never serving.

Notice what `called ~> here` does NOT say:

- It does NOT say "as soon as called, here." There can be many states between.
- It does NOT say "called and here in the same state." Just that one always follows the other in TIME.
- It DOES re-arm: after the cycle completes and the rider presses again, the obligation is renewed automatically by the implicit `[]`.

In the cfg:

```
PROPERTY CallEventuallyServed
```

`~>` is sugar; `[](called => <>here)` is the equivalent unsugared form.

## Setup

A client sends requests to a server. When the client puts in a request (`pending = TRUE`), the server eventually responds (`served = TRUE` and `pending = FALSE`, ready for the next round). New requests can come at any time.

The system claim: "every request is eventually served." That's leads-to: `pending ~> served`.

## Task

Write a PlusCal spec with:

- Variables `pending = FALSE`, `served = FALSE`
- A `define` block with:
  - `TypeOK == pending \in BOOLEAN /\ served \in BOOLEAN`
  - `RequestServed == pending ~> served`
- A `fair process (client = "Client")` that loops: when `~pending /\ ~served`, set `pending := TRUE` (a fresh request).
- A `fair process (server = "Server")` that loops: when `pending`, atomically set `served := TRUE; pending := FALSE`.
- A second client step that resets the pair: when `served /\ ~pending`, set `served := FALSE` (the client picks up the response and is ready for the next round).

Hint: write the client as a single process with two `either/or` branches, one for "make a request" and one for "pick up the response," each with its own guard. Likewise the server has one branch.

In `Server.cfg`: `INVARIANT TypeOK` and `PROPERTY RequestServed`.

## Check

1. **TypeOK** holds.
2. **RequestServed** (`pending ~> served`) passes — every request is eventually served.

## Expected Result

- TLC finds **3 distinct states** cycling: `(pending=F, served=F)` → `(pending=T, served=F)` → `(pending=F, served=T)` and back.
- `RequestServed` passes with `fair process` on both client and server.
- **Strip test 1**: replace `~>` with `=>` (drop the `[]`-wrap) and write `RequestServed_BAD == pending => <>served`. TLC will only check this in the INITIAL state, where `pending = FALSE`, so the implication is vacuously true. The check passes for the wrong reason. The failure mode of `=>` for a recurring obligation is the canonical motivation for `~>`.
- **Strip test 2**: drop `fair` from the server's `process`. TLC reports a leads-to violation: a behavior in which the server stutters forever after a request, so the implied `<>served` never realizes. Trace under 5 states.
