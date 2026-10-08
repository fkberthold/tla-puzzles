#!/usr/bin/env bash
# Build the seeded-bug matrix for the IMAP MOVE spike.
#
#   bash sources/spikes/imap-move-partial-failure/gen-matrix.sh
#
# WHY THE VARIANTS ARE GENERATED AND NOT HAND-WRITTEN
#
# A seeded variant has to be the reference with ONE definition changed. Write
# five of them by hand and you get five files that drifted somewhere else as
# well, and a variant that differs in two places cannot tell you which change
# the property caught. Here each one starts as a byte copy of the reference
# and gets one sed, so `diff` against the reference is the proof.
#
# Root resolves from BASH_SOURCE for the reason gen-wrappers.sh records.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
M="$HERE/matrix"

rm -rf "$M"
mkdir -p "$M/reference" "$M/oracle" "$M/variants"

# ---------------------------------------------------------------------------
# THE REFERENCE. Two modules, because MoveAtomic EXTENDS MoveBase and the
# harness copies every .tla beside the reference into each staging directory.
#
# Holding two means `--matrix` alone will not do: its `sole_tla` resolution
# wants exactly one .tla in reference/, so run-matrix.sh passes --reference
# explicitly. The constants fragment is keyed to the reference DIRECTORY
# rather than the matrix root, so it still gets picked up.
# ---------------------------------------------------------------------------
cp "$HERE/MoveBase.tla" "$HERE/MoveAtomic.tla" "$M/reference/"

{
  printf 'CONSTANTS\n'
  printf '  Msg = {m1, m2, m3}\n'
} > "$M/reference/constants.cfg"

# ---------------------------------------------------------------------------
# THE ORACLE. One operator, because the harness checks one invariant name.
#
# That is a different job from the .cfg decomposition the rest of the spike
# uses. The clause configs ask WHICH clause a server breaks. The matrix asks
# whether a property ever says no at all, so one conjunction is the right
# shape here and says nothing against naming the three separately elsewhere.
# ---------------------------------------------------------------------------
{
  printf -- '------------------------------- MODULE Oracle -------------------------------\n'
  printf '(***************************************************************************)\n'
  printf "(* THE AUTHOR'S OWN PROPERTY, which is the matrix's instrument and not a    *)\\n"
  printf '(* submission. It must exit 0 against the reference and 12 against every    *)\n'
  printf '(* variant, and seeded-bugs.sh checks both before it grades anything.       *)\n'
  printf '(*                                                                          *)\n'
  printf '(* All four names come from MoveBase. The three normative clauses are the    *)\n'
  printf '(* sentences of RFC 9051 section 6.4.8, and TypeOK is the type layer.        *)\n'
  printf '(***************************************************************************)\n'
  printf 'EXTENDS MoveAtomic\n'
  printf '\n'
  printf 'Inv == /\\ TypeOK\n'
  printf '       /\\ MovedOrUnaffected\n'
  printf '       /\\ NotLostOrOrphaned\n'
  printf '       /\\ NotInBothMailboxes\n'
  printf '\n'
  printf '=============================================================================\n'
} > "$M/oracle/Oracle.tla"

# ---------------------------------------------------------------------------
# THE VARIANTS. Each is one sed over a byte copy of the reference module.
#
# variant <name> <module> <banner> <sed-expr>...
# ---------------------------------------------------------------------------
variant() {
  local name="$1" module="$2" banner="$3"; shift 3
  local dir="$M/variants/$name"
  mkdir -p "$dir"
  printf '%s\n' "$banner" > "$dir/.banner"

  # The anchor the banner goes after. MoveAtomic has an EXTENDS line and
  # MoveBase does not, so one pattern cannot serve both, and a pattern that
  # matches nothing drops the banner silently.
  local anchor='^EXTENDS Move'
  [ "$module" = "MoveBase.tla" ] && anchor='^CONSTANT Msg$'
  grep -qE "$anchor" "$M/reference/$module" || {
    printf 'gen-matrix: anchor %s absent from %s\n' "$anchor" "$module" >&2
    exit 2
  }

  local -a seds=()
  local e
  for e in "$@"; do seds+=(-e "$e"); done

  sed -e "/$anchor/r $dir/.banner" "${seds[@]}" \
    "$M/reference/$module" > "$dir/$module"
  rm -f "$dir/.banner"

  # Every variant supplies the reference module under the reference's own
  # name, which the harness refuses to run without. A variant that mutates
  # MoveBase instead still has to hand over an unchanged MoveAtomic.
  if [ "$module" != "MoveAtomic.tla" ]; then
    cp "$M/reference/MoveAtomic.tla" "$dir/MoveAtomic.tla"
  fi
}

variant copy-without-expunge MoveAtomic.tla \
'
\* SEEDED VARIANT: copy-without-expunge. WRONG ON PURPOSE.
\*
\* MoveOne puts the target copy in place and leaves the source copy behind,
\* so every moved message ends up in both mailboxes. This is Thunderbird bug
\* 610131 compressed into one step.
\*
\* Caught by MovedOrUnaffected and by NotInBothMailboxes. NOT caught by
\* NotLostOrOrphaned, which is the clause a duplicating server satisfies.' \
  "s|= {Target}\]|= Mailbox]|"

variant expunge-without-copy MoveAtomic.tla \
'
\* SEEDED VARIANT: expunge-without-copy. WRONG ON PURPOSE.
\*
\* MoveOne drops the source copy without putting a target copy anywhere, so
\* the message is gone.
\*
\* Caught by MovedOrUnaffected and by NotLostOrOrphaned. NOT caught by
\* NotInBothMailboxes, which a losing server satisfies.' \
  "s|= {Target}\]|= {}]|"

variant stray-deleted-flag MoveAtomic.tla \
'
\* SEEDED VARIANT: stray-deleted-flag. WRONG ON PURPOSE.
\*
\* MoveOne marks the source copy \Deleted and never moves it, which is the
\* STORE of the RFC decomposition landing with the COPY and the EXPUNGE
\* missing. RFC 9051 section 6.4.8: "the \Deleted flag MUST NOT be set for
\* any message".
\*
\* This is the one variant caught by MovedOrUnaffected ALONE. The message is
\* in exactly one mailbox, so the other two clauses hold, and a property that
\* checked only the safety floor and the duplicate preference would miss it.' \
  "s|/\\\\ loc' = \[loc EXCEPT !\[m\] = {Target}\]|/\\\\ flagged' = [flagged EXCEPT ![m] = TRUE]|" \
  "s|<< flagged, resp >>|<< loc, resp >>|"

variant leave-half-moves MoveAtomic.tla \
'
\* SEEDED VARIANT: leave-half-moves. WRONG ON PURPOSE.
\*
\* LeaveOne is the branch where the server fails on one message and leaves it
\* alone. Here it drops the source copy instead, so the FAILURE path is what
\* loses the message.
\*
\* Same clause pair as expunge-without-copy and a different route to it. The
\* whole paragraph is about the failure path, so a property that only ever
\* watched the success path is the mistake worth seeding.' \
  "s|/\\\\ UNCHANGED << loc, flagged, resp >>|/\\\\ loc' = [loc EXCEPT ![m] = {}]\n    /\\\\ UNCHANGED << flagged, resp >>|"

variant abort-loses-pending MoveBase.tla \
'
\* SEEDED VARIANT: abort-loses-pending. WRONG ON PURPOSE.
\*
\* Abort answers a tagged NO and drops the source copy of everything it had
\* not got to. RFC 9051 section 6.4.8 closes the paragraph with "This is true
\* even if the server returns a tagged NO response to the command", so the
\* guarantee has to hold on this path too.
\*
\* This one mutates MoveBase rather than MoveAtomic, because Abort is shared
\* by all four servers. The variant therefore also supplies an unchanged
\* MoveAtomic, which the harness requires of every variant.' \
  "s|/\\\\ UNCHANGED << loc, flagged >>|/\\\\ loc' = [m \\\\in Msg \|-> IF m \\\\in pending THEN {} ELSE loc[m]]\n    /\\\\ UNCHANGED flagged|"

printf 'matrix built: %d variants\n' \
  "$(find "$M/variants" -mindepth 1 -maxdepth 1 -type d | wc -l)"
