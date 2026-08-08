---------------------------- MODULE Consign ----------------------------
\* The frozen reference, with the author's commentary. The spec text is
\* byte-identical to Consign.tla in this directory, comments aside, and
\* harness/comment-gate.sh checks that mechanically rather than trusting
\* it. Read this after your own attempt, next to the alternatives note
\* (ALTERNATIVES.md), which records the representations that lost. The
\* comments explain modeling decisions, not TLA+.
EXTENDS Naturals, FiniteSets

\* Owners, Items, and the ownership map are constants because the round
\* fixes them: ownership is a fact of the agreement, not a thing a step
\* can re-map. Floor is the shop's own size, not a finiteness device.
\* The item set already bounds the state.
CONSTANTS Owners, Items, OwnerOf, Floor

\* A total function, so every item has exactly one owner, for good.
ASSUME OwnerOf \in [Items -> Owners]
ASSUME Floor \in Nat

\* One variable, the counter's book: where each item stands right now.
\* Sold means owed and settled means paid, so the payout ledger folds
\* into the standing for free. The representations that lost (five
\* sets, a place field beside a ledger, an event log, merged terminal
\* standings) are argued one by one in the alternatives note. The
\* ledger was the tempting one, and its gap decided it: two variables
\* tracking one fact admit states where they disagree, and the
\* interface below can't show the drift. A representation that can't
\* express the drift beats one that has to carry an invariant
\* forbidding it.
VARIABLE standing

\* Strings, not model values. Strings keep Observe printable and
\* comparable across specs that never share a module, which I suspect
\* the grading harness leans on.
Standings == {"unlisted", "listed", "returned", "sold", "settled"}

\* Model-side helpers, both over the raw variable. Listed feeds the
\* intake guard, SoldOf feeds the till. What the shop owes an owner is
\* their items standing sold: no ledger variable, no running total,
\* nothing beside the book to drift from it.
Listed == {i \in Items : standing[i] = "listed"}

SoldOf(o) == {i \in Items : OwnerOf[i] = o /\ standing[i] = "sold"}

\* The graded interface, and identity packaging on this reference: the
\* interface and the moving state are the same values. One field is
\* thin on purpose. Ownership and the item set are constants, so every
\* question the book answers is standing plus constants. A model that
\* keeps a payable ledger beside the standings is welcome to, and a
\* ledger that drifts from the standings is invisible here. That's the
\* cost of stopping the interface at the book's own face, and I'd
\* rather pay it than expose state the domain doesn't have.
Observe == [standing |-> standing]

\* The opening: every item home with its owner, never yet listed.
Init == standing = [i \in Items |-> "unlisted"]

\* One item in, one step. The guard admits only "unlisted", and that's
\* where forward-only starts: a returned item's listing is spent, and
\* relisting it is the backward move LawfulPath forbids. The cap guard
\* is strict, so a full floor refuses intake, and there's no waiting
\* list. The count is computed at need. A stored counter would be a
\* second fact to keep honest against the book.
Intake(i) ==
    /\ standing[i] = "unlisted"
    /\ Cardinality(Listed) < Floor
    /\ standing' = [standing EXCEPT ![i] = "listed"]

\* The shop's step: any listed item, any time, and the world supplies
\* the buyer. Sold means the payout is owed from this moment, and the
\* standing carries that fact on its own. No amount appears anywhere,
\* because the payout here is per-item, owed or paid, never a number.
Sell(i) ==
    /\ standing[i] = "listed"
    /\ standing' = [standing EXCEPT ![i] = "sold"]

\* One action for two hands. The owner can fetch the item and the shop
\* can send it back, and the counter's book doesn't record whose hand
\* carried it out. A two-action model and this one look the same
\* through Observe, and the seeded split-GoHome variant confirmed the
\* fold rather than refuting it. The target is "returned", never
\* "unlisted": the listing is spent, and the round doesn't hand it
\* back.
GoHome(i) ==
    /\ standing[i] = "listed"
    /\ standing' = [standing EXCEPT ![i] = "returned"]

\* The till, and the only action that can move more than one item.
\* When an owner with anything owed comes to the till, every sold item
\* of theirs settles in this one step, and nothing else moves. The
\* whole-function rebuild is the wholeness: this form has no way to
\* leave one sold item behind. The nonempty guard keeps an empty till
\* visit from being a step. Dropping it turns out to be inert, since
\* the leftover disjunct implies UNCHANGED and stuttering already
\* allows that, but the rule says a visit with nothing owed isn't an
\* event, so the guard states the rule.
Settle(o) ==
    /\ SoldOf(o) # {}
    /\ standing' = [i \in Items |-> IF i \in SoldOf(o) THEN "settled" ELSE standing[i]]

\* Free interleaving, four kinds of step. Nothing coordinates anyone,
\* so any party's next step can land between any two steps of another.
Next ==
    \/ \E i \in Items : Intake(i) \/ Sell(i) \/ GoHome(i)
    \/ \E o \in Owners : Settle(o)

\* No fairness, and the absence is the decision. Rule 6 of the system:
\* nobody must act. A listed item can hang forever, a payout can wait
\* forever, an owner can stay home forever. Every obligation below is
\* safety on purpose, and the missing liveness property is how that
\* rule is rendered. Fairness would only remove behaviors, and no
\* safety property can see a behavior that stopped happening. One
\* practical face: a behavior where every item lands returned or
\* settled has no step left at all. A checker reporting deadlock there
\* is reporting the design working, so deadlock checking stays off.
Spec == Init /\ [][Next]_standing

(***************************************************************************)
(* Every obligation below reads the shop through Observe, never through    *)
(* the variable. The hand-off states all five over the observable of its   *)
(* section 3, and the grading engine builds a learner's score on the same  *)
(* operator, so an obligation that reads `standing` directly grades a      *)
(* different system from the one the interface publishes.                  *)
(*                                                                         *)
(* On this reference the two readings agree, because Observe.standing is   *)
(* standing. That agreement is what makes the raw form tempting and what   *)
(* makes it unsafe: a model whose Observe lies keeps every raw obligation  *)
(* green, and nothing downstream looks again.                              *)
(*                                                                         *)
(* The model half above still reads the variable. Only the obligations     *)
(* route through the operator. Routing the actions too would change the    *)
(* shop instead of what we check about it.                                 *)
(*                                                                         *)
(* Both action properties keep `_standing` as the subscript, and it has to *)
(* stay the raw variable. Under `[][...]_Observe` a model whose Observe    *)
(* never moves turns every step into a stutter, and the property passes    *)
(* without checking anything. The subscript picks which steps we grade.    *)
(* The body says what we grade about them.                                 *)
(***************************************************************************)

\* The routing above was bought with a seeded bug, and the mechanics
\* are worth keeping next to it. The variant matrix shipped an Observe
\* that reports every item unlisted, and the raw-reading obligations
\* stayed green at the reference's own 608 states. The declared
\* interface could say anything at all, and nothing looked. The repair
\* was measured at two widths before this one shipped. Routing only
\* the change-set kills that lie but not the next one: an Observe that
\* relabels standings through a bijection, sold and settled swapped
\* say, leaves the change-set identical to the reference's and passes
\* clean. So every obligation routes, not just Changed. And the tidy
\* to fear is real: rewriting the subscripts to _Observe reads as
\* consistency and rebuilds the same hole one layer up, in the one
\* place a reader is least likely to look.

\* "Exactly one of five" lands as a typing fact because the chosen
\* representation makes it one: a function gives each item one value,
\* and what's left to check is that the value stays in range. On the
\* five-set representation this would be a live partition an action
\* could break. It earns its keep against learner specs, not against
\* this one, and the sixth-standing variant is the one it catches.
OneStandingEach == Observe.standing \in [Items -> Standings]

\* The cap, recounted from the interface rather than read from Listed,
\* so the obligation leans on nothing model-side. Intake's strict < is
\* what maintains this <=, and the off-by-one variant that loosened
\* the guard was caught here, not there.
FloorCap == Cardinality({i \in Items : Observe.standing[i] = "listed"}) <= Floor

\* The opening condition. It sits in the cfg under PROPERTIES, not
\* INVARIANTS, because it must hold at the first state and only there.
\* As an invariant it would be false one intake in.
OpeningAllUnlisted == \A i \in Items : Observe.standing[i] = "unlisted"

\* An item's one-way story as a relation: the four real moves, plus
\* a = b so a step that leaves an item alone stays lawful. The
\* absences do the work. No clause leaves "returned" or "settled", so
\* both are terminal, and no clause runs backward.
LawfulMove(a, b) ==
    \/ a = b
    \/ a = "unlisted" /\ b = "listed"
    \/ a = "listed" /\ b \in {"returned", "sold"}
    \/ a = "sold" /\ b = "settled"

\* Which moves an item may make, checked at every step through the
\* interface. Eight of the seeded matrix's nineteen catches landed
\* here, more than on any other obligation.
LawfulPath ==
    [][\A i \in Items :
          LawfulMove(Observe.standing[i], Observe'.standing[i])]_standing

\* The change-set, read through Observe on both sides of the step.
\* Under the all-unlisted lie this set is frozen empty, SingleStep
\* wants a singleton, and SettlementStep wants a nonempty owed set.
\* Meanwhile the subscript still sees the raw variable move, so the
\* box can't discharge the lying step as a stutter.
Changed == {i \in Items : Observe'.standing[i] # Observe.standing[i]}

\* The interface-side twin of SoldOf: the same set, stated over
\* Observe, so the obligation block never reads the model's helpers.
Owed(o) == {i \in Items : OwnerOf[i] = o /\ Observe.standing[i] = "sold"}

\* An ordinary step moves exactly one item, and the exclusion on the
\* second line is the load-bearing clause. Without it a one-item
\* settlement reads as a lawful single move. The weaker form is green
\* on this reference, so an author who wrote it would have shipped it,
\* and it misses both till mutants, the per-item till and the partial
\* payout. That was measured by ablation, not assumed. The author
\* can't see the difference by running their own spec. Only a mutant
\* separates the two forms.
SingleStep ==
    \E i \in Items :
        /\ Changed = {i}
        /\ ~(Observe.standing[i] = "sold" /\ Observe'.standing[i] = "settled")

\* The till as a step shape: one owner, their whole owed set, all
\* landing "settled". Changed = Owed(o) carries wholeness and frame in
\* one equation, nothing left behind and nobody else's goods touched.
\* The set-valued footprint is the part to respect. The panel's weak
\* seat rendered the step-shaped obligations as invariants, passed the
\* first three, and never checked this one or the path, because an
\* invariant can't say "together".
SettlementStep ==
    \E o \in Owners :
        /\ Owed(o) # {}
        /\ Changed = Owed(o)
        /\ \A i \in Owed(o) : Observe'.standing[i] = "settled"

\* The disjunction earns both arms. A probe forbidding any step that
\* changes more than one item fails on this reference, with two items
\* of one owner settling together in the witness, so the settlement
\* arm carries transitions the single arm rejects. The subscript stays
\* _standing, for the reason the block comment above the obligations
\* gives.
SingleStepOrSettlement == [][SingleStep \/ SettlementStep]_standing

\* ---------------------------------------------------------------------
\* What this obligation set deliberately does not carry. Five of the
\* matrix's 24 seeded variants stay green against this reference, and
\* each names an edge of the design rather than a hole in it. One is
\* inert rather than uncaught: the empty till visit admits exactly the
\* reference's behaviors, so there's nothing to catch. The other four
\* are below, and a fifth edge came from the blind panel rather than
\* the matrix.
\*
\* Whose hand. A going-home step doesn't show whether the owner
\* fetched the item or the shop sent it back. Rule 4 of the system
\* folds the two hands into one event, and the split-action variant
\* produced the same observable behavior, with nothing to catch.
\*
\* Removed behavior. One variant added weak fairness, another
\* tightened the cap to count sold items against the floor. Both only
\* remove behaviors, and every obligation here quantifies over all
\* behaviors, so a model that does less passes everything. The
\* fairness variant keeps the reference's exact state graph, 608
\* states, which is why no safety property could catch it even in
\* principle. Over-constraint is graded on the other channel: a
\* learner's conjuncts must not forbid behaviors the reference allows.
\*
\* Drifting ownership. Make OwnerOf a variable a step can re-map, and
\* a settlement can group by an ownership that changed since intake.
\* Observe has one field and it isn't ownership, so no obligation over
\* the interface reaches the drift, and one over the internals can't
\* either, because the mutant moves the internals and stays consistent
\* with them. The interface stops at the book's face, and this is that
\* choice's price, paid knowingly.
\*
\* Incoherence behind a lawful face. A panel seat built the
\* measurement on purpose: a spec that holds an item on the shop floor
\* and in a debt at once, keeps a lawful book face throughout, and
\* passes all five obligations. View-level obligations can't constrain
\* concrete state the book never shows. It's the routing boundary seen
\* from the other side: routing closes a lying interface, and nothing
\* stated over the interface can close an incoherent model behind an
\* honest one.
\*
\* Amounts, and the buyer. No prices, no totals, no shop's cut, and a
\* sale's buyer leaves no trace but the standing. The payout is
\* item-grained and the standing carries it: sold is owed, settled is
\* paid.
\* ---------------------------------------------------------------------
=========================================================================
