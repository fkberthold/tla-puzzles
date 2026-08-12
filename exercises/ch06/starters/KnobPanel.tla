---- MODULE KnobPanel ----
\* Exercise 3 starter. Three holes, marked TODO.
\*
\* The file does not parse until all three are filled. That is on purpose. Fill
\* them, run `pcal KnobPanel.tla`, then run the model.
\*
\* A panel carries NumKnobs knobs. Each knob rests on a notch. `ceiling` is the
\* highest notch this panel allows, and it is picked once at startup, so a
\* single run covers every panel from a 1-notch one to a MaxNotch one.
EXTENDS Integers

CONSTANT NumKnobs
ASSUME NumKnobs > 0

MaxNotch == 3

Knobs == 1..NumKnobs

(*--algorithm knobpanel
variables
  ceiling \in 1..MaxNotch;
  \* TODO 1. Every knob starts at notch 0. Write one function literal over
  \* Knobs. Do not write out the knobs by hand, the panel size is a constant.
  dial = TODO_1;
  next = 1;

define
  \* TODO 2. The set of every legal dial. The domain is Knobs. A notch runs
  \* from 0 up to this panel's `ceiling`, not up to MaxNotch.
  DialType == TODO_2

  TypeOK == dial \in DialType
end define;

begin
  Turn:
    while next <= NumKnobs do
      \* TODO 3. Turn knob `next` all the way up to `ceiling`. One assignment,
      \* and it updates one entry of `dial` rather than replacing the whole
      \* function.
      TODO_3;
      next := next + 1;
    end while;
end algorithm; *)
====
