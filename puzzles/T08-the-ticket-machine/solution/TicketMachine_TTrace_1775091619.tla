---- MODULE TicketMachine_TTrace_1775091619 ----
EXTENDS Sequences, TLCExt, Toolbox, Naturals, TLC, TicketMachine

_expression ==
    LET TicketMachine_TEExpression == INSTANCE TicketMachine_TEExpression
    IN TicketMachine_TEExpression!expression
----

_trace ==
    LET TicketMachine_TETrace == INSTANCE TicketMachine_TETrace
    IN TicketMachine_TETrace!trace
----

_inv ==
    ~(
        TLCGet("level") = Len(_TETrace)
        /\
        sold = (2)
        /\
        pc = ([Machine |-> "Done"])
        /\
        tickets = (1)
        /\
        served = (5)
        /\
        status = ("closed")
    )
----

_init ==
    /\ sold = _TETrace[1].sold
    /\ status = _TETrace[1].status
    /\ pc = _TETrace[1].pc
    /\ served = _TETrace[1].served
    /\ tickets = _TETrace[1].tickets
----

_next ==
    /\ \E i,j \in DOMAIN _TETrace:
        /\ \/ /\ j = i + 1
              /\ i = TLCGet("level")
        /\ sold  = _TETrace[i].sold
        /\ sold' = _TETrace[j].sold
        /\ status  = _TETrace[i].status
        /\ status' = _TETrace[j].status
        /\ pc  = _TETrace[i].pc
        /\ pc' = _TETrace[j].pc
        /\ served  = _TETrace[i].served
        /\ served' = _TETrace[j].served
        /\ tickets  = _TETrace[i].tickets
        /\ tickets' = _TETrace[j].tickets

\* Uncomment the ASSUME below to write the states of the error trace
\* to the given file in Json format. Note that you can pass any tuple
\* to `JsonSerialize`. For example, a sub-sequence of _TETrace.
    \* ASSUME
    \*     LET J == INSTANCE Json
    \*         IN J!JsonSerialize("TicketMachine_TTrace_1775091619.json", _TETrace)

=============================================================================

 Note that you can extract this module `TicketMachine_TEExpression`
  to a dedicated file to reuse `expression` (the module in the 
  dedicated `TicketMachine_TEExpression.tla` file takes precedence 
  over the module `TicketMachine_TEExpression` below).

---- MODULE TicketMachine_TEExpression ----
EXTENDS Sequences, TLCExt, Toolbox, Naturals, TLC, TicketMachine

expression == 
    [
        \* To hide variables of the `TicketMachine` spec from the error trace,
        \* remove the variables below.  The trace will be written in the order
        \* of the fields of this record.
        sold |-> sold
        ,status |-> status
        ,pc |-> pc
        ,served |-> served
        ,tickets |-> tickets
        
        \* Put additional constant-, state-, and action-level expressions here:
        \* ,_stateNumber |-> _TEPosition
        \* ,_soldUnchanged |-> sold = sold'
        
        \* Format the `sold` variable as Json value.
        \* ,_soldJson |->
        \*     LET J == INSTANCE Json
        \*     IN J!ToJson(sold)
        
        \* Lastly, you may build expressions over arbitrary sets of states by
        \* leveraging the _TETrace operator.  For example, this is how to
        \* count the number of times a spec variable changed up to the current
        \* state in the trace.
        \* ,_soldModCount |->
        \*     LET F[s \in DOMAIN _TETrace] ==
        \*         IF s = 1 THEN 0
        \*         ELSE IF _TETrace[s].sold # _TETrace[s-1].sold
        \*             THEN 1 + F[s-1] ELSE F[s-1]
        \*     IN F[_TEPosition - 1]
    ]

=============================================================================



Parsing and semantic processing can take forever if the trace below is long.
 In this case, it is advised to uncomment the module below to deserialize the
 trace from a generated binary file.

\*
\*---- MODULE TicketMachine_TETrace ----
\*EXTENDS IOUtils, TLC, TicketMachine
\*
\*trace == IODeserialize("TicketMachine_TTrace_1775091619.bin", TRUE)
\*
\*=============================================================================
\*

---- MODULE TicketMachine_TETrace ----
EXTENDS TLC, TicketMachine

trace == 
    <<
    ([sold |-> 0,pc |-> [Machine |-> "serve"],tickets |-> 3,served |-> 0,status |-> "open"]),
    ([sold |-> 1,pc |-> [Machine |-> "serve"],tickets |-> 2,served |-> 1,status |-> "open"]),
    ([sold |-> 2,pc |-> [Machine |-> "serve"],tickets |-> 1,served |-> 2,status |-> "open"]),
    ([sold |-> 2,pc |-> [Machine |-> "serve"],tickets |-> 1,served |-> 3,status |-> "open"]),
    ([sold |-> 2,pc |-> [Machine |-> "serve"],tickets |-> 1,served |-> 4,status |-> "open"]),
    ([sold |-> 2,pc |-> [Machine |-> "serve"],tickets |-> 1,served |-> 5,status |-> "open"]),
    ([sold |-> 2,pc |-> [Machine |-> "close"],tickets |-> 1,served |-> 5,status |-> "open"]),
    ([sold |-> 2,pc |-> [Machine |-> "Done"],tickets |-> 1,served |-> 5,status |-> "closed"])
    >>
----


=============================================================================

---- CONFIG TicketMachine_TTrace_1775091619 ----

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
\* Generated on Wed Apr 01 18:00:19 PDT 2026