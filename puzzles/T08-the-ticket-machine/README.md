# T08: The Ticket Machine ⭐⭐

## Lesson: Capstone — Combining the Toolkit

No new concept. This puzzle asks you to reach for everything from Tier 1 in a single spec:

- **T01** — variables, process, loop, labels, invariants
- **T02** — nondeterministic value selection with `with`
- **T03** — nondeterministic control flow with `either/or`
- **T04** — thinking carefully about what belongs in which label
- **T05** — `assert` for runtime sanity checks
- **T06** — named operators in the `define` block
- **T07** — TLC as a tool for catching designed-in bugs

**Worked example — a parking garage.**

Cars arrive at a garage with 3 spots. A truck may block the entrance on any given moment (nondeterministic). When the entrance is clear and a spot is available, the next car either parks or drives on (nondeterministic). The garage closes after 5 cars have arrived or when full.

```
(*--algorithm Garage {
  variables spots = 3, parked = 0, served = 0, blocked = FALSE;

  define {
    Available == spots > 0
    Full == spots = 0
    Conservation == parked + spots = 3
    ShouldShutDown == served = 5 \/ Full
  }

  fair process (attendant = "Attendant") {
    serve:
      while (~ShouldShutDown) {
        with (truck \in BOOLEAN) {
          blocked := truck;
        };
        if (~blocked /\ Available) {
          either {
            spots := spots - 1;
            parked := parked + 1;
            assert Conservation;
          } or {
            skip;  \* driver decides not to park
          };
        };
        served := served + 1;
      }
  }
}*)
```

Every Tier 1 technique shows up in one spec:

- `variables` with initial values (T01)
- `define` block with operators built from other operators (T06)
- `with` for nondeterministic truck arrival (T02)
- `if` and multi-statement atomic label (T01, T04)
- `either/or` for park-or-drive-on (T03)
- `assert Conservation` inside the park branch (T05)
- Invariants like `Conservation` and `TypeOK` that TLC checks globally
- And when you flip any operator's definition the wrong way to introduce a bug, TLC's counterexample tells you exactly where and why (T07)

The puzzle below is the same kind of composition — different domain, same toolkit. Reach for each piece when you need it.

## Setup

A ticket machine at a train station has 3 tickets to sell. Customers arrive one at a time. Each customer either buys a ticket (removing one from stock) or walks away (decided nondeterministically). The machine shuts down when all tickets are sold or when 5 customers have been served.

## Task

Write a PlusCal spec with:

- `tickets` starting at 3 (tickets remaining)
- `served` starting at 0 (customers who have been through)
- `sold` starting at 0 (tickets sold)
- `status` starting at `"open"`

Define useful operators in the `define` block:

- `SoldOut == tickets = 0`
- `MaxCustomers == served = 5`
- `ShutDown == SoldOut \/ MaxCustomers`

A single process loops while `~ShutDown`:

1. Increment `served`
2. Use `either/or`: buy (decrement `tickets`, increment `sold`) or walk away (do nothing)
3. After the loop, set `status := "closed"`

## Check

1. **TypeOK**: tickets in 0..3, served in 0..5, sold in 0..3, status in {"open", "closed"}
2. **NeverOversell**: `sold <= 3 - tickets` — tickets sold plus tickets remaining equals initial stock
3. **TicketConservation**: `sold + tickets = 3` — the real conservation law
4. **AllSold**: `status = "closed" => SoldOut` — this SHOULD be violated (the machine can close at 5 customers with unsold tickets)

## Expected Result

- TLC explores all customer decision orderings — buying or walking in every combination
- TicketConservation should PASS
- AllSold should be VIOLATED — trace shows 5 customers where enough walked away that tickets remain
