# T42: `<>` Eventually — Deeper ⭐

## Lesson: Conjunctions of `<>` Properties

T03 used `<>` once: ONE thing eventually happens. Real systems usually have several pending eventualities. The shape

```
EachStepHappens == <>(a = TRUE) /\ <>(b = TRUE) /\ <>(c = TRUE)
```

is a property that says all three flags individually become true at some point — not necessarily at the same time, not in any fixed order. Each `<>` is its own claim; the `/\` joins them.

This matters because beginners often write one `<>` and assume it covers the whole behavior. It doesn't. You need one `<>` per thing-that-must-eventually-happen.

**Worked example — a stopwatch ticking up.**

A stopwatch's reading `t` starts at `0` and ticks up by 1 each step until it reaches `3`. The claim: `t` eventually visits every value 1, 2, 3 along the way.

```
(*--algorithm Stopwatch {
  variables t = 0;

  define {
    HitsAll == <>(t = 1) /\ <>(t = 2) /\ <>(t = 3)
  }

  fair process (clock = "Clock") {
    tick:
      t := 1;
    tick2:
      t := 2;
    tick3:
      t := 3;
  }
}*)
```

The conjunction of three `<>` properties holds: each label fires once and `t` passes through 1, 2, and 3 in turn. No branching, no choice — just three `<>` claims, one per value the property cares about.

Now suppose you wrote `<>(t = 1)` ALONE as the property and removed the other two. TLC would still pass — but only because that one specific value is reached. The stopwatch could in principle never reach `t = 2` or `t = 3` and the property wouldn't notice. That's why each eventuality needs its own `<>`.

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

- TLC should report `No error has been found`. The canonical solution reports 9 distinct states; your spec may produce more if you split any action into multiple labels — that's fine, the behavior is what matters.
- `MorningComplete` passes.
- **Strip test**: replace the conjunction with the single property `<>(alarmRang = TRUE)`. TLC still passes — but the spec now happily allows behaviors that never brew coffee or never lock the door. That's the point of the conjunction: each eventuality must be CALLED OUT to be checked.

## Hints

??? hint "💡 Hint 1 — Counting the eventualities"
    The setup mentions three sub-tasks. How many `<>` operators should appear in your `MorningComplete` property? Why does each task get its own `<>`?

??? hint "💡 Hint 2 — The loop structure"
    Your process loops while at least one flag is still FALSE — that's your loop condition, `~alarmRang \/ ~coffeeBrewed \/ ~doorLocked`. When all three are TRUE the loop exits.

??? hint "💡 Hint 3 — The property formula"
    Your `MorningComplete` is a CONJUNCTION of three `<>` claims. In TLA+, use `/\` to join them: `<>(alarmRang = TRUE) /\ <>(coffeeBrewed = TRUE) /\ <>(doorLocked = TRUE)`.
