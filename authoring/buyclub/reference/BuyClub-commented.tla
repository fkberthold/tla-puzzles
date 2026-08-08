------------------------------ MODULE BuyClub ------------------------------
\* The frozen reference, with the author's commentary. The spec text is
\* byte-identical to BuyClub.tla in this directory, comments aside, and
\* harness/comment-gate.sh checks that mechanically rather than trusting
\* it. Read this after your own attempt, next to the alternatives note
\* (ALTERNATIVES.md), which records the representations that lost. The
\* comments explain modeling decisions, not TLA+.
EXTENDS Naturals, FiniteSets

\* Min is the supplier's term, Cap is the club's own rule that no one
\* household takes the whole delivery. Both are facts of the system
\* before they are model bounds, and Cap earns its keep twice: it
\* bounds any one pledge and it gives the book a finite type.
CONSTANTS Members, Products, Min, Cap

\* Min >= 1 because a zero minimum is no minimum at all.
ASSUME /\ IsFiniteSet(Members)
       /\ IsFiniteSet(Products)
       /\ Min \in Nat /\ Min >= 1
       /\ Cap \in Nat

\* Three variables, one per observable, and nothing else. Keeping book
\* and share apart is what makes collection visible: at a collect step
\* the book holds still and the share moves. The representations that
\* lost (a stored order total, one record per product, a collected
\* flag, partial share maps, phase sets) are argued one by one in the
\* alternatives note.
VARIABLES phase, book, share

vars == <<phase, book, share>>

\* Strings, not model values. Model values would add cfg plumbing for a
\* fixed three-word vocabulary, and the strings print as corkboard
\* facts in traces and in Observe.
Phases == {"open", "placed", "arrived"}

\* One name for the pledge range, read by Pledge's guard and by TypeOK,
\* so the guard and the type can't drift apart. Zero means no pledge,
\* which keeps book and share total functions with no moving domain.
PledgeAmounts == 0..Cap

\* The book's total for p, computed at the moment it's needed. There's
\* no stored order total on purpose: placement closes the book on p, so
\* the total stays derivable for the rest of the product's story.
\* Storing it buys one lookup and costs a variable plus a coupling
\* invariant tying it to the book forever. The recursive sum keeps
\* EXTENDS down to Naturals and FiniteSets.
Total(p) ==
    LET Sum[T \in SUBSET Members] ==
            IF T = {} THEN 0
            ELSE LET m == CHOOSE x \in T : TRUE
                 IN  book[m][p] + Sum[T \ {m}]
    IN  Sum[Members]

\* The opening: every product open, every number zero.
Init ==
    /\ phase = [p \in Products |-> "open"]
    /\ book  = [m \in Members |-> [p \in Products |-> 0]]
    /\ share = [m \in Members |-> [p \in Products |-> 0]]

\* A pledge rewrites one book cell while the product is open, and
\* nothing else moves. Two decisions live in the guard. The "open" test
\* is what closes the book at placement: no revision lands after it,
\* and SharesTellTheBook leans on that freeze. Excluding the standing
\* number keeps the no-op out, so every pledge step is a real book
\* move. Allowing it would only add self-loops the step properties
\* exempt as stutters anyway.
Pledge(m, p, n) ==
    /\ phase[p] = "open"
    /\ n \in PledgeAmounts \ {book[m][p]}
    /\ book' = [book EXCEPT ![m][p] = n]
    /\ UNCHANGED <<phase, share>>

\* Placement is one step carrying three facts: the product closes for
\* good, each standing pledge becomes that member's share, and the
\* order goes out for the book's total. Splitting those across steps
\* would make states where the book is closed but no share is set, and
\* no rule of the club names such a moment.
\*
\* The threshold is read at this step and nowhere else. The total can
\* fall back under Min while the product sits open, and nothing here
\* remembers that it was ever covered. That race, a withdrawal landing
\* just before the coordinator moves, is the heart of this system.
\*
\* The snapshot writes every member's share of p from the book in one
\* stroke and touches no other product's shares. And note what Place
\* does not have: fairness. Reaching the minimum never forces the
\* order. See the comment at Spec.
Place(p) ==
    /\ phase[p] = "open"
    /\ Total(p) >= Min
    /\ phase' = [phase EXCEPT ![p] = "placed"]
    /\ share' = [m \in Members |-> [share[m] EXCEPT ![p] = book[m][p]]]
    /\ UNCHANGED book

\* Delivery moves the phase and nothing else. The supplier has no other
\* observable effect, and no property names it as an actor.
Deliver(p) ==
    /\ phase[p] = "placed"
    /\ phase' = [phase EXCEPT ![p] = "arrived"]
    /\ UNCHANGED <<book, share>>

\* The share > 0 guard carries "once" on its own: collection zeroes the
\* share, and the guard shuts behind it. The tempting alternative was a
\* collected flag with shares kept frozen. I think that version is
\* defensible, but Observe would have to compute the visible share
\* instead of reading it, and the flag needs its own invariant to stay
\* honest. One member, one product, the whole share: no partial
\* pickups, no trades at the table.
Collect(m, p) ==
    /\ phase[p] = "arrived"
    /\ share[m][p] > 0
    /\ share' = [share EXCEPT ![m][p] = 0]
    /\ UNCHANGED <<phase, book>>

\* Four moves, one per kind of step, free to interleave. Nothing
\* coordinates the members, so any party's step can land between any
\* two steps of another.
Next ==
    \/ \E m \in Members, p \in Products, n \in PledgeAmounts : Pledge(m, p, n)
    \/ \E p \in Products : Place(p)
    \/ \E p \in Products : Deliver(p)
    \/ \E m \in Members, p \in Products : Collect(m, p)

\* The one fairness conjunct, and its placement is a decision. Delivery
\* is the single obligation in this system: a placed order eventually
\* arrives, and everything else is permission. Weak fairness is enough
\* because a placed product keeps Deliver(p) enabled until it fires.
\* And there's deliberately no fairness on Place. Fairness there would
\* compel the order once the pledges cover Min, and the club's rule is
\* that reaching the minimum never forces anything.
Spec == Init /\ [][Next]_vars /\ \A p \in Products : WF_vars(Deliver(p))

\* Identity packaging: the graded interface and the moving state are
\* the same values. I wanted a mismatch to only ever come from a
\* property, never from a rendering step.
Observe == [phase |-> phase, book |-> book, share |-> share]

\* The book is well formed and phases stay in range. share draws from
\* the same range as book because a share is only ever a frozen book
\* entry or zero.
TypeOK ==
    /\ phase \in [Products -> Phases]
    /\ book  \in [Members -> [Products -> PledgeAmounts]]
    /\ share \in [Members -> [Products -> PledgeAmounts]]

\* The state-level tie between shares and the book: an open product
\* carries only zero shares, and afterward each share is that member's
\* book entry or zero. The comparison against book only means something
\* because Pledge's "open" guard froze the book at placement. If the
\* book could move afterward, this would measure against a moving
\* target. The invariant and the freeze carry that rule together.
SharesTellTheBook ==
    \A m \in Members, p \in Products :
        IF phase[p] = "open"
        THEN share[m][p] = 0
        ELSE share[m][p] \in {book[m][p], 0}

\* The opening condition. It sits in the cfg as a PROPERTY, not an
\* INVARIANT, because it must hold at the first state and only there.
\* As an invariant it would be false one pledge in.
Opening ==
    /\ \A p \in Products : phase[p] = "open"
    /\ \A m \in Members, p \in Products : book[m][p] = 0 /\ share[m][p] = 0

\* Any step that moves the book moves one cell, only while that product
\* is open, and moves nothing else. The frame clauses (the
\* every-other-cell quantifier and the UNCHANGED) are the load-bearing
\* half. When the seeded-variant matrix attacked this spec, the
\* hold-still clauses were the surface that mattered: a pledge writing
\* a whole row, a pledge that also moves a share, a combined
\* deliver-and-pledge step. All three were caught, two here and one by
\* SharesTellTheBook.
OneHandOnTheBook ==
    book' # book =>
        /\ \E m \in Members, p \in Products :
                /\ phase[p] = "open"
                /\ book'[m][p] # book[m][p]
                /\ \A mm \in Members, pp \in Products :
                        (mm # m \/ pp # p) => book'[mm][pp] = book[mm][pp]
        /\ UNCHANGED <<phase, share>>

\* Placed only at a step where the pledges cover Min. The antecedent
\* names the placement step, open before and placed after, so a model
\* whose placement jumps straight to arrived slides past this property
\* as vacuously true. TwoWaysOnly is what catches that model, on the
\* shares jumping at a step that isn't open-to-placed.
ThresholdAtPlacement ==
    \A p \in Products :
        (phase[p] = "open" /\ phase'[p] = "placed") => Total(p) >= Min

\* At placement each member's share of p becomes the standing pledge,
\* and every other share of every product holds still. The second
\* conjunct is the frame, and it isn't decoration: without it a
\* placement could quietly zero a neighbor product's shares.
SnapshotAtPlacement ==
    \A p \in Products :
        (phase[p] = "open" /\ phase'[p] = "placed") =>
            /\ \A m \in Members : share'[m][p] = book[m][p]
            /\ \A m \in Members, pp \in Products :
                    pp # p => share'[m][pp] = share[m][pp]

\* A share moves at two moments only: its product's placement, zero up
\* to the pledge, and its owner's collection, the whole share back to
\* zero, only after arrival, only from a positive share. The collection
\* disjunct carries its own frames because nothing else pins down what
\* a collect step may move. The placement disjunct travels lighter,
\* since Snapshot already carries those frames.
SharesMoveTwoWays ==
    \A m \in Members, p \in Products :
        share'[m][p] # share[m][p] =>
            \/ /\ phase[p] = "open" /\ phase'[p] = "placed"
               /\ share[m][p] = 0
               /\ share'[m][p] = book[m][p]
            \/ /\ phase[p] = "arrived"
               /\ share[m][p] > 0
               /\ share'[m][p] = 0
               /\ UNCHANGED <<phase, book>>
               /\ \A mm \in Members, pp \in Products :
                        (mm # m \/ pp # p) => share'[mm][pp] = share[mm][pp]

\* Phases run one way, one product per step, and a phase move carries
\* no book change. The second conjunct is delivery's own-step clause:
\* placed to arrived moves no share. Placement can't say the same,
\* because the snapshot is a share move by design.
PhasesRunForward ==
    /\ \A p \in Products :
            phase'[p] # phase[p] =>
                /\ \/ phase[p] = "open" /\ phase'[p] = "placed"
                   \/ phase[p] = "placed" /\ phase'[p] = "arrived"
                /\ \A pp \in Products : pp # p => phase'[pp] = phase[pp]
                /\ UNCHANGED book
    /\ \A p \in Products :
            (phase[p] = "placed" /\ phase'[p] = "arrived") => UNCHANGED share

OneHandAtATime == [][OneHandOnTheBook]_vars

Threshold == [][ThresholdAtPlacement]_vars

Snapshot == [][SnapshotAtPlacement]_vars

TwoWaysOnly == [][SharesMoveTwoWays]_vars

ForwardPhases == [][PhasesRunForward]_vars

\* The one liveness obligation, and the only line that needs the
\* fairness in Spec. Everything else in this model is permission.
DeliveryComes ==
    \A p \in Products : (phase[p] = "placed") ~> (phase[p] = "arrived")

\* ---------------------------------------------------------------------
\* What this obligation set deliberately does not carry.
\*
\* Over-constraint. Every obligation above quantifies over all
\* behaviors, so a model that removes behaviors passes them all. A club
\* where nobody withdraws, a placement compelled at the minimum, a
\* placement whose guard demands the total equal Min: all came back
\* green when we seeded them. No strengthening of this set changes
\* that, because removing behaviors can't falsify a universally
\* quantified property. Over-constraint is graded on the other channel:
\* your conjuncts must not forbid behaviors the reference allows. Worth
\* naming: the no-withdrawal club reaches the same 20,736 states as the
\* reference at the shipped instance. Only the transitions differ, and
\* the withdrawal race is the heart of the system.
\*
\* The ordered amount. The club orders the book's total, and no
\* observable carries that number, so a model that orders the wrong
\* amount passes everything here. The elision is deliberate: after the
\* freeze the total is a function of the book, so a stored copy adds no
\* distinguishing power, only a coupling invariant to keep honest.
\*
\* Hands. A pledge shows whose row moved. A placement and a delivery
\* show no hand at all, and no property names the coordinator or the
\* supplier as an actor.
\* ---------------------------------------------------------------------
=============================================================================
