# Answer

```tla
WF_vars(Serve)
```

What it guarantees:

```tla
[](Waiting /\ []Present => <>~Waiting)
```

A customer who waits while the clerk stays at the counter gets served.

What it doesn't:

```tla
Waiting ~> ~Waiting
```

A clerk who keeps stepping away never has to serve anyone, and L2 is that
clerk. The specifier allowed L2, so the obligation is weak fairness, and
weak fairness buys only the first line.

L1 has `Serve` enabled forever and never taken. Weak fairness kills it. L2
has `Serve` enabled every other state. Weak fairness lets it through, and
strong wouldn't. L3 has nothing to serve, and `Serve` is never enabled, so
weak fairness on `Serve` says nothing about it. Any conjunct on a wider
action would.

## Measured on the lassos

Each candidate is checked as a PROPERTY of one lasso. 0 means the conjunct
admits that lasso. 13 means it rules it out.

| candidate | L1 | L2 | L3 |
|---|---|---|---|
| `WF_vars(Serve)` | 13 | 0 | 0 |
| `SF_vars(Serve)` | 13 | 13 | 0 |
| `WF_vars(Next)` | 13 | 0 | 13 |
| `WF_vars(Arrive)` | not run | not run | 13 |

The answer's row reads forbidden, allowed, allowed. L1 doesn't separate
`WF_vars(Next)` from the answer, which is why L3 is in the table.

## Measured on the system

`verify/HelpDesk.tla` is the desk, with one spec per candidate.

| spec | `ServedIfClerkStays` | `ServedIfClerkReturns` | `Served` | `NeverStops` |
|---|---|---|---|---|
| no fairness | 13 | 13 | not run | not run |
| `WF_vars(Serve)` | 0 | 13 | 13 | 13 |
| `SF_vars(Serve)` | not run | 0 | 13 | not run |
| `WF_vars(Next)` | not run | not run | 13 | 0 |

`ServedIfClerkReturns` is `[](Waiting /\ []<>Present => <>~Waiting)`, the
strong-fairness guarantee: served if the clerk keeps coming back. Weak
fairness doesn't buy it. `NeverStops` is `[]<><<Next>>_vars`, and it's what
`WF_vars(Next)` adds that nobody asked for: the shop can never go quiet.

Unconditional `Served` fails under every candidate, including strong
fairness, because a clerk who steps away and never returns is a behavior
of the spec. That's the same shape as L3 in `05-flaky-link`, and the same
lesson: fairness on one action can't promise what the rest of the spec is
free to prevent.

## Elimination table

| wrong neighbor | killed by | rc | why |
|---|---|---|---|
| no conjunct | L1 | 13 on `SysNoneStaysRun` | L1 is a behavior of the bare spec |
| `SF_vars(Serve)` | L2 | 13 on L2 | forbids the flapping clerk, which the specifier allowed |
| `WF_vars(Next)` | L3 | 13 on L3 | `Arrive` and `StepAway` are enabled, so something must happen. A quiet shop is now illegal |
| `WF_vars(Arrive)` | L3 | 13 on L3 | makes customers fair, which nobody asked for |

## Runs

Every module below is a three-line wrapper that extends either the lasso
table or the system spec and runs the cfg beside it, which is the pairing
`harness/drill-gate.sh` checks.
`bash drill/temporal/verify-item.sh drill/temporal/06-help-desk` reproduces
the rc column.

| module | spec | rows | checks | rc |
|---|---|---|---|---|
| `LassoSfserveL1Run` | `Spec` | 1 | `PROPERTY SFServe` | rc 13 |
| `LassoSfserveL2Run` | `Spec` | 2 | `PROPERTY SFServe` | rc 13 |
| `LassoSfserveL3Run` | `Spec` | 3 | `PROPERTY SFServe` | rc 0 |
| `LassoWfarriveL3Run` | `Spec` | 3 | `PROPERTY WFArrive` | rc 13 |
| `LassoWfnextL1Run` | `Spec` | 1 | `PROPERTY WFNext` | rc 13 |
| `LassoWfnextL2Run` | `Spec` | 2 | `PROPERTY WFNext` | rc 0 |
| `LassoWfnextL3Run` | `Spec` | 3 | `PROPERTY WFNext` | rc 13 |
| `LassoWfserveL1Run` | `Spec` | 1 | `PROPERTY WFServe` | rc 13 |
| `LassoWfserveL2Run` | `Spec` | 2 | `PROPERTY WFServe` | rc 0 |
| `LassoWfserveL3Run` | `Spec` | 3 | `PROPERTY WFServe` | rc 0 |
| `SysNoneReturnsRun` | `Spec` | - | `PROPERTY ServedIfClerkReturns` | rc 13 |
| `SysNoneStaysRun` | `Spec` | - | `PROPERTY ServedIfClerkStays` | rc 13 |
| `SysSfserveReturnsRun` | `SpecSFServe` | - | `PROPERTY ServedIfClerkReturns` | rc 0 |
| `SysSfserveServedRun` | `SpecSFServe` | - | `PROPERTY Served` | rc 13 |
| `SysWfnextNeverstopsRun` | `SpecWFNext` | - | `PROPERTY NeverStops` | rc 0 |
| `SysWfnextServedRun` | `SpecWFNext` | - | `PROPERTY Served` | rc 13 |
| `SysWfserveNeverstopsRun` | `SpecWFServe` | - | `PROPERTY NeverStops` | rc 13 |
| `SysWfserveReturnsRun` | `SpecWFServe` | - | `PROPERTY ServedIfClerkReturns` | rc 13 |
| `SysWfserveServedRun` | `SpecWFServe` | - | `PROPERTY Served` | rc 13 |
| `SysWfserveStaysRun` | `SpecWFServe` | - | `PROPERTY ServedIfClerkStays` | rc 0 |

## Why not in prompt

Same shape as `05-flaky-link` with the verdicts reversed: there the flapping
lasso is forbidden and the answer is strong, here it's allowed and the
answer is weak. A reader who does both cold gets the distinction from the
rows and not from a spec with `WF` already typed on it.

The caveat: "L2 is allowed" is a decision the prompt asserts, not argues. A
reader who thinks a flapping clerk should still have to serve will write
`SF` and be wrong by fiat. I think that's acceptable, because the thing
being drilled is what weak fairness buys, and the reference specs use it in
8 of 12 against 0 for strong (`drill/INVENTORY.md`, rows K095 and K096).
The other caveat is structural. If the desk had a `Leave` action with the
same guard as `Serve`, no lasso could separate `WF_vars(Leave)` from
`WF_vars(Serve)`. There's no `Leave` here for that reason.
