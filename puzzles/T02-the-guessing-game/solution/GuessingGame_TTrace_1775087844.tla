---- MODULE GuessingGame_TTrace_1775087844 ----
EXTENDS Sequences, TLCExt, GuessingGame, Toolbox, Naturals, TLC

_expression ==
    LET GuessingGame_TEExpression == INSTANCE GuessingGame_TEExpression
    IN GuessingGame_TEExpression!expression
----

_trace ==
    LET GuessingGame_TETrace == INSTANCE GuessingGame_TETrace
    IN GuessingGame_TETrace!trace
----

_inv ==
    ~(
        TLCGet("level") = Len(_TETrace)
        /\
        result = ("won")
        /\
        pc = ([Player |-> "Done"])
        /\
        guess = (1)
        /\
        secret = (1)
    )
----

_init ==
    /\ result = _TETrace[1].result
    /\ secret = _TETrace[1].secret
    /\ pc = _TETrace[1].pc
    /\ guess = _TETrace[1].guess
----

_next ==
    /\ \E i,j \in DOMAIN _TETrace:
        /\ \/ /\ j = i + 1
              /\ i = TLCGet("level")
        /\ result  = _TETrace[i].result
        /\ result' = _TETrace[j].result
        /\ secret  = _TETrace[i].secret
        /\ secret' = _TETrace[j].secret
        /\ pc  = _TETrace[i].pc
        /\ pc' = _TETrace[j].pc
        /\ guess  = _TETrace[i].guess
        /\ guess' = _TETrace[j].guess

\* Uncomment the ASSUME below to write the states of the error trace
\* to the given file in Json format. Note that you can pass any tuple
\* to `JsonSerialize`. For example, a sub-sequence of _TETrace.
    \* ASSUME
    \*     LET J == INSTANCE Json
    \*         IN J!JsonSerialize("GuessingGame_TTrace_1775087844.json", _TETrace)

=============================================================================

 Note that you can extract this module `GuessingGame_TEExpression`
  to a dedicated file to reuse `expression` (the module in the 
  dedicated `GuessingGame_TEExpression.tla` file takes precedence 
  over the module `GuessingGame_TEExpression` below).

---- MODULE GuessingGame_TEExpression ----
EXTENDS Sequences, TLCExt, GuessingGame, Toolbox, Naturals, TLC

expression == 
    [
        \* To hide variables of the `GuessingGame` spec from the error trace,
        \* remove the variables below.  The trace will be written in the order
        \* of the fields of this record.
        result |-> result
        ,secret |-> secret
        ,pc |-> pc
        ,guess |-> guess
        
        \* Put additional constant-, state-, and action-level expressions here:
        \* ,_stateNumber |-> _TEPosition
        \* ,_resultUnchanged |-> result = result'
        
        \* Format the `result` variable as Json value.
        \* ,_resultJson |->
        \*     LET J == INSTANCE Json
        \*     IN J!ToJson(result)
        
        \* Lastly, you may build expressions over arbitrary sets of states by
        \* leveraging the _TETrace operator.  For example, this is how to
        \* count the number of times a spec variable changed up to the current
        \* state in the trace.
        \* ,_resultModCount |->
        \*     LET F[s \in DOMAIN _TETrace] ==
        \*         IF s = 1 THEN 0
        \*         ELSE IF _TETrace[s].result # _TETrace[s-1].result
        \*             THEN 1 + F[s-1] ELSE F[s-1]
        \*     IN F[_TEPosition - 1]
    ]

=============================================================================



Parsing and semantic processing can take forever if the trace below is long.
 In this case, it is advised to uncomment the module below to deserialize the
 trace from a generated binary file.

\*
\*---- MODULE GuessingGame_TETrace ----
\*EXTENDS IOUtils, GuessingGame, TLC
\*
\*trace == IODeserialize("GuessingGame_TTrace_1775087844.bin", TRUE)
\*
\*=============================================================================
\*

---- MODULE GuessingGame_TETrace ----
EXTENDS GuessingGame, TLC

trace == 
    <<
    ([result |-> "playing",pc |-> [Player |-> "choose"],guess |-> 0,secret |-> 1]),
    ([result |-> "playing",pc |-> [Player |-> "check"],guess |-> 1,secret |-> 1]),
    ([result |-> "won",pc |-> [Player |-> "Done"],guess |-> 1,secret |-> 1])
    >>
----


=============================================================================

---- CONFIG GuessingGame_TTrace_1775087844 ----

INVARIANT
    _inv

CHECK_DEADLOCK
    \* CHECK_DEADLOCK off because of PROPERTY or INVARIANT above.
    FALSE

INIT
    _init

NEXT
    _next

CONSTANT
    _TETrace <- _trace

ALIAS
    _expression
=============================================================================
\* Generated on Wed Apr 01 16:57:24 PDT 2026