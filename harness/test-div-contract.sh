#!/usr/bin/env bash
# test-div-contract.sh — the reviewed-set gate for `\div`, bead tla-7n7e.
#
# THE BUG. tla2tools v1.8.0 ships a Naturals.tla that states its own contract:
# for any integers a and b with b > 0, `a = b * (a \div b) + (a % b)`. TLC
# 2026.07.31.184830 breaks it. Measured with PrintT, `-17 \div 5` comes back
# -3 and `-17 % 5` comes back 3, so `5 * -3 + 3` is -12 rather than -17. The
# remainder half holds, sitting in 0..4 as the contract requires. The quotient
# is the half that is wrong: it truncates toward zero where the contract
# forces it to round down.
#
# WHY IT MATTERS HERE. This corpus takes its verdicts from TLC's exit codes,
# so an item written over a negative dividend gets a baked answer that is
# TLC's bug rather than the truth. It caught three of the first 80 level 0
# swipe items, and those three were replaced rather than relabeled.
#
# WHAT THIS GATE IS, AND WHAT IT IS NOT. "The dividend can never be negative"
# is a semantic property and no scan decides it, so this suite does not try.
# It holds the tree to harness/div-sites.tsv, a set of sites somebody has
# read, each carrying the reason its dividend is safe. A `\div` that is not in
# that file fails, and an entry whose site has gone fails. The enforcement is
# that a new `\div` stops its author and makes them look at the dividend.
#
# That is the same shape as REQUIRES_PATTERN_NAMES in harness/recall-gate.sh,
# and it borrows that file's rule about a total miss: if NOT ONE entry
# resolves, the inventory is describing some other tree and saying so once is
# worth more than 73 separate findings. Here there is only one tree, so a
# total miss is still a failure. It just gets one line rather than seventy.
#
# WHEN THIS GOES RED, GO AND READ THE DIVIDEND. Never add a row to the
# inventory to quiet the gate. A row nobody read is worth nothing.
#
# THIS IS NOT THE TOOLCHAIN TRIPWIRE, and the two should not be confused.
# harness/test-swipe-level0.sh asserts that the identity is STILL broken, so a
# TLC that fixes `\div` turns that suite red on purpose. That one watches the
# jar. This one watches what authors write.
#
# `%` IS DELIBERATELY OUT. The remainder obeys the contract, so a `%` site
# carries no wrong answer, and the character cannot be told from a percentage
# or a printf format without a TLA+ parser. The inventory header has the
# measurement behind that call.
#
# Usage:  harness/test-div-contract.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }

INVENTORY="harness/div-sites.tsv"

# The operator, as a fixed string. Every match in this suite is literal rather
# than a regex, and the control in part 4 is what makes that sound: it asserts
# that no `\div` under the roots is followed by a word character, so the fixed
# string and the TLA+ token are the same set on this tree. The day somebody
# writes `\divide`, that control says so instead of this file silently
# counting it as an operator.
DIV='\div'

# ---------------------------------------------------------------------------
# THE ROOTS.
#
# Add a ROOT here, never an individual file. A file written tomorrow should be
# covered without anybody remembering to enroll it, which is why selection
# runs over `git ls-files` rather than over a list. Tracked rather than found,
# so a scratch directory or a build artifact never turns this red.
#
# chapter/ carries no site today and is in the list so that the first one is
# caught rather than discovered later.
# ---------------------------------------------------------------------------
SCAN_ROOTS=(drill reading recall completion exercises chapter swipe harness/fixtures)

# root:floor, measured 2026-10-18 over 2222 tracked files. Each floor sits
# under the count that day, so it asserts that a root is still being walked
# rather than how big it has grown.
ROOT_FLOORS=(
  "drill:900"
  "reading:50"
  "recall:40"
  "completion:70"
  "exercises:250"
  "chapter:30"
  "swipe:3"
  "harness/fixtures:50"
)

# ---------------------------------------------------------------------------
# WHAT IS DELIBERATELY NOT A ROOT, with the count each carried on 2026-10-18.
# A gate that passes by being narrow is worth less than no gate, so these are
# named rather than left for somebody to rediscover. This file and
# harness/div-sites.tsv are left out of the census, since a gate counting its
# own prose says nothing about the corpus.
#
#   harness/ above fixtures  16  gate code, 12 of it the tripwire in
#                                test-swipe-level0.sh. A gate author reading a
#                                gate is a different reader from an item
#                                author
#   puzzles/                  8  v1, out of scope by era, as everywhere else
#   scripts/test              5  this suite's registry row and its note
#   .beads/issues.jsonl       3  the tracker export, which is generated
#   module-docs/              2  Integers.md and Naturals.md document the
#                                operator. Integers.md:16 already reads
#                                "truncates toward zero", which is TLC's
#                                behavior rather than Naturals.tla's contract
#   top-level .md             2  SCAFFOLDING_MAP.md, PLAN-reading-expansion.md
#
# That is 36 occurrences. Clear one and move its root up into SCAN_ROOTS with
# a floor, which is a two-line change and the point of the layout.
# ---------------------------------------------------------------------------

# Every tracked file under the roots.
SELECTED=()
select_scan_files() {
  SELECTED=()
  local f
  # stderr is dropped because the control in part 4 hands this a path outside
  # the repository on purpose, and git says so loudly. The assertion there is
  # that nothing comes back.
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    SELECTED+=("$f")
  done < <(git ls-files -- "$@" 2>/dev/null | sort)
}

# Narrows a file list to the ones that could report anything, in ONE grep
# rather than one per file. harness/test-spelling.sh measured the obvious loop
# at 20x slower over the same order of tracked files, and that row would have
# been the dearest in the fast tier for a suite that runs no TLC at all.
#
# `-I` skips binary files.
CANDIDATES=()
narrow_to_candidates() {
  CANDIDATES=()
  [ "$#" -gt 0 ] || return 0
  local f
  while IFS= read -r f; do
    [ -n "$f" ] && CANDIDATES+=("$f")
  done < <(grep -lIF -- "$DIV" "$@" 2>/dev/null | sort)
}

# ---------------------------------------------------------------------------
# THE KEY, and it is the one design choice worth reading before you change
# anything here.
#
# A site is identified by its path and by a WINDOW: the whitespace token
# carrying `\div`, plus one token on each side. `17 \div 5 = 3` and
# `(17 \div 5) * 5 + (17 % 5) = 17` give `17 \div 5` and `(17 \div 5)`.
#
# A line number was the obvious key and it is the wrong one. It goes stale on
# the next edit above it, so the inventory would be red constantly and
# somebody would delete it. The whole line is the next obvious key and it is
# also wrong: a swipe item row carries its explanation prose in field 11, so
# rewording a sentence would redden a gate that has nothing to say about
# prose. The window holds the operands and drops the sentence.
#
# The price is that distinct sites can share a window, which is why the
# inventory carries an exact count. Four items state `17 \div 5`, so they are
# one row at count 4, and a fifth reddens the gate until somebody reads it.
#
# `read -r -a` ON PURPOSE, although .claude/rules/dispatched-agents.md warns
# against `read` over tab-delimited data. That warning is about reading FIELDS
# out of a TSV, where folding a run of tabs into one delimiter shifts every
# field after it. Here the folding is the behavior wanted: the job is to split
# a line into whitespace tokens, and a tab is whitespace.
# ---------------------------------------------------------------------------
SITES=""
SITE_COUNT=0
collect_sites() {
  SITES=""
  SITE_COUNT=0
  local f line i w n rest
  local -a toks
  for f in "$@"; do
    while IFS= read -r line; do
      read -r -a toks <<<"$line"
      for i in "${!toks[@]}"; do
        case "${toks[$i]}" in *"$DIV"*) ;; *) continue ;; esac
        w=""
        [ "$i" -gt 0 ] && w="${toks[$((i - 1))]} "
        w="$w${toks[$i]}"
        [ "$((i + 1))" -lt "${#toks[@]}" ] && w="$w ${toks[$((i + 1))]}"
        # Occurrences, not tokens. `a\div b\div c` written without spaces is
        # one token carrying two operators, and counting the token once would
        # let the second in unreviewed.
        n=0
        rest="${toks[$i]}"
        while [ -n "$rest" ]; do
          case "$rest" in
          *"$DIV"*)
            n=$((n + 1))
            rest=${rest#*"$DIV"}
            ;;
          *) break ;;
          esac
        done
        while [ "$n" -gt 0 ]; do
          SITES="${SITES}${f}	${w}
"
          SITE_COUNT=$((SITE_COUNT + 1))
          n=$((n - 1))
        done
      done
    done < <(grep -hIF -- "$DIV" "$f" 2>/dev/null)
  done
}

# Occurrence lines to "path<TAB>count<TAB>window". Sorted, so the aggregate is
# stable whatever order the files came in.
aggregate_sites() {
  local text="$1" counted row n rest path win
  [ -n "$text" ] || return 0
  # The trailing newline goes first. A here-string appends one of its own, so
  # a text already ending in a newline reaches sort as a blank line, and uniq
  # counts it into a phantom site with an empty path. That phantom was the
  # first thing this gate reported.
  counted=$(sort <<<"${text%
}" | uniq -c)
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    while [ "${row# }" != "$row" ]; do row=${row# }; done
    n=${row%% *}
    rest=${row#* }
    [ -n "$rest" ] || continue
    path=${rest%%	*}
    win=${rest#*	}
    printf '%s\t%s\t%s\n' "$path" "$n" "$win"
  done <<<"$counted"
}

# ---------------------------------------------------------------------------
# THE INVENTORY READER.
#
# Field extraction by prefix stripping rather than by `IFS=$'\t' read`, for
# exactly the reason the tokenizer above does the opposite: here the fields
# are tab-delimited data, a reason is free text, and folding a run of tabs
# would shift the columns without saying so.
# ---------------------------------------------------------------------------
INV_AGG=""
INV_ROWS=0
INV_BAD=""
read_inventory() {
  local file="$1" row rest path cnt win reason key
  local seen=""
  INV_AGG=""
  INV_ROWS=0
  INV_BAD=""
  [ -f "$file" ] || { INV_BAD="no inventory at ${file}"; return 1; }
  while IFS= read -r row; do
    case "$row" in
    'SITE	'*) ;;
    *) continue ;;
    esac
    rest=${row#*	}
    path=${rest%%	*}
    rest=${rest#*	}
    cnt=${rest%%	*}
    rest=${rest#*	}
    win=${rest%%	*}
    # The tab in this pattern is quoted because bash tokenizes a case pattern
    # on whitespace, so a bare one reads as two words and is a syntax error.
    case "$rest" in
    *"	"*) reason=${rest#*	} ;;
    *) reason="" ;;
    esac

    INV_ROWS=$((INV_ROWS + 1))
    case "$cnt" in
    '' | *[!0-9]*) INV_BAD="${INV_BAD}
      ${path}  count '${cnt}' is not a number" ;;
    0) INV_BAD="${INV_BAD}
      ${path}  count is 0, so the row asserts nothing. Delete it instead" ;;
    esac
    [ -n "$win" ] || INV_BAD="${INV_BAD}
      ${path}  window is empty"
    [ -n "$reason" ] || INV_BAD="${INV_BAD}
      ${path}  ${win}  has no reason. A row nobody read is worth nothing"

    key="${path}	${win}"
    case "
${seen}" in
    *"
${key}
"*) INV_BAD="${INV_BAD}
      ${path}  ${win}  is listed twice. The second row is unreachable" ;;
    *) seen="${seen}${key}
" ;;
    esac

    INV_AGG="${INV_AGG}${path}	${cnt}	${win}
"
  done <"$file"
  return 0
}

# ---------------------------------------------------------------------------
# THE COMPARATOR.
#
# Takes two aggregates as text rather than reading the tree, so part 4 can
# drive it over synthetic input. A comparator that only ever runs against the
# real inventory cannot be controlled: if it quietly stopped reporting, every
# assertion below would still say "found nothing" and pass.
# ---------------------------------------------------------------------------
CMP_NEW=""
CMP_VANISHED=""
CMP_DRIFT=""
CMP_RESOLVED=0
compare_inventory() {
  local inv_text="$1" live_text="$2"
  local row rest path cnt win key
  # `=()` is not decoration. A `declare -A` with no assignment leaves the
  # array declared and unset, and `${#have[@]}` over that is an unbound
  # expansion under `set -u`, which is how the empty-tree control first died.
  declare -A want=()
  declare -A have=()
  CMP_NEW=""
  CMP_VANISHED=""
  CMP_DRIFT=""
  CMP_RESOLVED=0

  while IFS= read -r row; do
    [ -n "$row" ] || continue
    path=${row%%	*}
    rest=${row#*	}
    cnt=${rest%%	*}
    win=${rest#*	}
    want["${path}	${win}"]="$cnt"
  done <<<"$inv_text"

  while IFS= read -r row; do
    [ -n "$row" ] || continue
    path=${row%%	*}
    rest=${row#*	}
    cnt=${rest%%	*}
    win=${rest#*	}
    have["${path}	${win}"]="$cnt"
  done <<<"$live_text"

  # Guarded on the element count rather than expanded bare. An empty
  # associative array under `set -u` is an unbound expansion on bash before
  # 4.4, and the keys here carry spaces, so the usual `${a[@]+...}` dodge
  # would word-split them.
  if [ "${#have[@]}" -gt 0 ]; then
    for key in "${!have[@]}"; do
      if [ -z "${want[$key]+set}" ]; then
        CMP_NEW="${CMP_NEW}
      ${key%%	*}  ->  ${key#*	}  (x${have[$key]})"
      else
        CMP_RESOLVED=$((CMP_RESOLVED + 1))
        if [ "${want[$key]}" != "${have[$key]}" ]; then
          CMP_DRIFT="${CMP_DRIFT}
      ${key%%	*}  ->  ${key#*	}  inventory says ${want[$key]}, tree has ${have[$key]}"
        fi
      fi
    done
  fi

  if [ "${#want[@]}" -gt 0 ]; then
    for key in "${!want[@]}"; do
      if [ -z "${have[$key]+set}" ]; then
        CMP_VANISHED="${CMP_VANISHED}
      ${key%%	*}  ->  ${key#*	}  (inventory says x${want[$key]})"
      fi
    done
  fi
}

# ===========================================================================
# PART 1 — the scan reaches every root.
# ===========================================================================

select_scan_files "${SCAN_ROOTS[@]}"

echo "== part 1: the scan covers ${SCAN_ROOTS[*]} =="

# One assertion PER ROOT, never one over the total. A single total goes green
# on drill/ alone, so it could not tell "swipe/ is covered" from "swipe/
# silently dropped out of the listing". Every finding below is of the form
# "found nothing", which reads the same whether the scan is clean or blind.
check_root() {
  local root="$1" floor="$2" f n=0
  for f in "${SELECTED[@]}"; do
    case "$f" in "$root"/*) n=$((n + 1)) ;; esac
  done
  if [ "$n" -ge "$floor" ]; then
    ok "scan covers $root/ — $n tracked files"
  else
    nope "scan found only $n tracked files under $root/ (floor $floor) — the gate is not covering that root"
  fi
}

for entry in "${ROOT_FLOORS[@]}"; do
  check_root "${entry%%:*}" "${entry#*:}"
done

narrow_to_candidates "${SELECTED[@]}"

if [ "${#CANDIDATES[@]}" -gt 0 ]; then
  ok "narrowing left ${#CANDIDATES[@]} of ${#SELECTED[@]} files carrying '$DIV'"
else
  nope "narrowing left no files at all — either the tree has no '$DIV' anywhere, which contradicts the inventory, or the grep is not running"
fi

# The assumption under every fixed-string match in this file. `\div` is a
# complete TLA+ token, so nothing in the corpus should carry `\divide` or a
# name starting the same way. If one lands, the fixed string stops being the
# operator and this suite would quietly count the wrong thing.
word_hits=""
if [ "${#CANDIDATES[@]}" -gt 0 ]; then
  word_hits=$(grep -nHIE -- '\\div[A-Za-z0-9_]' "${CANDIDATES[@]}" 2>/dev/null)
fi
if [ -z "$word_hits" ]; then
  ok "every '$DIV' under the roots is the bare operator, so the fixed-string match is the token"
else
  nope "a '$DIV' is followed by a word character, so the fixed string is no longer the operator:
$word_hits"
fi

# ===========================================================================
# PART 2 — the inventory is well formed.
# ===========================================================================

echo
echo "== part 2: $INVENTORY is well formed =="

if read_inventory "$INVENTORY"; then
  if [ "$INV_ROWS" -gt 0 ]; then
    ok "read $INV_ROWS SITE row(s) from $INVENTORY"
  else
    nope "$INVENTORY holds no SITE row. A row is tab-delimited and begins with the literal SITE"
  fi
  if [ -z "$INV_BAD" ]; then
    ok "every row carries a path, a positive count, a window and a reason"
  else
    nope "malformed row(s) in $INVENTORY:$INV_BAD"
  fi
else
  nope "$INV_BAD"
fi

# ===========================================================================
# PART 3 — the tree matches the inventory.
# ===========================================================================

echo
echo "== part 3: every '$DIV' under the roots is a reviewed site =="

collect_sites "${CANDIDATES[@]}"
LIVE_AGG=$(aggregate_sites "$SITES")

compare_inventory "$INV_AGG" "$LIVE_AGG"

if [ "$CMP_RESOLVED" -eq 0 ] && [ "$INV_ROWS" -gt 0 ]; then
  # The recall-gate rule. A total miss is a different tree rather than 73
  # independent findings, and saying so once is the useful report.
  nope "not one of the $INV_ROWS inventory rows resolves against this tree, so $INVENTORY is describing some other checkout. Reporting that once rather than row by row"
else
  ok "$CMP_RESOLVED inventory row(s) resolve against the tree"
fi

if [ -z "$CMP_NEW" ]; then
  ok "no unreviewed '$DIV' site under ${SCAN_ROOTS[*]}"
else
  nope "unreviewed '$DIV' site(s). GO AND READ THE DIVIDEND, then add a row to $INVENTORY saying why it is safe:$(sort <<<"$CMP_NEW")"
fi

if [ -z "$CMP_VANISHED" ]; then
  ok "every inventory row still matches a site in the tree"
else
  nope "inventory row(s) matching nothing. Delete the row rather than leaving a standing exemption for a site that has gone, and check for a rename first:$(sort <<<"$CMP_VANISHED")"
fi

if [ -z "$CMP_DRIFT" ]; then
  ok "every inventory count is exact"
else
  nope "inventory count(s) out of step with the tree. Read the dividend at each new occurrence before you bump a number:$(sort <<<"$CMP_DRIFT")"
fi

if [ "$SITE_COUNT" -gt 0 ]; then
  ok "$SITE_COUNT '$DIV' occurrence(s) scanned across ${#CANDIDATES[@]} file(s)"
else
  nope "the scan produced no site at all, so every check above passed on an empty set"
fi

# ===========================================================================
# PART 4 — controls on the scanner and the comparator.
#
# Every assertion in part 3 reports "found nothing", which is also what a
# scanner that stopped working reports. These plant the shapes in synthetic
# input outside the roots and require both directions to be right.
# ===========================================================================

echo
echo "== part 4: the scanner and the comparator still bite =="

CONTROL_DIR=$(mktemp -d -t tla_div_control.XXXXXX)
trap 'rm -rf "$CONTROL_DIR"' EXIT

# A swipe item row, tabs and all, with a negative dividend in it. The window
# must come back as the expression alone, with the explanation prose dropped,
# because that is the whole claim the key rests on.
PLANTED="$CONTROL_DIR/planted.tsv"
printf 'ITEM\tL0-T9-01\tT9\tholds\ttrue\tright\t0\t0\t-17 \\div 5 = -3\t-\tFive goes into minus seventeen.\n' >"$PLANTED"
printf 'Rescaled == Chained(LAMBDA a: a \\div 2, LAMBDA b: b - 12, 28)\n' >>"$PLANTED"

collect_sites "$PLANTED"
planted_sites="$SITES"

if [ "$SITE_COUNT" -eq 2 ]; then
  ok "control: the scanner finds both planted occurrences"
else
  nope "control: the scanner found $SITE_COUNT planted occurrence(s), wanted 2 — the detailed pass is dead and part 3 is vacuous"
fi

if grep -qF -- "-17 ${DIV} 5" <<<"$planted_sites"; then
  ok "control: the window is the expression, and the item's explanation prose is dropped"
else
  nope "control: the window did not come back as '-17 ${DIV} 5'. The key is no longer prose-independent:
$planted_sites"
fi

CLEAN="$CONTROL_DIR/clean.tla"
printf 'Half(n) == n %% 2\n' >"$CLEAN"
collect_sites "$CLEAN"
if [ "$SITE_COUNT" -eq 0 ]; then
  ok "control: a file with no '$DIV' yields no site"
else
  nope "control: a clean file yielded $SITE_COUNT site(s), so the scanner matches something it should not"
fi

# Selection must not reach outside the repository, whatever it is handed.
select_scan_files "$CONTROL_DIR"
if [ "${#SELECTED[@]}" -eq 0 ]; then
  ok "control: selection over a path outside the repository returns nothing"
else
  nope "control: selection returned ${#SELECTED[@]} file(s) from outside the repository, so the gate is not reading the index"
fi

# --- the comparator, over synthetic aggregates -----------------------------

CTL_INV=$(printf 'a/b.tla\t1\tx \\div 2\nc/d.tla\t2\ty \\div 3\n')

compare_inventory "$CTL_INV" "$CTL_INV"
if [ -z "$CMP_NEW" ] && [ -z "$CMP_VANISHED" ] && [ -z "$CMP_DRIFT" ] && [ "$CMP_RESOLVED" -eq 2 ]; then
  ok "control: an inventory matching its tree reports clean"
else
  nope "control: identical aggregates reported a difference, so the gate cries wolf on a tree nobody changed"
fi

CTL_EXTRA=$(printf '%s\ne/f.tla\t1\tz \\div 4\n' "$CTL_INV")
compare_inventory "$CTL_INV" "$CTL_EXTRA"
if [ -n "$CMP_NEW" ] && [ -z "$CMP_VANISHED" ]; then
  ok "control: a planted unreviewed site is DETECTED and named"
else
  nope "control: an unreviewed site was not detected, so the ban in part 3 is vacuous"
fi

CTL_MISSING=$(printf 'a/b.tla\t1\tx \\div 2\n')
compare_inventory "$CTL_INV" "$CTL_MISSING"
if [ -n "$CMP_VANISHED" ] && [ -z "$CMP_NEW" ]; then
  ok "control: an inventory row whose site has gone is DETECTED"
else
  nope "control: a vanished site was not detected, so an exemption could outlive the line it covers"
fi

CTL_DRIFT=$(printf 'a/b.tla\t1\tx \\div 2\nc/d.tla\t3\ty \\div 3\n')
compare_inventory "$CTL_INV" "$CTL_DRIFT"
if [ -n "$CMP_DRIFT" ] && [ -z "$CMP_NEW" ] && [ -z "$CMP_VANISHED" ]; then
  ok "control: a count that has moved is DETECTED without reading as a new site"
else
  nope "control: a count change was not detected, so a second occurrence under a reviewed window would walk in"
fi

compare_inventory "$CTL_INV" ""
if [ "$CMP_RESOLVED" -eq 0 ]; then
  ok "control: an aggregate matching nothing resolves 0 rows, which is what part 3 reports once"
else
  nope "control: an empty tree resolved $CMP_RESOLVED row(s), so the total-miss branch can never fire"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
