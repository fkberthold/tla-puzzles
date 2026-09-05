---------------------------- MODULE P06S02 ----------------------------
EXTENDS S02

MarksOneSided ==
    \A w \in Wares :
        Observe.marked[w] => Observe.finding[w] = "atStandard"

=============================================================================
