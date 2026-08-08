------------------------------- MODULE Bureau -------------------------------
\* The QSL bureau reference, commented after the freeze. The spec text is
\* the frozen Bureau.tla byte for byte, and harness/comment-gate.sh checks
\* that claim rather than trusting it. Comments are the only addition.
\*
\* Written for a reader who has already built a property set against this
\* system. The notes cover decisions, not syntax: the representation and
\* its rejected rivals, each action's atomicity boundary, the kind and the
\* subscript of each obligation, and the rules no property here can carry.
\* Measurements cited below are from step2-variants.md and step6-spread.md
\* in authoring/qsl/reports/.

\* The domain's own sets, not devices for keeping the model finite. Every
\* obligation below must hold for any finite instance. The shipped config
\* picks 3 operators and 2 bands: the least where mutuality bites across
\* distinct pairs, and the least where the band half of a claim does work.
CONSTANTS Operators, Bands

\* Two functions, each operator to a set of [station, band] records. The
\* state is the interface: Observe below renders as the identity over it.
\*
\* Rivals weighed and rejected:
\*
\* Credit as one set of pair-facts (an unordered operator pair plus a
\* band). Mutuality would hold by construction, and no action could break
\* it. That turns Observe.credited into a derived projection, and it makes
\* CreditIsMutual unfalsifiable inside the model. An obligation that can't
\* fail grades nothing. A legibility call, not a correctness call: the
\* obligations hold either way.
\*
\* One flat [owner, station, band] relation. The per-owner partition is
\* what the one-envelope rule and the filed rendering both want, and the
\* function form gives it for free. The relation form re-derives it inside
\* every obligation that mentions a file.
\*
\* Tuples instead of records for claims. Records won because f.station
\* reads at the interface without positional decoding. Cheap call.
\*
\* What has no variable at all: the station logs at home, and the truth of
\* any claim. Private logging is stutter under Observe, so a model that
\* carries logs and one that skips straight to the mail produce identical
\* observations. Whether a claim describes a contact that happened is
\* knowledge the register never has, so the model never states it. Dates,
\* times, modes, and signal reports fall the same way: the one question
\* this register answers is worked-or-not, per counterpart, per band.
VARIABLES filed, credited

vars == <<filed, credited>>

\* One operator's claim space. Excluding o is the desk refusal (you can't
\* work yourself), landed in the type rather than as a guard inside Mail.
\* The set shape carries duplicate collapse on its own: a set can't hold a
\* claim twice, so re-mailing a claim on file changes nothing, and no
\* property needs to say so.
ClaimsBy(o) == [station : Operators \ {o}, band : Bands]

\* The bureau's whole public face, the files and the register, rendered as
\* the identity over state. That rendering also fixes the subscript for
\* every action property below. The note at FilesOnlyGrow says what goes
\* wrong when a subscript names one field instead of the whole record.
Observe == [filed |-> filed, credited |-> credited]

\* A definition, not a behavior: corroborated-on-b is a fact about a pair,
\* readable from the files alone. No obligation constrains it directly.
\* The behavior it feeds is graded at CreditIsCorroborated and at
\* BureauKeepsUp.
Corroborated(a, c, b) ==
    /\ [station |-> c, band |-> b] \in Observe.filed[a]
    /\ [station |-> a, band |-> b] \in Observe.filed[c]

\* Empty files, empty register. Half of the soundness argument at
\* CreditIsCorroborated rests here. See that note.
Init ==
    /\ filed = [o \in Operators |-> {}]
    /\ credited = [o \in Operators |-> {}]

\* One envelope, one step. The atomicity boundary is the envelope, not the
\* claim: the bureau opens mail one envelope at a time, so all of an
\* envelope's claims land together and the register holds still.
\*
\* The draw is from the NONEMPTY powerset. An empty envelope is stutter
\* under Observe, so admitting it buys self-loop edges and nothing else
\* (measured: the variant that keeps it reaches the same 15,625 states).
\*
\* Note what this action does not pin down: that multi-claim envelopes
\* exist at all. A bureau restricted to single-claim mail reaches the
\* same states, and no property can catch that. See the closing note.
Mail(o) ==
    /\ \E env \in (SUBSET ClaimsBy(o)) \ {{}} :
           filed' = [filed EXCEPT ![o] = @ \cup env]
    /\ UNCHANGED credited

\* One fact, both sides, one motion. The conjuncts, in order:
\*
\* Corroborated(a, c, b) is the charter's gate. The bureau credits only
\* what the files support, and CreditIsCorroborated grades the gate.
\*
\* The \notin guard trims re-credit steps. Re-crediting a held fact would
\* change nothing observable, so the guard is invisible to every property
\* (measured: dropping it adds self-loops and nothing else). It is here
\* for the state graph, not for the grade.
\*
\* UNCHANGED filed keeps a credit step from filing its own proof. A
\* variant that files the mirror claim and credits it in one step is
\* caught as a malformed envelope, not as a bad credit.
Credit(a, c, b) ==
    /\ Corroborated(a, c, b)
    /\ [station |-> c, band |-> b] \notin credited[a]
    /\ credited' = [credited EXCEPT
                        ![a] = @ \cup {[station |-> c, band |-> b]},
                        ![c] = @ \cup {[station |-> a, band |-> b]}]
    /\ UNCHANGED filed

CreditStep == \E a, c \in Operators, b \in Bands : Credit(a, c, b)

\* Two events, and only two. Their observable signatures are disjoint by
\* construction: mail moves one file, credit moves two register entries.
\* OneEnvelopeAtATime and CreditComesWhole grade the signatures.
Next ==
    \/ \E o \in Operators : Mail(o)
    \/ CreditStep

\* The charter lands as fairness, and the form is a decision. Two
\* candidates: WF on the existential CreditStep, or per-fact WF quantified
\* over pairs and bands. The existential form is the weaker assumption,
\* and it suffices: facts are finite and credit is permanent, so every
\* non-stuttering credit step credits a new fact, the fact space runs out,
\* and a pending fact's turn must come. I think the weaker form is also
\* the truer reading of the charter. The bureau owes work, not any
\* particular order. BureauKeepsUp leans on this conjunct: drop it and the
\* leads-to fails over a trace that ends in a stuttering lasso.
Spec == Init /\ [][Next]_vars /\ WF_vars(CreditStep)

\* ---------------------------------------------------------------------
\* The obligations. Ten in the config. The kind decisions carry more of
\* the judgment than the formulas do:
\*
\*   state invariants   TypeOK, FilesWellFormed, CreditIsCorroborated,
\*                      CreditIsMutual
\*   opening condition  Opening (a PROPERTY, not an INVARIANT)
\*   action properties  FilesOnlyGrow, OneEnvelopeAtATime,
\*                      CreditComesWhole, CreditIsPermanent
\*   liveness           BureauKeepsUp, the only one
\* ---------------------------------------------------------------------

\* Shape only, and looser than ClaimsBy on purpose: station ranges over
\* all Operators here, so a self-claim is a content bug, not a type bug.
\* FilesWellFormed carries the content. A violation then reports as the
\* rule that broke instead of as a type error.
TypeOK ==
    /\ filed \in [Operators -> SUBSET [station : Operators, band : Bands]]
    /\ credited \in [Operators -> SUBSET [station : Operators, band : Bands]]

\* A condition on the opening state only, and the kind trap runs both
\* ways. As an INVARIANT this is false the moment any file grows. And a
\* state predicate under PROPERTIES constrains only the initial state, so
\* an intended invariant filed there silently grades the opening alone.
\* Here PROPERTIES is the correct home. The step-6 panel demonstrated
\* both directions live.
Opening ==
    \A o \in Operators :
        /\ Observe.filed[o] = {}
        /\ Observe.credited[o] = {}

\* Every claim on a file names a different operator and a band from the
\* band set. This invariant is also why the a # c conjunct in
\* CreditComesWhole is defensive rather than load-bearing. See there.
FilesWellFormed ==
    \A o \in Operators : Observe.filed[o] \subseteq ClaimsBy(o)

\* The moment-of-credit rule, done as a plain state invariant. The
\* argument has two legs. CreditComesWhole keeps a credit step from
\* filing the claims that justify it, so a credit sound now was sound
\* when given. Init starts the register empty and FilesOnlyGrow keeps
\* every claim on file, so a credit sound when given is sound now. A
\* model is free to maintain either reading. The obligations don't care.
\*
\* In the variant matrix this is the workhorse: ungated credit,
\* one-sided corroboration, self-credit, and the wrong-band mirror all
\* land here. That last one was authored against mutuality and routes
\* here instead, because a credit mirrored onto the wrong band has no
\* corroboration behind it.
CreditIsCorroborated ==
    \A o \in Operators :
        \A f \in Observe.credited[o] : Corroborated(o, f.station, f.band)

\* Both directions, so a one-sided grant and a one-sided loss both break
\* it. Under this representation mutuality CAN break, and the variant
\* that drops half the credit update is caught here in 4 states. Under
\* the pair-fact rival it could not break, and an obligation that can't
\* fail grades nothing.
CreditIsMutual ==
    \A a, c \in Operators, b \in Bands :
        [station |-> c, band |-> b] \in Observe.credited[a]
            <=> [station |-> a, band |-> b] \in Observe.credited[c]

\* The place to state the subscript rule once. The subscript names the
\* state whose stutter a step property forgives, so it must be _Observe,
\* the whole record, on every step obligation here. Subscript this one
\* _(Observe.credited) instead and every mail step is exempt from the
\* box, because mail leaves credited alone. The property then never
\* examines the steps it was written about, and TLC reports green with
\* no warning. That silent green was measured twice: in the step-2
\* matrix, and again by the step-6 panel against the very mutant the
\* property was written to catch.
\*
\* One caveat from the matrix: with the wrong subscript here, a
\* file-shrinking bureau is still caught, but by BureauKeepsUp, because
\* a shrunk file loses its corroboration and the leads-to still demands
\* the credit. That coverage is incidental. Treat a green run on one
\* variant as weak evidence about one property, in this problem more
\* than most.
FilesOnlyGrow ==
    [][\A o \in Operators : Observe.filed[o] \subseteq Observe'.filed[o]]_Observe

\* The envelope's event signature: exactly one file grows, every other
\* file and the whole register hold still. This is what catches a
\* carbon-copy mail step, and it is half of what keeps the two events
\* distinguishable by signature alone.
OneEnvelopeAtATime ==
    [][Observe'.filed # Observe.filed =>
           \E o \in Operators :
               /\ \A p \in Operators \ {o} : Observe'.filed[p] = Observe.filed[p]
               /\ Observe'.credited = Observe.credited]_Observe

\* The credit's event signature: one new fact, both sides in the same
\* motion, everyone else framed, files untouched. This is the obligation
\* whose wrong-field subscript went silently green in the measurements:
\* under _(Observe.filed) a credit step is absorbed by the stuttering
\* disjunct, and the band-batching mutant this property catches came
\* back clean.
\*
\* The a # c conjunct is defensive, not load-bearing. Without it a
\* one-sided self-credit satisfies the obligation through a collapsed
\* witness with a = c, where the two per-side updates land on one
\* operator. The matrix could not build a variant where this conjunct
\* alone makes the catch: the collapse needs a self-claim on file to get
\* past CreditIsCorroborated, and no well-formed file holds one. It
\* stays so the step obligation stands on its own instead of leaning on
\* a neighbor. One conjunct buys that.
CreditComesWhole ==
    [][Observe'.credited # Observe.credited =>
           \E a, c \in Operators, b \in Bands :
               /\ a # c
               /\ [station |-> c, band |-> b] \notin Observe.credited[a]
               /\ Observe'.credited[a] =
                      Observe.credited[a] \cup {[station |-> c, band |-> b]}
               /\ Observe'.credited[c] =
                      Observe.credited[c] \cup {[station |-> a, band |-> b]}
               /\ \A p \in Operators \ {a, c} :
                      Observe'.credited[p] = Observe.credited[p]
               /\ Observe'.filed = Observe.filed]_Observe

\* Follows from CreditComesWhole in one line: any step that changes the
\* register adds one fact to both sides and frames everyone else, so
\* every credited set only grows. The matrix agrees: both variants
\* authored against permanence were reported against CreditComesWhole,
\* and nothing was ever caught by this property alone. It stays because
\* the charter states it and a reader shouldn't have to derive it. A
\* property set that ships without it, with the coupling argued, matches
\* the measurement rather than missing it.
CreditIsPermanent ==
    [][\A o \in Operators : Observe.credited[o] \subseteq Observe'.credited[o]]_Observe

\* The one liveness obligation. Whenever a fact is corroborated on file
\* and uncredited, it is eventually credited. The leads-to re-arms in
\* every state where the antecedent holds, so the bureau can't discharge
\* the charter once and retire. This is the property that leans on
\* WF_vars(CreditStep). Without the fairness the bureau may simply stop,
\* and the violation arrives as a stuttering lasso.
BureauKeepsUp ==
    \A a, c \in Operators, b \in Bands :
        (Corroborated(a, c, b)
             /\ [station |-> c, band |-> b] \notin Observe.credited[a])
            ~> [station |-> c, band |-> b] \in Observe.credited[a]

\* ---------------------------------------------------------------------
\* What this property set deliberately cannot carry. The step-6 panel
\* produced this taxonomy blind, which I take as evidence the boundary
\* is real and not an author's rationalization.
\*
\* Permissions. "The bureau may credit" and "an envelope can carry
\* several claims" assert that behaviors exist. Safety and liveness
\* properties constrain the behaviors that do exist, so neither kind can
\* demand one. Measured: a bureau restricted to single-claim mail
\* reaches the reference's own 15,625 states, so envelope granularity
\* degrades to operator granularity with nothing watching.
\*
\* Absent obligations. The operators owe nothing, ever. That is carried
\* by restraint: no fairness sits on Mail, and nothing demands an
\* envelope. Only an over-constrained spec gets this wrong, and only a
\* control run notices.
\*
\* Ground truth. Whether a claim describes a contact that happened is
\* outside the interface. The register never knows, so the model never
\* says.
\*
\* Idempotence. Re-mailing a claim on file changes nothing because a
\* set can't hold a duplicate. The representation carries the rule, so
\* no property has to.
\*
\* The re-credit guard. Crediting a held fact again would change
\* nothing observable, so the \notin guard in Credit is invisible to
\* every property here. State-graph hygiene, not graded behavior.
\* ---------------------------------------------------------------------
=============================================================================
