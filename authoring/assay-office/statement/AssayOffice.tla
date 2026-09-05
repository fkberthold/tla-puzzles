---------------------------- MODULE AssayOffice ----------------------------
CONSTANTS Wares, Officers

(*--algorithm assayoffice {
  variables
    book = [w \in Wares |->
                [verdict |-> "none", struck |-> FALSE, damaged |-> FALSE]];

  define {
    Findings == {"none", "atStandard", "substandard"}

    Observe ==
        [finding |-> [w \in Wares |-> book[w].verdict],
         marked  |-> [w \in Wares |-> book[w].struck],
         defaced |-> [w \in Wares |-> book[w].damaged]]
  }

  process (officer \in Officers) {
    Bench:
      while (TRUE) {
        with (w \in Wares) {
          either {
            await book[w].verdict = "none";
            with (f \in Findings \ {"none"}) {
              book[w].verdict := f;
            };
          } or {
            await book[w].verdict = "atStandard";
            await ~book[w].struck;
            book[w].struck := TRUE;
          } or {
            await book[w].verdict = "substandard";
            await ~book[w].damaged;
            book[w].damaged := TRUE;
          };
        };
      };
  }
}*)
\* BEGIN TRANSLATION (chksum(pcal) = "a9da77da" /\ chksum(tla) = "fa8830eb")
VARIABLE book

(* define statement *)
Findings == {"none", "atStandard", "substandard"}

Observe ==
    [finding |-> [w \in Wares |-> book[w].verdict],
     marked  |-> [w \in Wares |-> book[w].struck],
     defaced |-> [w \in Wares |-> book[w].damaged]]


vars == << book >>

ProcSet == (Officers)

Init == (* Global variables *)
        /\ book = [w \in Wares |->
                       [verdict |-> "none", struck |-> FALSE, damaged |-> FALSE]]

officer(self) == \E w \in Wares:
                   \/ /\ book[w].verdict = "none"
                      /\ \E f \in Findings \ {"none"}:
                           book' = [book EXCEPT ![w].verdict = f]
                   \/ /\ book[w].verdict = "atStandard"
                      /\ ~book[w].struck
                      /\ book' = [book EXCEPT ![w].struck = TRUE]
                   \/ /\ book[w].verdict = "substandard"
                      /\ ~book[w].damaged
                      /\ book' = [book EXCEPT ![w].damaged = TRUE]

Next == (\E self \in Officers: officer(self))

Spec == Init /\ [][Next]_vars

\* END TRANSLATION 

Deface(o, w) ==
    /\ book[w].verdict = "substandard"
    /\ ~book[w].damaged
    /\ book' = [book EXCEPT ![w].damaged = TRUE]

FairSpec ==
    /\ Spec
    /\ \A o \in Officers, w \in Wares : WF_vars(Deface(o, w))

=============================================================================
