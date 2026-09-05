----------------------------- MODULE Herbarium -----------------------------
\* The herbarium-sheet reference, commented after the freeze. The spec text
\* below is the frozen Herbarium.tla byte for byte, at sha256
\* 9405395b58fb8bf9eb07eb70668a211aef6179113f3f0fae7c1de2ec0391c8db, and
\* harness/comment-gate.sh checks that claim rather than trusting it. Comments
\* are the only addition.
\*
\* Written for a reader who has already modelled this system and wants to see
\* what they missed. The notes cover decisions, not syntax. They carry the five
\* variables and the rivals they beat, where each action's atomicity boundary
\* sits, which of the seven requirements each obligation grades, which measured
\* variant it catches, and what nothing here can carry at all.
\*
\* Measurements come from reports/step2-variants.md and reports/step6-spread.md
\* in authoring/herbarium-sheet/. A variant id like S13 or P03S11 is a row in
\* the step 2 matrix.
\*
\* This rung ships a seeded defect. The block after ConsultationIsAnswered says
\* what it is, why it passes, and why counting states won't find it.
EXTENDS Naturals

\* Sheets are accession numbers rather than model values, and that's forced.
\* Allowances below has to tell them apart to give one sheet 2 and the other 1.
\* TLC's config grammar takes model values, numbers, strings and sets of those,
\* and it won't take a function literal. Handling = [s1 |-> 2, s2 |-> 1] in the
\* cfg dies with a ConfigFileException at that line, which I checked. So
\* Handling is a declared constant the cfg overrides with a definition in the
\* module. A sheet carries an accession number in real life, so I don't think
\* the numbering reads as a modelling accident.
\*
\* None is one marker for two fields, reading and accepted. Both have an empty
\* case, and I'd rather the two empty cases look the same at the interface.
CONSTANTS Sheets, Botanists, Names, Handling, None

\* The allowance is a number per sheet, and the marker sits outside Names.
\* Keeping it out of Names is what lets a comparison against a name answer
\* false rather than abort the run.
ASSUME /\ Handling \in [Sheets -> Nat]
       /\ None \notin Names

\* Five variables, one per Observe field, and Observe renders as the identity
\* over them. That's the representation decision on this rung. A sixth variable
\* would break it: a derived cache, or a history the operator can't show, takes
\* the representation level from 2 to 3.
\*
\* Rivals weighed and rejected.
\*
\* Slips as a sequence, or as a map from stamp to name. The map gives
\* distinctness for free, since a function holds one value per point, and it
\* makes the accepted name a lookup at the largest key. It loses because
\* distinctness is graded here. Requirement 1 says no two slips on one sheet
\* share a stamp, and under the map shape that clause can't fail inside the
\* model. A requirement the representation makes unfalsifiable is one no seeded
\* defect can be built against, and this whole rung leans on seeded defects. The
\* sequence loses from the other side. Position would carry the order, the
\* highest-stamped slip would turn into the last one, and the stamp would stop
\* doing any work.
\*
\* Reading as one set of [botanist, sheet, stamp] records, present or absent.
\* The function wins on two counts. Rule 2 caps a botanist at one open
\* consultation per sheet, and a function has nowhere to put a second, so the
\* cap rides the representation instead of needing a property. And the set form
\* reports an absent consultation by absence, where accepted reports its empty
\* case with a marker.
\*
\* Reading as the last stamp read, with a separate boolean for openness. That
\* splits one fact over two fields, and the interface has room for one. The
\* stamp field would then report history, where every other field here reports
\* the current moment.
VARIABLES slips, consulted, reading, accepted, doubted

vars == <<slips, consulted, reading, accepted, doubted>>

\* The whole public face of the collection, and it renders as the identity over
\* the state. That rendering also fixes the subscript for every step obligation
\* below. The note at RecordOnlyGrows says what a narrowed subscript costs, and
\* the closing block says what it cost here on purpose.
\*
\* Why accepted is carried and never derived. This is the one real decision in
\* the operator, so it gets said plainly. Define accepted as the top slip's name
\* and requirement 2 becomes an identity. TLC passes it, the learner has written
\* TRUE in a costume, and nothing is graded. So the filing step sets the name,
\* which means a step could in principle move it out of step with the slips, and
\* requirement 2 is what forbids that. The cost is real. A filing has to compute
\* the top of a slip set that's about to change. Variant S09 files under the
\* filer's own name and AcceptedIsTopSlip catches it, so the property does lean
\* on the choice.
\*
\* Why reading is a field at all, and it's the hard one. What a botanist read is
\* a fact about the botanist, not about the sheet. A model that skips it reports
\* every other field correctly and still can't state requirement 4. It also
\* can't express the failure this system is about, which is a botanist filing a
\* determination that was current when they read it and isn't current when it
\* lands.
Observe ==
    [slips     |-> slips,
     consulted |-> consulted,
     reading   |-> reading,
     accepted  |-> accepted,
     doubted   |-> doubted]

\* What has no variable at all, and why each elision is safe.
\*
\* No calendar. Real determination slips are dated. A date is a step this system
\* assigns to no party, so it takes step sources from 1 to 3 and breaks the rung
\* outright. The consultation count already gives the only order the rules ask
\* for.
\*
\* No loans. A sheet never leaves the herbarium. A borrowing curator is a second
\* kind of actor, and nothing in the seven requirements reads a sheet's
\* location.
\*
\* No retraction. A slip is never removed and never edited. Real herbaria answer
\* a slip they think is wrong with another slip, and this model already allows
\* that, so the append-only reading loses nothing the domain needs.
\*
\* No nomenclature past the top slip. Priority, synonymy, basionyms and types
\* are a second system sitting on this one, and none of them is readable from
\* the interface.
\*
\* No countersigning curator. Anyone who consulted may file. A countersignature
\* is another kind of actor, at the same cost as the loans above.
\*
\* No doubter. Who raised a mark is state Observe can't show and no obligation
\* can constrain, which is the definition of decoration here. The description
\* says recording one isn't banned, so I looked, and nothing grades it.
\*
\* No filer's name on the slip. Whose consultation closed is visible in the
\* step, and requirement 4 reads it there, so a name field would be a second
\* copy of a fact the step already carries.

\* Every stamp any sheet can hand out, unioned over the sheets. The bound is the
\* handling allowance, which is a conservation fact about a pressed specimen
\* before it's a finiteness device. Handling damages a specimen, so the
\* herbarium caps it. Without the cap the consultation count is unbounded and
\* there's no finite instance to check.
Stamps == UNION {1..Handling[s] : s \in Sheets}

\* The shape of a filed slip. Used by TypeOK and nowhere else, because the
\* content rules live in RecordWellFormed.
Slip == [name : Names, stamp : Stamps]

\* The name on the highest-stamped slip. The CHOOSE is determined rather than
\* arbitrary, because RecordWellFormed makes the stamps on one sheet distinct,
\* so the maximum is unique. It's undefined on the empty set, which is why
\* AcceptedIsTopSlip splits the empty case out instead of calling this.
TopName(S) == (CHOOSE r \in S : \A q \in S : q.stamp =< r.stamp).name

\* What the cfg overrides Handling with. Sheet 1 takes two consultations and
\* sheet 2 takes one. Two on one sheet is the least that lets two botanists hold
\* a stamp each, which is the least that lets the lost determination happen at
\* all. The second sheet is there so the per-sheet rules have something to be
\* wrong about. A filing on one sheet must not move the other's accepted name
\* and must not take the other's mark off. Its allowance of 1 keeps it cheap,
\* and a fragile sheet with a short allowance is an ordinary thing to find in a
\* collection.
Allowances == [s \in Sheets |-> IF s = 1 THEN 2 ELSE 1]

\* The opening is bare. Every field starts at its empty case, and Opening below
\* is the obligation that grades it. A slip present at the opening is a way a
\* slip gets onto a sheet that no step obligation sees, since requirement 4 only
\* watches slips that appear in a step. An earlier rung's review was blocked on
\* exactly that shape of gap.
Init ==
    /\ slips = [s \in Sheets |-> {}]
    /\ consulted = [s \in Sheets |-> 0]
    /\ reading = [b \in Botanists |-> [s \in Sheets |-> None]]
    /\ accepted = [s \in Sheets |-> None]
    /\ doubted = [s \in Sheets |-> FALSE]

\* The atomicity boundary is the whole consultation. The register moves and the
\* botanist takes the stamp in one step. Split it and two botanists can read the
\* same number, and the count is the only order this system has.
\*
\* consulted[s] + 1 is the same value as consulted'[s], written the way it
\* reads. The step hands out the number it just took.
\*
\* The guard is the withdrawal rule. A sheet at its allowance takes no further
\* consultations, and anyone already holding an open one can still file on it.
\*
\* Re-consulting a sheet you already hold overwrites your stamp, and the old one
\* is gone. That's ambiguity 7 resolved. Letting a botanist accumulate open
\* consultations and file against any of them multiplies the state and asks
\* nothing new. It's load-bearing further downstream, though. A replaced stamp
\* is not a closed consultation, so requirement 4's way-out clause doesn't fire
\* on a re-consultation, and neither does the liveness obligation discharge on
\* one. A blind seat flagged that the rules never say so outright, and it's
\* right.
Consult(b, s) ==
    /\ consulted[s] < Handling[s]
    /\ consulted' = [consulted EXCEPT ![s] = @ + 1]
    /\ reading' = [reading EXCEPT ![b][s] = consulted[s] + 1]
    /\ UNCHANGED <<slips, accepted, doubted>>

\* One slip, one step, and the same step closes the consultation, sets the
\* accepted name and takes the doubtful mark off. Four of the five fields move
\* together here, and that's the atomicity boundary the rules ask for. Rule 3
\* says filing closes the consultation, rule 5 says the accepted name is the top
\* slip at every moment, and rule 6 says a filing is the only thing that clears
\* a mark. Split any of those out and there's a reachable state where the record
\* disagrees with itself.
\*
\* The slip carries the stamp the botanist holds. Requirement 4 grades only that
\* it's at most that stamp, so a botanist who files below the one they hold
\* passes the cap. That cap stays a cap on purpose. Tighten it to equality and a
\* state with two slips at one stamp breaks requirements 3 and 4 as well, so
\* requirement 1's distinctness clause loses the trace that would isolate it.
\* I'd rather keep the looser cap and the isolating trace.
\*
\* The mark comes off whoever files, not only the botanist who raised it. That's
\* ambiguity 9. Binding it to the doubter is a stronger obligation and one more
\* clause on the rule, for no new modelling question.
\*
\* UNCHANGED consulted keeps a filing from taking a consultation it never asked
\* for. The mirror case is variant S13, where a consultation moves the count and
\* hands out no stamp, and RecordOnlyGrows catches it in 2 states.
File(b, s, n) ==
    /\ reading[b][s] # None
    /\ LET filed == slips[s] \cup {[name |-> n, stamp |-> reading[b][s]]}
       IN  /\ slips' = [slips EXCEPT ![s] = filed]
           /\ accepted' = [accepted EXCEPT ![s] = TopName(filed)]
           /\ reading' = [reading EXCEPT ![b][s] = None]
           /\ doubted' = [doubted EXCEPT ![s] = FALSE]
    /\ UNCHANGED consulted

\* The existential over names is the step fairness sits on below. The botanist
\* has to file something on that sheet, and which name they pick stays free.
FileStep(b, s) == \E n \in Names : File(b, s, n)

\* Marking isn't a determination, so it leaves the consultation open. That's
\* what makes the obligation deliverable. The botanist still holds an open
\* consultation, so their filing step is enabled and stays enabled, and the
\* filing is what takes the mark off.
\*
\* The reading guard is ambiguity 8. You can only doubt a sheet you've looked
\* at. Let anyone mark any sheet at any time and nobody is on the hook for it,
\* because no fairness sits on a step of theirs. Variant S21 drops this conjunct
\* and ConsultationIsAnswered catches it at rc=13 over 10 states.
\*
\* The doubted[s] = FALSE guard is my call, and the description leaves it open.
\* Marking a sheet that's already marked is a no-op on paper too, so the
\* alternative is a self-loop under Observe with every variable unchanged. It
\* buys no reachable state and no property. I went with the guard because a step
\* that can't change the record is a step the model doesn't need, and because
\* the vacuity probe's dead-action check reads better when every action moves
\* something. Anyone who wants the looser reading drops one conjunct, and
\* nothing else moves.
\*
\* A sheet with no slips can be marked. Requiring an accepted name first is
\* ambiguity 10 the other way, and variant S23 measures what that costs. It
\* comes back rc=0 over 155 distinct states, uncaught. No obligation here can
\* see it, and I don't think any safety or liveness property over Observe could,
\* because "a bare sheet can be marked" is a claim that a behavior exists.
Doubt(b, s) ==
    /\ reading[b][s] # None
    /\ doubted[s] = FALSE
    /\ doubted' = [doubted EXCEPT ![s] = TRUE]
    /\ UNCHANGED <<slips, consulted, reading, accepted>>

\* Three actions, and every one of them is some botanist's. There's no clock, no
\* calendar and no step that happens on its own, which is what holds this rung
\* at one step source. Observe shows the record and not the hands in it, so
\* "every step is a botanist's" isn't a property any model here can carry. The
\* closing block says so as a taxonomy entry rather than as a gap.
Next ==
    \/ \E b \in Botanists, s \in Sheets : Consult(b, s)
    \/ \E b \in Botanists, s \in Sheets : FileStep(b, s)
    \/ \E b \in Botanists, s \in Sheets : Doubt(b, s)

\* Weak fairness on one botanist's filing on one sheet, and on nothing else.
\* Consulting and doubting carry no fairness, and that restraint is what leaves
\* rule 7's "nothing else is obliged" true.
\*
\* Weak is enough. Once a botanist holds an open consultation of a sheet, their
\* filing stays enabled until they take it, so strong fairness would be a
\* heavier assumption than the system needs.
\*
\* The form is a decision this instance can't measure, and I want that on the
\* record. I expected the per-botanist-per-sheet form to be needed here, and I
\* wrote that down before running it. It isn't needed. Variant P04 takes the
\* single existential over botanists and sheets, P05 takes the per-botanist
\* form, P06 puts weak fairness on Next, and all three come back rc=0 over the
\* reference's own 259 distinct states.
\*
\* The handling allowance is why. It caps consultations, so every behavior holds
\* finitely many filings and nobody can file forever to starve another botanist
\* out. Once every other action is disabled the pending filing is all that's
\* left, and it fires. Only dropping the conjunct outright shows up, which is
\* variant S22 at rc=13 over 8 states and a stuttering tail.
\*
\* So a seeded defect that weakens the fairness form won't be caught at 2 sheets
\* and 2 botanists. I kept this form anyway. Lift the allowance and the single
\* existential lets one botanist file forever while another's consultation sits
\* open, so this is the reading that survives a bigger instance. The repair for
\* the measurement gap is a bigger instance, and that costs this rung its
\* state-space band, so I'd rather record the limit than pay for it.
Spec ==
    /\ Init
    /\ [][Next]_vars
    /\ \A b \in Botanists, s \in Sheets : WF_vars(FileStep(b, s))

\* ---------------------------------------------------------------------
\* The obligations. Eight lines in the cfg, three under INVARIANTS and five
\* under PROPERTIES. Seven are the description's seven requirements. The eighth,
\* TypeOK, is mine, and the learner is never asked to produce it.
\*
\*   requirement 1   RecordWellFormed
\*   requirement 2   AcceptedIsTopSlip
\*   requirement 3   RecordOnlyGrows
\*   requirement 4   SlipComesFromAConsultation
\*   requirement 5   DoubtClearsOnlyOnFiling
\*   requirement 6   ConsultationIsAnswered, the only liveness here
\*   requirement 7   Opening, under PROPERTIES and not under INVARIANTS
\*
\* Requirements 1 and 2 are claims about one state. Requirements 3, 4 and 5 each
\* compare the record at two consecutive moments, so all three are action
\* properties subscripted over the whole of Observe. Requirement 6 is the one
\* that needs "eventually". Requirement 7 is a condition on the opening.
\*
\* Each note below names the shortest measured variant its obligation catches,
\* from reports/step2-variants.md section 6.
\* ---------------------------------------------------------------------

\* Mine, and none of the seven. It carries shape and nothing else, which is
\* looser than the content rules on purpose. RecordWellFormed carries the
\* content, so a violation reports as the rule that broke rather than as a type
\* error. Catches variant S24, where a slip's name field carries the stamp, at
\* rc=12 over 3 states.
TypeOK ==
    /\ Observe.slips \in [Sheets -> SUBSET Slip]
    /\ Observe.consulted \in [Sheets -> Nat]
    /\ Observe.reading \in [Botanists -> [Sheets -> Stamps \cup {None}]]
    /\ Observe.accepted \in [Sheets -> Names \cup {None}]
    /\ Observe.doubted \in [Sheets -> BOOLEAN]

\* Requirement 1, in four clauses: the stamp range on a filed slip, distinctness
\* on one sheet, the range on an open consultation, and the handling cap.
\* Catches variant S05, where a consultation hands out the allowance instead of
\* the new count, at rc=12 over 2 states. Variant S06's uncapped allowance lands
\* here too, at 3 states.
\*
\* The distinctness clause has no variant that isolates it, and I'd rather say
\* so than let a reader take the two catches above as coverage of all four
\* clauses. Variant S07 stamps every slip 1 and was authored to reach a state
\* with two slips at one stamp under different names. It never gets there. A
\* botanist re-filing a name already on the sheet leaves slips unchanged while
\* their consultation closes, which trips requirement 4 two steps before the
\* two-name state is reachable. The mutation that would isolate the clause
\* forbids the no-change filing. Nobody has run it.
RecordWellFormed ==
    \A s \in Sheets :
        /\ \A r \in Observe.slips[s] :
              /\ r.name \in Names
              /\ r.stamp \in 1..Observe.consulted[s]
        /\ \A r, q \in Observe.slips[s] : r.stamp = q.stamp => r = q
        /\ \A b \in Botanists :
              Observe.reading[b][s] # None =>
                  Observe.reading[b][s] \in 1..Observe.consulted[s]
        /\ Observe.consulted[s] =< Handling[s]

\* Requirement 2, and it does the work the derived field would have done for
\* free. It pins the accepted name to the top slip in every state, so a step
\* that moves the name has to move the slips. That's why no step rule about the
\* accepted name earns a line of its own, and why the screener's "the accepted
\* name moves only on a filing" got dropped. Anything that breaks that rule
\* breaks this one in the same state, so no trace isolates it, and a line that
\* grades nothing is worse than no line because it reads as coverage.
\*
\* Catches variant S08, a filing that leaves the name alone, at rc=12 over 3
\* states. Variants S09 and S10 file the wrong name and land here at 5 states.
AcceptedIsTopSlip ==
    \A s \in Sheets :
        IF Observe.slips[s] = {}
        THEN Observe.accepted[s] = None
        ELSE Observe.accepted[s] = TopName(Observe.slips[s])

\* Requirement 7, and the kind decision is the whole point of it. A state
\* predicate under PROPERTIES constrains the initial state alone, which is what
\* an opening condition wants. As an INVARIANT it's false the moment any sheet
\* is consulted. TLC prints a paragraph here recommending INVARIANT for a
\* state-level formula under PROPERTIES, and for this formula the recommendation
\* is wrong. Two blind seats hit that warning and read it right, and a learner
\* is likely to read it as their own mistake.
\*
\* Catches variant S03, an opening with a consultation count of 1, at rc=13, and
\* S01's opening doubt the same way. Two measured facts about how it reports.
\* TLC splits a PROPERTIES state predicate per top-level conjunct and names a
\* source location rather than the obligation, so a tutor has no name to print.
\* And the invariants beat it at the opening: S02 seeds a slip and S04 seeds an
\* accepted name, and both report against RecordWellFormed and AcceptedIsTopSlip
\* instead, because TLC checks the invariants on the initial state before the
\* implied inits.
Opening ==
    /\ \A s \in Sheets :
          /\ Observe.slips[s] = {}
          /\ Observe.consulted[s] = 0
          /\ Observe.accepted[s] = None
          /\ Observe.doubted[s] = FALSE
    /\ \A b \in Botanists, s \in Sheets : Observe.reading[b][s] = None

\* Requirement 3, and the place to state the subscript rule once. The subscript
\* names the state whose stutter a step obligation forgives, so it has to be
\* _Observe, the whole record, on all three step obligations here.
\*
\* Narrow this one to _(Observe.consulted) and every filing is exempt, because a
\* filing leaves the count alone. Variant P03S11 measures it: the property goes
\* blind to a filing that replaces a sheet's slips, and the whole obligation set
\* then passes at rc=0 over 245 distinct states. Nothing else notices a slip
\* leaving a sheet. Requirement 4 sees one slip appear and a consultation close,
\* which is all it asks, and requirement 2 sees an accepted name that agrees
\* with the one slip that's left.
\*
\* This is the one place on this problem where a wrong subscript is graded by
\* the property it belongs to, which is why requirement 3 is the one whose
\* subscript the learner picks. Narrow requirement 4 the same way and variant
\* P02S16 gets caught anyway, at rc=13 by requirement 6, over a sheet whose
\* allowance is spent and whose mark nobody can ever take off. That coverage is
\* incidental. It has nothing to do with the property that was got wrong, so
\* treat a green run on one variant as weak evidence about one property.
\*
\* Three clauses sit past the growth: the count rises one at a time, the new
\* number lands in some botanist's hand, and a botanist's stamp changes only at
\* a step where that sheet's count rises to it. Catches variant S13, a
\* consultation that bumps the count and hands out nothing, at rc=13 over 2
\* states.
RecordOnlyGrows ==
    [][\A s \in Sheets :
          /\ Observe.slips[s] \subseteq Observe'.slips[s]
          /\ Observe.consulted[s] =< Observe'.consulted[s]
          /\ (Observe'.consulted[s] # Observe.consulted[s] =>
                 /\ Observe'.consulted[s] = Observe.consulted[s] + 1
                 /\ \E b \in Botanists :
                       Observe'.reading[b][s] = Observe'.consulted[s])
          /\ \A b \in Botanists :
                (/\ Observe'.reading[b][s] # None
                 /\ Observe'.reading[b][s] # Observe.reading[b][s])
                    => /\ Observe'.consulted[s] # Observe.consulted[s]
                       /\ Observe'.consulted[s] = Observe'.reading[b][s]]_Observe

\* Requirement 4, in both directions. The way in forbids a slip appearing with
\* no consultation closing, holds one filing to one slip, and caps the stamp at
\* what that consultation carried. The way out forbids a consultation closing
\* with nothing filed.
\*
\* Both halves are load-bearing. A set that ships the way in alone passes this
\* instance without carrying the requirement, and a blind seat did exactly that.
\* Its declared seven came back rc=0 against the forbidden run built for this
\* requirement, where the same run with the way-out clause added comes back
\* rc=13.
\*
\* Catches variant S16, a consultation cancelled with nothing filed, at rc=13
\* over 3 states. S16 is the shortest, and I'd take it over S18's filing with no
\* consultation at all, which reads as a typo rather than as something a person
\* would build.
SlipComesFromAConsultation ==
    [][\A s \in Sheets :
          /\ (Observe'.slips[s] # Observe.slips[s] =>
                 \E b \in Botanists :
                     \E r \in Observe'.slips[s] \ Observe.slips[s] :
                         /\ Observe'.slips[s] \ Observe.slips[s] = {r}
                         /\ Observe.reading[b][s] # None
                         /\ Observe'.reading[b][s] = None
                         /\ r.stamp =< Observe.reading[b][s])
          /\ \A b \in Botanists :
                (/\ Observe.reading[b][s] # None
                 /\ Observe'.reading[b][s] = None)
                    => Observe'.slips[s] \ Observe.slips[s] # {}]_Observe

\* Requirement 5, and this is the formula the seeded defect is made from. Here
\* it carries the wide subscript and it works. Catches variant S19, a
\* consultation taking the mark off, at rc=13 over 4 states, and the hidden
\* model D01 at 4 states. The block below says what ships to the learner in its
\* place.
\*
\* This requirement isn't in the screener's sketch and I added it. Without it
\* the doubt half of requirement 6 grades almost nothing, because a model that
\* lets a mark come off on any step satisfies "a doubted sheet is eventually
\* re-determined" for free.
DoubtClearsOnlyOnFiling ==
    [][\A s \in Sheets :
          (/\ Observe.doubted[s] = TRUE
           /\ Observe'.doubted[s] = FALSE)
              => Observe'.slips[s] \ Observe.slips[s] # {}]_Observe

\* Requirement 6, the only liveness here, and both clauses ship on one cfg line.
\* The first obliges every open consultation to close. The second obliges every
\* doubtful mark to come off.
\*
\* The wide clause doesn't stand in for the narrow one, which is why both are
\* here. A model where filing leaves the mark on satisfies the first clause and
\* requirement 5 both, and the mark never comes off. The second clause is what
\* grades that.
\*
\* One fairness conjunct delivers both halves. A botanist who marks a sheet
\* still holds an open consultation of it. Their filing step is enabled from
\* that moment and stays enabled, and the filing takes the mark off.
\*
\* Catches variant S22, the fairness conjunct dropped, at rc=13 over 8 states
\* and a stuttering tail. Variants S20 and S21 land here too. Every liveness
\* counterexample on this problem ends in a stuttering tail rather than a back
\* edge, and that matters downstream. No finite prefix violates this property,
\* so a trace player that closes a finite run with stutter makes this fire on
\* runs that are lawful. See the last paragraph of the block below.
ConsultationIsAnswered ==
    /\ \A b \in Botanists, s \in Sheets :
          (Observe.reading[b][s] # None) ~> (Observe.reading[b][s] = None)
    /\ \A s \in Sheets :
          (Observe.doubted[s] = TRUE) ~> (Observe.doubted[s] = FALSE)

\* ---------------------------------------------------------------------
\* The seeded defect. This rung hands the learner a green TLC run and asks why
\* the green is worth nothing, so the seeding gets explained here rather than
\* left for a reader to reconstruct.
\*
\* Requirement 5 ships already rendered, subscript and all, and the subscript is
\* wrong on purpose. What the learner gets is this:
\*
\*     DoubtClearsOnlyOnFiling ==
\*         [][\A s \in Sheets :
\*               (/\ Observe.doubted[s] = TRUE
\*                /\ Observe'.doubted[s] = FALSE)
\*                   => Observe'.slips[s] \ Observe.slips[s] # {}]_(Observe.slips)
\*
\* Same body as the shipped module above. The subscript is _(Observe.slips)
\* rather than _Observe, and _Observe is the widening that fixes it.
\*
\* Why it can't see the step it's about. [][A]_v holds on any step that leaves v
\* alone, whatever A says. A step that clears a mark and files nothing leaves
\* slips untouched, so it's a stutter for the formula and the body is never
\* looked at. Those steps are the whole of what the rule was written to catch.
\* Every other step falls one of two ways. It touches slips, and then a slip has
\* appeared and the consequent holds anyway. Or it leaves the marks alone, and
\* the antecedent is false. So TLC returns green and reports no violation,
\* because there was nothing to violate.
\*
\* The subscript names the consequent's field rather than the antecedent's, and
\* I think that's what makes it fair to seed rather than a trick. Requirement 4
\* sits one line up, and it opens on a step where a slip appears, so watching
\* Observe.slips reads as the natural move there. The defect is that subscript
\* copied one line down onto a rule whose subject is the marks. It's the mistake
\* the layout invites.
\*
\* The state count doesn't discriminate it, and I'd rather say that plainly than
\* leave anyone hunting for a suspicious number. There isn't one. The hidden
\* model D01, where a mark comes off on any step, reaches 259 distinct states in
\* 1,275 generated. This reference reaches the same 259 distinct in 1,103
\* generated. The step 6 panel then found two more wrong models landing on 259:
\* a re-doubting variant at 1,289 generated, and a blind seat whose Doubt
\* carries no doubted[s] = FALSE guard, also at 1,289, which read its 259 as a
\* match. Two wrong models reach the count, so the distinct count is a one-way
\* check here. The figure that discriminates is 1,103 generated, not 259
\* distinct. The vacuity gate doesn't discriminate it either, and reports
\* NON_VACUOUS with all five probes clean on the seeded run.
\*
\* So the only way in is to know which steps clear a mark and then read which of
\* them the subscript lets through. Two of the three panel seats diagnosed the
\* seed blind, and both proved it with a mutant rather than by argument.
\*
\* One caution the panel settled, and it matters to anyone holding the shipped
\* formula against a trace. Nothing in a correct set of the seven rejects the
\* forbidden run built for requirement 5. Requirement 5 is blind to it by
\* construction, and the other six hold on it. Requirement 6 looks like it
\* rejects the run under a trace player that closes a finite prefix with a
\* stuttering tail, and that reading is wrong. The same instrument rejects runs
\* the statement guarantees are lawful, and requirement 6 is pure liveness, so
\* no finite prefix can violate it. One seat took the stuttering reading and
\* called it a rejection, which is the route that lets a reader stop before the
\* diagnosis.
\* ---------------------------------------------------------------------

\* ---------------------------------------------------------------------
\* What this obligation set deliberately can't carry.
\*
\* Authorship. Observe shows the record, not the hands in it, so "every step is
\* some botanist's" isn't statable over any model here, whatever fields you add,
\* because the interface has nowhere to report that a step had no author. Which
\* botanist filed is visible, since it's whose consultation closed, and
\* requirement 4 reads it there. Whether a step happened by itself is not. All
\* three blind seats found this edge on their own, which I take as evidence the
\* boundary is real rather than my rationalization.
\*
\* Permissions. "A bare sheet may be marked doubtful" and "a botanist may
\* re-consult a sheet they hold" assert that behaviors exist. Safety and
\* liveness properties constrain the behaviors that do exist, so neither kind
\* can demand one. Variant S23 is the measurement, at rc=0 and uncaught over 155
\* distinct states.
\*
\* The fairness form. Three forms agree at this instance and TLC can't tell them
\* apart. The note at Spec carries the measurement and the reason.
\*
\* Absent obligations. Nobody has to consult anything and nobody has to doubt
\* anything, and a sheet nobody has consulted can sit undetermined as long as
\* the collection lasts. That's carried by restraint, since no fairness sits on
\* Consult or on Doubt. Only an over-constrained model gets it wrong, and only a
\* control run notices.
\*
\* Idempotence, and the re-doubt guard. Re-filing a slip already on a sheet
\* changes nothing, because a set can't hold a duplicate, so the representation
\* carries the rule and no property has to. The doubted[s] = FALSE guard in
\* Doubt is invisible to every obligation here in the same way. Both are
\* state-graph hygiene rather than graded behavior.
\*
\* A model that does nothing. Variant S25 replaces Next with UNCHANGED vars, and
\* all eight obligations pass it at rc=0 over one distinct state. It's the one
\* variant the obligations can't touch and the vacuity gate can, at
\* VACUOUS_EMPTY_SPACE against a floor of 100. That's the argument for running
\* the gate on every grading run rather than only on the reference.
\*
\* Quiescence, which is not a fault. When every consultation is closed and every
\* sheet has reached its allowance, no action is enabled and the system stops.
\* That's the intended end of the story, so the cfg sets CHECK_DEADLOCK FALSE
\* rather than inventing a stuttering action this system doesn't have.
\* ---------------------------------------------------------------------
=============================================================================
