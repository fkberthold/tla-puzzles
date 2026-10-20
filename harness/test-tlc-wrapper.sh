#!/usr/bin/env bash
# test-tlc-wrapper.sh: the generated ~/bin/tlc wrapper dispatches every mode
# the curriculum tells a learner to type, and its usage text still names the
# level 0 limit (bead tla-tyqy).
#
# THE INVARIANTS
#
#   1. The wrapper body in scripts/setup is valid bash.
#   2. It dispatches tlc2.TLC with no arguments, pcal.trans under -pcal, and
#      tlc2.REPL under -repl.
#   3. -h and -help reach TLC rather than the wrapper, because both print
#      TLC's own option list.
#   4. The usage text names level 0 and names the ENABLED answer.
#
# WHY THE BODY IS TESTED AND NOT THE INSTALLED FILE
#
# ~/bin/tlc is generated. It only exists on a machine where scripts/setup has
# run, so a gate that read it would have nothing to read in CI and would skip
# every run. The generator is tracked, so this suite reads the body out of
# scripts/setup instead and runs that. Nothing here needs $HOME, the pinned
# jar, or a network.
#
# WHY A FAKE java RATHER THAN A GREP FOR THE CLASS NAMES
#
# A grep over the body proves a string is present. It does not prove which
# branch reaches it, and the branch is the whole invariant. So the body runs
# against a java shim on PATH that prints its own arguments, and each
# assertion reads the class the wrapper actually chose. That costs no JVM and
# no jar, and it catches a mis-ordered branch that a grep passes.
#
# WHY INVARIANT 1 NEEDS A GATE OF ITS OWN
#
# The body is a single-quoted string inside scripts/setup, so shellcheck does
# not parse it. scripts/lint reads 28 files clean and says nothing about these
# 60 lines. A syntax error in the body therefore ships, and the first person
# to find it is a learner whose tlc stopped working. `bash -n` over the
# extracted body closes that, and it is the assertion I would keep if I could
# only keep one.
#
# WHY THE USAGE TEXT IS AN INVARIANT AND NOT A NICETY
#
# tlc2.REPL splits three ways on the pinned build, and only two are loud. A
# variable or a prime reports `Unknown operator`. A temporal operator reports
# a parse error. `ENABLED (1 = 1)` and `UNCHANGED 1` both return TRUE, because
# a constant expression is trivially enabled and trivially unchanged. The
# third case hands a false TRUE to the reader this curriculum teaches, so the
# limit is printed rather than discovered. A later edit that trims the usage
# text to save space would take that warning with it, which is what checks 8
# and 9 are here to stop.
#
# WHAT THIS SUITE DOES NOT READ, AND I THINK IT SHOULD
#
# scripts/build-docs.sh carries a SECOND wrapper body, hand-copied into the
# learner install instructions it emits for getting-started.md. Find it by the
# `cat > ~/bin/tlc <<WRAPPER` heredoc rather than by a line number, which
# moved by 24 lines inside the hour I wrote this. It has the -pcal branch and
# not the -repl one, so the published docs now tell a reader to install a
# wrapper the generator has moved past.
#
# That is the shape bead tla-urv removed from the same two files for the jar
# URL, and the fix there was to delete the copy rather than to sync it:
# build-docs.sh reads TLA_RELEASE back out of scripts/setup so that no second
# copy exists. The same fix fits here and it wants its own bead, because the
# extraction belongs in build-docs.sh and this suite only reads.
#
# So I left the copy uncovered on purpose rather than gating the divergence as
# correct. A gate that pinned today's difference would have to be deleted as
# step one of the real fix, and I would rather the hole be named here than
# cemented in an assertion. Named, not covered.
#
# THE FLOOR
#
# Check 1 is the floor. A gate whose scope is one file can be switched off by
# a rename, and the extraction coming back empty is how that looks. It fails
# rather than passing with nothing to say.
#
# THE CONTROLS
#
# Part 3 plants six mutated bodies and requires each check to fire on the one
# it owns: a dropped -repl branch, a misspelled class, a trimmed usage line, a
# usage branch in front of the no-argument dispatch, an apostrophe, and a
# syntax error. Every check in part 2 has the shape "nothing here is wrong",
# which is also what a checker that stopped reading reports.
#
# Usage:  harness/test-tlc-wrapper.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

SETUP="scripts/setup"
TEST_RUNNER="scripts/test"

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }
note() { printf "  NOTE  %s\n" "$1"; }

TMPROOT=$(mktemp -d -t tla_wrapper.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

# A java shim that reports what it was asked to run and starts no JVM.
mkdir -p "$TMPROOT/bin"
cat >"$TMPROOT/bin/java" <<'SHIM'
#!/usr/bin/env bash
printf 'JAVA_ARGS %s\n' "$*"
SHIM
chmod +x "$TMPROOT/bin/java"

# ---------------------------------------------------------------------------
# PART 1: get the body out of the generator.
# ---------------------------------------------------------------------------

echo "== part 1: the wrapper body comes out of ${SETUP} =="

# The body is the single-quoted argument to the tlc install_wrapper call. It
# starts after the first apostrophe on that line and ends on the next line
# that ends with one. Check 3 below is what keeps that terminator unambiguous.
extract_body() {
  local src="$1" raw
  raw=$(sed -n "/^install_wrapper \"\${BIN_DIR}\/tlc\" '/,/'\$/p" "$src")
  [ -n "$raw" ] || return 1
  sed -e "1s/^[^']*'//" -e "\$s/'\$//" <<<"$raw"
}

BODY=$(extract_body "$SETUP" || true)

if [ -z "$BODY" ]; then
  nope "check 1 (floor): no tlc wrapper body found in ${SETUP}. Every check below reads it, so nothing else can run"
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
ok "check 1 (floor): extracted a $(wc -l <<<"$BODY")-line tlc wrapper body from ${SETUP}"

# Materialize the body as a runnable wrapper.
WRAPPER="$TMPROOT/tlc"
printf '%s\n' "$BODY" >"$WRAPPER"
chmod +x "$WRAPPER"

# --- the predicates, each used once in part 2 and once per control ---------

# p_syntax <file>: bash parses it.
p_syntax() { bash -n "$1" 2>/dev/null; }

# p_noquote <file>: no apostrophe, which would end the string early in setup.
p_noquote() { ! grep -qF -- "'" "$1"; }

# p_says <file> <extended-regex>: the usage text carries a pattern. Reads the
# -repl help output rather than the file, so a line moved into a comment does
# not count as printed.
#
# CASE-SENSITIVE ON PURPOSE. It was case-insensitive for one run and its own
# control caught it: with `-i`, deleting every ENABLED line still passed,
# because the paragraph underneath says "trivially enabled" in lowercase. An
# operator name is not a word, and a check that cannot tell them apart passes
# on a usage text that has stopped naming the operator.
p_says() {
  local out
  out=$("$1" -repl -h 2>&1 </dev/null || true)
  grep -qE -- "$2" <<<"$out"
}

# dispatch_of <file> <args...>: the class the wrapper chose, or the empty
# string when it dispatched nothing.
dispatch_of() {
  local w="$1"; shift
  local out
  out=$(PATH="$TMPROOT/bin:$PATH" "$w" "$@" 2>&1 </dev/null || true)
  sed -n 's/^JAVA_ARGS .*[[:space:]]\(tlc2\.[A-Za-z]*\|pcal\.trans\)\([[:space:]].*\)*$/\1/p' <<<"$out"
}

# ---------------------------------------------------------------------------
# PART 2: the invariants hold on the real body.
# ---------------------------------------------------------------------------

echo
echo "== part 2: the invariants hold =="

if p_syntax "$WRAPPER"; then
  ok "check 2: bash -n accepts the wrapper body, which shellcheck never reads"
else
  nope "check 2: bash -n rejects the wrapper body. The generated ~/bin/tlc would be broken on every machine scripts/setup touches"
fi

if p_noquote "$WRAPPER"; then
  ok "check 3: the body carries no apostrophe, so the single-quoted string in ${SETUP} stays closed"
else
  nope "check 3: the body carries an apostrophe. It is a single-quoted string in ${SETUP}, so that ends the string early"
fi

check_dispatch() {
  local label="$1" want="$2"; shift 2
  local got
  got=$(dispatch_of "$WRAPPER" "$@")
  if [ "$got" = "$want" ]; then
    ok "check ${label}: ${want}"
  else
    nope "check ${label}: wanted ${want}, got '${got:-nothing}'"
  fi
}

check_dispatch "4 (no arguments reaches TLC, which is what the pin assertion in ${SETUP} reads a version out of)" tlc2.TLC
check_dispatch "5 (-pcal reaches the translator)" pcal.trans -pcal Foo.tla
check_dispatch "6 (-repl reaches the REPL)" tlc2.REPL -repl '1 + 1'
check_dispatch "7 (-h stays TLC's own, it prints the option list)" tlc2.TLC -h
check_dispatch "7b (-help stays TLC's own)" tlc2.TLC -help

if p_says "$WRAPPER" 'level 0'; then
  ok "check 8: the usage text names level 0"
else
  nope "check 8: the usage text does not name level 0. That limit is the reason this mode is worth exposing (bead tla-tyqy)"
fi

if p_says "$WRAPPER" 'ENABLED'; then
  ok "check 9: the usage text names ENABLED, which answers TRUE over a constant and says nothing"
else
  nope "check 9: the usage text does not name ENABLED. It returns TRUE over any constant, and that false TRUE is the trap this text exists to head off"
fi

# The no-argument -repl case warns before it hands over, so a learner who
# never types -h still reads the limit once per session.
repl_bare=$(PATH="$TMPROOT/bin:$PATH" "$WRAPPER" -repl 2>&1 </dev/null || true)
if grep -qiE -- 'level 0' <<<"$repl_bare"; then
  ok "check 10: bare -repl prints the limit before it starts the prompt"
else
  nope "check 10: bare -repl starts the prompt without naming the limit"
fi

if grep -qF -- 'tlc2.REPL' <<<"$repl_bare"; then
  ok "check 11: bare -repl still reaches the REPL after warning"
else
  nope "check 11: bare -repl warned and then dispatched nothing"
fi

# An unquoted expression arrives as several arguments, and tlc2.REPL ignores
# all of them and opens the prompt. Measured on the pinned build. The wrapper
# refuses instead, because a silently ignored expression looks like it ran.
mult_rc=0
PATH="$TMPROOT/bin:$PATH" "$WRAPPER" -repl 1 + 1 >/dev/null 2>&1 </dev/null || mult_rc=$?
if [ "$mult_rc" -eq 2 ]; then
  ok "check 12: an unquoted multi-word expression is refused with rc 2 rather than silently dropped"
else
  nope "check 12: an unquoted multi-word expression gave rc ${mult_rc}, so tlc2.REPL got it and ignored it"
fi

# ---------------------------------------------------------------------------
# PART 3: the controls. Each mutant must trip the check that owns it.
# ---------------------------------------------------------------------------

echo
echo "== part 3: controls =="

# mutant <name> <sed-program>
mutant() {
  local prog="$2" path="$TMPROOT/mutant-$1"
  sed -e "$prog" "$WRAPPER" >"$path"
  chmod +x "$path"
  printf '%s' "$path"
}

m_class=$(mutant class 's/tlc2\.REPL/tlc2.NOPE/')
if [ "$(dispatch_of "$m_class" -repl '1 + 1')" != "tlc2.REPL" ]; then
  ok "control: a misspelled REPL class is seen as not dispatching tlc2.REPL"
else
  nope "control: a misspelled REPL class still read as tlc2.REPL, so check 6 proves nothing"
fi

# The apostrophe has to be a real one. This control passed on its first run
# with a mutant whose comment read "it cannot be written this way", because I
# wrote the mutant in the same apostrophe-free style the body is written in
# and so mutated nothing.
m_quote=$(mutant quote "2a# it can't be written this way")
if ! p_noquote "$m_quote"; then
  ok "control: an apostrophe in the body is caught"
else
  nope "control: an apostrophe in the body passed check 3"
fi

# The single quotes are load-bearing: `$a` is sed's append command and has to
# reach sed unexpanded.
# shellcheck disable=SC2016
m_syntax=$(mutant syntax '$a if [ 1 = 1 ]; then')
if ! p_syntax "$m_syntax"; then
  ok "control: an unterminated if is caught by bash -n"
else
  nope "control: an unterminated if passed check 2, so check 2 proves nothing"
fi

m_level=$(mutant level '/level 0/d')
if ! p_says "$m_level" 'level 0'; then
  ok "control: a usage text with the level 0 lines cut is caught"
else
  nope "control: cutting every level 0 line still passed check 8"
fi

m_enabled=$(mutant enabled '/ENABLED/d')
if ! p_says "$m_enabled" 'ENABLED'; then
  ok "control: a usage text with the ENABLED lines cut is caught"
else
  nope "control: cutting every ENABLED line still passed check 9"
fi

# The one that protects the pin assertion 40 lines below the wrapper in
# scripts/setup: a usage-on-no-arguments branch is a reasonable-looking edit
# that breaks a check nothing connects to it.
# Load-bearing single quotes again. The `\$1` and `$#` are the wrapper's own
# text, which sed matches and inserts literally.
# shellcheck disable=SC2016
m_bare=$(mutant bare '/^if \[ "\$1" = "-pcal" \]; then$/i if [ "$#" -eq 0 ]; then repl_usage; exit 0; fi')
if [ "$(dispatch_of "$m_bare")" != "tlc2.TLC" ]; then
  ok "control: a usage-on-no-arguments branch is seen as not reaching tlc2.TLC"
else
  nope "control: a usage-on-no-arguments branch still read as reaching tlc2.TLC, so check 4 does not protect the pin assertion"
fi

# ---------------------------------------------------------------------------
# Registration.
# ---------------------------------------------------------------------------

echo
echo "== structural =="

# Read the SUITES array rather than the whole file, so a mention of this suite
# in a comment cannot stand in for a row that actually runs it.
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"fast[|][^|]*[|][^|]*[|]\./harness/test-tlc-wrapper\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif grep -qE -- "$SUITE_ROW" <<<"$SUITES_BLOCK"; then
  ok "SUITES carries a fast-tier row for ./harness/test-tlc-wrapper.sh"
else
  nope "SUITES carries no fast-tier row for ./harness/test-tlc-wrapper.sh"
fi

note "the second wrapper body in scripts/build-docs.sh is not read here. See the header."

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
