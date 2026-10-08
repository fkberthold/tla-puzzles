#!/usr/bin/env bash
# refutation-coverage.sh: report, per statement package, whether the package
# ships a refutation for every requirement it declares.
#
# Bead tla-n8oq. Usage:
#
#   harness/refutation-coverage.sh [<root>]
#
# <root> is a directory holding statement packages in the shape
# <root>/<name>/statement/PROBLEM.md. It defaults to authoring/ under the repo
# this script lives in. The root is resolved from ${BASH_SOURCE[0]} and never
# from a literal path, so a worktree run writes and reads inside that worktree.
#
# Exit: 0 if every package is OK, 1 if any is not, 2 on a usage error.
#
# ---------------------------------------------------------------------------
# WHAT THIS CHECKS, AND IT IS NARROWER THAN THE RULE IT SERVES
#
# The rule is in PRACTICE-PLAN.md, under the prose pipeline: for every
# requirement, does the rule set permit a model that violates it? That question
# is semantic. No shell script answers it, and one that claimed to would be a
# gate reporting a pass over a shape it cannot see.
#
# What a script CAN check is the instrument the rule is enforced through: a
# violating run, authored per requirement, before the freeze. Authoring one is
# what forces the defect into the open, because a requirement no permitted model
# can violate has no violating run to write down. So this script checks that the
# artifact exists and that it covers every requirement by count.
#
# Two per-package assertions, both arithmetic:
#
#   1. statement/traces/ exists and holds at least one refutation file.
#   2. the number of refutation files is at least the number of requirements
#      the statement states.
#
# WHAT IT DELIBERATELY DOES NOT CHECK, each one measured rather than assumed:
#
#   - That a trace file actually exhibits a violating run. Three incompatible
#     conventions are live in this tree: `## Forbidden` in 8 of 11 trace
#     directories, `**Where it breaks` in custody's 10, and neither in buyclub's
#     or consign's. A marker regex over those would mis-flag two packages, so
#     the count is over FILES and is an upper bound on refutations. A package
#     whose trace files are all satisfying runs passes this check.
#   - That the trace is consistent with the statement's rules. That is step 5's
#     job and it is a reader's job.
#   - That a requirement is falsifiable. This is the imap-move-partial-failure
#     shape, where PROBLEM.md:96 removes the action rather than forbidding the
#     outcome, and requirement 1 is true by construction. It is not detectable
#     from the statement's text: the sentence that closes the door reads like
#     any other rule. The gate reaches it only indirectly, by requiring the
#     violating trace that cannot be written.
#   - Whether the requirement set contains a reachability claim. This was
#     considered and rejected. 196 of 337 published configs declare no fairness
#     at all (.claude/rules/tla-practice.md section 7), so pure safety is the
#     corpus norm and a gate demanding a liveness requirement would be wrong
#     about most correct work. It also catches only one of the pattern's two
#     faces. See the bead.
#
# HOW A REQUIREMENT COUNT IS READ, AND WHY IT IS NOT A PROSE PARSER
#
# From the statement's own sentence: the FIRST line of PROBLEM.md that BEGINS
# with a number word followed by requirements, properties, obligations or
# "of them". Case-insensitive. Every package in this tree that states a count
# introduces its requirement list with exactly such a line, and 14 of 16 state
# one. The two that do not report NO_STATED_COUNT, which is not an OK.
#
# A requirement enumerator over the requirement BODIES was built and thrown
# away. Three numbering forms are live here (`1. **...**`, `**1. ...**` and
# `### Requirement N`) over at least four different section headings, and a
# whole-file grep for the first form reads 19 requirements in custody, which
# has ten. An enumerator that mis-reads a count low turns this gate into a
# pass over a shape it cannot see, which is the defect bead tla-hl96 is about.
# Reading the statement's own arithmetic instead means the gate is checking a
# sentence an author wrote on purpose.
#
# First-match-wins is a choice and not a proof, so it is not left to stand
# alone. harness/test-refutation-coverage.sh pins this script's verdict for
# every package in the tree, one line each. A change in how any package reads
# a mis-read count included, changes a verdict and fails that suite. The
# pin is where the per-package judgement lives, and this script only reports.
# ---------------------------------------------------------------------------

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${1:-${SCRIPT_DIR}/../authoring}"

if [ ! -d "$ROOT" ]; then
  echo "refutation-coverage.sh: no such root: $ROOT" >&2
  exit 2
fi

# <numberword> -> integer. Returns the empty string for anything unrecognised,
# which the caller treats as "no count", never as zero.
word_to_int() {
  case "${1,,}" in
    one)    echo 1  ;;
    two)    echo 2  ;;
    three)  echo 3  ;;
    four)   echo 4  ;;
    five)   echo 5  ;;
    six)    echo 6  ;;
    seven)  echo 7  ;;
    eight)  echo 8  ;;
    nine)   echo 9  ;;
    ten)    echo 10 ;;
    eleven) echo 11 ;;
    twelve) echo 12 ;;
    *)      echo "" ;;
  esac
}

COUNT_RE='^(one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve) (requirements?|properties|obligations?|of them)\b'

bad=0
seen=0

for problem in "$ROOT"/*/statement/PROBLEM.md; do
  [ -f "$problem" ] || continue
  statement_dir="$(dirname -- "$problem")"
  pkg="$(basename -- "$(dirname -- "$statement_dir")")"
  seen=$((seen + 1))

  # --- the stated requirement count ---------------------------------------
  # Captured, never piped into an early-exiting consumer: `grep -m 1` and
  # `| head -1` both return 141 under pipefail here, and a 141 would read as
  # "no count stated" on a statement that states one (bead tla-kr9).
  raw="$(grep -oiE "$COUNT_RE" "$problem" 2>/dev/null)"
  first_word="$(awk 'NR == 1 { print tolower($1) }' <<<"$raw")"
  req="$(word_to_int "$first_word")"

  # --- the refutations shipped --------------------------------------------
  traces_dir="${statement_dir}/traces"
  refutations=0
  has_traces=0
  declared_none=0
  if [ -d "$traces_dir" ]; then
    has_traces=1
    for f in "$traces_dir"/*.md; do
      [ -f "$f" ] || continue
      base="$(basename -- "$f")"
      [ "${base,,}" = "readme.md" ] && continue
      # NONE.md is a DECLARATION that this package ships no refutation trace,
      # carrying the reason. It is not itself a refutation, so it does not
      # count, and its presence is what separates a deliberate absence from an
      # absence nobody has explained. Added 2026-10-08 after acme-challenge-
      # retry-deadlock was measured UNABLE to carry a trace for its own
      # requirement 1: the violating state that trace needs is exactly the
      # state its other requirements forbid. That is a true fact about the
      # problem rather than unfinished work, and a gate that cannot tell the
      # two apart reports the same verdict for both.
      if [ "${base,,}" = "none.md" ]; then
        declared_none=1
        continue
      fi
      refutations=$((refutations + 1))
    done
  fi

  # --- the verdict ---------------------------------------------------------
  if [ "$has_traces" -eq 0 ]; then
    printf 'NO_TRACES         %-32s requirements=%-4s refutations=-   no statement/traces/ directory\n' \
      "$pkg" "${req:-?}"
    bad=$((bad + 1))
  elif [ "$refutations" -eq 0 ] && [ "$declared_none" -eq 1 ]; then
    printf 'DECLARED_NONE     %-32s requirements=%-4s refutations=0   traces/NONE.md declares and explains the absence\n' \
      "$pkg" "${req:-?}"
  elif [ "$refutations" -eq 0 ]; then
    printf 'EMPTY_TRACES      %-32s requirements=%-4s refutations=0   traces/ holds no refutation file\n' \
      "$pkg" "${req:-?}"
    bad=$((bad + 1))
  elif [ -z "$req" ]; then
    printf 'NO_STATED_COUNT   %-32s requirements=?    refutations=%-3s statement states no requirement count this reads\n' \
      "$pkg" "$refutations"
    bad=$((bad + 1))
  elif [ "$refutations" -lt "$req" ]; then
    printf 'UNDER_COVERED     %-32s requirements=%-4s refutations=%-3s fewer refutations than requirements\n' \
      "$pkg" "$req" "$refutations"
    bad=$((bad + 1))
  else
    printf 'OK                %-32s requirements=%-4s refutations=%-3s\n' \
      "$pkg" "$req" "$refutations"
  fi
done

if [ "$seen" -eq 0 ]; then
  echo "refutation-coverage.sh: no statement package under $ROOT. Refusing to report success." >&2
  exit 2
fi

if [ "$bad" -eq 0 ]; then
  exit 0
fi
exit 1
