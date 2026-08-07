---------------------------- MODULE PermitReview ----------------------------
\* ==========================================================================
\* WHAT THIS MODELS
\*
\* A city reviews one building permit application. Three kinds of party act
\* and nothing orders them: the applicant, a finite set of review
\* departments, and the city, the only party that can issue.
\*
\* These comments are about modeling decisions, not about TLA+. They cover
\* why the state has this shape, what other shapes were tried and dropped,
\* where the atomic steps start and stop, and what each check does and
\* doesn't catch. "Measured" below means somebody ran it.
\*
\* One thing to hold on to while reading the property block at the bottom.
\* Most of it is true by construction of this representation, so no mutation
\* of the state machine here can falsify it. That isn't waste. The block is
\* the vocabulary a critic's answer and a competing spec get compared in,
\* and a competing spec doesn't share the construction.
\* ==========================================================================
EXTENDS Naturals, FiniteSets

CONSTANTS Departments, MaxAmendments

\* --------------------------------------------------------------------------
\* THE TWO ALPHABETS
\*
\* `Statuses` is one three-valued variable and not two booleans. Two
\* booleans are the obvious move, since `Observe` below exposes two of them.
\* I think they're the wrong move. Two booleans admit `issued /\ withdrawn`,
\* a state the process has no meaning for. The spec would then need an
\* invariant to rule out a state that shouldn't have been representable.
\* One three-valued status makes "at most one outcome" true by construction,
\* and `Pending` becomes the single guard every action shares.
\*
\* It's also the clearest sign that `Observe` is representation-neutral. The
\* interface promises two booleans and the state doesn't have them.
\*
\* `Positions` keeps three values even though nothing reads the difference
\* between "changes" and "none". Only "approved" is ever tested. It's kept
\* because the process names three positions, and a department holding
\* nothing isn't a department asking for changes. The cost is a position
\* space of 3^|Departments| instead of 2^|Departments|, and nothing else.
\* --------------------------------------------------------------------------
Positions == {"none", "approved", "changes"}
Statuses  == {"open", "issued", "withdrawn"}

\* --------------------------------------------------------------------------
\* WHAT THE ASSUMPTIONS ARE DOING
\*
\* Non-emptiness is load-bearing. With no departments, `ApprovedBy` and
\* `Departments` are both empty, so `Unanimous` holds in the initial state.
\* The city could issue at once, and `IssuedOnlyWhenUnanimous` could never
\* fail. The unanimity rule would have no content.
\*
\* The disjointness conjunct is a modeling artifact and not a rule of the
\* process. PlusCal processes here carry string identifiers, so a department
\* named "city" would collide with the City process.
\*
\* Model values plus SYMMETRY were considered for `Departments` and dropped.
\* Symmetry reduction is the usual reason to reach for model values, and it
\* isn't available here. This module declares temporal properties, and
\* SYMMETRY makes temporal checking unsound. With symmetry off the table,
\* model values buy nothing and cost trace readability. Strings also survive
\* being handed to a separately authored competing spec with no shared
\* config. The disjointness conjunct holds trivially for model values too,
\* so the spec isn't locked to strings either way.
\* --------------------------------------------------------------------------
ASSUME /\ Departments # {}
       /\ IsFiniteSet(Departments)
       /\ Departments \cap {"applicant", "city"} = {}
       /\ MaxAmendments \in Nat

(* --algorithm PermitReview {
     \* ------------------------------------------------------------------
     \* THE STATE, AND THE FRESHNESS DECISION
     \*
     \* An amendment sets every position back to "none". A recorded
     \* position therefore always refers to the current version, and
     \* `ApprovedBy` is the set approving the current version by
     \* construction.
     \*
     \* Rejected: keep positions across an amendment and stamp each one
     \* with the version it refers to. That gives
     \* `reviewedVersion \in [Departments -> 0..MaxAmendments]` beside a
     \* version counter, with `ApprovedBy` filtering on both. Three
     \* reasons it loses.
     \*
     \* It says a different sentence. The rule is that an amendment throws
     \* every recorded position away. Version stamps say that an amendment
     \* makes every position stale, which happens to be observationally
     \* equivalent. A spec should say what the rule says.
     \*
     \* It adds states that differ but are observationally identical and
     \* behave the same forever after. A department carrying a stale
     \* "approved" from version 0 and one carrying a stale "changes" look
     \* the same through `Observe`. Junk distinctions are bad anyway, and
     \* worse here, since the grading interface is a behavior comparison.
     \*
     \* It costs a factor of (MaxAmendments+1)^|Departments| for
     \* information that `position` alone already encodes.
     \*
     \* A hybrid was rejected too: keep the clearing and carry
     \* `approvedVersion` as an auxiliary variable purely so the version
     \* claim becomes checkable. After a clear it holds stale entries and
     \* the phantom states come back. Reset it on amendment as well and
     \* it's redundant with `position`, catching nothing.
     \*
     \* The price is real and it's paid at `AmendmentClearsApprovals`.
     \* Clearing makes the freshness half of `IssuedOnlyWhenUnanimous`
     \* true by construction rather than checked. Measured: delete the
     \* clearing assignment and all four invariants still pass.
     \*
     \* Position flips are not bounded and no constant was added for it.
     \* `position` ranges over a finite function space however often
     \* departments flip, so free flipping adds edges and no states.
     \* Measured: 220 distinct states at 3 departments and
     \* MaxAmendments = 3, 815 at 4 and 4, both under a second.
     \* ------------------------------------------------------------------
     variables
       position   = [d \in Departments |-> "none"],
       amendments = 0,
       status     = "open";

     \* ------------------------------------------------------------------
     \* THE OBSERVATION INTERFACE
     \*
     \* `Observe` is why this define block exists. Answers and competing
     \* specs are written over `Observe` and `Departments`, never over the
     \* variables, so an answer survives a change of representation.
     \*
     \* It exposes no amendment count, and that's a decision with a price.
     \* The price is itemized at `AmendmentClearsApprovals` below.
     \*
     \* `Unanimous` is set equality rather than a cardinality test. Same
     \* claim here, and set equality doesn't lean on `Departments` being
     \* finite to mean what it says.
     \* ------------------------------------------------------------------
     define {
       Pending    == status = "open"
       ApprovedBy == {d \in Departments : position[d] = "approved"}
       Unanimous  == ApprovedBy = Departments

       Observe == [ issued     |-> status = "issued",
                    withdrawn  |-> status = "withdrawn",
                    approvedBy |-> ApprovedBy ]
     }

     \* ------------------------------------------------------------------
     \* WHY THREE PROCESS GROUPS
     \*
     \* Rejected: one process whose body is a single big `either`. Under
     \* interleaving semantics the two are equivalent and the single
     \* process is shorter. Three groups win because the description names
     \* three kinds of independent actor, and process structure is the
     \* part of PlusCal that says so. It also keeps issuance attributed to
     \* the city instead of smuggled into an applicant's step.
     \*
     \* The translation costs nothing for it. Each body is a single-label
     \* `while (TRUE)` loop, so the translator drops `pc` and `vars` is the
     \* three real variables. The action properties below are subscripted
     \* `_vars`, so that matters.
     \*
     \* Rejected: `while (Pending)` in place of `while (TRUE)`. It lets
     \* each process fall through to Done, lets the translator emit its
     \* own Terminating disjunct, and kills the deadlock with no config
     \* line. It also multiplies every terminal state by the combinations
     \* of which processes have noticed yet. That's `pc` noise in the one
     \* region of the graph the safety properties are about. The config
     \* carries CHECK_DEADLOCK FALSE instead. Terminal states are real
     \* here: once `status` leaves "open" no action is enabled, and that
     \* is what "an outcome is the end" means.
     \*
     \* ATOMICITY, for this process. One label, so one turn of the loop is
     \* one atomic step. The `await` and the assignment land together.
     \* There's no state where a department has passed the `Pending` test
     \* but hasn't recorded yet.
     \*
     \* The `with` lets a department record the position it already holds.
     \* The process allows that, "as often as it likes", and such a step
     \* leaves `vars` unchanged. It's a stutter, and harmless. It adds no
     \* state and satisfies every action property below trivially.
     \*
     \* A reviewer can't reach "none". Only an amendment produces it. The
     \* process gives a department no way back to holding neither.
     \* ------------------------------------------------------------------
     process (Reviewer \in Departments)
     {
       Review:
         while (TRUE) {
           await Pending;
           with (p \in {"approved", "changes"}) {
             position[self] := p;
           }
         }
     }

     \* ------------------------------------------------------------------
     \* ATOMICITY, AND THE AMENDMENT BOUND
     \*
     \* The `either` is a choice inside one atomic step, not two labels.
     \* The increment and the clearing land in the same step, and that's
     \* the load-bearing part. Split across labels, an interleaved
     \* reviewer could approve into the gap, or the city could issue on
     \* unanimity the amendment was about to destroy.
     \*
     \* The bound sits on an `await` inside the action, so it's part of
     \* the specified system. Rejected: leave the spec unbounded and cut
     \* the state space with CONSTRAINT amendments <= MaxAmendments in the
     \* config. The idiomatic argument for the constraint is real, and it
     \* still loses twice here. A CONSTRAINT truncates behaviors, TLC's
     \* temporal checking over truncated behaviors isn't sound in general,
     \* and this module declares four temporal properties. With the bound
     \* in the config, the reachable graph becomes a property of the
     \* config rather than of the module. A competing spec then has to
     \* replicate the config to be compared against this one.
     \*
     \* The process also says the bound is a rule the city runs and not a
     \* device for keeping the model finite. Putting it in the action is
     \* what that sentence looks like in TLA+.
     \*
     \* Withdrawal carries no guard past `Pending`. The process gives it
     \* none.
     \* ------------------------------------------------------------------
     process (Applicant = "applicant")
     {
       AmendOrWithdraw:
         while (TRUE) {
           await Pending;
           either {
             await amendments < MaxAmendments;
             amendments := amendments + 1;
             position   := [d \in Departments |-> "none"];
           }
           or {
             status := "withdrawn";
           }
         }
     }

     \* ------------------------------------------------------------------
     \* ATOMICITY, AND WHY UNANIMITY DOESN'T FORCE ISSUANCE
     \*
     \* The unanimity test and the assignment are one step, so unanimity
     \* can't lapse between the two.
     \*
     \* Unanimity lets the city issue and doesn't make it. That's the
     \* `while (TRUE)` loop with no fairness. Nothing here declares WF or
     \* SF, so `Spec` permits a behavior in which the city sits at
     \* unanimity forever while departments drop approvals underneath it.
     \*
     \* Only City assigns "issued" and only Applicant assigns "withdrawn".
     \* Authorization isn't a guard in this model, it's the process
     \* partition. That partition is the whole of who may do what.
     \* ------------------------------------------------------------------
     process (City = "city")
     {
       Issue:
         while (TRUE) {
           await Pending /\ Unanimous;
           status := "issued";
         }
     }
   }
*)
\* BEGIN TRANSLATION (chksum(pcal) = "b7136896" /\ chksum(tla) = "8c98674")
VARIABLES position, amendments, status

(* define statement *)
Pending    == status = "open"
ApprovedBy == {d \in Departments : position[d] = "approved"}
Unanimous  == ApprovedBy = Departments

Observe == [ issued     |-> status = "issued",
             withdrawn  |-> status = "withdrawn",
             approvedBy |-> ApprovedBy ]


vars == << position, amendments, status >>

ProcSet == (Departments) \cup {"applicant"} \cup {"city"}

Init == (* Global variables *)
        /\ position = [d \in Departments |-> "none"]
        /\ amendments = 0
        /\ status = "open"

Reviewer(self) == /\ Pending
                  /\ \E p \in {"approved", "changes"}:
                       position' = [position EXCEPT ![self] = p]
                  /\ UNCHANGED << amendments, status >>

Applicant == /\ Pending
             /\ \/ /\ amendments < MaxAmendments
                   /\ amendments' = amendments + 1
                   /\ position' = [d \in Departments |-> "none"]
                   /\ UNCHANGED status
                \/ /\ status' = "withdrawn"
                   /\ UNCHANGED <<position, amendments>>

City == /\ Pending /\ Unanimous
        /\ status' = "issued"
        /\ UNCHANGED << position, amendments >>

Next == Applicant \/ City
           \/ (\E self \in Departments: Reviewer(self))

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 
\* ==========================================================================
\* THE PROPERTY BLOCK
\*
\* Read this block as a vocabulary more than as a test of the algorithm
\* above it. Most of it holds by construction of the representation, and
\* each entry says which parts do. The block earns its keep against a
\* competing spec, which doesn't share the construction.
\* ==========================================================================
\*
\* Not a rule of the process. It's the range guard, and the conjunct with
\* teeth is the one on `amendments`. Take the bound off the amend guard and
\* this is the check that fires. Measured.

TypeOK ==
    /\ position   \in [Departments -> Positions]
    /\ amendments \in 0..MaxAmendments
    /\ status     \in Statuses

\* Guards the shape of the graded interface, not the process. It's here
\* because everything downstream reads `Observe` and nothing downstream
\* re-derives its type.
\*
ObserveWellTyped ==
    Observe \in [issued: BOOLEAN, withdrawn: BOOLEAN, approvedBy: SUBSET Departments]

\* The rule: the city can issue only while the application is open, and only
\* when every department holds an approval at that moment.
\*
\* Written at the issued state rather than at the issuing step. It says what
\* the rule says only because every action carries the `Pending` guard, so
\* no position moves after issuance. The issued state therefore still
\* carries the vector the city issued on.
\*
\* Against a spec that lets reviewers move after issuance, the same formula
\* says something stronger: positions have to stay unanimous forever. It
\* fires there, and what it catches is post-terminal activity rather than a
\* unanimity fault. Measured. `OutcomeIsAbsorbing` below is the check that
\* fault belongs to.
\*
\* What it deliberately doesn't capture: freshness. It can't falsify a spec
\* that bumps the amendment counter without clearing positions. The stale
\* approvals still read "approved", `ApprovedBy` is still `Departments`, and
\* the invariant passes. Measured. That half of the rule is carried by the
\* representation, and by `AmendmentClearsApprovals` below.
\*
IssuedOnlyWhenUnanimous ==
    Observe.issued => (Observe.approvedBy = Departments)

\* The rule: an application reaches at most one outcome.
\*
\* No mutation of the state machine can falsify this. One three-valued
\* `status` can't be issued and withdrawn at once. It's kept as a check on
\* `Observe` itself, and it guards two of the three fields. Rewrite the
\* `withdrawn` field as `status # "open"` and it fires at an issued state.
\*
\* Rewrite `approvedBy` and nothing in the config notices. That's the one
\* hole this property set can't close from inside. The states where a wrong
\* `approvedBy` would show are the states this spec never reaches, so no
\* property over this spec separates the two. Measured, and it matters more
\* than it looks. Pair that rewrite with a real break in the state machine
\* and the rewrite hides the break from every declared check. Catching it
\* needs something outside the module, checking `Observe` against the
\* variables rather than through them.
\*
OutcomeExclusive ==
    ~(Observe.issued /\ Observe.withdrawn)

\* The rule: an amendment throws away every position recorded against the
\* old version, so right after an amendment no department holds an approval.
\*
\* This is the only formal witness that rule has, and it's the one check in
\* the block that reaches past `Observe` into a raw variable. That's
\* deliberate. As far as I can tell it can't be phrased at the observation
\* interface at all, and the reasoning is the most interesting thing here.
\*
\* Take this module and delete the clearing assignment, changing nothing
\* else. Dump both reachable state sets and compare them as sets of whole
\* records. They're equal: 220 on each side, nothing in either direction of
\* the difference. A state predicate is a function of the state, so no
\* invariant whatever separates them. Not over `Observe`, and not over
\* `position`, `amendments` and `status` either.
\*
\* The reason is a direction, and it's the part worth carrying away. What
\* the weakened spec loses isn't a state, it's a transition. Its amend step
\* leaves `Observe` unchanged where a correct one clears `approvedBy` to
\* empty, so the amendment becomes an `Observe`-stutter. Failing to clear
\* makes a spec observably smaller than a correct one, not bigger. An
\* invariant can only rule states out, so it can't catch a missing behavior.
\*
\* So the check has to be an action property, and an action property about
\* amendments has to detect that an amendment happened. `Observe` exposes no
\* amendment count, so this one reads `amendments`.
\*
\* What that costs, stated plainly. It sits outside the vocabulary the rest
\* of the block is written in. So it doesn't survive a change of
\* representation the way the others do. A competing spec that counts
\* amendments differently, or doesn't count them at all, can't be checked
\* against it.
\*
\* And it's switched off by freezing the counter it reads. A spec that
\* clears on amendment but never increments satisfies this vacuously, since
\* the antecedent is never true. Measured. The only witness the amendment
\* rule has is defeated by editing a variable the rule never mentions. I
\* don't have a fix that keeps the representation-neutrality the rest of
\* this block depends on.
\*
\* One consequence for tooling. This is an action property, and TLC reports
\* an action-property violation with exit code 13 where an invariant
\* violation gives 12. A harness pinned to 12 reads this check's catch as a
\* pass.
\*
\* One near miss, recorded so nobody mistakes it for the missing invariant.
\* There is a separator over `Observe` alone that fires on the non-clearing
\* spec:
\*
\*   [][ (Observe.approvedBy = Departments /\ ~Observe.issued
\*         /\ ~Observe.withdrawn) => (Observe' # Observe) ]_vars
\*
\* It says a fully approved open state can't step silently. That's an
\* accident of this spec's step structure and not something the process
\* asserts, so it wouldn't hold of every correct spec of this process.
\*
AmendmentClearsApprovals ==
    [][ (amendments' # amendments) => (Observe'.approvedBy = {}) ]_vars

\* The rule: once the permit is issued, or the application withdrawn,
\* nothing else happens.
\*
\* These two pin the outcome flags and nothing else. A flag never retracts.
\* They don't say the rest of the world stops, and that gap is real rather
\* than theoretical. A spec where departments keep recording positions after
\* a withdrawal satisfies both, and so does one where the applicant amends
\* after withdrawing. Measured: both slipped through the original property
\* set, which is why `OutcomeIsAbsorbing` exists.
\*
IssuanceIsFinal ==
    [](Observe.issued => []Observe.issued)

WithdrawalIsFinal ==
    [](Observe.withdrawn => []Observe.withdrawn)

\* The full statement of "an outcome is the end", over the interface. Once
\* either outcome holds, no step changes anything observable.
\*
\* It subsumes the two properties above. They're kept because a single-check
\* run attributes a violation to the direction that broke, where this one
\* reports only that something moved.
\*
\* Like `OutcomeExclusive`, it's true by construction here. Every action
\* carries the `Pending` guard, so nothing is enabled once `status` leaves
\* "open". Drop the guard from any one action and this fires while both
\* finality properties above stay green. Measured on two such drops.
\*
OutcomeIsAbsorbing ==
    [][ (Observe.issued \/ Observe.withdrawn) => (Observe' = Observe) ]_vars

\* ==========================================================================
\* WHAT'S ELIDED, AND WHY THAT'S SAFE
\*
\* Every elision below is safe for the same kind of reason. No rule of the
\* process reads the thing left out, so no behavior the rules distinguish
\* turns on it.
\*
\* No time and no deadlines. No rule mentions either.
\*
\* No application content and no version payload. An amendment is a counter
\* bump and a reset. The only thing about a new version that any rule reads
\* is that it invalidates the old positions, and the reset says that.
\*
\* No reason attached to a "changes" position, and no reviewer comments.
\* Nothing reads them.
\*
\* No messages and no delay. A department records straight into shared state
\* and the record is visible at once. The process has the city issue when
\* every department is holding an approval "at that moment", so it already
\* assumes a single point of truth. A model with votes in flight would have
\* to say what holding means for a vote in transit, and the process doesn't
\* say.
\*
\* No second application. The process puts one in front of the city.
\*
\* No fairness, and so no liveness properties. Every rule in the process is
\* a safety rule. Nothing obliges the city to issue or the applicant to act,
\* and the process says outright that unanimity doesn't make the city issue.
\* Weak fairness would assert something the process doesn't.
\*
\* No department identity beyond a name, and no authorization guards. Who
\* may do what is the process partition.
\*
\* No un-withdrawal, no re-opening, no appeal, no expiry.
\*
\* One thing that looks elidable and isn't. The amendment bound reads like a
\* device for keeping the model finite and it isn't one. It's a rule the
\* city runs, so it lives in the action rather than in a CONSTRAINT.
\*
\* Two things this module knowingly doesn't check, both argued above. The
\* `approvedBy` field of `Observe` has no guard, and on this spec alone it
\* can't have one. And `AmendmentClearsApprovals` goes vacuous against a
\* spec that never moves its counter. I'd file both against the surrounding
\* pipeline rather than against the module.
\* ==========================================================================
=============================================================================
