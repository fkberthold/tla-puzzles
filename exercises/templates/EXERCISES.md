# Exercise set template

Copy this file to `exercises/chNN/EXERCISES.md` and fill in every field.
3 to 5 exercises per chapter.

The block below is the shape for `write-from-prompt` and
`complete-the-skeleton`, where the expected outcome sits with the other fields.
A `predict-then-check` exercise uses the variant at the foot of this file
instead, which holds its outcomes back until after the run.

## Exercise 1

- Title: `<short title>`
- Format: `<one of: write-from-prompt, complete-the-skeleton>`
- Task: `<what the learner must do>`
- Time budget: `<one of: 10 min, 12 min, 15 min>`
- Uses: `<which of this chapter's themes this exercises>`
- Expected outcome:
  - Pass run: `<TLC verdict on the correct model>`
  - Fail run: `<TLC verdict on the seeded-wrong model>`
- How to run: `<command>`

## Exercise 2

- Title: `<short title>`
- Format: `<one of: write-from-prompt, complete-the-skeleton>`
- Task: `<what the learner must do>`
- Time budget: `<one of: 10 min, 12 min, 15 min>`
- Uses: `<which of this chapter's themes this exercises>`
- Expected outcome:
  - Pass run: `<TLC verdict on the correct model>`
  - Fail run: `<TLC verdict on the seeded-wrong model>`
- How to run: `<command>`

## Exercise 3

- Title: `<short title>`
- Format: `<one of: write-from-prompt, complete-the-skeleton>`
- Task: `<what the learner must do>`
- Time budget: `<one of: 10 min, 12 min, 15 min>`
- Uses: `<which of this chapter's themes this exercises>`
- Expected outcome:
  - Pass run: `<TLC verdict on the correct model>`
  - Fail run: `<TLC verdict on the seeded-wrong model>`
- How to run: `<command>`

<!--
  Add Exercise 4 and Exercise 5 blocks here if the chapter needs them.
  Same fields, same shape.
-->

## The predict-then-check variant

Same fields in a different order. The expected outcomes move below the
how-to-run block, behind the marker line, so a learner reading the file
straight through meets the prediction prompt before the answer to it.

- Title: `<short title>`
- Format: `predict-then-check`
- Task: `<what the learner must predict, and where to write the prediction>`
- Time budget: `<one of: 10 min, 12 min, 15 min>`
- Uses: `<which of this chapter's themes this exercises>`
- How to run: `<command>`

### After the run

Run before you read on.

- Expected outcome:
  - Pass run: `<TLC verdict on the correct model>`
  - Fail run: `<TLC verdict on the seeded-wrong model>`

`<any prose that explains the verdict, or names the wrong guess most people
make, belongs here rather than above the run.>`
