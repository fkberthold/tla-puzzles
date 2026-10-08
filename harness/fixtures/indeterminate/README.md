# fixtures/indeterminate — the reserved-indeterminate gate

Driven by `harness/test-indeterminate.sh` (bead `tla-hl96`). Every file here
exists to reach a path where an instrument was asked for a check it could not
perform, and to prove it reports `99 CHECK_DID_NOT_RUN` rather than a pass.

| file | what it drives |
|---|---|
| `ViolatedWithDeadAction.tla` + `.cfg` | site 2. The MASKING PAIR: the invariant is violated AND an action can never fire, so probes 4, 5 and 6 are skipped and the fault one of them would have caught is never looked for. |
| `DeadlockKeyword.tla` | site 3. `x = 2` has no successor, so the module deadlocks and the six-cell table in its own header is measurable against it. |
| `DeadlockKeywordTrue.cfg` | the defect: the keyword asks for a check the default command line suppresses. |
| `DeadlockKeywordFalse.cfg` | the other direction, and the control for 334 real configs in this repo that write `FALSE` on purpose. |
| `DeadlockKeywordAbsent.cfg` | no keyword, so no conflict. |
| `DeadlockKeywordCommented.cfg` | a keyword mentioned in a line comment AND in a two-line block comment. A gate that fires on prose is worse than no gate. |
| `gh-unavailable` | site 1. A `gh` stub that cannot answer, reproducing what the real one does on a 403: GitHub's JSON body on stdout and a nonzero status. |

`NoSuchModule.tla` is deliberately ABSENT — `test-indeterminate.sh` names it to
prove the deadlock refusal precedes the run, which only means something while
TLC would otherwise answer 150. Do not create it.

Two of these pair with fixtures elsewhere and the pairing is the point:
`fixtures/vacuity/DeadGuard.{tla,cfg}` is the same dead action with its
invariant satisfied, so the suite can show that the skipped probe had something
to find. `fixtures/screen/` supplies the cached Examples README and the working
`gh` stub for the clean-run controls.
