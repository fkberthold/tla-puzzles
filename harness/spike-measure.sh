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
# sed rather than ${var//search/replace}, which shellcheck suggests and which
# is wrong here. This strips a \* comment to end of LINE, and bash pattern
# replacement has no line concept: * matches newlines too, so the parameter
# form would delete from the first comment to the end of the file.
# shellcheck disable=SC2001
strip() { sed -e 's/\\\*.*//' <<<"$1"; }
CLEAN="$(strip "$SRC")"

# No \b here. mawk does not implement it, and with it this counted zero
# variables on a module that plainly declares four.
nvars="$(awk '
  /^[[:space:]]*VARIABLES?([ \t]|$)/ {
    grab=1
    line=$0
    sub(/^[[:space:]]*VARIABLES?/,"",line)
  }
  grab {
    if (!line) line=$0
    if (line ~ /==/ || line ~ /^[[:space:]]*$/ || line ~ /^-{4}/) { grab=0; line=""; next }
    n=split(line, a, /[ ,\t]+/)
    for(i=1;i<=n;i++) if (a[i] ~ /^[A-Za-z_][A-Za-z0-9_]*$/) c++
    line=""
  }
  END{print c+0}' <<<"$CLEAN")"

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
