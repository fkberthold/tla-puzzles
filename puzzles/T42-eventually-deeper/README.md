# T42: `<>` Eventually — Deeper ⭐

## Lesson: Conjunctions of `<>` Properties

T03 used `<>` once: ONE thing eventually happens. Real systems usually have several pending eventualities. The shape

```
EachStepHappens == <>(a = TRUE) /\ <>(b = TRUE) /\ <>(c = TRUE)
```

is a property that says all three flags individually become true at some point — not necessarily at the same time, not in any fixed order. Each `<>` is its own claim; the `/\` joins them.

This matters because beginners often write one `<>` and assume it covers the whole behavior. It doesn't. You need one `<>` per thing-that-must-eventually-happen.

**Worked example — a packet clearing three security checkpoints.**

A network packet starts unprocessed. It must (in some order) be encrypted, signed, and ack'd. Different orderings are valid; the spec allows any.

```
(*--algorithm Packet {
  variables encrypted = FALSE, signed = FALSE, acked = FALSE;

  define {
    PassesChecks ==
      /\ <>(encrypted = TRUE)
      /\ <>(signed = TRUE)
      /\ <>(acked = TRUE)
  }

  fair process (handler = "Handler") {
    work:
      while (~encrypted \/ ~signed \/ ~acked) {
        either {
          encrypted := TRUE;
        } or {
          signed := TRUE;
        } or {
          acked := TRUE;
        };
      }
  }
}*)
```

The `either/or/or` lets TLC explore every order. The conjunction of three `<>` properties holds: with weak fairness on the loop, every flag must eventually flip.

Now suppose you wrote `<>(encrypted = TRUE)` ALONE as the property and removed the other two. TLC would still pass — but only because that one specific flag becomes true. The packet could in principle never get signed and the property wouldn't notice. That's why each eventuality needs its own `<>`.

Compare two near-identical lines:

- `<>(a /\ b)` — at SOME single state, both `a` and `b` are true.
- `<>a /\ <>b` — at some state `a` is true; possibly at a DIFFERENT state `b` is true.

Different claims. The first is stronger. For "all these things eventually happen, possibly at different times," use the second.

## Setup

A morning routine has three sub-tasks: the alarm rings, coffee is brewed, and the front door is locked. They can happen in any order. The home assistant claims: "by the end of the morning each of these has happened."

## Task

Write a PlusCal spec with:

- Variables `alarmRang = FALSE`, `coffeeBrewed = FALSE`, `doorLocked = FALSE`
- A `define` block with:
  - `TypeOK == /\ alarmRang \in BOOLEAN /\ coffeeBrewed \in BOOLEAN /\ doorLocked \in BOOLEAN`
  - A property `MorningComplete` that is the conjunction `<>(alarmRang = TRUE) /\ <>(coffeeBrewed = TRUE) /\ <>(doorLocked = TRUE)`
- A single `fair process` `routine` that loops while any of the three flags is still FALSE, on each iteration choosing nondeterministically (`either/or/or`) which of the three flags to set to TRUE.

## Check

1. **TypeOK** holds.
2. **MorningComplete** passes — every flag eventually flips.

## Expected Result

- TLC should report `No error has been found`. The canonical solution reports 9 distinct states (each subset of the three flags, 8 combinations, plus a final "Done" state once the loop exits); your spec may produce more if you split any action into multiple labels — that's fine, the behavior is what matters.
- `MorningComplete` passes.
- **Strip test**: replace the conjunction with the single property `<>(alarmRang = TRUE)`. TLC still passes — but the spec now happily allows behaviors that never brew coffee or never lock the door. That's the point of the conjunction: each eventuality must be CALLED OUT to be checked.

## Hints

??? hint "💡 Hint 1 — Counting the eventualities"
    The setup mentions three sub-tasks. How many `<>` operators should appear in your `MorningComplete` property? Why does each task get its own `<>`?

??? hint "💡 Hint 2 — The loop structure"
    Your process loops `while (TRUE)` but the loop guard is checking something. What condition means "at least one of the three flags is still FALSE"?

??? hint "💡 Hint 3 — The property formula"
    Your `MorningComplete` is a CONJUNCTION of three `<>` claims. In TLA+, use `/\` to join them: `<>(alarmRang = TRUE) /\ <>(coffeeBrewed = TRUE) /\ <>(doorLocked = TRUE)`.
