# T11: Sequences — Concat and SubSeq ⭐

## Lesson: Joining and Slicing

T10 built sequences one element at a time with `Append`. T11 adds two more operators that work on whole sequences.

**Concat with `\o`** — joins two sequences end-to-end:

```
<<1, 2>> \o <<3, 4>>           \* <<1, 2, 3, 4>>
<<>> \o <<7>>                  \* <<7>>          (concat with empty is identity)
s \o <<x>>                     \* same as Append(s, x)
```

`\o` is left-associative and has the obvious algebraic properties: associative, has `<<>>` as identity.

**Slice with `SubSeq(s, i, j)`** — returns the sub-sequence from index `i` through index `j`, inclusive, both 1-indexed:

```
s == <<10, 20, 30, 40, 50>>
SubSeq(s, 1, 3)        \* <<10, 20, 30>>
SubSeq(s, 2, 4)        \* <<20, 30, 40>>
SubSeq(s, 3, 3)        \* <<30>>          (single element)
SubSeq(s, 4, 3)        \* <<>>            (empty when j < i)
```

Important constraints: `1 <= i` and `j <= Len(s)`. If `j < i`, the result is the empty sequence — but you must still respect `i >= 1`.

**Worked example — a music playlist.**

A DJ has a fixed intro and outro and builds a playlist by concatenating the intro, a chosen middle, and the outro. The DJ also wants to "preview the first half" — the first three songs of whatever was built.

```
(*--algorithm Playlist {
  variables intro = <<"jingle">>, outro = <<"signoff">>,
            middle = <<>>, playlist = <<>>, preview = <<>>;

  fair process (dj = "DJ") {
    pickMiddle:
      with (m \in {<<"a", "b", "c">>, <<"a", "b", "d">>, <<"x", "y", "z">>}) {
        middle := m;
      };
    assemble:
      playlist := intro \o middle \o outro;
    previewFirst:
      preview := SubSeq(playlist, 1, 3);
  }
}*)
```

Sample invariants:

- `TypeOK == Len(intro) = 1 /\ Len(outro) = 1 /\ Len(playlist) \in 0..5 /\ Len(preview) \in 0..3`
- `PreviewSize == Len(preview) > 0 => Len(preview) = 3`
- `IntroFirst == Len(playlist) > 0 => playlist[1] = "jingle"` — concat preserves order: intro is first

Things to internalize:

1. **`\o` is concat, not Append.** `Append(s, x)` adds ONE value `x` to the end. `s \o t` joins two sequences.
2. **`SubSeq` is 1-indexed and inclusive on both ends.** `SubSeq(s, 1, Len(s))` is the whole sequence.
3. **Empty results are fine.** `SubSeq(s, 5, 4)` is `<<>>` (empty), not an error.

## Setup

A train scheduler builds the day's runs by combining a morning run and an afternoon run into a full schedule. Each run is a sequence of station codes. The dispatcher also wants to inspect the MIDDLE THREE STATIONS of the full schedule — useful for traffic planning.

## Task

Write a PlusCal spec with:

- `morning` initialized to `<<"A", "B", "C">>`
- `afternoon` initialized to `<<"D", "E", "F">>`
- `fullDay` starting at `<<>>` (will hold the concat)
- `middleThree` starting at `<<>>` (will hold the slice)
- `phase` starting at `0`

A single fair process runs three labels:

1. **combine**: set `fullDay := morning \o afternoon`. Increment `phase`.
2. **slice**: set `middleThree := SubSeq(fullDay, 2, 4)`. Increment `phase`.
3. **finish**: increment `phase`.

In the `define` block:

- `TotalLen == Len(fullDay)`
- `SliceLen == Len(middleThree)`
- `TypeOK == TotalLen \in {0, 6} /\ SliceLen \in {0, 3} /\ phase \in 0..3`
- `LengthsAddUp == TotalLen > 0 => Len(morning) + Len(afternoon) = TotalLen`
- `MiddleStations == phase >= 2 => middleThree = <<"B", "C", "D">>`

## Check

1. **TypeOK** — see above.
2. **LengthsAddUp** — concat preserves total length.
3. **MiddleStations** — once the slice has run, the middle three stations are exactly `B, C, D`.

## Expected Result

- TLC should report `No error has been found`.
- All three invariants pass.
- The canonical solution reports **4 distinct states** (one per phase value). Your label choices will be deterministic and likely produce the same count, but the metric is passing invariants, not state count.
- Trace through by hand: after `combine`, `fullDay = <<"A","B","C","D","E","F">>`. `SubSeq(fullDay, 2, 4)` is indices 2 through 4: `<<"B","C","D">>`. Confirm with TLC.

**Bonus.** What does `SubSeq(fullDay, 1, Len(fullDay))` evaluate to? What about `SubSeq(fullDay, 4, 2)`? Predict, then add an operator that returns each and check.

## Hints

??? hint "💡 Hint 1 — Concat before slice"
    You have two sequences initialized at the top level (`morning` and `afternoon`). The first label's job is to combine them using `\o` (concat). After that, `fullDay` should hold the result. The second label then slices the result. Does the slice happen on `fullDay` or on the original sequences?

??? hint "💡 Hint 2 — SubSeq is inclusive on both ends"
    `SubSeq(s, i, j)` returns elements from index `i` through index `j`, INCLUSIVE. So `SubSeq(s, 2, 4)` gives you THREE elements (indices 2, 3, 4). Both indices are 1-based, just like sequence indexing. Check your indices carefully against the expected result `<<"B", "C", "D">>`.

??? hint "💡 Hint 3 — Three labels with phase incrementing"
    The `combine` label concatenates and increments `phase`. The `slice` label slices and increments `phase`. The `finish` label just increments `phase`. No loop here — three sequential labels, one phase increment per label. After `finish`, `phase = 3`.
