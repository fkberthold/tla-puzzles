Cached copy of https://github.com/tlaplus/Examples/blob/master/README.md

Fetched as BYTES, never through WebFetch (V2-PLAN.md §4.5 — WebFetch runs a
summarizer and returns paraphrase, so a WebFetch quotation is unsourced):

    gh api repos/tlaplus/Examples/contents/README.md --jq '.content' | base64 -d \
      > harness/fixtures/screen/examples-README.md

fetched:  2026-08-06T19:56:14Z
sha256:   8130fbbc2b3a8b08ada74c886aaea78f37547745a7161372c055e6a54e52877c
bytes:    38499
lines:    170

The file is stored byte-for-byte as upstream serves it — no header, no edits —
so this record, not a comment inside the file, is where provenance lives.

Refresh with `harness/screen.sh --refresh`, which reruns exactly that command.
This file is simultaneously:

  - the screen's CACHE, so screening N candidates is not N network calls; and
  - the self-test's FIXTURE, so the test cannot fail merely because GitHub is
    unreachable.
