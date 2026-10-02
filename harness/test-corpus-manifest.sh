#!/usr/bin/env bash
# Gate for corpus/manifest.tsv, the list of candidate systems PRACTICE-PLAN.md
# curates from.
#
# The invariant: every row names a repo, a path that exists in that repo at the
# recorded SHA, a licence, and a level in 1..5.
#
# Path existence needs a clone of the corpus, which is not in this repo and is
# 54M. So that half of the check runs only when TLA_CORPUS points at one, and
# reports itself as skipped otherwise. Everything else runs offline.
#
# Lineage: bead tla-e7q2.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_ROOT/corpus/manifest.tsv"

PASS=0
FAIL=0
SKIP=0

ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
skip() { SKIP=$((SKIP+1)); printf '  skip %s\n' "$1"; }

HEADER='system	repo	sha	dir	modules	level	describable	prose	prose_path	licence	checkable	tlc_seconds	why'

# Checks one manifest file and prints a defect count on stdout. Runs over a
# here-string rather than a pipe, since a pipeline into an early-exiting
# consumer returns 141 under pipefail and reads as a pass.
check_file() {
  local file="$1"
  local defects=0
  local line_no=0
  local seen_header=""
  local systems=""

  if [ ! -f "$file" ]; then
    printf 'missing\n'
    return 0
  fi

  local line
  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no+1))

    if [ "$line_no" -eq 1 ]; then
      seen_header="$line"
      if [ "$line" != "$HEADER" ]; then
        defects=$((defects+1))
      fi
      continue
    fi

    [ -z "$line" ] && continue

    local n
    n="$(awk -F'\t' '{print NF}' <<<"$line")"
    if [ "$n" -ne 13 ]; then
      defects=$((defects+1))
      continue
    fi

    # Split with awk, one field per line, rather than with read. Tab is IFS
    # whitespace, so `IFS=$'\t' read` collapses a run of tabs into one
    # delimiter and an empty field disappears. The empty-licence control
    # caught that.
    local F
    mapfile -t F < <(awk -F'\t' '{for (i=1; i<=NF; i++) print $i}' <<<"$line")

    local system="${F[0]}"  repo="${F[1]}"        sha="${F[2]}"
    local modules="${F[4]}" level="${F[5]}"       describable="${F[6]}"
    local prose="${F[7]}"   licence="${F[9]}"

    [ -n "$system" ]  || defects=$((defects+1))
    [ -n "$repo" ]    || defects=$((defects+1))
    [ -n "$modules" ] || defects=$((defects+1))
    [ -n "$licence" ] || defects=$((defects+1))

    case "$level" in
      1|2|3|4|5) ;;
      *) defects=$((defects+1)) ;;
    esac

    case "$describable" in
      yes|no) ;;
      *) defects=$((defects+1)) ;;
    esac

    case "$prose" in
      yes|no) ;;
      *) defects=$((defects+1)) ;;
    esac

    if ! [[ "$sha" =~ ^[0-9a-f]{7,40}$ ]]; then
      defects=$((defects+1))
    fi

    case "$systems" in
      *"|$system|"*) defects=$((defects+1)) ;;
      *) systems="$systems|$system|" ;;
    esac
  done <"$file"

  if [ -z "$seen_header" ]; then
    defects=$((defects+1))
  fi

  printf '%s\n' "$defects"
}

# ---------------------------------------------------------------------------
# corpus/MANIFEST.md, the prose beside the TSV.
#
# MANIFEST.md states counts that are functions of manifest.tsv, and until bead
# tla-rsjc nothing read them, so the two could drift apart in silence. That is
# the same shape as the drift MANIFEST.md was written to fix. PRACTICE-PLAN.md
# carried its funnel as six numbers with no rows behind them, the rows were
# lost, and a wrong level-3 count sat in the live plan for 26 days while
# decisions rested on it. So the file that fixed ungated numbers reintroduced
# ungated numbers one layer down.
#
# Derivable, so compared: every table cell the TSV can recompute, and fifteen
# counts stated in prose.
#
# Not derivable, so announced as skipped. The funnel's `modules`, `specs` and
# `candidate groups` came from passes over a 54M corpus clone this repo does
# not keep, and so did the per-repository `.tla` column. The exit-code table
# counts specs where the TSV holds one row per system. A silent skip is the
# bug this check exists to close, so every one of them prints.
#
# Coverage has two halves and only one of them closes. Every table in the file
# is enumerated and must appear in MD_TABLES, in both directions, so a new
# table fails this gate until somebody classifies it and a deleted one stops
# MD_TABLES from lying. Prose gets no equivalent net, because an integer in a
# sentence carries no marker telling a TSV-derived count from a date, a bead
# id or a count over something else, and flagging every integer would produce
# noise that gets muted. What the prose claims get instead is an exactly-once
# match requirement, so rewording a claimed sentence fails here rather than
# quietly switching the check off.
#
# Lineage: bead tla-rsjc.

MANIFEST_MD="$REPO_ROOT/corpus/MANIFEST.md"

# Every table in MANIFEST.md, as "<section>::<first header cell>".
MD_TABLES='The corpus::repository
The funnel::stage
What moved against the recorded counts::stage
Levels::level
Levels::system
Checkability::exit code
Licence::licence'

# Dumps every table in a markdown file in one pass. "T=<section>::<header>"
# per table, then "R=<section>::<header>=<cell>|<cell>|..." per data row. One
# awk per file rather than one per lookup: this check runs over twelve
# fixtures, and at a lookup apiece the forks were the whole suite's wall clock.
md_dump() {
  awk '
    /^## /{ cur = substr($0, 4); intab = 0; next }
    $0 !~ /^[[:space:]]*\|/ { intab = 0; next }
    {
      n = split($0, f, "|")
      for (i = 1; i <= n; i++) {
        gsub(/[`*]/, "", f[i])
        gsub(/^[ \t]+|[ \t]+$/, "", f[i])
      }
      if (!intab) { intab = 1; tid = cur "::" f[2]; print "T=" tid; next }
      if (f[2] ~ /^-+$/) next
      out = ""
      for (i = 2; i < n; i++) out = out (i > 2 ? "|" : "") f[i]
      print "R=" tid "=" out
    }
  ' "$1"
}

# Field k of a "|"-joined row into REPLY, 1-based. !ABSENT for no row at all,
# which is what a missing label looks like and reads that way in a report.
cell() {
  local -a a
  local IFS='|'
  if [ -z "$1" ]; then REPLY='!ABSENT'; return 0; fi
  read -r -a a <<<"$1"
  REPLY="${a[$2 - 1]-}"
}

nonblank() { awk 'NF > 0 { c++ } END { print c+0 }' <<<"$1"; }

# The capture from an ERE that must match the flattened file exactly once.
# Flattened, because several claims wrap across lines and sed works a line at a
# time. Every pattern guards its capture group with a literal or a
# complementary character class, because a bare leading `.*` is greedy:
# `.*([0-9]+)` against "92" captures "2", and `.*([a-z]+)` against "five"
# captures "e". Both of those happened while this was being written, and the
# second one is why the guard is worth a comment rather than a convention.
md_claim() {
  local matches
  matches="$(grep -oE -- "$2" <<<"$1")" || matches=""
  case "$matches" in
    '')      printf '!MISSING\n'; return 0 ;;
    *$'\n'*) printf '!MULTI\n';   return 0 ;;
  esac
  sed -nE "s/^.*${2}.*\$/\\1/p" <<<"$1"
}

# Digits, or a number spelled out as a word, since the level-3 survival
# sentence writes "five" and "eleven".
as_num() {
  if [[ "$1" =~ ^[0-9]+$ ]]; then printf '%s\n' "$((10#$1))"; return 0; fi
  case "${1,,}" in
    zero)     printf '0\n'  ;; one)      printf '1\n'  ;; two)       printf '2\n'  ;;
    three)    printf '3\n'  ;; four)     printf '4\n'  ;; five)      printf '5\n'  ;;
    six)      printf '6\n'  ;; seven)    printf '7\n'  ;; eight)     printf '8\n'  ;;
    nine)     printf '9\n'  ;; ten)      printf '10\n' ;; eleven)    printf '11\n' ;;
    twelve)   printf '12\n' ;; thirteen) printf '13\n' ;; fourteen)  printf '14\n' ;;
    fifteen)  printf '15\n' ;; sixteen)  printf '16\n' ;; seventeen) printf '17\n' ;;
    eighteen) printf '18\n' ;; nineteen) printf '19\n' ;; twenty)    printf '20\n' ;;
    *)        printf '!NAN\n' ;;
  esac
}

# Every count the TSV can answer, in one pass, as "key=value" lines. Column
# numbers against the declared header: 2 repo, 3 sha, 4 dir, 5 modules,
# 6 level, 7 describable, 10 licence, 11 checkable, 12 seconds.
#
# The survivor rows come out as one key per repo|seconds pair with a count, so
# two systems sharing both still compare as a multiset rather than collapsing.
tsv_facts() {
  awk -F'\t' '
    NR == 1 || $0 == "" { next }
    {
      rows++
      lvl[$6]++
      lic[$10]++
      chk[$11]++
      if ($7 == "yes") descr++
      if (!($2 in rseen)) {
        rseen[$2] = 1
        repolist = repolist (repolist == "" ? "" : " ") $2
        sha[$2] = $3
        rlic[$2] = $10
      } else if (sha[$2] != $3 || rlic[$2] != $10) conflict[$2] = 1
      if ($10 == "NONE FOUND" && !($2 in useen)) { useen[$2] = 1; urepos++ }
      if (index($4, "LoopInvariance")) loopinv++
      if ($2 == "lemmy_BlockingQueue") { bqrows++; bqmods = split($5, m, ";") }
      if ($6 == "3") {
        l3t++
        if ($7 == "yes") {
          l3d++
          if ($10 != "NONE FOUND") {
            l3l++
            if ($11 == "unattempted") l3u++
            if ($11 == "yes") {
              l3y++
              r = $2
              sub(/_/, "/", r)
              k = r "|" $12
              if (!(k in surv)) survkeys = survkeys (survkeys == "" ? "" : ";") k
              surv[k]++
            }
          }
        }
      }
    }
    END {
      print "rows=" rows+0
      print "describable=" descr+0
      print "urepos=" urepos+0
      print "loopinv=" loopinv+0
      print "bqrows=" bqrows+0
      print "bqmods=" bqmods+0
      print "l3total=" l3t+0
      print "l3descr=" l3d+0
      print "l3lic=" l3l+0
      print "l3yes=" l3y+0
      print "l3unatt=" l3u+0
      print "l3ceiling=" l3y+l3u+0
      n = 0; for (k in rseen) n++
      print "repos=" n
      n = 0; for (k in conflict) n++
      print "conflicts=" n
      print "repolist=" repolist
      print "survkeys=" survkeys
      n = 0
      for (k in lic) {
        print "lic." k "=" lic[k]
        liclist = liclist (liclist == "" ? "" : "|") k
        n++
      }
      print "lics=" n
      print "liclist=" liclist
      for (k in lvl) print "level." k "=" lvl[k]
      for (k in chk) print "chk." k "=" chk[k]
      for (k in rseen) { print "sha." k "=" sha[k]; print "rlic." k "=" rlic[k] }
      for (k in surv) print "surv." k "=" surv[k]
    }
  ' "$1"
}

declare -A TF=()
TF_PATH=''

# Fills TF from one TSV, and does nothing when TF already holds that file. The
# control battery runs the markdown check twelve times over two TSVs, and each
# run happens in a command substitution, so the parent loads the real one up
# front and every subshell inherits it.
load_tsv_facts() {
  local line k
  [ "$TF_PATH" = "$1" ] && return 0
  TF=()
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    k="${line%%=*}"
    TF["$k"]="${line#*=}"
  done <<<"$(tsv_facts "$1")"
  TF_PATH="$1"
}

# Reports a row label a table is not expected to carry, so a new stage in a
# partly-derivable table fails until somebody classifies it.
labels_ok() {
  local have="$1" name="$2" allow="$3" lab
  while IFS= read -r lab; do
    [ -z "$lab" ] && continue
    case "|$allow|" in
      *"|$lab|"*) ;;
      *) printf '%s: unexpected row "%s", classify it as derivable or not\n' "$name" "$lab" ;;
    esac
  done <<<"$have"
}

# One prose claim. Prints a mismatch line, or nothing.
claim() {
  local flat="$1" label="$2" pat="$3" want="$4" got num
  got="$(md_claim "$flat" "$pat")"
  case "$got" in
    '!MISSING')
      printf 'prose "%s": not found, so the sentence was reworded and the check went blind\n' "$label"
      return 0 ;;
    '!MULTI')
      printf 'prose "%s": matches more than once, so which number is claimed is ambiguous\n' "$label"
      return 0 ;;
  esac
  num="$(as_num "$got")"
  if [ "$num" = '!NAN' ]; then
    printf 'prose "%s": reads "%s", which this check cannot read as a number\n' "$label" "$got"
    return 0
  fi
  [ "$num" = "$want" ] || printf 'prose "%s": markdown says "%s", TSV recomputes %s\n' "$label" "$got" "$want"
}

# Prints one line per count in md that disagrees with tsv, naming the count,
# what the markdown says and what the TSV recomputes. Silence is agreement.
md_mismatches() {
  local md="$1" tsv="$2"
  local flat line tbl row lab got want repo mdrepo lic sk r s
  local -A MDROW=() MDN=() MDLAB=() MDROWS=() mdsurv=()
  local -a repoarr licarr skarr
  local seen=''

  if [ ! -f "$md" ]; then
    printf 'corpus/MANIFEST.md is missing\n'
    return 0
  fi

  flat="$(tr '\n' ' ' <"$md")"
  load_tsv_facts "$tsv"

  while IFS= read -r line; do
    case "$line" in
      'T='*)
        tbl="${line#T=}"
        seen="$seen$tbl"$'\n'
        ;;
      'R='*)
        row="${line#R=}"
        tbl="${row%%=*}"
        row="${row#*=}"
        lab="${row%%|*}"
        MDROW["$tbl::$lab"]="$row"
        MDLAB["$tbl"]="${MDLAB["$tbl"]-}$lab"$'\n'
        MDROWS["$tbl"]="${MDROWS["$tbl"]-}$row"$'\n'
        MDN["$tbl"]=$(( ${MDN["$tbl"]-0} + 1 ))
        ;;
    esac
  done <<<"$(md_dump "$md")"

  # -- Coverage, both directions. An unclassified table is a number nobody
  #    decided about, which is this bead's own failure mode returning. A
  #    classified table that has gone is MD_TABLES lying the other way.
  while IFS= read -r tbl; do
    [ -z "$tbl" ] && continue
    case "$MD_TABLES" in
      *"$tbl"*) ;;
      *) printf 'unclassified table "%s": add it to MD_TABLES, then check its cells or say why it cannot be\n' "$tbl" ;;
    esac
  done <<<"$seen"
  while IFS= read -r tbl; do
    [ -z "$tbl" ] && continue
    case "$seen" in
      *"$tbl"*) ;;
      *) printf 'table "%s" is classified in MD_TABLES and no longer in the file\n' "$tbl" ;;
    esac
  done <<<"$MD_TABLES"

  # -- Levels. Every cell derivable. check_file above constrains the level
  #    column to 1..5, so those five labels are exhaustive by its own gate.
  for lab in 1 2 3 4 5; do
    cell "${MDROW["Levels::level::$lab"]-}" 2
    got="$REPLY"
    want="${TF["level.$lab"]-0}"
    [ "$got" = "$want" ] || printf 'Levels table, level %s: markdown says "%s", TSV recomputes %s\n' "$lab" "$got" "$want"
  done
  got="${MDN["Levels::level"]-0}"
  [ "$got" = 5 ] || printf 'Levels table has %s rows, and the level column only admits 1..5\n' "$got"

  # -- The funnel. `systems` is the row count, `describable` is column 7. The
  #    other three stages were counted over the clone.
  cell "${MDROW["The funnel::stage::systems"]-}" 3
  got="$REPLY"; want="${TF["rows"]}"
  [ "$got" = "$want" ] || printf 'funnel, systems: markdown says "%s", TSV has %s data rows\n' "$got" "$want"
  cell "${MDROW["The funnel::stage::describable"]-}" 3
  got="$REPLY"; want="${TF["describable"]}"
  [ "$got" = "$want" ] || printf 'funnel, describable: markdown says "%s", TSV recomputes %s\n' "$got" "$want"
  labels_ok "${MDLAB["The funnel::stage"]-}" 'funnel' 'modules|specs|candidate groups|systems|describable'

  # -- What moved against the recorded counts. The rebuilt column is this TSV.
  #    The recorded column is the lost funnel and stays unchecked.
  cell "${MDROW["What moved against the recorded counts::stage::distinct systems"]-}" 3
  got="$REPLY"; want="${TF["rows"]}"
  [ "$got" = "$want" ] || printf 'what moved, distinct systems rebuilt: markdown says "%s", TSV has %s data rows\n' "$got" "$want"
  cell "${MDROW["What moved against the recorded counts::stage::describable"]-}" 3
  got="$REPLY"; want="${TF["describable"]}"
  [ "$got" = "$want" ] || printf 'what moved, describable rebuilt: markdown says "%s", TSV recomputes %s\n' "$got" "$want"
  labels_ok "${MDLAB["What moved against the recorded counts::stage"]-}" 'what moved' \
    'modules|specs|distinct systems|describable'

  # -- The corpus. Clone SHA and licence per repository, keyed off the TSV so a
  #    new repository fails until the table gains a row. The markdown spells a
  #    repository with a slash where the TSV uses an underscore.
  want="${TF["conflicts"]}"
  [ "$want" = 0 ] || printf 'TSV gives %s repositories more than one SHA or licence, so the corpus table cannot state either\n' "$want"
  read -r -a repoarr <<<"${TF["repolist"]}"
  for repo in "${repoarr[@]}"; do
    [ -z "$repo" ] && continue
    mdrepo="${repo/_//}"
    cell "${MDROW["The corpus::repository::$mdrepo"]-}" 2
    got="$REPLY"; want="${TF["sha.$repo"]}"
    [ "$got" = "$want" ] || printf 'corpus table, %s clone SHA: markdown says "%s", TSV says %s\n' "$mdrepo" "$got" "$want"
    cell "${MDROW["The corpus::repository::$mdrepo"]-}" 4
    got="$REPLY"; want="${TF["rlic.$repo"]}"
    [ "$got" = "$want" ] || printf 'corpus table, %s licence: markdown says "%s", TSV says %s\n' "$mdrepo" "$got" "$want"
  done
  got="${MDN["The corpus::repository"]-0}"; want="${TF["repos"]}"
  [ "$got" = "$want" ] || printf 'corpus table has %s rows, TSV names %s distinct repositories\n' "$got" "$want"

  # -- Licence. Keyed off the TSV, since the licence column is free text and
  #    nothing enumerates its values.
  IFS='|' read -r -a licarr <<<"${TF["liclist"]}"
  for lic in "${licarr[@]}"; do
    [ -z "$lic" ] && continue
    cell "${MDROW["Licence::licence::$lic"]-}" 2
    got="$REPLY"; want="${TF["lic.$lic"]}"
    [ "$got" = "$want" ] || printf 'Licence table, %s: markdown says "%s", TSV recomputes %s\n' "$lic" "$got" "$want"
  done
  got="${MDN["Licence::licence"]-0}"; want="${TF["lics"]}"
  [ "$got" = "$want" ] || printf 'Licence table has %s rows, TSV names %s distinct licences\n' "$got" "$want"

  # -- The five level-3 survivors, as a multiset of repository and seconds. The
  #    markdown shortens every system name, so the names do not compare.
  while IFS= read -r row; do
    [ -z "$row" ] && continue
    cell "$row" 2; r="$REPLY"
    cell "$row" 3; s="$REPLY"
    mdsurv["$r|$s"]=$(( ${mdsurv["$r|$s"]-0} + 1 ))
  done <<<"${MDROWS["Levels::system"]-}"
  IFS=';' read -r -a skarr <<<"${TF["survkeys"]}"
  for sk in "${skarr[@]}"; do
    [ -z "$sk" ] && continue
    want="${TF["surv.$sk"]}"
    got="${mdsurv["$sk"]-0}"
    [ "$got" = "$want" ] || printf 'level-3 survivors, %s: markdown lists it %s times, TSV recomputes %s\n' "$sk" "$got" "$want"
    unset "mdsurv[$sk]"
  done
  for sk in "${!mdsurv[@]}"; do
    printf 'level-3 survivors, %s: in the markdown and not a TSV survivor at all\n' "$sk"
  done

  # -- Counts stated in prose rather than in a table. The level-3 survival
  #    chain lives here, so a table-only check would miss it entirely.
  claim "$flat" 'the candidate pool' \
    '[^0-9]([0-9]+) rows are still a candidate pool' "${TF["rows"]}"
  claim "$flat" 'level 3 against the plan' \
    '[^0-9]([0-9]+) systems at level 3 against the plan' "${TF["l3total"]}"
  claim "$flat" 'settled, level-3 rows' \
    'filters to these ([0-9]+) rows' "${TF["l3total"]}"
  claim "$flat" 'settled, describable' \
    'rows\. ([0-9]+) are describable' "${TF["l3descr"]}"
  claim "$flat" 'settled, licensed' \
    'describable, ([0-9]+) of those carry a licence' "${TF["l3lic"]}"
  claim "$flat" 'settled, of the licensed' \
    'and of the ([0-9]+) [a-z]+ read .checkable=yes.' "${TF["l3lic"]}"
  claim "$flat" 'settled, checkable=yes' \
    'and of the [0-9]+ ([a-z]+) read .checkable=yes.' "${TF["l3yes"]}"
  claim "$flat" 'settled, unattempted' \
    'while ([a-z]+) read .unattempted.' "${TF["l3unatt"]}"
  claim "$flat" 'band floor' \
    'belongs between ([0-9]+) and [0-9]+ rather than' "${TF["l3yes"]}"
  claim "$flat" 'band ceiling' \
    'belongs between [0-9]+ and ([0-9]+) rather than' "${TF["l3ceiling"]}"
  claim "$flat" 'unattempted rows' \
    'for ([0-9]+) of the [0-9]+ rows' "${TF["chk.unattempted"]-0}"
  claim "$flat" 'unattempted, out of all rows' \
    'for [0-9]+ of the ([0-9]+) rows' "${TF["rows"]}"
  claim "$flat" 'repositories with no licence' \
    '[^A-Za-z]([A-Za-z]+) of the [a-z]+ repositories carry no' "${TF["urepos"]}"
  claim "$flat" 'repositories in all' \
    'of the ([a-z]+) repositories carry no' "${TF["repos"]}"
  claim "$flat" 'systems with no licence' \
    'account for ([0-9]+) systems here' "${TF["lic.NONE FOUND"]-0}"

  # These five were not on the bead's list. They turned up reading the whole
  # file, which is the argument for a gate rather than a reading.
  claim "$flat" 'tla-16je, unlicensed repositories' \
    '[^a-z]([a-z]+) repositories ship no licence' "${TF["urepos"]}"
  claim "$flat" 'repositories to clone' \
    'Clone the ([a-z]+) repositories above' "${TF["repos"]}"
  claim "$flat" 'algorithms in LoopInvariance' \
    'holds ([a-z]+) unrelated algorithms in .LoopInvariance.' "${TF["loopinv"]}"
  claim "$flat" 'systems in BlockingQueue' \
    ', and ([a-z]+) system across' "${TF["bqrows"]}"
  claim "$flat" 'files in BlockingQueue' \
    'system across ([a-z]+) files in .BlockingQueue.' "${TF["bqmods"]}"
}

printf 'corpus manifest gate\n'

# 1. The manifest is there and clean.
result="$(check_file "$MANIFEST")"
if [ "$result" = "missing" ]; then
  bad "corpus/manifest.tsv exists"
elif [ "$result" -eq 0 ]; then
  ok "corpus/manifest.tsv: every row well formed"
else
  bad "corpus/manifest.tsv: $result malformed rows"
fi

# 2. Controls. Each is a manifest the checker MUST reject. A checker that
#    passes these is not reading the fields it claims to read.
CTRL="$(mktemp -d)"
trap 'rm -rf "$CTRL"' EXIT

printf '%s\n' "$HEADER" > "$CTRL/level.tsv"
printf 'a\tr\tabc1234\td\tM\t6\tyes\tyes\tp\tMIT\tyes\t1.0\tbecause\n' >> "$CTRL/level.tsv"

printf '%s\n' "$HEADER" > "$CTRL/licence.tsv"
printf 'a\tr\tabc1234\td\tM\t3\tyes\tyes\tp\t\tyes\t1.0\tbecause\n' >> "$CTRL/licence.tsv"

printf '%s\n' "$HEADER" > "$CTRL/sha.tsv"
printf 'a\tr\tnotasha\td\tM\t3\tyes\tyes\tp\tMIT\tyes\t1.0\tbecause\n' >> "$CTRL/sha.tsv"

printf '%s\n' "$HEADER" > "$CTRL/dup.tsv"
printf 'a\tr\tabc1234\td\tM\t3\tyes\tyes\tp\tMIT\tyes\t1.0\tbecause\n' >> "$CTRL/dup.tsv"
printf 'a\tr\tabc1234\td\tM\t3\tyes\tyes\tp\tMIT\tyes\t1.0\tbecause\n' >> "$CTRL/dup.tsv"

printf '%s\n' "$HEADER" > "$CTRL/width.tsv"
printf 'a\tr\tabc1234\td\tM\t3\n' >> "$CTRL/width.tsv"

printf 'system\trepo\n' > "$CTRL/header.tsv"
printf 'a\tr\n' >> "$CTRL/header.tsv"

for c in level licence sha dup width header; do
  r="$(check_file "$CTRL/$c.tsv")"
  if [ "$r" != "missing" ] && [ "$r" -gt 0 ]; then
    ok "control $c: rejected ($r defects)"
  else
    bad "control $c: accepted, so the check is blind to it"
  fi
done

# 3. corpus/MANIFEST.md agrees with the TSV on every count the TSV can
#    recompute. Load the real TSV's facts here, in the parent, so the twelve
#    command substitutions below inherit them instead of each recomputing.
load_tsv_facts "$MANIFEST"

if [ ! -f "$MANIFEST_MD" ]; then
  bad "corpus/MANIFEST.md exists"
else
  md_result="$(md_mismatches "$MANIFEST_MD" "$MANIFEST")"
  md_n="$(nonblank "$md_result")"
  if [ "$md_n" -eq 0 ]; then
    ok "corpus/MANIFEST.md: every derivable count agrees with the TSV"
  else
    bad "corpus/MANIFEST.md: $md_n derivable counts disagree with the TSV"
    while IFS= read -r md_line; do
      [ -z "$md_line" ] && continue
      printf '       %s\n' "$md_line"
    done <<<"$md_result"
  fi
fi

# 4. What the markdown states that the TSV cannot answer. These print because
#    a silent skip is indistinguishable from a check that looked and agreed,
#    which is the defect this whole section exists to close.
skip "funnel modules 666, specs 211, candidate groups 127 (counted over a corpus clone, not in the TSV)"
skip "corpus table .tla column (every module in each clone, not the ones a system picked up)"
skip "'what moved' recorded column (the lost 2026-09 funnel, not a function of this TSV)"
skip "Checkability exit-code table and '79 of 211 specs' (per spec, and the TSV holds one row per system)"
skip "Totals: 666 modules and 337 configuration files (clone-wide counts)"
skip "the plan's 67 filtered systems and its '68 fast enough to check' stage (PRACTICE-PLAN.md's numbers)"
skip "the five survivors' system names (the markdown shortens them, so only repo and tlc_seconds compare)"
skip "the Left out bullet (an excluded row is not in the TSV to be counted)"
skip "any count in a sentence no claim above names (prose has no coverage net, only the tables do)"

# 5. Controls for the markdown check. Each perturbs ONE number in a copy of
#    the real pair, and the check must reject it and name what moved. A
#    checker that passes these is not reading the file it claims to read.
sed 's/^| 3 | 24 |$/| 3 | 23 |/'                               "$MANIFEST_MD" > "$CTRL/md-level.md"
sed 's/naming a variable | 131 |/naming a variable | 130 |/'    "$MANIFEST_MD" > "$CTRL/md-funnel.md"
sed 's/^| MIT | 116 |$/| MIT | 115 |/'                          "$MANIFEST_MD" > "$CTRL/md-licence.md"
sed 's/ceeaa90/deadbee/'                                        "$MANIFEST_MD" > "$CTRL/md-sha.md"
sed 's/| 22 | Apache-2.0 |/| 22 | MIT |/'                        "$MANIFEST_MD" > "$CTRL/md-repolic.md"
sed 's/| 12.6 |/| 12.7 |/'                                      "$MANIFEST_MD" > "$CTRL/md-survivor.md"
sed 's/five read/six read/'                                     "$MANIFEST_MD" > "$CTRL/md-word.md"
sed 's/for 92 of the 143 rows/for 91 of the 143 rows/'           "$MANIFEST_MD" > "$CTRL/md-prose.md"
sed 's/belongs between 5 and 16 rather than/sits well above/'    "$MANIFEST_MD" > "$CTRL/md-reword.md"

cp "$MANIFEST_MD" "$CTRL/md-newtable.md"
printf '\n## Widgets\n\n| widget | count |\n|---|---|\n| a | 7 |\n' >> "$CTRL/md-newtable.md"

# The only control that perturbs the TSV side. The real markdown must then be
# the thing that reads wrong, which is what makes the check bidirectional.
awk -F'\t' -v OFS='\t' 'NR > 1 && $6 == "3" && !bumped { $6 = "4"; bumped = 1 } { print }' \
  "$MANIFEST" > "$CTRL/md-tsv.tsv"

for c in md-level md-funnel md-licence md-sha md-repolic md-survivor md-word md-prose md-reword md-newtable; do
  r="$(md_mismatches "$CTRL/$c.md" "$MANIFEST")"
  n="$(nonblank "$r")"
  if [ "$n" -gt 0 ]; then
    ok "control $c: rejected ($(sed -n '1p' <<<"$r"))"
  else
    bad "control $c: accepted, so the check is blind to it"
  fi
done

r="$(md_mismatches "$MANIFEST_MD" "$CTRL/md-tsv.tsv")"
n="$(nonblank "$r")"
if [ "$n" -gt 0 ]; then
  ok "control md-tsv: rejected ($(sed -n '1p' <<<"$r"))"
else
  bad "control md-tsv: a moved TSV level left the markdown reading correct"
fi

# 6. Paths resolve, when a corpus clone is available.
if [ -n "${TLA_CORPUS:-}" ] && [ -d "${TLA_CORPUS:-}" ] && [ -f "$MANIFEST" ]; then
  missing=0
  rows=0
  # awk again, not read. A spec sitting at its repository root has an empty
  # dir, and `IFS=$'\t' read` swallows it, so every such row resolves against
  # the wrong field. That misreported 9 good rows as broken on the first run.
  while IFS= read -r row; do
    [ -z "$row" ] && continue
    rows=$((rows+1))
    local_repo="$(awk -F'\t' '{print $2}' <<<"$row")"
    local_dir="$(awk -F'\t' '{print $4}' <<<"$row")"
    [ -d "$TLA_CORPUS/$local_repo/$local_dir" ] || {
      missing=$((missing+1))
      printf '       unresolved: %s/%s\n' "$local_repo" "$local_dir"
    }
  done < <(tail -n +2 "$MANIFEST")
  if [ "$missing" -eq 0 ]; then
    ok "all $rows rows resolve under TLA_CORPUS"
  else
    bad "$missing of $rows rows name a directory not in TLA_CORPUS"
  fi
else
  skip "path resolution (set TLA_CORPUS to a corpus clone to run it)"
fi

printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
