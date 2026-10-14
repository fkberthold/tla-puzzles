---- MODULE Pipeline ----
\* The system behind drill item 07-pipeline-halt. Spec has the eviction bug
\* the prompt describes; SpecFixed does not. The answer is a state predicate
\* over ENABLED, checked as an invariant and as a boxed property.
EXTENDS Naturals

VARIABLES stage, artifact, retries

vars == <<stage, artifact, retries>>

MaxRetries == 1

Init == /\ stage = "queued"
        /\ artifact = "none"
        /\ retries = 0

Start == /\ stage = "queued"
         /\ stage' = "building"
         /\ UNCHANGED <<artifact, retries>>

Build == /\ stage = "building"
         /\ stage' = "testing"
         /\ artifact' = "present"
         /\ UNCHANGED retries

BuildFail == /\ stage = "building"
             /\ stage' = "failed"
             /\ UNCHANGED <<artifact, retries>>

Pass == /\ stage = "testing"
        /\ artifact = "present"
        /\ stage' = "done"
        /\ UNCHANGED <<artifact, retries>>

Retry == /\ stage = "testing"
         /\ retries < MaxRetries
         /\ stage' = "queued"
         /\ retries' = retries + 1
         /\ UNCHANGED artifact

\* The cache may evict the artifact at any time. That is the bug.
Evict == /\ artifact = "present"
         /\ artifact' = "none"
         /\ UNCHANGED <<stage, retries>>

Next == Start \/ Build \/ BuildFail \/ Pass \/ Retry \/ Evict

Spec == Init /\ [][Next]_vars

\* The fix: no eviction while the artifact is under test.
EvictSafe == /\ artifact = "present"
             /\ stage # "testing"
             /\ artifact' = "none"
             /\ UNCHANGED <<stage, retries>>

NextFixed == Start \/ Build \/ BuildFail \/ Pass \/ Retry \/ EvictSafe

SpecFixed == Init /\ [][NextFixed]_vars

Halted == stage \in {"done", "failed"}

\* The answer, as an invariant and as a property, against each Next.
HaltsOnlyFinished      == ~Halted => ENABLED Next
HaltsOnlyFinishedFixed == ~Halted => ENABLED NextFixed
AnswerProp      == [](~Halted => ENABLED Next)
AnswerPropFixed == [](~Halted => ENABLED NextFixed)

\* The guard, written out by hand. Equal to the answer on this system.
Inlined == ~Halted => (stage = "testing" => (artifact = "present" \/ retries < MaxRetries))

\* Neighbors.
N1 == []<>Halted
N2 == <>Halted
N4 == ~Halted => ENABLED Next
====
