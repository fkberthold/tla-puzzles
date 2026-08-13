#!/usr/bin/env bash
# test-printed-commands.sh: every command printed in a chapter's EXERCISES.md
# is true as printed, from the directory the chapter tells the learner to
# stand in (bead tla-60le).
#
# THE INVARIANT
#
#   Deliver chapter N with scripts/deliver-exercises.sh. Stand in the
#   delivered chapter directory. Every printed verdict.sh and pcal command
#   names a harness that exists and files that resolve from there.
#
# WHY THIS NEEDS A SUITE
#
# The 2026-08-12 readability review found five chapters printing commands that
# cannot run as printed. Ch.2 through ch.6 tell the learner to stand in the
# repo checkout, ch.7 through ch.11 tell them to stand in their practice
# directory, and each half prints paths for its own stance. A learner in a
# delivered tree gets a file-not-found, which surfaces as TLC_EXCEPTION, which
# those chapters either do not gloss or gloss wrong.
#
# The check that would have caught it already existed. It was the last item on
# exercises/templates/REVIEW-CHECKLIST.md, it was advisory, and it was
# per-chapter, so nobody was ever asked whether ch.3 and ch.7 agree. That is
# the gate-don't-advise failure CLAUDE.md names, and this file closes it.
#
# STATIC, NOT EXECUTED
#
# This suite resolves paths. It never runs TLC and never runs pcal. Two
# reasons, and the second is the one that matters. Running the model checker
# would put this in the slow tier for a check that is about text. And a run's
# verdict depends on learner state: half these commands are meant to be typed
# against a starter the learner has not filled in yet, so the honest expected
# result is a checkpoint token rather than a pass. Resolvability has no such
# dependence. It is either true of the delivered tree or it is not.
#
# WHAT COUNTS AS A PRINTED COMMAND
#
# Both surfaces the chapters actually use:
#
#   - a line inside a fenced block, with backslash continuations joined
#   - an inline backtick span, with a span split over a line break joined
#
# A span qualifies as a command only when it carries a file argument. A bare
# `verdict.sh` or `pcal` in a sentence is prose about the tool, so it is
# skipped rather than failed. Two spans in the set do run over a line break,
# both prose, and joining them costs four lines and removes the caveat.
#
# THE RESOLUTION LADDER, applied to each module and config argument
#
#   1. It resolves from the delivered chapter directory. Pass.
#   2. starters/<name> is what got delivered. Fail, and say so, because the
#      command is one prefix away from working.
#   3. The exercise is write-from-prompt and the path is under starters/.
#      Pass. The learner writes this file, and the print pins where it goes.
#   4. The exercise is write-from-prompt and the path is not under starters/.
#      Fail. A file the learner creates with no stated home is how a chapter
#      ends up with five answers in five places.
#   5. Anything else. Fail.
#
# A verdict.sh call with no -c gets its config checked too, since the default
# is <module>.cfg beside the module and a missing one is a TLC_EXCEPTION.
#
# PLACEHOLDERS
#
# The preamble of most chapters prints the shape of the command rather than a
# real one, over a stand-in name. Those names are listed in PLACEHOLDER_STEMS
# and PLACEHOLDER_DIRS below. A stand-in file name is not resolved, but its
# directory still is, so a shape line pointing at a directory that is not in
# the delivered tree fails like any other. That is what catches ch.4's
# exercises/ch04/starters/<Module>.tla.
#
# Keep both lists short and explicit. A new stand-in name arrives as a failure
# a human has to look at, which is the direction I want the error to run.
#
# THE NON-VACUITY CONTROL
#
# Every assertion here is of the form "this resolves", and a scanner that
# extracted nothing would report a clean sweep. So each chapter also asserts
# it has at least three exercise sections and that every one of them prints a
# verdict.sh command. That control fails loudly if the heading shape, the
# Format field, or the extractor itself drifts, and it is a real content rule
# on its own: an exercise you cannot run is a defect.
#
# THE HARNESS PATH ON A BOX WITHOUT THE CLONE
#
# The canonical form names the harness by absolute path, and the chapters tell
# the reader to adjust it to wherever they cloned. So an absolute path that
# does not resolve here is not always the text's fault. If the printed path is
# absolute, ends in /harness/verdict.sh, and this box has no clone at the root
# it names, the check falls back to this repo's own harness and prints a NOTE.
# A relative harness path gets no such rescue, and that is the one the five
# broken chapters print.
#
# Usage:  harness/test-printed-commands.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

DELIVER="scripts/deliver-exercises.sh"
TEST_RUNNER="scripts/test"
CHAPTERS=(02 03 04 05 06 07 08 09 10 11)

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }
note() { printf "  NOTE  %s\n" "$1"; }

# Stand-in names. A file called one of these is the shape of a command, not a
# file anybody ships. Anything bracketed counts too, which is how ch.4 writes
# its stand-in.
PLACEHOLDER_STEMS=(Module MyModule YourSpec Thing Spec)
PLACEHOLDER_DIRS=(DIR PATH)

FENCE_RE='^[[:space:]]*```'

TMPROOT=$(mktemp -d -t tla_printed.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

DEST="$TMPROOT/practice"
SANDBOX_HOME="$TMPROOT/home"
mkdir -p "$SANDBOX_HOME"

# ---------------------------------------------------------------------------
# Command parsing.
#
# parse_command sets PC_KIND, PC_HARNESS, PC_TARGETS and PC_ERR from one line
# of printed text. PC_KIND comes back empty when the text is a mention rather
# than a command, and the caller skips it silently.
# ---------------------------------------------------------------------------

PC_KIND=""
PC_HARNESS=""
PC_ERR=""
PC_TARGETS=()
TOKS=()

parse_command() {
  PC_KIND=""
  PC_HARNESS=""
  PC_ERR=""
  PC_TARGETS=()
  TOKS=()

  local -a raw=()
  read -r -a raw <<<"$1"

  # Drop a trailing shell comment. Two chapters annotate the shape line with
  # `# PlusCal specs only`, which is legal shell and leaves the command true
  # as printed, so the words after the hash are not file arguments.
  local w
  for w in "${raw[@]}"; do
    case "$w" in
    '#'*) break ;;
    esac
    TOKS+=("$w")
  done
  [ "${#TOKS[@]}" -eq 0 ] && return 0

  local n=${#TOKS[@]} k i=-1 j tok module="" cfg="" target=""

  for ((k = 0; k < n; k++)); do
    case "${TOKS[k]}" in
    *verdict.sh)
      i=$k
      break
      ;;
    esac
  done

  if [ "$i" -ge 0 ]; then
    j=$((i + 1))
    while [ "$j" -lt "$n" ]; do
      tok="${TOKS[j]}"
      case "$tok" in
      --) break ;;
      -c | --config)
        j=$((j + 1))
        if [ "$j" -ge "$n" ]; then
          PC_ERR="$tok carries no value"
          break
        fi
        cfg="${TOKS[j]}"
        ;;
      -t | --timeout | -p | --postcondition | --trace | --log | --scratch)
        j=$((j + 1))
        if [ "$j" -ge "$n" ]; then
          PC_ERR="$tok carries no value"
          break
        fi
        ;;
      -d | --check-deadlock | -q | --quiet | -h | --help) ;;
      -*) PC_ERR="verdict.sh has no flag $tok" ;;
      *)
        if [ -n "$module" ]; then
          PC_ERR="two module arguments, $module and $tok"
        else
          module="$tok"
        fi
        ;;
      esac
      j=$((j + 1))
    done

    # No module argument means this is a sentence about verdict.sh, not a
    # command someone is meant to type.
    [ -z "$module" ] && return 0

    PC_KIND="verdict"
    PC_HARNESS="${TOKS[i]}"
    case "$module" in
    *.tla) ;;
    *) PC_ERR="module argument $module is not a .tla" ;;
    esac
    PC_TARGETS+=("$module")
    if [ -n "$cfg" ]; then
      case "$cfg" in
      *.cfg) ;;
      *) PC_ERR="config argument $cfg is not a .cfg" ;;
      esac
      PC_TARGETS+=("$cfg")
    else
      # verdict.sh defaults to <module>.cfg beside the module, so the command
      # is only true as printed if that file is there too.
      PC_TARGETS+=("${module%.tla}.cfg")
    fi
    return 0
  fi

  if [ "${TOKS[0]}" = "pcal" ]; then
    j=1
    while [ "$j" -lt "$n" ]; do
      tok="${TOKS[j]}"
      case "$tok" in
      -*) ;;
      *)
        if [ -n "$target" ]; then
          PC_ERR="two file arguments, $target and $tok"
        else
          target="$tok"
        fi
        ;;
      esac
      j=$((j + 1))
    done
    [ -z "$target" ] && return 0
    PC_KIND="pcal"
    case "$target" in
    *.tla) ;;
    *) PC_ERR="pcal argument $target is not a .tla" ;;
    esac
    PC_TARGETS+=("$target")
  fi

  return 0
}

# ---------------------------------------------------------------------------
# Extraction.
#
# One forward pass. The Format field always precedes the how-to-run line
# inside an exercise block, so a single pass is enough to know which format a
# command belongs to.
# ---------------------------------------------------------------------------

# Three parallel arrays rather than one array of packed records. A tab-packed
# record splits wrong the moment a field is empty, because a tab is an IFS
# whitespace character and `read` folds a run of them into one delimiter. The
# preamble commands have no Format field, so that is most of the set.
CMD_LINE_NO=()
CMD_FMT=()
CMD_TEXT=()
SEC_NAMES=()
SEC_HAS_RUN=()

record_if_command() {
  local lineno="$1" fmt="$2" text="$3" sec="$4"
  parse_command "$text"
  [ -z "$PC_KIND" ] && return 0
  CMD_LINE_NO+=("$lineno")
  CMD_FMT+=("$fmt")
  CMD_TEXT+=("$text")
  if [ "$PC_KIND" = "verdict" ] && [ "$sec" -ge 0 ]; then
    SEC_HAS_RUN[sec]=1
  fi
  return 0
}

extract() {
  local file="$1"
  CMD_LINE_NO=()
  CMD_FMT=()
  CMD_TEXT=()
  SEC_NAMES=()
  SEC_HAS_RUN=()

  local lineno=0 in_fence=0 fmt="" sec=-1
  local line trimmed cont="" cont_line=0
  local span_buf="" span_line=0 ticks rest span

  while IFS= read -r line || [ -n "$line" ]; do
    lineno=$((lineno + 1))

    if [[ $line =~ $FENCE_RE ]]; then
      in_fence=$((1 - in_fence))
      continue
    fi

    if [ "$in_fence" -eq 1 ]; then
      trimmed="${line#"${line%%[![:space:]]*}"}"
      if [ -n "$cont" ]; then
        cont="$cont $trimmed"
      else
        cont="$trimmed"
        cont_line=$lineno
      fi
      case "$cont" in
      *\\)
        cont="${cont%\\}"
        continue
        ;;
      esac
      record_if_command "$cont_line" "$fmt" "$cont" "$sec"
      cont=""
      continue
    fi

    case "$line" in
    '## '*)
      fmt=""
      case "$line" in
      '## Exercise'*)
        SEC_NAMES+=("${line#\#\# }")
        SEC_HAS_RUN+=(0)
        sec=$((${#SEC_NAMES[@]} - 1))
        ;;
      *) sec=-1 ;;
      esac
      ;;
    '- Format: '*)
      fmt="${line#- Format: }"
      fmt="${fmt//\`/}"
      ;;
    esac

    if [ -n "$span_buf" ]; then
      span_buf="$span_buf $line"
    else
      span_buf="$line"
      span_line=$lineno
    fi
    ticks="${span_buf//[^\`]/}"
    if [ $((${#ticks} % 2)) -eq 1 ]; then
      continue
    fi

    rest="$span_buf"
    span_buf=""
    while :; do
      case "$rest" in
      *'`'*) ;;
      *) break ;;
      esac
      rest="${rest#*\`}"
      case "$rest" in
      *'`'*)
        span="${rest%%\`*}"
        rest="${rest#*\`}"
        ;;
      *) break ;;
      esac
      record_if_command "$span_line" "$fmt" "$span" "$sec"
    done
  done <"$file"

  return 0
}

# ---------------------------------------------------------------------------
# Resolution.
# ---------------------------------------------------------------------------

CHECK_MSG=""

is_placeholder_stem() {
  local stem="$1" p
  case "$stem" in
  *'<'* | *'>'*) return 0 ;;
  esac
  for p in "${PLACEHOLDER_STEMS[@]}"; do
    [ "$stem" = "$p" ] && return 0
  done
  return 1
}

is_placeholder_dir() {
  local dir="$1" part p
  case "$dir" in
  *'<'* | *'>'*) return 0 ;;
  esac
  local IFS=/
  for part in $dir; do
    for p in "${PLACEHOLDER_DIRS[@]}"; do
      [ "$part" = "$p" ] && return 0
    done
  done
  return 1
}

# check_harness <chapter-dir> <printed-path>
check_harness() {
  local chdir="$1" printed="$2" abs rooted=0

  CHECK_MSG=""

  # Written as prefix strips rather than as `case "$printed" in '~/'*)`,
  # because shellcheck reads a leading tilde in a quoted word as a path it
  # will not expand (SC2088). Here the tilde is a character in text somebody
  # printed, so there is nothing to expand and nothing to warn about. The
  # strip form says that without a suppression.
  if [ "${printed#\~/}" != "$printed" ]; then
    abs="$HOME/${printed#\~/}"
    rooted=1
  elif [ "${printed#/}" != "$printed" ]; then
    abs="$printed"
    rooted=1
  else
    abs="$chdir/$printed"
  fi

  [ -f "$abs" ] && return 0

  # The clone-root fallback. See the header before widening it.
  if [ "$rooted" -eq 1 ] && [ "${abs%/harness/verdict.sh}" != "$abs" ]; then
    if [ -f "$REPO_ROOT/harness/verdict.sh" ]; then
      note "no clone at $abs on this box, so the harness path was read against $REPO_ROOT instead"
      return 0
    fi
  fi

  CHECK_MSG="the harness path $printed does not resolve from the chapter directory"
  return 1
}

# check_target <chapter-dir> <format> <printed-path>
check_target() {
  local chdir="$1" fmt="$2" printed="$3" dir base stem
  CHECK_MSG=""

  base="${printed##*/}"
  if [ "$base" = "$printed" ]; then
    dir=""
  else
    dir="${printed%/*}"
  fi
  stem="${base%.*}"

  if is_placeholder_stem "$stem"; then
    if [ -z "$dir" ] || is_placeholder_dir "$dir"; then
      return 0
    fi
    [ -d "$chdir/$dir" ] && return 0
    CHECK_MSG="the shape line points at $dir/, which the delivered chapter has no such directory for"
    return 1
  fi

  [ -e "$chdir/$printed" ] && return 0

  if [ "$printed" != "starters/$base" ] && [ -e "$chdir/starters/$base" ]; then
    CHECK_MSG="$printed does not resolve, the delivered file is starters/$base"
    return 1
  fi

  if [ "$fmt" = "write-from-prompt" ]; then
    case "$printed" in
    starters/*) return 0 ;;
    esac
    CHECK_MSG="$printed is a file the learner writes, so print it as starters/$base to pin where it goes"
    return 1
  fi

  CHECK_MSG="$printed does not resolve from the delivered chapter directory"
  return 1
}

# check_command <chapter> <chapter-dir> <lineno> <format> <text>
check_command() {
  local n="$1" chdir="$2" lineno="$3" fmt="$4" text="$5"
  local label="ch$n/EXERCISES.md:$lineno  $5"
  local -a problems=()
  local t p

  parse_command "$text"
  [ -n "$PC_ERR" ] && problems+=("$PC_ERR")

  if [ "$PC_KIND" = "verdict" ]; then
    check_harness "$chdir" "$PC_HARNESS" || problems+=("$CHECK_MSG")
  fi

  for t in "${PC_TARGETS[@]}"; do
    check_target "$chdir" "$fmt" "$t" || problems+=("$CHECK_MSG")
  done

  if [ "${#problems[@]}" -eq 0 ]; then
    ok "$label"
    return 0
  fi
  nope "$label"
  for p in "${problems[@]}"; do
    printf "          %s\n" "$p"
  done
  return 0
}

# ---------------------------------------------------------------------------
echo "== delivery =="
# ---------------------------------------------------------------------------

if [ -f "$DELIVER" ]; then
  ok "$DELIVER exists"
else
  nope "$DELIVER does not exist"
fi

declare -a READY=()

for n in "${CHAPTERS[@]}"; do
  err="$TMPROOT/deliver-$n.err"
  HOME="$SANDBOX_HOME" bash "$DELIVER" "$n" "$DEST" >/dev/null 2>"$err"
  rc=$?
  if [ "$rc" -ne 0 ]; then
    nope "chapter $n delivers cleanly (rc=$rc), stderr: $(tr '\n' ' ' <"$err")"
    continue
  fi
  if [ ! -f "$DEST/ch$n/EXERCISES.md" ]; then
    nope "chapter $n delivers cleanly. Exited 0 but landed no EXERCISES.md"
    continue
  fi
  ok "chapter $n delivers cleanly"
  READY+=("$n")
done

# ---------------------------------------------------------------------------
# Per chapter: every printed command, then the non-vacuity control.
# ---------------------------------------------------------------------------

for n in "${READY[@]}"; do
  chdir="$DEST/ch$n"
  echo
  echo "== ch$n: printed commands, resolved from $chdir =="
  extract "$chdir/EXERCISES.md"

  for i in "${!CMD_TEXT[@]}"; do
    check_command "$n" "$chdir" "${CMD_LINE_NO[$i]}" "${CMD_FMT[$i]}" "${CMD_TEXT[$i]}"
  done

  if [ "${#SEC_NAMES[@]}" -ge 3 ]; then
    ok "ch$n has ${#SEC_NAMES[@]} exercise sections"
  else
    nope "ch$n has ${#SEC_NAMES[@]} exercise sections, wanted 3 or more. The scan is not reading this file"
  fi

  for i in "${!SEC_NAMES[@]}"; do
    if [ "${SEC_HAS_RUN[$i]}" -eq 1 ]; then
      ok "ch$n ${SEC_NAMES[$i]} prints a verdict.sh command"
    else
      nope "ch$n ${SEC_NAMES[$i]} prints no verdict.sh command"
    fi
  done
done

# ---------------------------------------------------------------------------
echo
echo "== structural =="
# ---------------------------------------------------------------------------

# Every pcal line above is checked as text. This is the one assertion that the
# tool those lines name is on the path at all.
if command -v pcal >/dev/null 2>&1; then
  ok "pcal is on the path, so the printed pcal commands name a real tool"
else
  nope "pcal is not on the path. Run scripts/setup"
fi

# Read the SUITES array rather than the whole file, so a mention of this suite
# in a comment cannot stand in for a row that actually runs it. The row is
# commented out on landing, by design, and this assertion is red until central
# uncomments it after the chapter repair wave merges.
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"fast[|][^|]*[|][^|]*[|]\./harness/test-printed-commands\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif grep -qE -- "$SUITE_ROW" <<<"$SUITES_BLOCK"; then
  ok "SUITES carries a fast-tier row for ./harness/test-printed-commands.sh"
else
  nope "SUITES carries no live fast-tier row for ./harness/test-printed-commands.sh"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
