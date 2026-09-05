# Alternatives considered (river-call reference)

Author-only note per V2-PLAN §9.4, written after the reference went green. It
records the state and constant representations I weighed and why the shipped
one won.

## What shipped

Two variables, `diverted` and `calling`, each a function on `Owners`.
`Observe` renders as the identity over them, field for field. The state is the
interface and nothing else is stored. Shortness and free water are worked out
inside the properties, from `diverted` and the constants, which is what the
description asks for.

## Owners named by their priority date

`Owners` is a set of naturals and `Senior(a, b) == a < b`. An owner's name is
their date off the register.

The rival was model values for owners plus a `Priority` constant function. I
rejected it because a model value has no name inside the module, so nothing in
the spec can build a date function over `{o1, o2, o3}`. The way out is a second
module that declares every owner as its own constant. That's what
`MCCustody.cfg` does with `A = A` and `B = B`. It buys abstract owner
identities and costs a file and five constants.

The cost of what shipped is real. Seniority now rides on identity, so a reader
can't tell an owner apart from their place in the order. Rule 2 says the dates
never change and never tie, so I think the two are one fact here. If a later
rung ever wants the register to move, this is the first thing that has to come
apart.

## The decree function, and why it sits in the module

`Decree` is a constant function on `Owners`. The cfg fills it with
`Decree <- Decrees`, and `Decrees == [o \in Owners |-> 2]` sits at the foot of
the module.

I'd rather it lived in the cfg. It can't. TLC's config parser takes model
values, numbers, strings and sets of those, and nothing else. `Decree = <<2, 2,
2>>` comes back with "expecting = or <-", and `Decree = [o1 |-> 2]` with
"expecting ]", both on the pinned 2026.07.31 build.

So the register has to live in some module. The repo's usual answer is a
sibling MC module, the way seedlib and custody and consign all do it. That's a
third file, and this rung ships two. One line at the foot of the reference is
the two-file version of the same move.

If the file count weren't fixed I'd take the MC module, because instance data
in a frozen spec is a smell. The one I rejected outright is a scalar `Decree`
shared by every owner. It's clean in the cfg and it costs the system. Rule 2
gives each owner their own amount, and a spec that can't say so models a
smaller river.

## One Set action instead of Open and Close

Rule 3 gives an owner one act that moves the gate to any lawful setting, so a
single `Set(o, n)` action is the closer reading. The call guard would fire only
when `n` rises.

I split it because Rule 7 reaches rises alone, and the split puts that guard
where it belongs instead of behind an `IF`. The transition relation is the same
either way. The split also pays off at the dead-action probe. On the flow-6
instance `vacuity.sh` names `CallOut` and `CallBack` as the actions that never
fired, which is a sharper report than one `Set` would give.

## A variable for the free water

Tempting, since Rule 5 counts against it and every call guard reads it. I
rejected it on representation. A third variable makes the reference's variables
wider than `Observe`'s fields, which is representation 3 and the wrong rung.
`Flow - Taken(diverted)` says the same thing and can't drift from the gates.

## `calling` as a set of owners

`calling \subseteq Owners` instead of a function into BOOLEAN. Cheap call, and
the function won. The description reports the field per owner, and a function
keeps the two fields the same shape. A set would make `Observe.calling` read
differently from `Observe.diverted` for no gain.

## Subscripting the step rules by the settings alone

`[][...]_(Observe.diverted)` on item 2 is smaller, and it looks safe, since
item 2 only talks about gates. The description warns against it and I think
it's right. A step that only puts a call out leaves `diverted` alone, so it
stutters out of that subscript, and item 3 is the property that step exists to
catch. Both step rules take the whole record.

## The guard on the call, and the handed green run

Item 3 is a property, so a reader could ask whether `CallOut` needs the `Short`
guard at all. It does, and the reason sits downstream rather than in section 2.
The rung hands the learner a green run at a flow at or above the sum of the
decrees. Free water then covers every decree, no owner is ever short, and the
guard leaves `CallOut` dead. Measured at flow 6: rc=0, 27 distinct states, and
`vacuity.sh` returns VACUOUS_DEAD_ACTION naming `CallOut`. Drop the guard and
the call fires, and the instance isn't vacuous any more.
