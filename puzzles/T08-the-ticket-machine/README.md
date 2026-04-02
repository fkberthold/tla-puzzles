# T08: The Ticket Machine ⭐⭐

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

## Concept

**Capstone: combining everything.** This puzzle requires variables (T01), nondeterminism with `either/or` (T03), define-block operators (T06), and an invariant that catches a real property (T07). No single new concept — the challenge is putting them together in a spec that models something realistic.
