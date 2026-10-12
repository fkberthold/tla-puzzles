#!/usr/bin/env bash
# drill-gate.sh — the three checks over a blank-page drill corpus.
#
# THE REASON THIS EXISTS. Six authors produce drill items in parallel and
# central cannot read forty to sixty of them by hand. So what this script
# checks is what the corpus is GUARANTEED to be, and everything it does not
# check is unguaranteed. The header below says which is which, per check,
# because a reader who assumes the wrong half is the failure this file is
# most likely to cause.
#
# USAGE
#   harness/drill-gate.sh [OPTIONS] <drill-root>
#
# OPTIONS
#   --inventory FILE   construct inventory (default: <drill-root>/INVENTORY.md)
#   --no-tlc           skip every TLC run in check 2. The static checks still
#                      run. This mode can NEVER exit 0 — see EXIT CODES.
#   --timeout SECS     per-module TLC budget, passed to verdict.sh (default 60)
#   -q, --quiet        suppress the per-item PASS lines; findings still print
#   -h, --help         this text
#
# OUTPUT — three machine-readable line shapes, then a human block.
#   FINDING   <code> <item> <detail>      a defect. Exits 1.
#   UNCHECKED <check> <subject> <detail>  a check that could not run. Exits 99.
#   COVERAGE  <count> <freq> <family> <construct>
#   WAIVER    <item> <token> <reason>     a per-item telegraph waiver, echoed
#                                         so waivers cannot accumulate unseen.
#
# EXIT CODES
#     0  every check ran and every check passed
#     1  at least one FINDING. Findings outrank unchecked: a run with both
#        exits 1, because the finding is the actionable half
#    99  no findings, but at least one check COULD NOT RUN. The project-wide
#        CHECK_DID_NOT_RUN code (harness/verdict.sh, bead tla-hl96). An
#        instrument that was asked for a check it could not perform must not
#        report success, so this is not folded into 0
#     2  usage error
#
# ONLY CHECKS 1 AND 2 CAN PRODUCE A FINDING. CHECK 3 PRINTS AND NEVER FAILS —
# no construct count can redden this gate. The reasoning is in CHECK 3's own
# section below, and it is worth reading before touching that block.
#
# ===========================================================================
# CHECK 1 — TELEGRAPH.  Is the answer recoverable from the prompt?
#
# This is the corpus's whole reason for existing. Frank's verdict on every
# prior attempt was "too rote, it was hard to make puzzles that didn't just
# have the answer built in", so an item that hands over its own answer is not
# a weak item, it is the defect the corpus was rebuilt to avoid.
#
# WHAT IS CHECKED, in two layers.
#
#   Layer A, the declared layer. For every construct META.md says the item
#   exercises, that construct's TOKEN must not appear in PROMPT.md. The token
#   comes from INVENTORY.md, so the thing being drilled is the thing the
#   prompt may not show. This layer is precise and it is the one that matters:
#   it flags `~>` in the prompt of a leads-to drill and ignores `~>` in the
#   prompt of a CHOOSE drill, where it would be scenery.
#
#   Layer B, the floor. Every DISTINCTIVE operator appearing inside a fenced
#   code block in ANSWER.md must be absent from PROMPT.md, whatever META.md
#   declared. This layer exists because layer A trusts a declaration, and an
#   item that under-declares would otherwise be unchecked.
#
#   A prompt carrying a TLC TRACE gets the same treatment as one carrying
#   code. This is a finding from the trial and it is the non-obvious half of
#   the check: the trace IS part of the prompt, and a LASSO trace is itself a
#   partial answer, because it shows exactly where an action was enabled and
#   skipped, which is half the diagnosis. So a prompt with a trace in it is
#   scanned for tokens like any other, and on top of that its ANSWER.md must
#   say in prose that the trace is there and what it gives away.
#
#   ANSWER.md must carry a non-empty why-not-in-prompt field. The format
#   requires it to hold an honest caveat where the item partly telegraphs.
#
# WHAT IS *NOT* CHECKED, and this list is the honest altitude of the check:
#
#   - DOMAIN SMELL. A prompt that telegraphs by familiarity is invisible
#     here. One trial author flagged exactly this failure in its own item:
#     "a reader who has met a request-served example before may recall `~>`
#     by the smell of the domain". No token appears, nothing fires, and the
#     item is as telegraphed as one that printed the operator. This gate does
#     not catch it and cannot. The why-not-in-prompt field is where that risk
#     is recorded, and only a human reading the field catches it.
#   - WHETHER THE CAVEAT IS TRUE. Presence and length are checked. Honesty is
#     not checkable and is not checked.
#   - ENGLISH PARAPHRASE, deliberately. A prompt saying "eventually the
#     request is served" is not flagged when the answer writes `<>`. That
#     phrasing is the PROBLEM STATEMENT: a drill has to state its
#     requirement in English, and flagging the English would forbid writing a
#     prompt at all. The gate flags the SYMBOL and never the gloss. This is
#     a deliberate hole and it is the largest one in the check.
#   - SHARED TLA+ VOCABULARY, by construction. See DISTINCTIVE below.
#   - WHETHER THE ANSWER IS DERIVABLE by reasoning that never touches the
#     answer's own tokens. That is the interesting case and it is unreachable
#     from here.
#
# ===========================================================================
# CHECK 2 — VERIFICATION.  Does verify/ actually run, and does the recorded
#                          rc reproduce?
#
# WHAT IS CHECKED. Every module under verify/ that is CHECKABLE — it has a
# .cfg and ANSWER.md records an rc for it — is run through
# harness/verdict.sh, and the rc TLC returns must equal the rc ANSWER.md
# claims. An item whose recorded rc does not reproduce is the defect; the
# number in the file is a measurement and a measurement that does not
# repeat is wrong.
#
# Three structural checks sit on top of the per-module one:
#
#   - At least one checkable module must record rc 0. Otherwise the stated
#     answer was never shown to check.
#   - At least one must record a non-zero rc. Otherwise no stated wrong
#     answer was ever shown to fail, and the item proves only that something
#     passes.
#   - A recorded rc must be a row of verdict.sh's table. A recorded 1 or 2 is
#     almost always a mis-transcription of a shell exit, and it reproduces
#     against nothing.
#
# The rc rows that matter most here, from harness/verdict.sh's table:
#
#     11 DEADLOCK   12 SAFETY_VIOLATION   13 LIVENESS_VIOLATION
#    150 PARSE_ERROR  255 TLC_EXCEPTION (usually a cross-type comparison,
#                     a string marker sitting beside an integer)
#
#   12 AND 13 SPLIT ON THE SHAPE OF THE FORMULA, NOT THE .cfg KEYWORD
#   (verdict.sh:81-91). `[](P => []P)` and `~<>P` are safety written with
#   temporal operators and exit 12, not 13. An author who reasons from the
#   keyword will record 13 and the run will return 12. That is a real defect
#   in the item and this check is what finds it.
#
# WHAT IS *NOT* CHECKED:
#   - WHETHER THE STATED ANSWER IS THE RIGHT ANSWER. rc 0 proves the module
#     checks, not that it answers the prompt. A vacuous invariant over an
#     empty model exits 0 too. harness/vacuity.sh is the instrument for that
#     question and this gate does not run it.
#   - WHETHER A WRONG ANSWER FAILS FOR THE STATED REASON. rc 12 proves a
#     safety violation happened, not that it was the intended one.
#   - THE ACCEPTABLE VARIANTS. ANSWER.md lists them; nothing here checks that
#     a variant also passes unless it has its own module and rc.
#   - A HELPER MODULE with no cfg and no recorded rc. It is reported as
#     skipped rather than silently ignored, but it is not run.
#
# ===========================================================================
# CHECK 3 — CORPUS COVERAGE. IT REPORTS. IT NEVER FAILS.
#
# THE COVERAGE CHECK PRINTS PER-CONSTRUCT COUNTS AND PRINTS THE GAPS, AND IT
# DOES NOT CONTRIBUTE TO THIS SCRIPT'S EXIT CODE. NO CONSTRUCT COUNT CAN
# REDDEN THE GATE.
#
# WHY, because the next person to read this will want to add the failing arm
# back, and this paragraph is what stops them. V2-PLAN.md:459: "Coverage is
# an end-of-run AUDIT, never the problem-list generator. Organizing by
# construct produces problems whose purpose is 'this one exercises CHOOSE,'
# which is contrived by construction."
#
# The mechanism of harm is a back door. A gate that fails on an uncovered
# token pushes an author to add an artifact for that token, which is the
# forbidden inventory-to-artifact direction arriving by another route. The
# item then exists to satisfy the gate rather than to be worth doing, and a
# contrived item is exactly what this corpus was created to avoid: the
# reader's verdict on every prior attempt was that they were too rote.
#
# THREE THINGS, AND ONLY TWO OF THEM ARE GATEABLE. Whether an ITEM is honest
# is a property of the item, so check 1 gates. Whether an item's recorded
# verdict REPRODUCES is a property of the item, so check 2 gates. Whether the
# CORPUS covers the inventory is a property of a set that is still being
# written, and gating it would make the set's shape serve the gate. That is
# the whole distinction, and it is why this check has no failing arm at all
# rather than a disabled one.
#
# WHAT IT REPORTS. INVENTORY.md names every construct with a family and an
# expected frequency of high, medium or low. Each item's META.md declares the
# constructs it exercises. The gate counts items per construct, prints one
# COVERAGE line each, and prints every gap grouped by frequency with the high
# rows first. That printout is what aims the next authoring wave, which was
# always its real job.
#
# WHAT IT DOES *NOT* DO:
#   - IT DOES NOT FAIL. Not on an uncovered high construct, not on a
#     thin one, not on a frequency column holding a word it does not
#     recognize. All three print.
#   - IT DOES NOT CHECK WHETHER AN ITEM THAT DECLARES A CONSTRUCT ACTUALLY
#     EXERCISES IT. META.md is taken at its word.
#   - IT DOES NOT CHECK WHETHER THE INVENTORY IS COMPLETE. A construct nobody
#     listed is not a gap this gate can see.
#   - IT DOES NOT CHECK ORDERING, DEPENDENCY OR PREREQUISITES. Items are
#     NON-PROGRESSIVE by design (Frank, 2026-10-12). There is deliberately no
#     such check here, and wanting one is a signal of drift rather than a gap.
#
# ONE THING THE COUNTS FEED THAT *DOES* AFFECT THE EXIT CODE, and the
# distinction is worth being exact about. META.md's declaration is also what
# layer A of CHECK 1 scans for. An item that declares nothing, or declares a
# construct INVENTORY.md does not list, leaves layer A with no token to
# compare — so that is reported as UNCHECKED against check 1, which is rc 99.
# That is not a coverage count reddening the gate; it is the telegraph check
# honestly saying it could not run.
#
# ===========================================================================
# WHAT THIS CORPUS DELIBERATELY DOES NOT GET
#
# Private-first, not shippable (Frank, 2026-10-12). So there is NO novelty
# screen, NO comment gate and NO freeze digest in this gate:
# harness/screen.sh, harness/comment-gate.sh and FREEZE.sha256 are NOT wired
# here, on purpose. That apparatus is what makes authoring expensive, and
# expensive authoring is what stalled both prior attempts at ten items. If
# the corpus ever ships, it gets added then.
# ===========================================================================

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERDICT="${REPO_ROOT}/harness/verdict.sh"

# ---------------------------------------------------------------------------
# DISTINCTIVE — layer B's token set, and the exclusions that make it usable.
#
# A drill prompt is often allowed to SHOW A SPEC and ask for the missing
# piece. That prompt legitimately contains `/\`, `\in`, `\A`, `=>` and the
# rest of the shared vocabulary of the language, and so does almost any
# answer. Flagging those would fail every item of that shape, so the floor
# set holds only tokens that pick out WHICH CONSTRUCT the answer is.
#
# DISTINCTIVE: in the prompt of an item whose answer uses it, this is a
# partial give-away.
DISTINCTIVE=(
  '~>' '<>' '[]' ']_' 'WF_' 'SF_' 'ENABLED'
  'UNCHANGED' 'CHOOSE' 'SUBSET' 'UNION' 'EXCEPT' 'INSTANCE' 'RECURSIVE'
  '|->' ':>' '@@' 'LAMBDA'
  'Cardinality' 'Permutations' 'SelectSeq' 'TLCGet' 'Assert'
  '\X' '\o' '\cup' '\cap' '\subseteq' '\notin'
)
# EXCLUDED ON PURPOSE, and this is the list to read before widening the set:
#
#   /\  \/  \in  \A  \E  =>  <=>  ~  '  =  #  /=
#       the shared vocabulary. Present in any shown spec and in any answer.
#   LET IN IF THEN ELSE  TRUE FALSE  Nat Int Seq BOOLEAN
#   Len Append Head Tail SubSeq  DOMAIN  VARIABLE VARIABLES CONSTANT EXTENDS
#       structure and the standard modules. A prompt that shows a spec shows
#       these, and an answer that touches a sequence or a function uses them
#       without that being the point of the drill.
#   '   the prime. Excluded because it is an apostrophe in English prose and
#       a prompt is prose.
#
# Layer A still covers every one of these: if the inventory names `DOMAIN` as
# a construct and META.md declares it, the prompt may not show it. The
# exclusions weaken the FLOOR only, never the declared layer.

# LAYER_A_SYMBOLS — what construct_tokens scans an inventory cell for. WIDER
# than DISTINCTIVE on purpose, because layer A is not guessing which tokens
# matter: the author declared the construct, so its symbol is the subject of
# the answer. The prime is still out, since it is an apostrophe in prose and
# a prompt is prose.
LAYER_A_SYMBOLS=(
  '~>' '<>[]' '<>' '[][' '[]' ']_' 'WF_' 'SF_'
  # $'/\\' rather than '/\': both are the two bytes /\ , proven against a
  # running shell, but the single-quoted form raises SC1003 because \' reads
  # as an attempted quote escape.
  '|->' ':>' '@@' ':=' '||' $'/\\' '\/' '=>' '<=>' '<<' '>>' '..' '\X' '\o'
  '\A' '\E' '\AA' '\EE' '\in' '\notin' '\subseteq' '\cup' '\cap' '\div'
  '==' '/=' '#' '^' '%'
  'UNCHANGED' 'ENABLED' 'CHOOSE' 'SUBSET' 'UNION' 'EXCEPT' 'DOMAIN'
  'INSTANCE' 'RECURSIVE' 'EXTENDS' 'LOCAL' 'ASSUME' 'THEOREM' 'LAMBDA'
  'VARIABLE' 'CONSTANT' 'LET' 'BOOLEAN'
  'Cardinality' 'Permutations' 'SelectSeq' 'SubSeq' 'Append' 'Head' 'Tail'
  'Len' 'Seq' 'TLCGet' 'Assert'
)

INVENTORY=""
NO_TLC=0
TIMEOUT=60
QUIET=0
ROOT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --inventory) INVENTORY="${2:-}"; shift ;;
    --no-tlc)    NO_TLC=1 ;;
    --timeout)   TIMEOUT="${2:-60}"; shift ;;
    -q|--quiet)  QUIET=1 ;;
    -h|--help)
      awk 'NR > 1 && /^set -uo pipefail$/ { exit } NR > 1' "${BASH_SOURCE[0]}"
      exit 0
      ;;
    -*)
      echo "drill-gate.sh: unknown option '$1' (try --help)" >&2
      exit 2
      ;;
    *)
      if [ -n "$ROOT" ]; then
        echo "drill-gate.sh: more than one drill root given ('$ROOT', '$1')" >&2
        exit 2
      fi
      ROOT="$1"
      ;;
  esac
  shift
done

if [ -z "$ROOT" ]; then
  echo "drill-gate.sh: no drill root given (try --help)" >&2
  exit 2
fi
if [ ! -d "$ROOT" ]; then
  echo "drill-gate.sh: '$ROOT' is not a directory" >&2
  exit 2
fi
[ -n "$INVENTORY" ] || INVENTORY="${ROOT}/INVENTORY.md"

finding_n=0
unchecked_n=0
item_n=0
LAYERA_COVERED=0
LAYERA_NOTOK=0

# One scratch dir for the whole run. SYMFILE holds LAYER_A_SYMBOLS one per
# line so construct_tokens can match them all in a single grep.
SCRATCH="$(mktemp -d)"
# shellcheck disable=SC2317  # reached through the EXIT trap on the next line
gate_cleanup() { rm -rf "$SCRATCH"; }
trap gate_cleanup EXIT
SYMFILE="${SCRATCH}/layer-a-symbols"
printf '%s\n' "${LAYER_A_SYMBOLS[@]}" >"$SYMFILE"

say()       { [ "$QUIET" = "1" ] || printf '%s\n' "$1"; }
finding()   { printf 'FINDING   %-28s %-44s %s\n' "$1" "$2" "$3"; finding_n=$((finding_n + 1)); }
unchecked() { printf 'UNCHECKED %-28s %-44s %s\n' "$1" "$2" "$3"; unchecked_n=$((unchecked_n + 1)); }

# declared <kind> <where> <why>: a check this gate CATEGORICALLY cannot run,
# as distinct from one that could not run TODAY.
#
# The difference is the whole point and it decides the exit code. UNCHECKED
# means the instrument failed and somebody should fix it, so it escalates to
# rc 99, CHECK_DID_NOT_RUN. DECLARED means the claim is not of a kind this
# gate can see, the item says so and carries its own measurement, and no
# amount of fixing the gate will change that. It prints and does not escalate.
#
# Conflating the two is the defect bead tla-hl96 is about, arriving from the
# other side: an instrument that cannot tell a permanent fact from today's
# breakage either cries wolf forever or goes quiet about a real failure. The
# refutation-coverage gate drew the same line this morning, between a
# traces/NONE.md that declares and explains an absence and a directory nobody
# has filled yet.
declared_n=0
declared() { printf 'DECLARED  %-28s %-44s %s\n' "$1" "$2" "$3"; declared_n=$((declared_n + 1)); }

# ---------------------------------------------------------------------------
# normalize <text>: the form constructs are MATCHED in. Lowercased, backticks
# and surrounding punctuation stripped, whitespace collapsed. The RAW cell is
# kept separately, because that is where a token like `~>` survives.
# ---------------------------------------------------------------------------
normalize() {
  local s="$1"
  s="${s//\`/}"
  s="$(tr '[:upper:]' '[:lower:]' <<<"$s")"
  s="$(sed -e 's/^[[:space:],.;:*_-]*//' -e 's/[[:space:],.;:*_-]*$//' -e 's/[[:space:]][[:space:]]*/ /g' <<<"$s")"
  printf '%s' "$s"
}

# ---------------------------------------------------------------------------
# INVENTORY.md — TWO shapes are read, and the TAB shape is the real one.
#
# SHAPE 1, TAB-DELIMITED ROW LINES. This is what drill/INVENTORY.md actually
# ships, and its own "For the gate author" section specifies it: rows carry
# the literal first field `ROW` and are separated by single tabs, so prose in
# the file can never be read as data. Eight fields, in this order:
#
#   1 marker `ROW`   2 id K001-K105      3 family        4 construct
#   5 source f:line  6 weight hi/med/low 7 basis         8 items
#
# Field 8 is the coverage field and it is empty on every row today. This gate
# READS it and unions whatever it names into the per-construct count, so the
# documented contract is honoured. It does NOT WRITE it: drill/ belongs to the
# authors and the sibling that owns the inventory, and a report-only check has
# no business editing the file it reports on.
#
# SHAPE 2, A MARKDOWN PIPE TABLE. Read as a fallback, with the header located
# by CONTENT rather than by position — the columns are found by looking for
# `construct`, `family` and `freq`-or-`weight` in the header cells, so a table
# that reorders them still parses.
#
# Neither shape parsing means check 3 reports UNCHECKED rather than quietly
# counting nothing.
#
# A NOTE ON THE CONSTRUCT CELL, because it decides how much CHECK 1's layer A
# can do. The real inventory's field 4 is PROSE taken verbatim from a cheat
# sheet: "Operator definition", "EXTENDS (module import)", "IF-THEN-ELSE".
# Some of those carry a symbol a prompt could leak and most do not, which is
# why construct_tokens below works hard to find one and why a construct with
# none is reported as out of layer A's reach rather than as a failure.
# ---------------------------------------------------------------------------
declare -a INV_RAW=() INV_NORM=() INV_FAMILY=() INV_FREQ=() INV_ITEMS=()
INV_OK=0
INV_SHAPE=""

# NOTE ON THE DELIMITER, because the obvious version of this is broken.
#
# `IFS=$'\t' read -r a b c d e` DOES NOT preserve an empty field. Tab is an
# IFS *whitespace* character, so a run of tabs collapses into one delimiter
# and the empty cell simply disappears, shifting every later field left.
# Field 8 of the real inventory is empty on every row today, which is exactly
# the case that triggers it: the sentinel slid into `items` and every one of
# the 105 constructs reported a count of 1. A fully-covered inventory with
# zero items in the tree, which is the false-PASS direction on the audit.
#
# So awk re-emits the record delimited by ASCII US (0x1f), which is not a
# whitespace character, and empty fields survive. harness/test-drill.sh part
# 1g is what caught this and is what keeps it fixed.
parse_inventory_tab() {
  local rec id fam raw weight items sentinel norm
  local n=0
  while IFS=$'\037' read -r id fam raw weight items sentinel; do
    [ "$sentinel" = "END" ] || continue
    norm="$(normalize "$raw")"
    [ -n "$norm" ] || continue
    case "$(normalize "$weight")" in
      high*) weight=high ;;
      med*)  weight=medium ;;
      low*)  weight=low ;;
      *)     weight="unrecognized:$(normalize "$weight")" ;;
    esac
    INV_RAW+=("$raw")
    INV_NORM+=("$norm")
    INV_FAMILY+=("${fam:-?}")
    INV_FREQ+=("$weight")
    # Field 8 is comma-separated; normalise to spaces for the union below.
    INV_ITEMS+=("$(tr ',' ' ' <<<"${items:-}")")
    n=$((n + 1))
    # id is read but not otherwise used; the construct text is the key.
    rec="$id"
  done < <(awk -F'\t' -v U=$'\037' \
    '$1 == "ROW" { printf "%s%s%s%s%s%s%s%s%s%sEND\n", $2, U, $3, U, $4, U, $6, U, $8, U }' \
    "$INVENTORY")
  [ -n "${rec:-}" ] || return 1
  [ "$n" -gt 0 ]
}

parse_inventory_pipe() {
  local c_construct=-1 c_family=-1 c_freq=-1
  local line cells i cell ncells
  local in_table=0

  while IFS= read -r line; do
    case "$line" in
      \|*) : ;;
      *) continue ;;
    esac
    local body="${line#\|}"
    body="${body%\|}"
    IFS='|' read -r -a cells <<<"$body"
    ncells=${#cells[@]}
    [ "$ncells" -ge 3 ] || continue

    if [ "$in_table" = "0" ]; then
      for ((i = 0; i < ncells; i++)); do
        cell="$(normalize "${cells[$i]}")"
        case "$cell" in
          *construct*)        c_construct=$i ;;
          *family*)           c_family=$i ;;
          *freq*|*weight*)    c_freq=$i ;;
        esac
      done
      if [ "$c_construct" -ge 0 ] && [ "$c_family" -ge 0 ] && [ "$c_freq" -ge 0 ]; then
        in_table=1
      fi
      continue
    fi

    # Skip the --- separator row.
    local sep="${cells[0]//-/}"
    sep="${sep// /}"
    sep="${sep//:/}"
    [ -n "$sep" ] || continue

    local raw="${cells[$c_construct]}"
    local norm; norm="$(normalize "$raw")"
    [ -n "$norm" ] || continue
    local fam; fam="$(normalize "${cells[$c_family]}")"
    local frq; frq="$(normalize "${cells[$c_freq]}")"
    case "$frq" in
      high*)   frq=high ;;
      med*)    frq=medium ;;
      low*)    frq=low ;;
      *)       frq="unrecognized:${frq}" ;;
    esac

    INV_RAW+=("$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<<"$raw")")
    INV_NORM+=("$norm")
    INV_FAMILY+=("${fam:-?}")
    INV_FREQ+=("$frq")
    INV_ITEMS+=("")
  done <"$INVENTORY"

  [ "${#INV_NORM[@]}" -gt 0 ]
}

if [ -f "$INVENTORY" ]; then
  if grep -qE '^ROW'$'\t' "$INVENTORY"; then
    if parse_inventory_tab; then INV_OK=1; INV_SHAPE="tab-delimited ROW lines"; fi
  elif parse_inventory_pipe; then
    INV_OK=1; INV_SHAPE="markdown pipe table"
  fi
fi

# ---------------------------------------------------------------------------
# construct_tokens <raw-cell>: the literal strings a prompt may not show for
# this construct, one per line. Derived four ways, in order:
#
#   1. a backticked span in the cell          `~>`          -> ~>
#   2. a parenthesised symbol-ish span        leads-to (~>) -> ~>
#   3. the cell itself, when it looks like a token (pure symbols, ALL_CAPS,
#      or a trailing-underscore operator like WF_)
#   4. an alias table, for a cell written as prose
#
# A construct that yields NO token is reported UNCHECKED rather than passed
# over, because layer A silently covering nothing is the false-PASS
# direction. The remedy is one backtick pair in the inventory cell.
# ---------------------------------------------------------------------------
construct_tokens() {
  local raw="$1"
  local got=0 t

  # 1. backticked spans
  local bt
  # The pattern needs two LITERAL backticks and must not expand, which is
  # what single quotes are doing here; shellcheck reads the pair as a
  # command substitution it is warning me about.
  # shellcheck disable=SC2016
  bt="$(grep -oE '`[^`]+`' <<<"$raw" || true)"
  if [ -n "$bt" ]; then
    while IFS= read -r t; do
      t="${t//\`/}"
      [ -n "$t" ] || continue
      printf '%s\n' "$t"
      got=1
    done <<<"$bt"
  fi

  # 2. parenthesised symbol-ish spans
  local par
  par="$(grep -oE '\([^)]+\)' <<<"$raw" || true)"
  if [ -n "$par" ]; then
    while IFS= read -r t; do
      t="${t#(}"; t="${t%)}"
      [ -n "$t" ] || continue
      if grep -qE '^[^A-Za-z0-9 ]+$|^[A-Z][A-Za-z]*_$|^[A-Z_]{2,}$' <<<"$t"; then
        printf '%s\n' "$t"
        got=1
      fi
    done <<<"$par"
  fi

  # 3. the bare cell, when it is itself a token
  local bare
  bare="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' <<<"$raw")"
  if grep -qE '^[^A-Za-z0-9 ]+$|^[A-Z][A-Za-z]*_$|^[A-Z_]{2,}$' <<<"$bare"; then
    printf '%s\n' "$bare"
    got=1
  fi

  # 3b. ALL-CAPS keywords sitting INSIDE a prose cell. This is what reaches
  # the real inventory, whose field 4 is prose from a cheat sheet:
  # "EXTENDS (module import)" yields EXTENDS, "IF-THEN-ELSE" yields IF, THEN
  # and ELSE. Two letters minimum, so an initial does not become a token.
  local caps
  caps="$(grep -oE '[A-Z][A-Z_]+' <<<"$raw" || true)"
  if [ -n "$caps" ]; then
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      printf '%s\n' "$t"
      got=1
    done <<<"$caps"
  fi

  # 3c. any TLA+ symbol or operator NAME appearing in the cell, in ONE grep
  # pass over a pattern file built once at startup. The obvious loop forks a
  # grep per symbol, which is 70 forks per construct and 7,350 for the real
  # 105-row inventory. That measured 25 s against 7 s for the whole suite.
  #
  # This scans LAYER_A_SYMBOLS, which is WIDER than DISTINCTIVE and includes
  # the shared vocabulary the floor excludes. The asymmetry is deliberate.
  # The floor has to guess which tokens matter, so it must not flag `\in` in
  # a prompt that merely shows a spec. Layer A is not guessing: the author
  # DECLARED this construct, so its symbol is the subject of the answer, and
  # a prompt showing it gives that away. The real inventory has rows named
  # `\A (universal quantifier, "forall")` and `:= assignment`, and layer A
  # would reach neither from DISTINCTIVE alone.
  local sym
  sym="$(grep -oF -f "$SYMFILE" <<<"$raw" || true)"
  if [ -n "$sym" ]; then
    printf '%s\n' "$sym"
    got=1
  fi

  [ "$got" = "0" ] || return 0

  # 4. the alias table. Modest on purpose: a prose cell that is not here is
  #    reported unchecked, which is a louder and more useful signal than a
  #    guess.
  local n; n="$(normalize "$raw")"
  case "$n" in
    *"eventually always"*)                     printf '%s\n' '<>[]' ;;
    *"leads to"*|*"leads-to"*|*"leadsto"*)     printf '%s\n' '~>' ;;
    *"weak fairness"*|*"weakly fair"*)         printf '%s\n' 'WF_' ;;
    *"strong fairness"*|*"strongly fair"*)     printf '%s\n' 'SF_' ;;
    *eventually*)                              printf '%s\n' '<>' ;;
    *"always"*|*"box operator"*)               printf '%s\n' '[]' ;;
    *enabled*)                                 printf '%s\n' 'ENABLED' ;;
    *unchanged*)                               printf '%s\n' 'UNCHANGED' ;;
    *choose*)                                  printf '%s\n' 'CHOOSE' ;;
    *except*|*"function update"*)              printf '%s\n' 'EXCEPT' ;;
    *subset*|*powerset*)                       printf '%s\n' 'SUBSET' ;;
    *union*)                                   printf '%s\n' 'UNION' ;;
    *instance*|*"refinement mapping"*)         printf '%s\n' 'INSTANCE' ;;
    *recursive*)                               printf '%s\n' 'RECURSIVE' ;;
    *cardinality*)                             printf '%s\n' 'Cardinality' ;;
    *"stuttering subscript"*|*subscript*)      printf '%s\n' ']_' ;;
    *) : ;;
  esac
}

# ---------------------------------------------------------------------------
# answer_code <answer.md>: the contents of every fenced code block. The
# telegraph floor reads THIS and not the whole file, because ANSWER.md's PROSE
# naturally names the operator it is explaining — "the answer is a leads-to,
# `~>`" is the explanation doing its job, and matching it would flag every
# well-written answer in the corpus.
# ---------------------------------------------------------------------------
answer_code() {
  awk '
    /^[[:space:]]*```/ { inblk = !inblk; next }
    inblk { print }
  ' "$1"
}

# ---------------------------------------------------------------------------
# caveat_text <answer.md>: the why-not-in-prompt field, tolerant about how it
# is written. Accepts a `key:` line or a markdown heading, in any case, with
# or without hyphens and with or without "the".
# ---------------------------------------------------------------------------
caveat_text() {
  awk '
    function iskey(s) {
      s = tolower(s)
      gsub(/[^a-z]/, "", s)
      return (index(s, "whynotinprompt") > 0 || index(s, "whyitisnotintheprompt") > 0)
    }
    {
      if (iskey($0)) { grabbing = 1; sub(/^[^:]*:/, ""); print; next }
      if (grabbing) {
        if ($0 ~ /^[[:space:]]*#/) { grabbing = 0; next }
        if ($0 ~ /^[[:space:]]*[A-Za-z][A-Za-z -]*:[[:space:]]/ && !iskey($0)) { grabbing = 0; next }
        print
      }
    }
  ' "$1"
}

# ---------------------------------------------------------------------------
# waivers <answer.md>: lines of the form
#     telegraph-waiver: <token> -- <reason>
# A waiver suppresses exactly one token for exactly one item. Every waiver is
# echoed in the output, so a corpus cannot quietly fill up with them; a waiver
# with no reason is itself a finding. This mirrors the per-site
# `# shellcheck disable` with its reason above it that scripts/lint requires.
# ---------------------------------------------------------------------------
waivers() {
  grep -iE '^[[:space:]]*[*_ ]*telegraph-waiver[*_ ]*:' "$1" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# prompt_shows_code <prompt.md>: does the prompt carry code or a TLC trace?
#
# The trace half is the finding from the trial. A prompt that shows a trace is
# showing output of the model checker, and a LASSO trace shows exactly where
# an action was enabled and skipped, which is half the diagnosis. So it earns
# the same token scan as a prompt carrying a spec.
# ---------------------------------------------------------------------------
prompt_shows_code() {
  grep -qE '^[[:space:]]*```' "$1" && return 0
  prompt_shows_trace "$1"
}

prompt_shows_trace() {
  grep -qE '^[[:space:]]*State [0-9]+:|Back to state|<Initial predicate>|Behavior up to this point|Error: Deadlock|Stuttering' "$1"
}

prompt_shows_lasso() {
  grep -qE 'Back to state' "$1"
}

# ---------------------------------------------------------------------------
# meta_constructs <meta.md>: the constructs the item declares, one per line.
# Accepts a `Constructs:` line (comma separated) and/or a `## Constructs`
# section of bullets.
# ---------------------------------------------------------------------------
meta_constructs() {
  awk '
    function iskey(s) {
      s = tolower(s); gsub(/[^a-z]/, "", s)
      return (index(s, "construct") > 0)
    }
    /^[[:space:]]*#/ {
      insec = (iskey($0) ? 1 : 0); next
    }
    iskey($0) && $0 ~ /:/ && $0 !~ /^[[:space:]]*[-*]/ {
      sub(/^[^:]*:/, "")
      n = split($0, a, ",")
      for (i = 1; i <= n; i++) print a[i]
      next
    }
    # A BULLET IS ONE CONSTRUCT and is NOT comma-split. The real inventory
    # has rows whose names contain a comma, such as
    #   \A (universal quantifier, "forall")
    # and splitting those produces a fragment that matches the wrong row plus
    # a second fragment that matches nothing. Only the inline `Constructs:`
    # key form above is comma-separated, because there the comma is a
    # separator the author chose.
    #
    # NOTE no apostrophes in this comment. The whole awk program sits in
    # single quotes, so one would close the quote and break the script.
    insec && /^[[:space:]]*[-*][[:space:]]/ {
      sub(/^[[:space:]]*[-*][[:space:]]*/, "")
      print
    }
  ' "$1"
}

# ---------------------------------------------------------------------------
# rc_claim <answer.md> <module-basename>: the rc ANSWER.md records for a
# module, or empty.
#
# TOLERANT ON PURPOSE. Six authors are writing to a format that says
# "measured rc in ANSWER.md" and does not fix a line shape, so this reads a
# table cell, `rc=12`, `rc: 12` and `exit 12` alike. What it will NOT do is
# guess: a module with no recoverable rc is a FINDING, never a pass.
# ---------------------------------------------------------------------------
rc_claim() {
  local ans="$1" mod="$2" lines hits rc=""
  # WORD-BOUNDARY, not substring. A plain `grep -F` on the basename matches
  # any English word the name is a prefix of: a module called Commit.tla
  # picked up the prose word "Committed" and the digit from that sentence
  # became a phantom rc 1 claim. Found by the tla-pmm2 temporal author, which
  # worked around it by renaming its module. A base name that is a prefix of
  # an English word would have bitten every later author.
  lines="$(grep -E -- "(^|[^A-Za-z0-9_])${mod}([^A-Za-z0-9_]|\$)" "$ans" 2>/dev/null || true)"
  [ -n "$lines" ] || return 0

  hits="$(grep -oiE 'rc[^0-9A-Za-z]{0,3}[0-9]{1,3}' <<<"$lines" || true)"
  if [ -z "$hits" ]; then
    hits="$(grep -oiE 'exit[^0-9A-Za-z]{0,3}[0-9]{1,3}' <<<"$lines" || true)"
  fi
  if [ -n "$hits" ]; then
    rc="$(grep -oE '[0-9]{1,3}' <<<"$hits" | tail -1 || true)"
  else
    # A bare table cell of digits, e.g. `| Wrong.tla | Wrong.cfg | 12 |`
    hits="$(grep -oE '\|[[:space:]]*[0-9]{1,3}[[:space:]]*\|' <<<"$lines" || true)"
    [ -n "$hits" ] && rc="$(grep -oE '[0-9]{1,3}' <<<"$hits" | tail -1 || true)"
  fi
  printf '%s' "$rc"
}

# verdict.sh's table. A recorded rc outside it is a mis-transcription.
rc_in_table() {
  case "$1" in
    0|10|11|12|13|14|75|76|77|99|124|150|151|255) return 0 ;;
    *) return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# Per-construct state, parallel to the INV_* arrays.
#
# INV_TOKENS is computed ONCE per construct rather than once per
# (item, construct) pair. With 105 real rows and dozens of items that is the
# difference between a few hundred forks and a few thousand.
#
# INV_SEEN holds the item ids already counted for a construct, seeded from
# the inventory's own field 8, so the count is a count of DISTINCT items
# whichever source named them.
# ---------------------------------------------------------------------------
declare -a INV_COUNT=() INV_TOKENS=() INV_SEEN=()
for ((_i = 0; _i < ${#INV_NORM[@]}; _i++)); do
  INV_TOKENS+=("$(construct_tokens "${INV_RAW[$_i]}")")
  _seed="$(tr -s ' ' <<<"${INV_ITEMS[$_i]}" | sed -e 's/^ //' -e 's/ $//')"
  INV_SEEN+=("$_seed")
  if [ -z "$_seed" ]; then
    INV_COUNT+=(0)
  else
    INV_COUNT+=("$(wc -w <<<"$_seed")")
  fi
done
unset _i _seed

# inv_index <normalized-construct> -> echoes index, or fails.
#
# Exact match first. Then CONTAINMENT, in both directions, because the real
# inventory's construct names are prose from a cheat sheet and an author
# typing "operator definitions" for the row "Operator definition" has not
# made a mistake worth a finding. A containment hit is reported as such in
# the run's MATCH lines, so the looser match is visible rather than silent.
# It echoes "<index> <mode>" rather than setting a global. A caller reads it
# through `$( )`, which is a SUBSHELL, so a global assigned in here would
# never reach the caller — the first version did that and reported all 105
# real constructs as containment matches when every one of them was exact.
inv_index() {
  local want="$1" i
  for ((i = 0; i < ${#INV_NORM[@]}; i++)); do
    if [ "${INV_NORM[$i]}" = "$want" ]; then
      printf '%s exact' "$i"
      return 0
    fi
  done
  for ((i = 0; i < ${#INV_NORM[@]}; i++)); do
    case "${INV_NORM[$i]}" in
      *"$want"*) printf '%s contains' "$i"; return 0 ;;
    esac
    case "$want" in
      *"${INV_NORM[$i]}"*) printf '%s contains' "$i"; return 0 ;;
    esac
  done
  return 1
}

# ===========================================================================
# THE SWEEP
# ===========================================================================
echo "drill-gate.sh: root=${ROOT} inventory=${INVENTORY}$([ "$NO_TLC" = "1" ] && printf ' (--no-tlc)')"
echo

if [ "$INV_OK" = "1" ]; then
  say "inventory: ${#INV_NORM[@]} construct(s) parsed from ${INVENTORY} (${INV_SHAPE})"
else
  unchecked "coverage" "$INVENTORY" "no parseable construct table; check 3 cannot run"
  cat <<'SHAPE'
          The shape expected, a markdown table with a locatable header:

            | construct | family | expected frequency |
            |---|---|---|
            | `~>` leads-to | liveness | high |

          Column order is not assumed. The header is found by looking for
          `construct`, `family` and `freq` in its cells.
SHAPE
fi

# Items live at <root>/<family>/<NN>-<slug>/.
#
# THE HIDDEN-DIR PREDICATE IS ANCHORED AT $ROOT ON PURPOSE. The obvious
# `-not -path '*/.*'` matches the ROOT PATH ITSELF whenever any ancestor
# directory starts with a dot, and every dispatched worker in this project
# runs under .claude/worktrees/agent-*. So that form found ZERO items on the
# real tree while passing over fixtures in /tmp, which is a false PASS on the
# whole sweep: an empty item list reports "nothing to guarantee" rather than
# checking anything. Anchoring at $ROOT excludes a hidden family or item and
# nothing else.
declare -a ITEMS=()
while IFS= read -r d; do
  [ -n "$d" ] || continue
  ITEMS+=("$d")
done < <(find "$ROOT" -mindepth 2 -maxdepth 2 -type d ! -name '.*' ! -path "${ROOT}/.*" | sort)

if [ "${#ITEMS[@]}" -eq 0 ]; then
  unchecked "corpus" "$ROOT" "no items found at <root>/<family>/<NN>-<slug>/; nothing to guarantee"
fi

for item in "${ITEMS[@]+"${ITEMS[@]}"}"; do
  rel="${item#"$ROOT"/}"
  base="$(basename "$item")"
  item_n=$((item_n + 1))

  # --- shape -------------------------------------------------------------
  case "$base" in
    [0-9][0-9]-*) : ;;
    *) finding "ITEM-BAD-NAME" "$rel" "directory is not <NN>-<slug>; an item the gate cannot address is unguaranteed" ;;
  esac

  prompt="${item}/PROMPT.md"
  answer="${item}/ANSWER.md"
  meta="${item}/META.md"
  verify="${item}/verify"

  missing=0
  for f in PROMPT.md ANSWER.md META.md; do
    if [ ! -f "${item}/${f}" ]; then
      finding "ITEM-MISSING-FILE" "$rel" "no ${f}"
      missing=1
    fi
  done
  if [ ! -d "$verify" ]; then
    finding "ITEM-MISSING-FILE" "$rel" "no verify/ directory"
    missing=1
  fi
  [ "$missing" = "0" ] || continue

  # =======================================================================
  # CHECK 1 — TELEGRAPH
  # =======================================================================

  # Waivers first, so layers A and B can honour them. Echoed unconditionally.
  declare -a WAIVED=()
  wv="$(waivers "$answer")"
  if [ -n "$wv" ]; then
    while IFS= read -r wline; do
      [ -n "$wline" ] || continue
      wbody="${wline#*:}"
      wtok="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*\(--\|—\).*$//' -e 's/[[:space:]]*$//' <<<"$wbody")"
      wreason="$(sed -n 's/.*\(--\|—\)[[:space:]]*//p' <<<"$wbody")"
      if [ -z "$wtok" ]; then
        finding "TELEGRAPH-WAIVER-EMPTY" "$rel" "telegraph-waiver names no token"
        continue
      fi
      if [ "${#wreason}" -lt 12 ]; then
        finding "TELEGRAPH-WAIVER-NO-REASON" "$rel" "waiver for '${wtok}' carries no reason; a waiver without one is an exemption"
        continue
      fi
      WAIVED+=("$wtok")
      printf 'WAIVER    %-44s %-10s %s\n' "$rel" "$wtok" "$wreason"
    done <<<"$wv"
  fi

  is_waived() {
    local t="$1" w
    for w in "${WAIVED[@]+"${WAIVED[@]}"}"; do
      [ "$w" = "$t" ] && return 0
    done
    return 1
  }

  # --- the why-not-in-prompt field ---------------------------------------
  cav="$(caveat_text "$answer")"
  cav_squeezed="$(tr -d '[:space:]' <<<"$cav")"
  if [ "${#cav_squeezed}" -lt 20 ]; then
    finding "TELEGRAPH-NO-CAVEAT" "$rel" \
      "ANSWER.md has no why-not-in-prompt field with real content (${#cav_squeezed} non-space chars, 20 required)"
  fi

  # --- the trace clause --------------------------------------------------
  if prompt_shows_trace "$prompt"; then
    kind="trace"
    prompt_shows_lasso "$prompt" && kind="lasso trace"
    if ! grep -qi 'trace' <<<"$cav"; then
      finding "TELEGRAPH-TRACE-UNCAVEATED" "$rel" \
        "PROMPT.md carries a ${kind} and why-not-in-prompt never mentions it; a lasso trace is itself a partial answer"
    fi
  fi

  # --- layer A: the declared constructs ----------------------------------
  declare -a DECLARED=()
  mc="$(meta_constructs "$meta")"
  if [ -n "$mc" ]; then
    while IFS= read -r c; do
      cn="$(normalize "$c")"
      [ -n "$cn" ] || continue
      DECLARED+=("$cn")
    done <<<"$mc"
  fi

  # NOT a coverage failure. See the note at the end of CHECK 3's header: a
  # missing declaration leaves layer A with no token to compare, so the
  # TELEGRAPH check reports that it could not run. The corpus-level count is
  # never what reddens this gate.
  if [ "${#DECLARED[@]}" -eq 0 ]; then
    unchecked "telegraph-declared" "$rel" \
      "META.md declares no constructs; layer A has no token to compare against"
  fi

  for cn in "${DECLARED[@]+"${DECLARED[@]}"}"; do
    if [ "$INV_OK" != "1" ]; then
      continue
    fi
    if ! hit="$(inv_index "$cn")"; then
      unchecked "telegraph-declared" "$rel" \
        "META.md declares '${cn}', which INVENTORY.md does not list, so no token resolves"
      continue
    fi
    idx="${hit% *}"
    mode="${hit##* }"
    [ "$mode" = "exact" ] || \
      printf 'MATCH     %-44s %s\n' "$rel" "declared '${cn}' matched row '${INV_RAW[$idx]}' by containment, not exactly"

    # Count DISTINCT items. INV_SEEN is seeded from the inventory's field 8,
    # so an item already named there is not counted twice.
    case " ${INV_SEEN[$idx]} " in
      *" ${base} "*) : ;;
      *)
        INV_SEEN[idx]="${INV_SEEN[$idx]} ${base}"
        INV_COUNT[idx]=$(( INV_COUNT[idx] + 1 ))
        ;;
    esac

    toks="${INV_TOKENS[$idx]}"
    if [ -z "$toks" ]; then
      # NOT an unchecked check. A construct whose inventory cell carries no
      # symbol — "Operator definition", "Integers" — has no token a prompt
      # could leak, so layer A does not apply to it rather than failing to
      # run. Layer B still covers the item. The run prints how many
      # constructs sit outside layer A's reach, so the boundary is visible
      # instead of silent.
      LAYERA_NOTOK=$(( LAYERA_NOTOK + 1 ))
      continue
    fi
    LAYERA_COVERED=$(( LAYERA_COVERED + 1 ))
    while IFS= read -r tok; do
      [ -n "$tok" ] || continue
      is_waived "$tok" && continue
      if grep -qF -- "$tok" "$prompt"; then
        finding "TELEGRAPH-DECLARED" "$rel" \
          "PROMPT.md shows '${tok}', the token of the declared construct '${INV_RAW[$idx]}'"
      fi
    done <<<"$toks"
  done

  # --- layer B: the floor over the answer's own code ---------------------
  code="$(answer_code "$answer")"
  if [ -z "$(tr -d '[:space:]' <<<"$code")" ]; then
    unchecked "telegraph-floor" "$rel" \
      "ANSWER.md has no fenced code block; the floor has no answer tokens to compare against"
  elif prompt_shows_code "$prompt"; then
    for tok in "${DISTINCTIVE[@]}"; do
      is_waived "$tok" && continue
      grep -qF -- "$tok" <<<"$code" || continue
      if grep -qF -- "$tok" "$prompt"; then
        finding "TELEGRAPH-FLOOR" "$rel" \
          "ANSWER.md's code uses '${tok}' and PROMPT.md shows it too"
      fi
    done
  fi

  # =======================================================================
  # CHECK 2 — VERIFICATION
  # =======================================================================
  declare -a MODS=()
  while IFS= read -r m; do
    [ -n "$m" ] || continue
    MODS+=("$m")
  done < <(find "$verify" -maxdepth 1 -type f -name '*.tla' | sort)

  if [ "${#MODS[@]}" -eq 0 ]; then
    finding "VERIFY-NO-MODULES" "$rel" "verify/ holds no .tla module"
  fi

  saw_pass=0
  saw_refutation=0
  checkable=0

  for mod in "${MODS[@]+"${MODS[@]}"}"; do
    modbase="$(basename "$mod")"
    modstem="${modbase%.tla}"
    cfg="${verify}/${modstem}.cfg"
    want="$(rc_claim "$answer" "$modstem")"

    if [ ! -f "$cfg" ]; then
      # Exactly one .cfg in verify/ is taken as this module's config only
      # when there is also exactly one module; otherwise guessing would
      # silently check the wrong pair.
      ncfg="$(find "$verify" -maxdepth 1 -type f -name '*.cfg' | wc -l)"
      if [ "$ncfg" = "1" ] && [ "${#MODS[@]}" = "1" ]; then
        cfg="$(find "$verify" -maxdepth 1 -type f -name '*.cfg')"
      elif [ -z "$want" ]; then
        say "  SKIP  ${rel}  ${modbase}: no .cfg and no recorded rc — read as an EXTENDS helper"
        continue
      else
        finding "VERIFY-NO-CFG" "$rel" "${modbase} records rc ${want} but has no ${modstem}.cfg"
        continue
      fi
    fi

    if [ -z "$want" ]; then
      finding "VERIFY-NO-RC" "$rel" \
        "${modbase} has a .cfg but ANSWER.md records no rc for it; an unrecorded rc is unverifiable"
      continue
    fi
    if ! rc_in_table "$want"; then
      finding "VERIFY-RC-NOT-IN-TABLE" "$rel" \
        "${modbase} records rc ${want}, which is not a row of verdict.sh's table (likely a shell exit mis-transcribed)"
      continue
    fi

    checkable=$((checkable + 1))
    [ "$want" = "0" ] && saw_pass=1
    [ "$want" = "0" ] || saw_refutation=1

    if [ "$NO_TLC" = "1" ]; then
      unchecked "verify-rc" "$rel" "${modbase}: --no-tlc, recorded rc ${want} not reproduced"
      continue
    fi

    # TLC's deadlock checking is an AND across the .cfg's CHECK_DEADLOCK
    # keyword and verdict.sh's -d flag, and verdict.sh defaults -d OFF
    # (harness/verdict.sh:25, :189-195). So an item whose cfg says
    # CHECK_DEADLOCK TRUE and whose recorded rc is 11 cannot reproduce here
    # unless the gate asks for the check too: verdict.sh refuses the
    # disagreement at rc 99, CHECK_DID_NOT_RUN.
    #
    # That refusal is correct and it is how this bug was found, within an hour
    # of the gate landing: four control-state items recorded rc 11 and the
    # gate reported VERIFY-RC-MISMATCH ... TLC returned 99 rather than a
    # silent 0. Pass -d when the cfg asks for it, and never strip the keyword
    # from an item to make this green -- the keyword is the item's own
    # statement that its terminal state is the subject. Bead tla-eafx reserved
    # rc 99 for exactly this, and tla-pmm2's control-state author kept its
    # keywords on purpose.
    deadlock_args=()
    if grep -qE '^[[:space:]]*CHECK_DEADLOCK[[:space:]]+TRUE' "$cfg"; then
      deadlock_args=(-d)
    fi

    got=0
    set +e
    "$VERDICT" --timeout "$TIMEOUT" -q "${deadlock_args[@]+"${deadlock_args[@]}"}" -c "$cfg" "$mod" >/dev/null 2>&1
    got=$?
    set -e

    # A RECORDED rc 99 IS NOT A MODULE PROPERTY, so this gate cannot verify it.
    # 99 is CHECK_DID_NOT_RUN (bead tla-hl96): it means the caller asked for a
    # check its configuration did not permit, so it is a fact about an
    # INVOCATION rather than about a module. This gate runs every module under
    # ONE convention, and since the deadlock fix above it always agrees with
    # the .cfg, so it can never produce the disagreement a 99 reports.
    #
    # state-space/04-clean-run-colleague-deadlock is the item that needs this:
    # its six-cell table demonstrates the deadlock AND across the keyword and
    # the flag, and the 99 cell is the one where caller and .cfg disagree.
    # The item is right and the gate is right, so the gate says it cannot see
    # this one rather than calling a correct item a mismatch. The item carries
    # its own measurement for that cell.
    if [ "$want" = "99" ]; then
      declared "verify-rc" "$rel" \
        "${modbase} records rc 99, CHECK_DID_NOT_RUN, which is a claim about an invocation rather than about the module. This gate uses one convention and cannot reproduce a refusal it never triggers."
      continue
    fi

    if [ "$got" != "$want" ]; then
      finding "VERIFY-RC-MISMATCH" "$rel" \
        "${modbase}: ANSWER.md records rc ${want}, TLC returned ${got}"
    else
      say "  OK    ${rel}  ${modbase} rc=${got}"
    fi
  done

  if [ "$checkable" -gt 0 ]; then
    [ "$saw_pass" = "1" ] || finding "VERIFY-NO-PASS" "$rel" \
      "no verify module records rc 0; the stated answer was never shown to check"
    [ "$saw_refutation" = "1" ] || finding "VERIFY-NO-REFUTATION" "$rel" \
      "every recorded rc is 0; no stated wrong answer was shown to fail"
  elif [ "${#MODS[@]}" -gt 0 ]; then
    finding "VERIFY-NOTHING-CHECKABLE" "$rel" \
      "verify/ holds ${#MODS[@]} module(s) and not one is checkable (a .cfg plus a recorded rc)"
  fi

  unset WAIVED DECLARED MODS
done

# ===========================================================================
# CHECK 3 — the corpus-level AUDIT. It prints. It never fails.
#
# There is no `finding` call anywhere in this block, and that is the point. If
# you are here to add one, read CHECK 3 in the header first: a gate that fails
# on an uncovered token pushes an author to write an item FOR the token, which
# is the inventory-to-artifact direction V2-PLAN.md:459 forbids, arriving
# through the back door. The item would then exist to satisfy the gate rather
# than to be worth doing.
# ===========================================================================
if [ "$INV_OK" = "1" ]; then
  echo
  echo "== check 3: construct coverage over ${item_n} item(s) — AUDIT ONLY, never a failure =="
  gaps_high=0
  gap_block=""
  thin_block=""
  badfreq_block=""
  for ((i = 0; i < ${#INV_NORM[@]}; i++)); do
    printf 'COVERAGE  %5d  %-12s %-20s %s\n' \
      "${INV_COUNT[$i]}" "${INV_FREQ[$i]}" "${INV_FAMILY[$i]}" "${INV_RAW[$i]}"
    case "${INV_FREQ[$i]}" in
      unrecognized:*)
        badfreq_block="${badfreq_block}
  - ${INV_RAW[$i]}  has frequency '${INV_FREQ[$i]#unrecognized:}', not high/medium/low"
        ;;
    esac
    if [ "${INV_COUNT[$i]}" -eq 0 ]; then
      gap_block="${gap_block}
  - ${INV_FREQ[$i]}  ${INV_FAMILY[$i]}  ${INV_RAW[$i]}"
      [ "${INV_FREQ[$i]}" = "high" ] && gaps_high=$((gaps_high + 1))
    elif [ "${INV_FREQ[$i]}" = "high" ] && [ "${INV_COUNT[$i]}" -eq 1 ]; then
      thin_block="${thin_block}
  - ${INV_FAMILY[$i]}  ${INV_RAW[$i]}  (1 item)"
    fi
  done

  echo
  echo "LAYER A REACH: ${LAYERA_COVERED} declared-construct scan(s) had a token to look for,"
  echo "  ${LAYERA_NOTOK} did not. A construct whose inventory cell carries no symbol —"
  echo "  \"Operator definition\", \"Integers\" — has no token a prompt could leak, so layer A"
  echo "  does not apply and the floor over the answer's own code is the only telegraph"
  echo "  layer covering those items. Backticking a symbol in the inventory cell is what"
  echo "  brings a row into layer A's reach."

  if [ -n "$gap_block" ]; then
    echo
    echo "CONSTRUCT GAPS — constructs with no item, ${gaps_high} of them expected-high.$gap_block"
    echo
    echo "  Every row's count is on the COVERAGE lines above, including the covered ones."
    echo "  This block is the aim for the next authoring wave, and that is ALL it is."
    echo "  It does not fail the gate at any frequency. Frank's requirement is"
    echo "  corpus-level — 'sooner or later everything gets hit and the common ones get"
    echo "  hit frequently' — so read it as a pointer to where the next item would be"
    echo "  worth writing, never as a list of items somebody now owes. An item written"
    echo "  to close a row here is contrived by construction, which is the thing this"
    echo "  corpus exists to avoid."
  fi

  if [ -n "$thin_block" ]; then
    echo
    echo "THIN — expected-high constructs carried by a single item.$thin_block"
  fi

  if [ -n "$badfreq_block" ]; then
    echo
    echo "INVENTORY FREQUENCY — rows whose frequency column is not high/medium/low.$badfreq_block"
    echo
    echo "  Printed, not failed. INVENTORY.md is a file that is still being written, and"
    echo "  the gate does not get a vote on its shape."
  fi
fi

# ===========================================================================
echo
echo "drill-gate.sh: ${item_n} item(s), ${finding_n} finding(s), ${unchecked_n} unchecked, ${declared_n} declared"

if [ "$finding_n" -gt 0 ]; then
  echo "VERDICT FINDINGS"
  exit 1
fi
if [ "$unchecked_n" -gt 0 ]; then
  echo "VERDICT CHECK_DID_NOT_RUN"
  exit 99
fi
echo "VERDICT OK"
exit 0
