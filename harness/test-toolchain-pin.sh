#!/usr/bin/env bash
# test-toolchain-pin.sh: the TLA+ toolchain pin is checked on download, and it
# says the same thing everywhere it is written down (bead tla-yvky).
#
# THE TWO INVARIANTS
#
#   1. The toolchain install checks the downloaded jar's sha256 against a
#      pinned digest. On a mismatch it exits non-zero and names both the
#      digest it wanted and the digest it got.
#
#   2. Every site carrying the pin agrees on the jar URL and on the sha256,
#      and this suite goes red when they diverge.
#
# WHY A DIGEST AND NOT A TAG
#
# Bead tla-5b4 pinned `TLA_RELEASE: v1.8.0` on the reading that a release tag
# names one artifact. For this tag it doesn't. Upstream flags v1.8.0 as a
# prerelease and rebuilds it in place, so three builds shipped under that one
# tag inside 22 days. CI went red on 2026-08-13 asserting a version the tag
# had stopped serving, and stayed red for 15 days.
#
# A tag is a name somebody else can rebind. A digest is not. So the pin moves
# to a self-hosted asset plus its sha256, and the install checks the digest
# instead of trusting the name. PIN_URL and PIN_SHA256 below are the whole
# pin, and every assertion in this file reads them from there.
#
# HOW INVARIANT 1 IS CHECKED WITHOUT A NETWORK
#
# scripts/test is offline, so this suite cannot download anything. The seam
# that makes the check runnable anyway is that scripts/setup honours the
# TLA_JAR_URL and TLA_JAR_SHA256 environment variables and falls back to the
# pinned values. Point TLA_JAR_URL at a `file://` URL for a stand-in jar in a
# temp directory, hand it a digest that does not match, and the behaviour is
# observable in full. curl reads `file://` the same way it reads https.
#
# The offline promise is enforced rather than hoped for. Both runs go through
# a curl shim on PATH that refuses any http or https argument, so a
# scripts/setup that ignores TLA_JAR_URL fails loudly here instead of quietly
# reaching the internet from inside the gate. That refusal is its own
# assertion below.
#
# HOME is a sandbox under the temp root for both runs, so nothing this suite
# does touches the real ~/lib/tla2tools.jar. That jar is the calibrated
# 2026.07.31.184830 build, it is no longer downloadable from anywhere, and
# every empirical constant in V2-PLAN.md section 5 was measured against it.
#
# THE STAND-IN JAR IS NOT A JAR, and the matching-digest run therefore still
# exits non-zero: setup installs it, asks it for its version, and gets nothing
# back. So the control for that run asserts on the installed file rather than
# on the exit code. What it establishes is that the mismatch above failed at
# the digest check and not at something incidental.
#
# WHICH SITES COUNT AS CARRYING THE PIN
#
# Five, not four. Four are the ones the bead names: the workflow,
# scripts/setup, scripts/cibuild, and scripts/build-docs.sh. README.md is the
# fifth, and it carries a full jar URL on line 55. scripts/cibuild phase 1
# already cross-checks that line, and scripts/build-docs.sh copies README.md
# verbatim into docs/index.md, so the URL there is what learners are told to
# install.
#
# UNRESOLVED IS NOT DIVERGED
#
# scripts/build-docs.sh builds its URL from a tag it reads back out of
# scripts/setup, on purpose, so that there is no fourth copy to drift
# (bead tla-urv). A site like that has nothing to compare, and this suite says
# so with a NOTE rather than a FAIL. The comparator substitutes only literal
# assignments from the same file, so a value that arrives from a command
# substitution stays unresolved and is reported as derived.
#
# THE CONTROLS
#
# Every assertion in part 2 has the shape "nothing here disagrees", which is
# also what a comparator that stopped reading files reports. Part 3 plants
# five synthetic sites in a temp directory and requires the comparator to get
# each one right: two that agree (one literal, one interpolated), two that
# diverge (one on the URL, one on the digest), and one that derives. The
# interpolated case is there to keep the comparator honest about an
# implementation that keeps the tag in its own variable, which is a shape the
# contract permits.
#
# Usage:  harness/test-toolchain-pin.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

# --- the pin ---------------------------------------------------------------
PIN_URL="https://github.com/fkberthold/tla-puzzles/releases/download/tla2tools-v1.8.0-20260731/tla2tools.jar"
PIN_SHA256="e22f8ffb4bacdea0a871f444dd94fe5fb0d8013b3388ae39e82e26f852c735d5"
# Byte size of the pinned asset. The stand-in jar is built to this size so the
# digest check is what the mismatch run trips, not a size check standing in
# front of it.
PIN_BYTES=4486015

SETUP="scripts/setup"
TEST_RUNNER="scripts/test"

PIN_SITES=(
  .github/workflows/verify-puzzles.yml
  scripts/setup
  scripts/cibuild
  scripts/build-docs.sh
  README.md
)

# A full jar URL, however it is quoted. The closing bracket is excluded so the
# markdown link in README.md ends where the link ends. Matching the whole URL
# rather than a fragment keeps the scan off the several comments that warn
# against `releases/latest/download/` without ever fetching it.
URL_RE='https://[^[:space:]"'"'"'`)]*tla2tools\.jar'
SHA_RE='\b[0-9a-f]{64}\b'

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }
note() { printf "  NOTE  %s\n" "$1"; }

TMPROOT=$(mktemp -d -t tla_pin.XXXXXX)
trap 'rm -rf "$TMPROOT"' EXIT

# ---------------------------------------------------------------------------
# PART 1: the install checks the digest.
# ---------------------------------------------------------------------------

echo "== part 1: the toolchain install checks the digest =="

REAL_CURL=$(command -v curl 2>/dev/null || true)
REAL_SHA=$(command -v sha256sum 2>/dev/null || true)

part1_ready=1
if [ -z "$REAL_CURL" ]; then
  nope "curl is on the path. Without it the download seam cannot be driven"
  part1_ready=0
fi
if [ -z "$REAL_SHA" ]; then
  nope "sha256sum is on the path. Without it the stand-in jar has no digest"
  part1_ready=0
fi

RUN_OUT=""
RUN_RC=0

# run_setup <home> <jar-url> <expected-sha256>
run_setup() {
  RUN_OUT=""
  RUN_RC=0
  RUN_OUT=$(HOME="$1" PATH="${SHIM_DIR}:${PATH}" \
    TLA_JAR_URL="$2" TLA_JAR_SHA256="$3" \
    bash "$SETUP" --no-docs 2>&1)
  RUN_RC=$?
  return 0
}

if [ "$part1_ready" -eq 1 ]; then
  # The offline guard. scripts/setup finds this before the real curl, so any
  # http or https fetch dies here and says which URL it was reaching for.
  SHIM_DIR="$TMPROOT/shim"
  mkdir -p "$SHIM_DIR"
  # The single quotes below are load-bearing. Every $ in this block is text
  # the shim resolves when it runs, so expanding any of it here would write
  # whatever this shell happens to hold into the file.
  # shellcheck disable=SC2016
  {
    printf '#!/usr/bin/env bash\n'
    printf '# Written by harness/test-toolchain-pin.sh. Offline guard.\n'
    printf 'for a in "$@"; do\n'
    printf '  case "$a" in\n'
    printf '  http://*|https://*)\n'
    printf '    printf "curl-shim: refusing to fetch %%s over the network\\n" "$a" >&2\n'
    printf '    exit 7\n'
    printf '    ;;\n'
    printf '  esac\n'
    printf 'done\n'
    printf 'exec %s "$@"\n' "$REAL_CURL"
  } >"$SHIM_DIR/curl"
  chmod +x "$SHIM_DIR/curl"

  FIXTURE="$TMPROOT/stand-in-tla2tools.jar"
  head -c "$PIN_BYTES" /dev/zero >"$FIXTURE"
  FIXTURE_SHA=$("$REAL_SHA" "$FIXTURE")
  FIXTURE_SHA=${FIXTURE_SHA%% *}
  # A digest that is 64 hex characters and is not the stand-in's, so a
  # mismatch is the only thing that can fail the run.
  WRONG_SHA="deadbeef${PIN_SHA256:8}"

  HOME_BAD="$TMPROOT/home-mismatch"
  mkdir -p "$HOME_BAD"
  run_setup "$HOME_BAD" "file://$FIXTURE" "$WRONG_SHA"

  if grep -qF -- "curl-shim: refusing" <<<"$RUN_OUT"; then
    nope "$SETUP reads TLA_JAR_URL. It went to the network for the jar instead"
  else
    ok "$SETUP reads TLA_JAR_URL and fetched the jar from there"
  fi

  if [ "$RUN_RC" -ne 0 ]; then
    ok "a digest mismatch exits non-zero (rc=$RUN_RC)"
  else
    nope "a digest mismatch exited 0"
  fi

  if grep -qF -- "$WRONG_SHA" <<<"$RUN_OUT"; then
    ok "a digest mismatch names the digest it wanted"
  else
    nope "a digest mismatch does not name the digest it wanted ($WRONG_SHA)"
  fi

  if grep -qF -- "$FIXTURE_SHA" <<<"$RUN_OUT"; then
    ok "a digest mismatch names the digest it got"
  else
    nope "a digest mismatch does not name the digest it got ($FIXTURE_SHA)"
  fi

  if [ -e "$HOME_BAD/lib/tla2tools.jar" ]; then
    nope "a digest mismatch installed the jar anyway"
  else
    ok "a digest mismatch installs nothing"
  fi

  HOME_OK="$TMPROOT/home-match"
  mkdir -p "$HOME_OK"
  run_setup "$HOME_OK" "file://$FIXTURE" "$FIXTURE_SHA"

  if [ -e "$HOME_OK/lib/tla2tools.jar" ]; then
    ok "control: a matching digest gets past the check and installs"
  else
    nope "control: a matching digest installed nothing, so the mismatch above may be failing for some other reason"
  fi
fi

# ---------------------------------------------------------------------------
# PART 2: every site says the same thing.
# ---------------------------------------------------------------------------

ASSIGN_KEYS=()
ASSIGN_VALS=()

# load_assignments <file>
#
# Collects NAME -> VALUE for every literal assignment in the file, in the
# shell form NAME=value and the YAML mapping form NAME: value. A value holding
# a dollar sign, a backtick, a bracket or a space is a command substitution or
# a sentence rather than a literal, so it is skipped. That is what keeps
# scripts/build-docs.sh out of the comparison: its tag arrives from a sed over
# scripts/setup, and there is nothing here to substitute it with.
load_assignments() {
  local file="$1" line name val sq dq
  sq="'"
  dq='"'
  ASSIGN_KEYS=()
  ASSIGN_VALS=()
  while IFS= read -r line || [ -n "$line" ]; do
    name=""
    val=""
    if [[ $line =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      name="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
    elif [[ $line =~ ^[[:space:]]*-?[[:space:]]*([A-Za-z_][A-Za-z0-9_]*):[[:space:]]+(.*)$ ]]; then
      name="${BASH_REMATCH[1]}"
      val="${BASH_REMATCH[2]}"
    fi
    [ -n "$name" ] || continue
    if [[ $val =~ ^${dq}(.*)${dq}$ ]]; then
      val="${BASH_REMATCH[1]}"
    elif [[ $val =~ ^${sq}(.*)${sq}$ ]]; then
      val="${BASH_REMATCH[1]}"
    fi
    case "$val" in
    "" | *'$'* | *'`'* | *'('* | *' '* | *'#'*) continue ;;
    esac
    ASSIGN_KEYS+=("$name")
    ASSIGN_VALS+=("$val")
  done <"$file"
  return 0
}

RESOLVED=""

# resolve_vars <text>
#
# Substitutes ${NAME} and $NAME from the assignments loaded for the current
# file. The braced form goes first so the bare form cannot eat half of it.
resolve_vars() {
  local s="$1" i k pat
  for i in "${!ASSIGN_KEYS[@]}"; do
    k="${ASSIGN_KEYS[$i]}"
    pat="\${${k}}"
    s="${s//"$pat"/${ASSIGN_VALS[$i]}}"
    pat="\$${k}"
    s="${s//"$pat"/${ASSIGN_VALS[$i]}}"
  done
  RESOLVED="$s"
  return 0
}

SV_URLS=()
SV_UNRESOLVED=()
SV_BAD_URLS=()
SV_SHAS=()
SV_BAD_SHAS=()

# scan_site <file>
scan_site() {
  local file="$1" u h out
  SV_URLS=()
  SV_UNRESOLVED=()
  SV_BAD_URLS=()
  SV_SHAS=()
  SV_BAD_SHAS=()

  load_assignments "$file"

  out=$(grep -oE -- "$URL_RE" "$file" 2>/dev/null || true)
  if [ -n "$out" ]; then
    while IFS= read -r u; do
      [ -n "$u" ] || continue
      resolve_vars "$u"
      case "$RESOLVED" in
      *'$'*)
        SV_UNRESOLVED+=("$RESOLVED")
        continue
        ;;
      esac
      SV_URLS+=("$RESOLVED")
      if [ "$RESOLVED" != "$PIN_URL" ]; then
        SV_BAD_URLS+=("$RESOLVED")
      fi
    done <<<"$out"
  fi

  out=$(grep -oE -- "$SHA_RE" "$file" 2>/dev/null || true)
  if [ -n "$out" ]; then
    while IFS= read -r h; do
      [ -n "$h" ] || continue
      SV_SHAS+=("$h")
      if [ "$h" != "$PIN_SHA256" ]; then
        SV_BAD_SHAS+=("$h")
      fi
    done <<<"$out"
  fi
  return 0
}

site_has_pin_url() {
  local u
  for u in "${SV_URLS[@]}"; do
    if [ "$u" = "$PIN_URL" ]; then
      return 0
    fi
  done
  return 1
}

site_has_pin_sha() {
  local h
  for h in "${SV_SHAS[@]}"; do
    if [ "$h" = "$PIN_SHA256" ]; then
      return 0
    fi
  done
  return 1
}

echo
echo "== part 2: every site carrying the pin agrees =="

# The floor. Agreement alone is satisfied by a tree that records the pin
# nowhere, so one site has to hold both halves. scripts/setup is that site:
# scripts/build-docs.sh already reads the tag back out of it, scripts/cibuild
# phase 1 compares against it, and the environment overrides in part 1 fall
# back to what it declares.
scan_site "$SETUP"

if site_has_pin_url; then
  ok "$SETUP names the pinned jar URL"
else
  nope "$SETUP does not name the pinned jar URL $PIN_URL"
fi

if site_has_pin_sha; then
  ok "$SETUP names the pinned sha256"
else
  nope "$SETUP does not name the pinned sha256 $PIN_SHA256"
fi

for site in "${PIN_SITES[@]}"; do
  if [ ! -f "$site" ]; then
    nope "$site exists"
    continue
  fi
  scan_site "$site"

  if [ "${#SV_BAD_URLS[@]}" -eq 0 ]; then
    ok "$site names no jar URL other than the pin"
  else
    nope "$site names a jar URL that is not the pin"
    for u in "${SV_BAD_URLS[@]}"; do
      printf "          %s\n" "$u"
    done
    printf "          wanted %s\n" "$PIN_URL"
  fi

  if [ "${#SV_BAD_SHAS[@]}" -eq 0 ]; then
    ok "$site names no sha256 other than the pin"
  else
    nope "$site names a sha256 that is not the pin"
    for h in "${SV_BAD_SHAS[@]}"; do
      printf "          %s\n" "$h"
    done
    printf "          wanted %s\n" "$PIN_SHA256"
  fi

  if [ "${#SV_UNRESOLVED[@]}" -ne 0 ]; then
    note "$site derives ${#SV_UNRESOLVED[@]} jar URL(s) from outside the file, so there is no copy to compare"
  fi
done

# ---------------------------------------------------------------------------
# PART 3: the comparator still bites.
# ---------------------------------------------------------------------------

echo
echo "== part 3: the comparator still bites =="

CTRL="$TMPROOT/controls"
mkdir -p "$CTRL"

{
  printf '#!/usr/bin/env bash\n'
  printf 'TLA_JAR_URL="%s"\n' "$PIN_URL"
  printf 'TLA_JAR_SHA256="%s"\n' "$PIN_SHA256"
} >"$CTRL/agrees-literal.sh"

{
  printf '#!/usr/bin/env bash\n'
  printf 'TLA_JAR_TAG="tla2tools-v1.8.0-20260731"\n'
  # The braces are fixture text the comparator reads back, so they must reach
  # the file unexpanded.
  # shellcheck disable=SC2016
  printf 'TLA_JAR_URL="https://github.com/fkberthold/tla-puzzles/releases/download/${TLA_JAR_TAG}/tla2tools.jar"\n'
  printf 'TLA_JAR_SHA256="%s"\n' "$PIN_SHA256"
} >"$CTRL/agrees-interpolated.sh"

{
  printf '#!/usr/bin/env bash\n'
  printf 'TLA_JAR_URL="https://github.com/fkberthold/tla-puzzles/releases/download/tla2tools-v1.8.0-20260901/tla2tools.jar"\n'
  printf 'TLA_JAR_SHA256="%s"\n' "$PIN_SHA256"
} >"$CTRL/diverged-url.sh"

{
  printf '#!/usr/bin/env bash\n'
  printf 'TLA_JAR_URL="%s"\n' "$PIN_URL"
  # The digest the rolling v1.8.0 tag served on 2026-08-28, which is the drift
  # this whole suite exists to catch.
  printf 'TLA_JAR_SHA256="eabd140a70f49eb9305a3bd3f3df944eddf87e5a90d329789085f8953a80533a"\n'
} >"$CTRL/diverged-sha.sh"

{
  printf '#!/usr/bin/env bash\n'
  # As above, the braces are fixture text. This file has no assignment for the
  # tag, which is what makes it the derived case.
  # shellcheck disable=SC2016
  printf 'TLA_JAR_URL="https://github.com/fkberthold/tla-puzzles/releases/download/${TLA_JAR_TAG}/tla2tools.jar"\n'
} >"$CTRL/derives.sh"

scan_site "$CTRL/agrees-literal.sh"
if site_has_pin_url && site_has_pin_sha \
  && [ "${#SV_BAD_URLS[@]}" -eq 0 ] && [ "${#SV_BAD_SHAS[@]}" -eq 0 ]; then
  ok "control: a site holding the pin as literals reads as agreeing"
else
  nope "control: a site holding the pin as literals did not read as agreeing"
fi

scan_site "$CTRL/agrees-interpolated.sh"
if site_has_pin_url && [ "${#SV_BAD_URLS[@]}" -eq 0 ] && [ "${#SV_UNRESOLVED[@]}" -eq 0 ]; then
  ok "control: a site holding the tag in its own variable resolves and agrees"
else
  nope "control: a site holding the tag in its own variable was not resolved, so the comparator would cry wolf on an interpolated pin"
fi

scan_site "$CTRL/diverged-url.sh"
if [ "${#SV_BAD_URLS[@]}" -ne 0 ]; then
  ok "control: a diverged jar URL is caught"
else
  nope "control: a diverged jar URL was NOT caught, so the URL half of part 2 is vacuous"
fi

scan_site "$CTRL/diverged-sha.sh"
if [ "${#SV_BAD_SHAS[@]}" -ne 0 ]; then
  ok "control: a diverged sha256 is caught"
else
  nope "control: a diverged sha256 was NOT caught, so the digest half of part 2 is vacuous"
fi

scan_site "$CTRL/derives.sh"
if [ "${#SV_UNRESOLVED[@]}" -ne 0 ] && [ "${#SV_BAD_URLS[@]}" -eq 0 ]; then
  ok "control: a site that derives its URL reads as derived, not as diverged"
else
  nope "control: a site that derives its URL was read as diverged, which would fail scripts/build-docs.sh for doing the right thing"
fi

# ---------------------------------------------------------------------------
# Registration.
# ---------------------------------------------------------------------------

echo
echo "== structural =="

# Read the SUITES array rather than the whole file, so a mention of this suite
# in a comment cannot stand in for a row that actually runs it.
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"fast[|][^|]*[|][^|]*[|]\./harness/test-toolchain-pin\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif grep -qE -- "$SUITE_ROW" <<<"$SUITES_BLOCK"; then
  ok "SUITES carries a fast-tier row for ./harness/test-toolchain-pin.sh"
else
  nope "SUITES carries no fast-tier row for ./harness/test-toolchain-pin.sh"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
