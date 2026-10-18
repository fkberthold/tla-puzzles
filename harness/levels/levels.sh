#!/usr/bin/env bash
# levels.sh — the level of every definition a TLA+ module declares.
#
# Bead tla-7xql.3, infrastructure for the swipe rung's level 1, 2 and 3 item
# kinds. A generator that cannot read a definition's level has to EXCLUDE
# whatever it cannot classify. With the level in hand it DISPATCHES instead,
# and that is the whole point of this file.
#
# TLA+'s level calculus, which is what the swipe rung is organized around:
#
#   0  constant expression   pin nothing, no model screen at all
#   1  state predicate       pin a state
#   2  action                pin a step
#   3  temporal              pin a lasso
#
# USAGE
#   harness/levels/levels.sh [OPTIONS] <module.tla>...
#   harness/levels/levels.sh [OPTIONS] --corpus
#
# OPTIONS
#   --corpus        every reading/ model, in sorted path order
#   --all           keep definitions an EXTENDS brought in, tagged with the
#                   module they came from. Off by default
#   --defs-only     print the DEF rows and drop the MOD rows
#   --tally         print a level histogram instead of the rows
#   -h, --help      this text
#
# OUTPUT — tab separated, two row kinds, first field is the kind:
#
#   MOD  <path>  <module-name>  <sany-rc>  <definition-count>
#   DEF  <module-name>  <name>  <level>  <arity>  <origin-module>
#        <local|exported>  <obligation|free|no-cfg>
#
# A MOD row per input is emitted even when the module has no definitions, so a
# consumer counting modules cannot miss one that failed to parse.
#
# EXIT
#    0  every module was read
#    1  at least one module failed to parse, or reported a level outside 0..3
#    2  usage error
#   99  CHECK_DID_NOT_RUN — the toolchain needed is absent, so nothing was
#       classified. NOT a verdict about any module. Project-wide reserved
#       code; harness/test-indeterminate.sh owns the convention
#
# ===== end of usage =====
#
# THE LAST COLUMN IS THE GENERABLE SET, AND THE JOIN IS PER MODULE
#
# A definition a .cfg declares as an INVARIANT or a PROPERTY is checked by
# TLC over that model, so it is true everywhere the model can reach. An item
# asking whether it holds has one answer by construction and teaches nothing.
# The free ones are the generable set, which is what the column is for.
#
# The join is against the .cfg BESIDE THAT MODULE, never against every
# obligation name in the corpus, and the difference is measurable. Five
# definitions in reading/ share a name with an obligation some OTHER model
# declares: Stamps!Gap and Chips!Held and Brackets!Closes at level 0,
# Shelves!Held and Tickets!Waiting at level 1. A name-only join calls all five
# declared. They are not, and the two at level 1 are generable items a
# name-only join silently drops. The research round behind this bead read 101
# free level-1 definitions on a name-only join; the per-module join reads 103.
#
# WHAT COUNTS AS A DECLARATION. The keyword is anchored at the start of a line
# and must carry an operand, which is harness/reading-gate.sh:744's recognizer.
# A `\*INVARIANT Inv2` is ordinary published practice and must not count
# (.claude/rules/tla-practice.md section 7), and a bare keyword with no operand
# must not count either, because TLC exits 0 having checked nothing.
#
# WHY A JAVA DRIVER LIVES IN THIS REPO, WHICH HAD NO JAVA BEFORE
#
# Three routes were measured before this one was written, and two of them do
# not work.
#
#   1. SANY's own command line. `java -cp jar tla2sany.SANY <module>` prints
#      no levels. Neither does `-d <module> mt`, which lists every top-level
#      definition and no level beside any of them, nor `-d <module> dot`,
#      whose semantic graph carries no level attribute. There is no flag.
#
#   2. The ASSUME refusal, through harness/verdict.sh. It works for a level
#      1, 2 or 3 definition of no arguments, and it is how the route below was
#      validated. It is wrong for anything else, because SANY reports the
#      level of the EXPRESSION the ASSUME holds, not of the definition.
#      Measured on reading/core/01-nim, where \oplus is level 0 of arity 2:
#      `ASSUME (a (+) b) = 0` reads level 1 while `ASSUME (Heap (+) Heap) = 1`
#      raises no level error at all. 37 of the 113 level 2 definitions in
#      reading/ take arguments, and the channel answers wrongly in silence for
#      every one. It costs 247 ms per definition besides, against 0.9 s for
#      the whole corpus here.
#
#   3. The semantic tree, which is this file. SANY builds it, the level is an
#      integer on the OpDefNode, and reading it is exact.
#
# NO BUILD STEP, ON PURPOSE. Levels.java runs under Java's single-file source
# launcher, so the JVM compiles it in memory on each invocation. There is no
# javac call, no .class or .jar artifact to gitignore, and nothing for
# scripts/setup to install. The in-memory compile is paid ONCE for the whole
# corpus, and it buys away a build step that CI, scripts/setup and
# scripts/cibuild would all have had to learn.
#
# The one thing it does require is that `java` be a JDK rather than a JRE.
# .github/workflows/verify-puzzles.yml already installs temurin 21 through
# actions/setup-java, which is a JDK, so CI needs no change. scripts/bootstrap
# checks for `java` and says "Java 17+", which a JRE satisfies, so a JRE-only
# machine reaches the 99 path below with the reason named.
#
# ONE SANY PARSE PER MODULE, ONE JVM FOR THE WHOLE RUN. Every path goes to one
# process. A JVM per definition is the fork-pressure defect this project has
# already shipped twice, and the tell is system time rather than user time.

set -uo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

DRIVER="harness/levels/Levels.java"
JAR="${TLA_JAR:-${HOME}/lib/tla2tools.jar}"

INDETERMINATE=99
TOKEN="CHECK_DID_NOT_RUN"

# A literal tab, so the row-kind greps anchor on the field separator rather
# than on a word boundary a definition name could reach.
TAB=$'\t'

CORPUS=0
PASS_ALL=0
DEFS_ONLY=0
TALLY=0
MODULES=()

# Prints the header down to the sentinel rather than a line range, so editing
# the header above cannot leave --help cut off mid-section or running into the
# next one. A hardcoded line number here is the same shape of rot as a
# hardcoded suite count.
usage() {
  awk 'NR == 1 { next } /^# ===== end of usage/ { exit } { print }' "${BASH_SOURCE[0]}"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
  --corpus) CORPUS=1 ;;
  --all) PASS_ALL=1 ;;
  --defs-only) DEFS_ONLY=1 ;;
  --tally) TALLY=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    echo "levels.sh: unknown option '$1' (try --help)" >&2
    exit 2
    ;;
  *) MODULES+=("$1") ;;
  esac
  shift
done

if [ "$CORPUS" -eq 1 ]; then
  # Every reading model's module, by shape rather than by a list. A hardcoded
  # count is what rots the moment a model lands, so there is none here.
  while IFS= read -r m; do
    [ -n "$m" ] || continue
    MODULES+=("$m")
  done < <(find reading -type f -name '*.tla' | sort)
fi

if [ "${#MODULES[@]}" -eq 0 ]; then
  echo "levels.sh: no modules given (pass paths, or --corpus)" >&2
  exit 2
fi

if ! command -v java >/dev/null 2>&1; then
  echo "levels.sh: ${TOKEN}: java is not on the path. Run: bash scripts/bootstrap" >&2
  exit "$INDETERMINATE"
fi

if [ ! -f "$JAR" ]; then
  echo "levels.sh: ${TOKEN}: no tla2tools.jar at ${JAR}. Run: bash scripts/setup" >&2
  exit "$INDETERMINATE"
fi

if [ ! -f "$DRIVER" ]; then
  echo "levels.sh: ${TOKEN}: the driver ${DRIVER} is missing" >&2
  exit "$INDETERMINATE"
fi

SCRATCH="$(mktemp -d -t tla_levels.XXXXXX)"
# shellcheck disable=SC2317  # reached through the EXIT trap on the next line
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT

ERRFILE="${SCRATCH}/err"
DECLFILE="${SCRATCH}/declared"

# --- the declared obligations, keyed by the module's PATH ------------------
# Keyed by path rather than by module name so two models that happen to share
# a module name cannot borrow each other's obligations.
: >"$DECLFILE"
for m in "${MODULES[@]}"; do
  cfg="${m%.tla}.cfg"
  if [ ! -f "$cfg" ]; then
    printf 'NOCFG\t%s\n' "$m" >>"$DECLFILE"
    continue
  fi
  printf 'HASCFG\t%s\n' "$m" >>"$DECLFILE"
  # Strip `\*` line comments first, then take every operand after an anchored
  # keyword. A `(* ... *)` block comment carrying a keyword at line start is
  # not handled and does not occur in reading/; a declaration this misses
  # reads as `free`, which is the direction that shows up as a wrong item
  # rather than as a silently dropped one.
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    printf 'DECL\t%s\t%s\n' "$m" "$name" >>"$DECLFILE"
  done < <(sed 's/\\\*.*$//' "$cfg" |
    awk '/^[[:space:]]*(INVARIANTS?|PROPERTIES|PROPERTY)[[:space:]]+[A-Za-z_]/ {
           for (i = 2; i <= NF; i++) { print $i }
         }')
done

DRIVER_ARGS=()
if [ "$PASS_ALL" -eq 1 ]; then
  DRIVER_ARGS+=(--all)
fi

RAW=""
RC=0
RAW="$(java -cp "$JAR" "$DRIVER" "${DRIVER_ARGS[@]}" "${MODULES[@]}" 2>"$ERRFILE")"
RC=$?

ERR="$(cat "$ERRFILE")"

# A JRE runs the `java` launcher but refuses a .java source file, reporting
# that it has no compiler. That is the one failure here that is about the
# machine rather than about a module, so it gets the reserved code and a
# reason rather than a parse verdict.
if [ "$RC" -ne 0 ] && [ -n "$ERR" ]; then
  case "$ERR" in
  *"no compiler"* | *"Compilation failed"*)
    printf 'levels.sh: %s: this java cannot compile the source-mode driver.\n' "$TOKEN" >&2
    printf '  A JRE runs the java launcher but has no compiler. Install a JDK 17 or newer.\n' >&2
    printf '%s\n' "$ERR" >&2
    exit "$INDETERMINATE"
    ;;
  esac
fi

if [ -n "$ERR" ]; then
  printf '%s\n' "$ERR" >&2
fi

# --- annotate each DEF row with its obligation standing -------------------
# Streaming: a MOD row names the path every DEF row after it belongs to, so
# nothing here depends on module names being unique across the corpus.
OUT="$(awk -F'\t' -v OFS='\t' '
  FILENAME == DECL {
    if ($1 == "DECL")  { declared[$2 FS $3] = 1 }
    if ($1 == "HASCFG") { hascfg[$2] = 1 }
    next
  }
  $1 == "MOD" { path = $2; print; next }
  $1 == "DEF" {
    if (!(path in hascfg))               { $8 = "no-cfg" }
    else if ((path FS $3) in declared)   { $8 = "obligation" }
    else                                 { $8 = "free" }
    print
    next
  }
  { print }
' DECL="$DECLFILE" "$DECLFILE" - <<<"$RAW")"

if [ "$TALLY" -eq 1 ]; then
  printf 'level\tarity-0\tarity-1-plus\ttotal\tobligation\tfree\n'
  defs="$(grep -E "^DEF${TAB}" <<<"$OUT" || true)"
  for lvl in 0 1 2 3; do
    rows="$(awk -F'\t' -v L="$lvl" '$4 == L' <<<"$defs" || true)"
    n_total=0
    n_zero=0
    n_ob=0
    n_free=0
    if [ -n "$rows" ]; then
      n_total="$(wc -l <<<"$rows")"
      n_zero="$(awk -F'\t' '$5 == 0' <<<"$rows" | wc -l)"
      n_ob="$(awk -F'\t' '$8 == "obligation"' <<<"$rows" | wc -l)"
      n_free="$(awk -F'\t' '$8 == "free"' <<<"$rows" | wc -l)"
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$lvl" "$n_zero" "$((n_total - n_zero))" "$n_total" "$n_ob" "$n_free"
  done
  exit "$RC"
fi

if [ "$DEFS_ONLY" -eq 1 ]; then
  grep -E "^DEF${TAB}" <<<"$OUT" || true
else
  printf '%s\n' "$OUT"
fi

exit "$RC"
