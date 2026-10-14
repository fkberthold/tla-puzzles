# Answer

```tla
SF_vars(Deliver)
```

The guarantee it buys:

```tla
[]<>(link = "up") => <>(msg = "delivered")
```

If the link keeps coming back, however briefly, the message gets through.

L1 has `Deliver` enabled in every state and never taken. Any fairness on
`Deliver` kills it. L2 has `Deliver` enabled in every other state and never
taken. Weak fairness asks nothing of an action that keeps getting disabled.
Strong fairness asks that an action enabled infinitely often be taken
infinitely often, and L2 is forbidden, so strong it is. L3 never enables
`Deliver` at all, so `SF` asks nothing, and L3 is allowed. That's what
rules out every conjunct that makes the link fair.

## Measured on the lassos

Each candidate is checked as a PROPERTY of one lasso. 0 means the conjunct
admits that lasso. 13 means it rules it out.

| candidate | L1 | L2 | L3 |
|---|---|---|---|
| `SF_vars(Deliver)` | 13 | 13 | 0 |
| `WF_vars(Deliver)` | 13 | 0 | 0 |
| `WF_vars(Next)` | 13 | 0 | not run |
| `SF_vars(Next)` | not run | 0 | 13 |
| `WF_vars(LinkUp) /\ WF_vars(Deliver)` | not run | 0 | not run |
| `SF_vars(Deliver) /\ WF_vars(LinkUp)` | not run | not run | 13 |

The answer's row reads forbidden, forbidden, allowed. Nothing else does.

## Measured on the system

`verify/FlakyLink.tla` is the sender and link. Each spec variant is checked
against the guarantee above and against unconditional delivery.

| spec | `DeliveredIfLinkReturns` | `Delivered` |
|---|---|---|
| no fairness | 13 | 13 |
| `SF_vars(Deliver)` | 0 | 13 |
| `WF_vars(Deliver)` | 13 | 13 |
| `WF_vars(Next)` | 13 | 13 |
| `SF_vars(Next)` | 13 | 13 |
| `WF_vars(LinkUp) /\ WF_vars(Deliver)` | 13 | 13 |
| `SF_vars(Deliver) /\ WF_vars(LinkUp)` | not run | 0 |

The last row is the one to look at. Making the link fair as well passes
every property, including unconditional delivery, and is still the wrong
answer. Only L3 catches it. A property check can't, because the thing it
gets wrong is admitting too little, and a property only sees what's
admitted.

## Elimination table

| wrong neighbor | killed by | rc | why |
|---|---|---|---|
| no conjunct | L1 | 13 on `SysNoneRun` | L1 is a behavior of the bare spec |
| `WF_vars(Deliver)` | L2 | 0 on L2 | content with an action that's disabled infinitely often |
| `WF_vars(Next)` | L2 | 0 on L2 | the link's flapping is `Next`, and it never stops, so the conjunct is satisfied while the message starves |
| `SF_vars(Next)` | L3 | 13 on L3 | forces the link back up, which the rules said nothing can |
| `WF_vars(LinkUp) /\ WF_vars(Deliver)` | L2 | 0 on L2 | both actions are enabled only every other state |
| `SF_vars(Deliver) /\ WF_vars(LinkUp)` | L3 | 13 on L3 | right on the message, wrong on the link |

## Runs

Every module below is a three-line wrapper that extends either the lasso
table or the system spec and runs the cfg beside it, which is the pairing
`harness/drill-gate.sh` checks.
`bash drill/temporal/verify-item.sh drill/temporal/05-flaky-link` reproduces
the rc column.

| module | spec | rows | checks | rc |
|---|---|---|---|---|
| `LassoLinkfairL3Run` | `Spec` | 3 | `PROPERTY SFDeliverLinkFair` | rc 13 |
| `LassoSfL1Run` | `Spec` | 1 | `PROPERTY SFDeliver` | rc 13 |
| `LassoSfL2Run` | `Spec` | 2 | `PROPERTY SFDeliver` | rc 13 |
| `LassoSfL3Run` | `Spec` | 3 | `PROPERTY SFDeliver` | rc 0 |
| `LassoSfnextL2Run` | `Spec` | 2 | `PROPERTY SFNext` | rc 0 |
| `LassoSfnextL3Run` | `Spec` | 3 | `PROPERTY SFNext` | rc 13 |
| `LassoWfbothL2Run` | `Spec` | 2 | `PROPERTY WFBoth` | rc 0 |
| `LassoWfL1Run` | `Spec` | 1 | `PROPERTY WFDeliver` | rc 13 |
| `LassoWfL2Run` | `Spec` | 2 | `PROPERTY WFDeliver` | rc 0 |
| `LassoWfL3Run` | `Spec` | 3 | `PROPERTY WFDeliver` | rc 0 |
| `LassoWfnextL1Run` | `Spec` | 1 | `PROPERTY WFNext` | rc 13 |
| `LassoWfnextL2Run` | `Spec` | 2 | `PROPERTY WFNext` | rc 0 |
| `RetNoneRun` | `Spec` | - | `PROPERTY DeliveredIfLinkReturns` | rc 13 |
| `RetSfnextRun` | `SpecSFNext` | - | `PROPERTY DeliveredIfLinkReturns` | rc 13 |
| `RetSfRun` | `SpecSF` | - | `PROPERTY DeliveredIfLinkReturns` | rc 0 |
| `RetWfbothRun` | `SpecWFBoth` | - | `PROPERTY DeliveredIfLinkReturns` | rc 13 |
| `RetWfnextRun` | `SpecWFNext` | - | `PROPERTY DeliveredIfLinkReturns` | rc 13 |
| `RetWfRun` | `SpecWF` | - | `PROPERTY DeliveredIfLinkReturns` | rc 13 |
| `SysNoneRun` | `Spec` | - | `PROPERTY Delivered` | rc 13 |
| `SysSfLinkfairRun` | `SpecSFLinkFair` | - | `PROPERTY Delivered` | rc 0 |
| `SysSfnextRun` | `SpecSFNext` | - | `PROPERTY Delivered` | rc 13 |
| `SysSfRun` | `SpecSF` | - | `PROPERTY Delivered` | rc 13 |
| `SysWfbothRun` | `SpecWFBoth` | - | `PROPERTY Delivered` | rc 13 |
| `SysWfnextRun` | `SpecWFNext` | - | `PROPERTY Delivered` | rc 13 |
| `SysWfRun` | `SpecWF` | - | `PROPERTY Delivered` | rc 13 |

## Why not in prompt

No spec, no `WF`, no `SF`. The earlier version of this item in the family
showed a spec with `WF` on screen and asked for the fix, and once the
reader remembered `SF` existed it was a two-letter edit. Here the reader
has to infer when `Deliver` is enabled from one sentence of rules, see that
L2 enables it intermittently, and retrieve that there are two fairness
operators and which one cares about intermittent enabling.

The caveat: L2 alone gives the answer, and a reader who knows that can skip
L1 and L3. L1 is there to kill "no fairness", and L3 to kill the over-fair
answers, neither of which a reader reaching for `SF` was going to write.
The item is as hard as L2 and no harder. I think that's about the honest
ceiling for a fairness item with no code in it.
