----------------------- MODULE MCDoubleBumpLiveness -------------------------
(* The liveness property under the pre-KAFKA-19367 double bump. MaxEpoch = 4 *)
(* rather than 2, because at 2 a +2 fence can only ever fire from 0 and the  *)
(* model would be answering a question about its own smallest size.          *)
EXTENDS TxnDoubleBump

=============================================================================
