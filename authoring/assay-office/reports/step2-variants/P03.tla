---------------------------- MODULE P03 ----------------------------
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

    TypeOK ==
        /\ Observe.finding \in [Wares -> Findings]
        /\ Observe.marked \in [Wares -> BOOLEAN]
        /\ Observe.defaced \in [Wares -> BOOLEAN]

    MarksFollowTheFinding ==
        \A w \in Wares :
            /\ Observe.marked[w] => Observe.finding[w] = "atStandard"
            /\ Observe.defaced[w] => Observe.finding[w] = "substandard"

    TheRecordOnlyGrows ==
        [][\A w \in Wares :
              /\ (Observe.finding[w] # "none")
                     => (Observe'.finding[w] = Observe.finding[w])
              /\ Observe.marked[w] => Observe'.marked[w]
              /\ Observe.defaced[w] => Observe'.defaced[w]]_Observe

    SubstandardIsDefaced ==
        \A w \in Wares :
            (Observe.finding[w] = "substandard") ~> Observe.defaced[w]
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
\* BEGIN TRANSLATION
VARIABLE book

(* define statement *)
Findings == {"none", "atStandard", "substandard"}

Observe ==
    [finding |-> [w \in Wares |-> book[w].verdict],
     marked  |-> [w \in Wares |-> book[w].struck],
     defaced |-> [w \in Wares |-> book[w].damaged]]

TypeOK ==
    /\ Observe.finding \in [Wares -> Findings]
    /\ Observe.marked \in [Wares -> BOOLEAN]
    /\ Observe.defaced \in [Wares -> BOOLEAN]

MarksFollowTheFinding ==
    \A w \in Wares :
        /\ Observe.marked[w] => Observe.finding[w] = "atStandard"
        /\ Observe.defaced[w] => Observe.finding[w] = "substandard"

TheRecordOnlyGrows ==
    [][\A w \in Wares :
          /\ (Observe.finding[w] # "none")
                 => (Observe'.finding[w] = Observe.finding[w])
          /\ Observe.marked[w] => Observe'.marked[w]
          /\ Observe.defaced[w] => Observe'.defaced[w]]_Observe

SubstandardIsDefaced ==
    \A w \in Wares :
        (Observe.finding[w] = "substandard") ~> Observe.defaced[w]


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
    /\ TRUE

=============================================================================
