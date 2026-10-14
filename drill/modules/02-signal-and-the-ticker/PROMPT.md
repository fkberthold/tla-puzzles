# The signal and the ticker

Ten minutes of thinking, maybe twelve. Every run is under a second.

## Two machines

The coarse one is a signal. It shows red, then green, then amber, then
red again, forever. That's its whole life, and it starts on red.

The fine one is a ticker. It counts from zero to five and wraps to zero.
Someone reads a color off the count: zero to two is red, three and four
are green, five is amber.

The claim: the ticker implements the signal. Every behavior of the
ticker, read as colors, is a behavior the signal could have had. TLC
can check that claim if you tell it how to read the count as a color
and which keyword in the config asks for the check.

## What happened

| model | verdict | distinct states |
|---|---|---|
| the ticker, read correctly | clean | 6 |
| the ticker, with five read as green | the signal's own step rule was violated, on the step from five back to zero | 6 |
| the ticker, with no reading given at all | refused before any state: a symbol the signal declares was never substituted | |
| the ticker, five read as green, the claim written as a theorem and nothing asked of the config | clean | 6 |
| the ticker, read correctly, the config naming the instance's formula directly | refused: the config found no such property | |

## The questions

1. Write both modules. Keep the signal to one variable and the ticker to
   one. The reading lives in the ticker.
2. Write the line that ties the two, the definition TLC can name, and
   the config line that names it.
3. Row two: say in one sentence why five-as-green breaks it, and what
   TLC's message blames.
4. Row four: why is that one clean? What is the theorem for, if not for
   TLC?
5. Row five: what can and can't a config name?

Write it, reproduce the 6, then break the reading.
