# R02: Define Block in a New Skin ⭐

## Lesson: Recap — Operators Pull Their Weight When the Data Has Shape

You met the `define` block in T06 (the scoreboard) and operators with parameters in the same lesson. This is a recap drill in a fresh domain: same toolkit, but the data your operators read is now a RECORD instead of a flat scalar.

A record in TLA+ is a value with named fields:

```
greeting == [salutation |-> "hello", language |-> "en"]
```

You read a field with `.fieldname`:

```
greeting.salutation       \* "hello"
greeting.language          \* "en"
```

Records are values like any other — you assign them, pass them to operators, compare them with `=`. (T09 will go further and show how to UPDATE one field of a record. For this review you just need to READ fields.)

**Recap example — a thermostat status panel.**

A thermostat reports a status record with fields `temp` and `mode`. The control logic uses operators in a `define` block to summarize the panel — both parameter-free operators and operators that take an argument.

```
(*--algorithm Thermo {
  variables status = [temp |-> 68, mode |-> "idle"], ticks = 0;

  define {
    \* Parameter-free operators read from the variable directly.
    Cold == status.temp < 65
    Hot == status.temp > 78
    Idle == status.mode = "idle"

    \* Parameterized operators take a record and ask a question of it.
    InRange(s, lo, hi) == s.temp >= lo /\ s.temp <= hi
    Active(s) == s.mode \in {"heating", "cooling"}

    Comfortable == ~Cold /\ ~Hot
  }

  fair process (controller = "Thermo") {
    tick:
      while (ticks < 3) {
        with (t \in 60..80) {
          with (m \in {"idle", "heating", "cooling"}) {
            status := [temp |-> t, mode |-> m];
          };
        };
        ticks := ticks + 1;
      }
  }
}*)
```

Sample invariants:

- `TypeOK == status.temp \in 60..80 /\ status.mode \in {"idle", "heating", "cooling"} /\ ticks \in 0..3`
- `AlwaysComfortable == Comfortable` — TLC violates this; the `with` can pick `temp = 80`, which fails `Hot`

The `define` block does the same three jobs it did in T06: READABILITY (the names tell the story), REUSABILITY (`Comfortable` is built from `Cold` and `Hot`), and PARAMETERS (`InRange` and `Active` take a record argument so they're reusable across multiple status values).

Records change nothing about how `define` works. They just give your operators richer data to look at.

## Setup

A delivery van logs each stop as a record with fields `address` (a number 1..5) and `kind` (`"pickup"` or `"dropoff"`). The dispatcher tracks the LATEST stop, the COUNT of stops made, and a flag indicating whether the van currently holds a package.

The route runs for 4 stops. At each stop, the kind is chosen nondeterministically.

## Task

Write a PlusCal spec with:

- A variable `last` initialized to the record `[address |-> 0, kind |-> "depot"]`
- A variable `stops` starting at `0`
- A variable `holding` starting at `FALSE` (van starts empty at the depot)
- A single fair process that loops while `stops < 4`. On each iteration:
  1. Use `with` to choose `a \in 1..5` (the address) and `k \in {"pickup", "dropoff"}` (the kind).
  2. Update `last` to `[address |-> a, kind |-> k]`.
  3. Update `holding`: if `k = "pickup"` then TRUE, else FALSE.
  4. Increment `stops`.

In the `define` block, create these operators:

- `IsPickup == last.kind = "pickup"`
- `IsDropoff == last.kind = "dropoff"`
- `AtDepot == last.address = 0`
- `ValidAddress(s) == s.address \in 0..5` — parameterized; takes a stop record
- `ValidKind(s) == s.kind \in {"depot", "pickup", "dropoff"}` — parameterized

## Check

1. **TypeOK**: combine your parameterized operators — `ValidAddress(last) /\ ValidKind(last) /\ stops \in 0..4 /\ holding \in BOOLEAN`
2. **PickupImpliesHolding**: `IsPickup => holding` — every pickup leaves the van holding a package
3. **NeverDropoffEmpty**: `IsDropoff => holding` — this SHOULD be violated (the van starts empty, and the first stop CAN be a dropoff)

## Expected Result

- TLC explores every combination of address and kind across 4 stops
- TypeOK and PickupImpliesHolding pass
- NeverDropoffEmpty is violated quickly — TLC finds a 2-state trace where the very first stop is a dropoff with the van still empty

## Hints

??? hint "💡 Hint 1 — Operators read fields like the lesson showed"
    R02 builds on T06. Look at your parameterized operators in the worked example (`InRange(s, lo, hi)`, `Active(s)`). They read FIELDS from the record argument. What fields does your record have? Write operators that READ those same fields.

??? hint "💡 Hint 2 — Parameter-free vs. parameterized"
    You need both. Parameter-free operators (`IsPickup`, `IsDropoff`, `AtDepot`) read from the VARIABLE `last` directly — no arguments. Parameterized operators (`ValidAddress(s)`, `ValidKind(s)`) take a record and inspect it. Which ones are which?

??? hint "💡 Hint 3 — Record syntax and EXCEPT"
    To BUILD a record in PlusCal, use `[address |-> a, kind |-> k]`. To READ a field, use dot notation: `last.address`. The assignment `last := [address |-> a, kind |-> k]` replaces the whole record. You don't need EXCEPT here — just a full reconstruction each time.
