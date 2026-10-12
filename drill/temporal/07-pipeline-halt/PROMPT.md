# Pipeline halt

A build pipeline moves one job through stages: queued, building, testing,
done, failed.

- From queued it starts building.
- Building either produces an artifact and moves to testing, or fails.
- Testing passes to done when the artifact is present.
- Testing may instead retry, back to queued, at most once per job.
- A cache may evict the artifact at any time.

The requirement: the pipeline may come to rest only at done or failed. In
every other stage, some step must still be possible.

Write that requirement as something TLC can check, without restating any
stage's rules. Then name the built-in TLC check it replaces, and say why
that check can't be used as it is.
