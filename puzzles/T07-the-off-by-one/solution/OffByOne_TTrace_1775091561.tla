---- MODULE OffByOne_TTrace_1775091561 ----
EXTENDS OffByOne, Sequences, TLCExt, Toolbox, Naturals, TLC

_expression ==
    LET OffByOne_TEExpression == INSTANCE OffByOne_TEExpression
    IN OffByOne_TEExpression!expression
----

_trace ==
    LET OffByOne_TETrace == INSTANCE OffByOne_TETrace
    IN OffByOne_TETrace!trace
----

_inv ==
    ~(
        TLCGet("level") = Len(_TETrace)
        /\
        pc = ([Counter |-> "Done"])
        /\
        count = (1)
        /\
        done = (TRUE)
    )
----

_init ==
    /\ done = _TETrace[1].done
    /\ pc = _TETrace[1].pc
    /\ count = _TETrace[1].count
----

_next ==
    /\ \E i,j \in DOMAIN _TETrace:
        /\ \/ /\ j = i + 1
              /\ i = TLCGet("level")
        /\ done  = _TETrace[i].done
        /\ done' = _TETrace[j].done
        /\ pc  = _TETrace[i].pc
        /\ pc' = _TETrace[j].pc
        /\ count  = _TETrace[i].count
        /\ count' = _TETrace[j].count

\* Uncomment the ASSUME below to write the states of the error trace
\* to the given file in Json format. Note that you can pass any tuple
\* to `JsonSerialize`. For example, a sub-sequence of _TETrace.
    \* ASSUME
    \*     LET J == INSTANCE Json
    \*         IN J!JsonSerialize("OffByOne_TTrace_1775091561.json", _TETrace)

=============================================================================

 Note that you can extract this module `OffByOne_TEExpression`
  to a dedicated file to reuse `expression` (the module in the 
  dedicated `OffByOne_TEExpression.tla` file takes precedence 
  over the module `OffByOne_TEExpression` below).

---- MODULE OffByOne_TEExpression ----
EXTENDS OffByOne, Sequences, TLCExt, Toolbox, Naturals, TLC

expression == 
    [
        \* To hide variables of the `OffByOne` spec from the error trace,
        \* remove the variables below.  The trace will be written in the order
        \* of the fields of this record.
        done |-> done
        ,pc |-> pc
        ,count |-> count
        
        \* Put additional constant-, state-, and action-level expressions here:
        \* ,_stateNumber |-> _TEPosition
        \* ,_doneUnchanged |-> done = done'
        
        \* Format the `done` variable as Json value.
        \* ,_doneJson |->
        \*     LET J == INSTANCE Json
        \*     IN J!ToJson(done)
        
        \* Lastly, you may build expressions over arbitrary sets of states by
        \* leveraging the _TETrace operator.  For example, this is how to
        \* count the number of times a spec variable changed up to the current
        \* state in the trace.
        \* ,_doneModCount |->
        \*     LET F[s \in DOMAIN _TETrace] ==
        \*         IF s = 1 THEN 0
        \*         ELSE IF _TETrace[s].done # _TETrace[s-1].done
        \*             THEN 1 + F[s-1] ELSE F[s-1]
        \*     IN F[_TEPosition - 1]
    ]

=============================================================================



Parsing and semantic processing can take forever if the trace below is long.
 In this case, it is advised to uncomment the module below to deserialize the
 trace from a generated binary file.

\*
\*---- MODULE OffByOne_TETrace ----
\*EXTENDS OffByOne, IOUtils, TLC
\*
\*trace == IODeserialize("OffByOne_TTrace_1775091561.bin", TRUE)
\*
\*=============================================================================
\*

---- MODULE OffByOne_TETrace ----
EXTENDS OffByOne, TLC

trace == 
    <<
    ([pc |-> [Counter |-> "loop"],count |-> 3,done |-> FALSE]),
    ([pc |-> [Counter |-> "loop"],count |-> 2,done |-> FALSE]),
    ([pc |-> [Counter |-> "loop"],count |-> 1,done |-> FALSE]),
    ([pc |-> [Counter |-> "finish"],count |-> 1,done |-> FALSE]),
    ([pc |-> [Counter |-> "Done"],count |-> 1,done |-> TRUE])
    >>
----


=============================================================================

---- CONFIG OffByOne_TTrace_1775091561 ----

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
\* Generated on Wed Apr 01 17:59:22 PDT 2026