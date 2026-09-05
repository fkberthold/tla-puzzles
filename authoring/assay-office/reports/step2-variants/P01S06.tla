---------------------------- MODULE P01S06 ----------------------------
EXTENDS S06

GrowsSub ==
    [][\A w \in Wares :
          /\ (Observe.finding[w] # "none")
                 => (Observe'.finding[w] = Observe.finding[w])
          /\ Observe.marked[w] => Observe'.marked[w]
          /\ Observe.defaced[w] => Observe'.defaced[w]]_(Observe.finding)

=============================================================================
