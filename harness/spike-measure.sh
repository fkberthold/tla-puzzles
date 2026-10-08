#!/usr/bin/env bash
# Measure a spike model, so difficulty is measured rather than predicted.
#
# WHY THIS EXISTS
#
# Difficulty cannot be read off a problem description. Over the 143 systems in
# corpus/manifest.tsv, variable-count medians by level run 3, 2, 6, 7, 8, levels
# 1 and 2 come out inverted, and level 1 alone spans 1 to 87 variables. The
# reason is structural rather than a weak measurement: the variable count is the
# ANSWER to a modelling problem, not a fact about it, so a description that told
# you the count would be handing over the representation the learner is meant to
# choose.
#
# So a candidate gets modelled first and measured second. This prints the row.
#
# THE ONE RULE THIS FILE HAS TO KEEP
#
# A verdict comes from the exit code. A measurement comes from stdout. Never the
# other way round. V2-PLAN.md section 5.1 forbids reading a pass or a fail out of
# TLC's console text, and that prohibition stands. State counts are not verdicts,
# they are numbers TLC reports about a run that already ended, and reading them
# says nothing about whether the check passed. Keeping the two apart in one file
# is deliberate: the `rc` column is authoritative and every other column is
# descriptive.
#
# WHAT `fairness` AND `temporal` ACTUALLY SAY
#
# They report what the module TEXT declares, not what the configuration checks.
# A module can carry a WF_ conjunct that no .cfg ever names, and this prints yes
# for it. That is the useful reading rather than an oversight: a declared
# fairness conjunct nobody consumes is a real and recurring shape, found
# independently in the corpus survey and in an RFC candidate, and a column that
# hid it would hide a finding. Read them as "the model needed this", never as
# "the check used this".
#
# Lineage: bead tla-frpu.

set -euo pipefail

usage() {
  cat <<'USAGE'
usage: spike-measure.sh --dir DIR --module NAME [--budget SECONDS] [--label TEXT]

  --dir      directory holding the .tla and .cfg files
  --module   module to check, without the .tla suffix
  --budget   wall-clock seconds before the run is killed (default 120)
  --label    free text carried through to the output row

Prints a one-row TSV to stdout with a header. Exit status is 0 when the
measurement was taken, whatever TLC's own verdict was, and 2 when the
measurement could not be taken at all.
USAGE
}

DIR="" MODULE="" BUDGET=120 LABEL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dir)     DIR="${2:-}"; shift 2 ;;
    --module)  MODULE="${2:-}"; shift 2 ;;
    --budget)  BUDGET="${2:-}"; shift 2 ;;
    --label)   LABEL="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$DIR" ] || [ -z "$MODULE" ]; then
  usage >&2
  exit 2
fi
[ -d "$DIR" ] || { printf 'no such directory: %s\n' "$DIR" >&2; exit 2; }
[ -f "$DIR/$MODULE.tla" ] || { printf 'no such module: %s/%s.tla\n' "$DIR" "$MODULE" >&2; exit 2; }

command -v tlc >/dev/null 2>&1 || { printf 'tlc not on PATH\n' >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cp "$DIR"/*.tla "$WORK"/ 2>/dev/null || true
cp "$DIR"/*.cfg "$WORK"/ 2>/dev/null || true

OUT="$WORK/.tlc-output"
T0="$(date +%s.%N)"
set +e
( cd "$WORK" && timeout "$BUDGET" tlc -workers 1 -cleanup "$MODULE" >"$OUT" 2>&1 )
RC=$?
set -e
T1="$(date +%s.%N)"
SECS="$(awk -v a="$T0" -v b="$T1" 'BEGIN{printf "%.1f", b-a}')"

# --- everything below is DESCRIPTIVE. rc above is the only verdict. ---

# TLC's progress line: "N states generated, M distinct states found".
# A here-string, never a pipe: a pipeline into an early-exiting consumer
# returns 141 under pipefail and a present pattern then reads as absent.
BODY="$(cat "$OUT" 2>/dev/null || true)"

generated="$(awk '/states generated/ {for(i=1;i<=NF;i++) if($(i+1)=="states"&&$(i+2)=="generated,") print $i}' <<<"$BODY" | tail -1)"
distinct="$(awk '/distinct states found/ {for(i=1;i<=NF;i++) if($(i+1)=="distinct"&&$(i+2)=="states") print $i}' <<<"$BODY" | tail -1)"
# "The depth of the complete state graph search is 6." -- last field, no period.
depth="$(awk '/depth of the complete state graph search/ {d=$NF; gsub(/[^0-9]/,"",d); print d}' <<<"$BODY" | tail -1)"

[ -n "${generated:-}" ] || generated="-"
[ -n "${distinct:-}"  ] || distinct="-"
[ -n "${depth:-}"     ] || depth="-"

# Close over EXTENDS inside DIR before measuring anything. The isolation spike
# checked a six-variable model and this reported one, because five of the six
# were declared in an extended scaffolding module and only the named module was
# read. A model is what TLC checks, not what one file says.
#
# Standard modules are skipped by the -f test, since Naturals and Sequences are
# not files in the directory. A multi-line EXTENDS is not handled; single-line
# is the attested form and a missed continuation undercounts rather than
# inventing a number.
SEEN=""
collect() {
  local mod="$1" f ext e
  case " $SEEN " in *" $mod "*) return 0 ;; esac
  SEEN="$SEEN $mod"
  f="$DIR/$mod.tla"
  [ -f "$f" ] || return 0
  cat "$f"
  ext="$(sed -n 's/^[[:space:]]*EXTENDS[[:space:]]*//p' "$f" | tr ',' ' ')"
  for e in $ext; do collect "$e"; done
}
SRC="$(collect "$MODULE")"
# collect runs inside a command substitution, so its SEEN never escapes the
# subshell. Count the module headers in the collected text, which is the same
# number by construction and does not depend on a variable surviving a fork.
NMODULES="$(grep -cE '^-{4,}[[:space:]]*MODULE[[:space:]]' <<<"$SRC" || true)"
# Remove both comment forms, so no column below reads prose as code. Comments
# are whitespace to TLA+ and this has to agree with that. Four things make a
# naive strip wrong, and every one of them was measured on a real module
# before this was written. The fixtures are in test-spike-measure.sh section
# 6, each labelled with the wrong number it used to produce.
#
#   - Block comments NEST. `(* a (* b *) c *)` is one comment, so a non-greedy
#     match stops at the first `*)` and leaves `c *)` standing as code, while
#     a greedy one runs to the last `*)` on the line and eats a declaration
#     sitting between two separate comments.
#   - The two forms are not independent. Inside a block, `\*` is ordinary
#     text; inside a line comment, `(*` opens nothing. Strip either form first
#     and the other leaves an unterminated comment that swallows the file.
#   - A comment opener inside a string literal is not an opener. Nothing used
#     to look for `(*` at all, so this is a hole the fix would otherwise open
#     rather than one it inherits, and it fails silently: the declaration
#     block disappears and the count reads 0.
#   - A line whose content is entirely comment is REMOVED, not blanked. The
#     declaration scanner below ends on a blank line, so blanking a commented
#     line between two declarations loses every declaration after it. The old
#     `\*` strip did exactly that, and a module with a line comment between
#     two VARIABLES entries read 1 for 2. A line that was already blank in the
#     source stays blank, so a real paragraph break still ends the block.
#
# Not handled, deliberately: an unterminated block comment bleeds into the
# next module in the EXTENDS closure rather than being reset at the module
# header. Such a module does not parse, so TLC reports it as rc 150 and the
# descriptive columns are not what anyone is reading on that row.
strip() {
  awk '
    {
      line = $0
      out = ""
      i = 1
      n = length(line)
      stripped = 0
      if (depth > 0) stripped = 1
      while (i <= n) {
        two = substr(line, i, 2)
        if (depth > 0) {
          if (two == "(*") { depth++; i += 2; continue }
          if (two == "*)") { depth--; i += 2; continue }
          i++
          continue
        }
        if (two == "(*") { depth++; stripped = 1; i += 2; continue }
        if (two == "\\*") { stripped = 1; break }
        if (substr(line, i, 1) == "\"") {
          out = out "\""
          i++
          while (i <= n) {
            ch = substr(line, i, 1)
            if (ch == "\\") { out = out substr(line, i, 2); i += 2; continue }
            out = out ch
            i++
            if (ch == "\"") break
          }
          continue
        }
        out = out substr(line, i, 1)
        i++
      }
      if (stripped && out ~ /^[ \t]*$/) next
      print out
    }' <<<"$1"
}
CLEAN="$(strip "$SRC")"

# No \b here. mawk does not implement it, and with it this counted zero
# variables on a module that plainly declares four.
# A declaration block runs from the VARIABLES keyword until a definition, a
# blank line, or a module rule. Two bugs lived here and both printed a
# confident wrong number:
#
#   - anchoring on \b counted zero, since this awk does not implement it
#   - falling back to re-reading the keyword line when nothing followed the
#     keyword counted the word VARIABLES itself, so a 7-variable model read 8
#
# The second is why the block below tracks whether it has already consumed the
# keyword line rather than testing whether a variable is empty. An empty
# remainder is a real answer, not a signal to look again.
nvars="$(awk '
  function tally(s,   n, a, i) {
    n = split(s, a, /[ ,\t]+/)
    for (i = 1; i <= n; i++)
      if (a[i] ~ /^[A-Za-z_][A-Za-z0-9_]*$/) c++
  }
  /^[[:space:]]*VARIABLES?([ \t]|$)/ {
    if (!grab) {
      grab = 1
      rest = $0
      sub(/^[[:space:]]*VARIABLES?/, "", rest)
      tally(rest)
      next
    }
  }
  grab {
    if ($0 ~ /==/ || $0 ~ /^[[:space:]]*$/ || $0 ~ /^-{4}/) { grab = 0; next }
    tally($0)
  }
  END { print c+0 }' <<<"$CLEAN")"

# Top-level definitions, not actions. An earlier version tried to count
# actions and read 0 on two specs that plainly have them, because it only
# matched a definition whose body starts on the next line. A column that
# lies is worse than a coarser one that does not, so this counts every
# top-level definition and the header says so.
ndefs="$(grep -cE '^[A-Za-z_][A-Za-z0-9_]*(\([^)]*\))?[[:space:]]*==' <<<"$CLEAN" || true)"
fairness="no";  grep -qE '(WF_|SF_)' <<<"$CLEAN" && fairness="yes"
temporal="no";  grep -qE '(~>|<>\[\]|\[\]<>|<>)' <<<"$CLEAN" && temporal="yes"
instance="no";  grep -qE '(^|[^A-Za-z])INSTANCE\b' <<<"$CLEAN" && instance="yes"
lines="$(printf '%s\n' "$SRC" | wc -l | tr -d ' ')"

case "$RC" in
  0)              verdict="checked, no violation" ;;
  11)             verdict="deadlock reported" ;;
  12)             verdict="invariant violated" ;;
  13)             verdict="property violated" ;;
  75|76|77)       verdict="evaluation failed, the check never happened" ;;
  124)            verdict="hit the ${BUDGET}s budget" ;;
  150)            verdict="parse or semantic failure" ;;
  151)            verdict="config names something absent" ;;
  *)              verdict="unclassified" ;;
esac

printf 'label\tmodule\trc\tverdict\tsecs\tgenerated\tdistinct\tdepth\tvars\tdefs\tfairness\ttemporal\tinstance\tmodules\tlines\n'
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "${LABEL:--}" "$MODULE" "$RC" "$verdict" "$SECS" \
  "$generated" "$distinct" "$depth" "$nvars" "$ndefs" \
  "$fairness" "$temporal" "$instance" "$NMODULES" "$lines"
