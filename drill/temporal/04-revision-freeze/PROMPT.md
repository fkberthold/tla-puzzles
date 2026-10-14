# Revision freeze

A document has a revision number and a published flag.

- Every behavior starts at revision 0, unpublished.
- An edit raises the revision by exactly one.
- Edits are possible only while the document is unpublished.
- Publishing sets the flag and leaves the revision alone.
- Nothing ever unpublishes.

Each row below is one step: the state before and the state after, written
(revision, published). The first three rows are starting states and have no
step.

| # | before | after | verdict |
|---|---|---|---|
| I1 | (0, no) | | allowed start |
| I2 | (0, yes) | | forbidden start |
| I3 | (1, no) | | forbidden start |
| S1 | (3, no) | (4, no) | allowed |
| S2 | (3, no) | (3, yes) | allowed |
| S3 | (3, no) | (4, yes) | forbidden |
| S4 | (3, yes) | (3, no) | forbidden |
| S5 | (3, yes) | (4, yes) | forbidden |
| S6 | (3, no) | (5, no) | forbidden |
| S7 | (3, yes) | (3, yes) | allowed |

Write the complete module, header to end marker. Its behavior formula must
admit every allowed start and step and reject every forbidden one.
