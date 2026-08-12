---- MODULE Ex3RetryFail ----
EXTENDS Integers, TLC

\* The seeded-wrong retry. One statement differs from Ex3Retry: a bookkeeping
\* update sits after the `goto`, with no label between them. A label must
\* immediately follow any goto, so pcal refuses to translate this module.
\*
\* There is no translation block below on purpose. A refused translation leaves
\* the file with whatever translation it had, and this one never had any, so
\* TLC has no Spec to check.
\*
\* Do not write the two marker words pcal looks for into a comment in a module
\* you expect pcal to translate. It scans the whole file for the opening marker
\* and then demands the closing one, so a mention in prose is read as a real
\* translation block and the run dies with "Unrecoverable error".

(*--algorithm retry
  variables
    attempts = 0,
    linked = FALSE;

begin
  Dial:
    attempts := attempts + 1;
    if attempts < 3 then
      goto Dial;
      linked := FALSE;
    else
      linked := TRUE;
    end if;
  Report:
    assert linked;
    assert attempts = 3;
end algorithm; *)
====
