---------------------------- MODULE BondedStore ----------------------------
\* The bonded-store reference, commented after the freeze. The spec text is
\* the frozen BondedStore.tla byte for byte, and harness/comment-gate.sh
\* checks that claim rather than trusting it. Comments are the only addition.
\*
\* Frozen BondedStore.tla, sha256:
\*   ed6093d4e0425f27da8177abb54e3da9e77e1146012752f5b85359cb57a43901
\*
\* Written for a reader who has already put a property set against this
\* store. The notes cover decisions, not syntax: the state I shipped and the
\* rivals I turned down, where a step's atomicity boundary falls, what each
\* obligation grades and what it leaves ungraded, and the rules no property
\* here can carry. Numbers come from reports/step2-variants.md and
\* reports/step6-spread.md, and the rejected representations from
\* author-notes/ALTERNATIVES.md.

\* The store's own set of lots, not a device for keeping the model finite.
\* Every obligation below has to hold at any finite size. The shipped config
\* picks 3, the least that holds one lot in each of the store's three
\* outcomes at once, one still inside, one released, one moved on. Two lots
\* already bite the duty rule in both directions, so the third lot buys the
\* three-outcome state and nothing else.

CONSTANTS Lots

(*--algorithm bondedstore {
  \* Two functions, a lot to a place string and a lot to a boolean. Observe
  \* below renders as the identity over them, field for field, so the state
  \* is the interface and nothing hides behind a projection. The measured run
  \* at three lots is 145 states generated, 64 distinct, depth 7, under a
  \* second.
  \*
  \* The rivals I weighed and turned down, at length in ALTERNATIVES.md:
  \*
  \* Duty derived from place, with dutyPaid read off place = "released". It's
  \* shorter and it drops a variable. It also turns DutyMatchesPlace into a
  \* claim about my own definition instead of a claim about the keeper's
  \* steps. The cost is measured rather than argued. Variant S03 pays the
  \* duty on a lot moved on under bond, and the shipped form catches it at
  \* rc=12. Under the derived form that mutant can't be written at all, and
  \* the derived spec reaches the reference's own 145 and 64 states
  \* (step2-variants.md finding 12). An obligation nothing can break isn't an
  \* obligation.
  \*
  \* One variable of per-lot records, each holding a place and a duty field.
  \* It reads well and it keeps a lot's two facts together. I rejected it on
  \* the interface: the description names two fields, so Observe would have
  \* to project each one back out of the record and would stop being a plain
  \* record over state. That's a legibility call, not a correctness one, and
  \* the qsl reference made the same call for the same reason.
  \*
  \* Four sets partitioning Lots, one per place, with movement as a transfer
  \* between sets. This one costs a cfg line, and that's what killed it. A
  \* lot sits in one place because place is a function, so rule 1's
  \* one-place-at-a-time clause rides the shape and needs no property. Four
  \* independent sets can overlap or drop a lot, so the model would owe a
  \* fifth obligation saying the sets partition Lots. Five lines breaks the
  \* rung's property count.
  \*
  \* A stage number in 0 to 3. Release and movement under bond aren't ordered
  \* against each other. Both are terminal and neither follows the other, so
  \* a number invites a reader to look for a sequence rule 5 says isn't
  \* there, and it pulls in Naturals for nothing.
  \*
  \* Duty as an amount instead of a flag. Rule 3 asks whether the duty is
  \* paid and never how much, so an amount is state no obligation reads, and
  \* it multiplies the state space by the range to buy that.
  \*
  \* What gets no variable at all: time, money, capacity, and the receiving
  \* store. A bond expiry needs a calendar, and a calendar is a step this
  \* system assigns to nobody. Rates and totals grade nothing the store asks
  \* about. A floor limit needs a guard on entry plus a fifth obligation to
  \* grade the cap. The receiving store sits outside the boundary by rule 4,
  \* so a lot moved on is simply gone and there's nothing left to observe.

  variables
    place = [l \in Lots |-> "notEntered"],
    dutyPaid = [l \in Lots |-> FALSE];

  define {
    Places == {"notEntered", "inStore", "released", "movedOn"}

    Observe == [place |-> place, dutyPaid |-> dutyPaid]

    TypeOK ==
        /\ Observe.place \in [Lots -> Places]
        /\ Observe.dutyPaid \in [Lots -> BOOLEAN]

    DutyMatchesPlace ==
        \A l \in Lots :
            Observe.dutyPaid[l] <=> Observe.place[l] = "released"

    MovementIsLawful ==
        [][\A l \in Lots :
              /\ ((Observe.place[l] = "notEntered"
                       /\ Observe'.place[l] # "notEntered")
                     => Observe'.place[l] = "inStore")
              /\ ((Observe.place[l] = "inStore"
                       /\ Observe'.place[l] # "inStore")
                     => Observe'.place[l] \in {"released", "movedOn"})]_Observe

    LeavingIsFinal ==
        [][\A l \in Lots :
              Observe.place[l] \in {"released", "movedOn"} =>
                  /\ Observe'.place[l] = Observe.place[l]
                  /\ Observe'.dutyPaid[l] = Observe.dutyPaid[l]]_Observe
  }

  \* One label, one process, and no pc in the translation. A label per action
  \* would read closer to the three rules, and I kept one on purpose. A
  \* program counter is state the stock account can't show, and I'd rather
  \* not carry a variable Observe has no honest field for. The single label
  \* is also what makes each keeper step atomic, which is what rule 3 means
  \* by paying the duty in the same motion.
  \*
  \* It costs something, and the cost is worth knowing. TLC prints one
  \* coverage row per disjunct of Next, and all three rows here are named
  \* Next, because the disjuncts come from one either inside one label. So a
  \* name-based dead-action probe has nothing to miss, and a variant with the
  \* movement arm deleted comes back non-vacuous (step2-variants.md finding
  \* 8). I'd read that as a limit on the probe for every one-label algorithm,
  \* not as a defect here.
  \*
  \* Nothing is fair and nothing has to happen. Rule 6 is graded by
  \* restraint. There's no fairness conjunct and no liveness obligation, and
  \* that absence is the whole of it. Once every lot has left the store no
  \* action is enabled and the system stops, which is the intended end of the
  \* story, so the cfg carries CHECK_DEADLOCK FALSE. The alternative was an
  \* idle action, and an idle action is a step this system assigns to nobody.

  {
    Keep:
      while (TRUE) {
        \* One lot per step, picked non-deterministically. The keeper works
        \* on whichever lot he likes in whatever order, so the with models
        \* his choice rather than a scheduler.

        with (l \in Lots) {
          either {
            \* Entry. The await is rule 2's guard, and goods never arrive on
            \* their own. Dropping the guard doesn't route where you'd
            \* expect: it comes back against the duty invariant rather than
            \* against the movement rule (step2-variants.md finding 7).

            await place[l] = "notEntered";
            place[l] := "inStore";
          } or {
            \* Release, and the atomicity boundary that matters most here.
            \* The lot leaves and the duty is paid in one step, because
            \* rule 3 makes release the duty point and gives no way to do
            \* one without the other. A separate payment action would need
            \* a fifth place, duty paid but still stored, and that kills
            \* the biconditional this rung leans on.
            \*
            \* A compound step reads as two steps to some people. One panel
            \* seat in three read the mirror-image forbidden trace that way
            \* and mis-attributed which obligation rejects it
            \* (step6-spread.md finding 1). Worth knowing before anyone
            \* writes an attribution by hand instead of running it.

            await place[l] = "inStore";
            place[l] := "released";
            dutyPaid[l] := TRUE;
          } or {
            \* Movement under bond. The lot leaves and the duty stays unpaid,
            \* because the bond carries on at the receiving store. That
            \* store has no observable at all, which is the point of
            \* putting it outside the boundary. Nothing here says the lot
            \* arrives anywhere, and nothing needs to.

            await place[l] = "inStore";
            place[l] := "movedOn";
          };
        };
      };
  }
}*)
\* ---------------------------------------------------------------------
\* The obligations, and why the notes on them sit here.
\*
\* pcal copies a define block into the generated translation word for word,
\* blank lines and all, so a comment written up there moves the translation
\* and the comment gate reads that as a changed spec. Measured on this file
\* against harness/comment-gate.sh. The definitions read the same either way,
\* so this is where the reasoning lives.
\*
\* Four cfg lines, and the kind decisions carry more judgment than the
\* formulas do.
\*
\*   state invariants   TypeOK, DutyMatchesPlace
\*   action properties  MovementIsLawful, LeavingIsFinal
\*   liveness           none, and the absence is itself graded. See the
\*                      closing note under the translation.
\* ---------------------------------------------------------------------
\*
\* Places.
\*
\* The four places live in the module because the rules fix them, not the
\* config. Declaring them as cfg model values was the alternative, and a
\* cfg that can vary them is a cfg that can model a store with three
\* places, which isn't this system.
\*
\* TypeOK is the only thing that reads this. Worth knowing, because the
\* learner's copy of the module ships without TypeOK, so Places looks
\* decorative there and invites a fourth property nobody asked for. The
\* panel raised it twice (step6-spread.md finding 6). It's an artifact of
\* the split, not of the reference.
\*
\* Observe.
\*
\* The store's whole public face, the stock account a keeper could read
\* off at any moment. It renders as the identity over the state, and that
\* rendering also fixes the subscript for both action properties below.
\*
\* Two things about it I'd rather say out loud than leave implied.
\*
\* DESCRIPTION section 5 narrows the author: the spec's own variables
\* mustn't carry the Observe field names, so that Observe reads as a
\* definition over state rather than a rename of it. This spec renames,
\* field for field, and the step-2 gate caught the contradiction
\* (step2-variants.md finding 10). I think the state-is-the-interface
\* reading is worth the cost at this rung, where the learner writes no
\* state at all and reads the actions instead. At a rung where they write
\* state, I'd expect the narrowing back.
\*
\* Because Observe is the identity here, a predicate over the bare place
\* and dutyPaid means the same thing as one over Observe.place and
\* Observe.dutyPaid. One panel seat wrote the bare form throughout and
\* was sound for it (step6-spread.md finding 5). That equality is an
\* accident of this rendering. Under the record rival or the partition
\* rival it stops holding, so the habit worth keeping is to write every
\* predicate over Observe.
\*
\* TypeOK.
\*
\* Shape only, and it's the reference author's own line rather than one
\* handed to the learner. It carries rule 1's four-places clause as a
\* real cfg line instead of as a shape argument. The rest of rule 1 rides
\* the shape of a total function. A lot has one place and there's nowhere
\* to record a second, and Lots is fixed and total under place, so lots
\* are never split, merged or created.
\*
\* It also fires first when a mutation is untyped. A write-off exit that
\* leaves Places alone comes back rc=12 here rather than against the
\* movement rule the break belongs to, because an invariant sits earlier
\* in the cfg and fires on the state (step2-variants.md finding 6). The
\* obligation that fires isn't always the one the mistake belongs to.
\*
\* DutyMatchesPlace.
\*
\* Duty and place agree, as a plain state invariant. The biconditional is
\* load-bearing in both directions, and I'd resist any weakening of it.
\*
\* Right to left is what stops a free release. Left to right is what
\* stops a payment on a lot still in the store, and that's the direction
\* a reader is tempted to drop. Variant P05 weakens this to released
\* implies paid and then misses S01, which pays the duty on a stored lot
\* with place unchanged (step2-variants.md finding 5). Nothing else in
\* the set sees S01 either. That step moves only dutyPaid, so both arms
\* of MovementIsLawful are vacuous and LeavingIsFinal's antecedent is
\* false. The one-way form doesn't just weaken this obligation, it leaves
\* the step with no obligation watching it at all.
\*
\* This is the workhorse of the variant matrix. Release without paying,
\* duty paid on a moved-on lot, a refund on a released lot, and a dropped
\* entry guard all land here. That last one routes here rather than to
\* the movement rule, by way of a released lot being put back in the
\* store still carrying its paid duty (step2-variants.md finding 7).
\*
\* What it says nothing about: how much the duty is, when it was paid, or
\* who paid it. Duty is a yes or no at this interface.
\*
\* MovementIsLawful.
\*
\* The way in and the two ways out, both arms under one property, because
\* they're two halves of one movement rule rather than two rules.
\*
\* Each arm's antecedent needs the lot's own place to have changed, so
\* standing still satisfies both arms for free. That's deliberate, and
\* it's the trap this rung sets. Read as an obligation to move, the
\* property fails on the shipped spec, because one lot sits still while
\* another acts. A panel seat built that control and got rc=13 back
\* (step6-spread.md finding 4). I'd call that the healthy kind of
\* mistake, since the learner's own run catches it.
\*
\* The subscript is the whole of Observe, never one field, and this is
\* the place to say why once. A subscript names the state whose stutter a
\* step property forgives. Subscript this over Observe.dutyPaid and every
\* place-only step gets absorbed by the stuttering disjunct. Measured:
\* S06 takes a stored lot back to not entered, the shipped form returns
\* rc=13 and the dutyPaid-subscripted form returns rc=0
\* (step2-variants.md finding 4). TLC issues no warning. The property
\* just stops looking at the steps it was written about, and two panel
\* seats reproduced the same silent green by different routes.
\*
\* What it doesn't carry: how many lots move in one step. It quantifies
\* over lots one at a time, so a keeper who enters two lots at once
\* breaks nothing here and comes back rc=0 at the reference's own 64
\* distinct states. That's a gap in the description rather than in the
\* property, and it's worth a sentence in rule 1 either way
\* (step2-variants.md finding 8).
\*
\* LeavingIsFinal.
\*
\* Out stays out, in both clauses, place and duty, because the rule states
\* both. Whether the second clause is redundant was a live question, and
\* the matrix answered it in two parts.
\*
\* The place clause earns its own cfg line. A carried note claimed this
\* whole property follows from the other two together, and four variants
\* refute it: re-entry from moved on, a released lot turning into a
\* moved-on one with the duty dropped in the same step, a moved-on lot
\* going released, and an opening that starts every lot released. Each is
\* rc=13 here and each holds both other obligations throughout
\* (step2-variants.md finding 2). The reason sits in the arms above. Both
\* guard on a lot being not entered or in store, so neither says anything
\* at all about a lot that has already left.
\*
\* The duty clause has no arrow pointing at it, and I think that's
\* structural rather than luck. Any step that changes an out lot's duty
\* leaves that lot either released and unpaid or moved on and paid, and
\* the biconditional above refuses both. So no variant can exercise this
\* clause alone, and dropping it changes nothing the harness can see
\* (step2-variants.md finding 3). It stays because the rule says it and a
\* reader shouldn't have to derive it. Don't expect the gate to defend
\* it.

\* Below is pcal's output, and it's the text TLC actually reads. Two things
\* about it have tripped a reader already. It carries no pc variable, which
\* is right for a one-process algorithm with a single label, since a constant
\* program counter buys nothing. And a define block's operators are copied
\* down here word for word, which is why every obligation appears twice in
\* this file. Read the algorithm above for intent and this block for what ran.

\* BEGIN TRANSLATION (chksum(pcal) = "24038cab" /\ chksum(tla) = "7a766261")
VARIABLES place, dutyPaid

(* define statement *)
Places == {"notEntered", "inStore", "released", "movedOn"}

Observe == [place |-> place, dutyPaid |-> dutyPaid]

TypeOK ==
    /\ Observe.place \in [Lots -> Places]
    /\ Observe.dutyPaid \in [Lots -> BOOLEAN]

DutyMatchesPlace ==
    \A l \in Lots :
        Observe.dutyPaid[l] <=> Observe.place[l] = "released"

MovementIsLawful ==
    [][\A l \in Lots :
          /\ ((Observe.place[l] = "notEntered"
                   /\ Observe'.place[l] # "notEntered")
                 => Observe'.place[l] = "inStore")
          /\ ((Observe.place[l] = "inStore"
                   /\ Observe'.place[l] # "inStore")
                 => Observe'.place[l] \in {"released", "movedOn"})]_Observe

LeavingIsFinal ==
    [][\A l \in Lots :
          Observe.place[l] \in {"released", "movedOn"} =>
              /\ Observe'.place[l] = Observe.place[l]
              /\ Observe'.dutyPaid[l] = Observe.dutyPaid[l]]_Observe


vars == << place, dutyPaid >>

Init == (* Global variables *)
        /\ place = [l \in Lots |-> "notEntered"]
        /\ dutyPaid = [l \in Lots |-> FALSE]

Next == \E l \in Lots:
          \/ /\ place[l] = "notEntered"
             /\ place' = [place EXCEPT ![l] = "inStore"]
             /\ UNCHANGED dutyPaid
          \/ /\ place[l] = "inStore"
             /\ place' = [place EXCEPT ![l] = "released"]
             /\ dutyPaid' = [dutyPaid EXCEPT ![l] = TRUE]
          \/ /\ place[l] = "inStore"
             /\ place' = [place EXCEPT ![l] = "movedOn"]
             /\ UNCHANGED dutyPaid

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 

\* ---------------------------------------------------------------------
\* What this property set deliberately can't carry.
\*
\* Who acts. Observe shows the store, not the hands in it. "The keeper enters
\* the lot" can't be a property of any model at this interface, whatever
\* fields you add. At this shape the spec ships complete, so the learner
\* reads the actions instead of grading them.
\*
\* An obligation to act. The keeper owes nothing, ever. That's carried by
\* restraint, and only an over-constrained spec gets it wrong.
\*
\* The opening state. Nothing pins every lot to not entered at the start.
\* Variants that open lots in the store, or open them released, both come
\* back rc=0 at the reference's own 64 distinct states, because the added
\* initial states were already reachable (step2-variants.md finding 8). A
\* fifth cfg line would close it and would break the rung's property count.
\* That was a stated decision, and this is its cost turning up where it was
\* predicted.
\*
\* A store that does too little. Delete the movement-under-bond arm and every
\* obligation still passes, at 27 distinct states. Every obligation here is a
\* safety property or a boxed action, and both kinds survive taking a subset
\* of the behaviors. No property set can see a system that does less than it
\* should.
\*
\* An empty run. A store whose entry action is gone satisfies all four
\* obligations vacuously on one state. The obligations miss it and the
\* vacuity gate catches it at rc=10, which is the argument for running that
\* gate on every grading run and not only on the reference
\* (step2-variants.md finding 11).
\*
\* Deficiency, partial lots, re-entry, and capacity. Real stores have all
\* four, and each one is a third way out or a new dimension carrying its own
\* duty rule. Any of them costs at least one more obligation, and the count
\* here already sits at the top of the rung's band.
\* ---------------------------------------------------------------------

=============================================================================
