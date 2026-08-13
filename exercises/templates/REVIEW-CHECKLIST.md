# Cold-solve review checklist

Run through this list before an exercise set ships. Check the content
items against the chapter's own set. The last item is the exception,
and it is deliberate. The frame around the exercises has to match the
other chapters.

- [ ] Each exercise fits its 10-15 minute budget.
- [ ] Every statement is unambiguous.
- [ ] No construct is used before the chapter that introduces it.
      Check this against the cheat sheets.
- [ ] No exercise is a near-copy of the chapter's running examples.
- [ ] The set covers the chapter's major themes, per its cheat sheet,
      or the omission is documented.
- [ ] Mutant evidence is present in `reports/`.
- [ ] Every expected outcome is verified through `harness/verdict.sh`.
- [ ] Deliver the chapter into a scratch tree with `scripts/deliver-exercises.sh`
      and confirm every how-to-run command works there. A module only in
      `references/` is not delivered and its exercise cannot be run.
- [ ] Cross-chapter: the command shape, glossary wording, and ritual lines
      match the other chapters. Check at least the neighbouring chapter, not
      only this one.
