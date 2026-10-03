#!/usr/bin/env bash
# test-build-docs-exercises.sh: executable spec for the exercises section of
# scripts/build-docs.sh (bead tla-jaob.1).
#
# Pins the RED invariant from the bead:
#
#   every chapter directory under exercises/ carrying an EXERCISES.md has a
#   page in the built site, adding a chapter without touching the generator
#   produces a page for it, and no page in that section contains a relative
#   link that resolves to nothing.
#
# Three halves, and the middle one is why this suite is more than a file-exists
# check.
#
# THE SECOND HALF IS PERFORMED, NOT ASSERTED. Nothing below names the number
# twelve. Part 1 derives the expected chapter set from the real tree with its
# own glob, so it is an independent oracle rather than the generator agreeing
# with itself. Part 2 then builds a fixture tree carrying ch07, a ch14 that
# does not exist in the real repo, a ch09 with no EXERCISES.md, a templates/
# and an appendix/, and requires the derivation to give exactly 07 and 14.
# Then it creates ch15 with the generator untouched and requires the page set
# to become 07 14 15. That is the assertion that keeps working when ch.14
# lands for real, and bead tla-i3zu measured why it is needed: narrowing the
# glob left ITS real-tree assertion passing, because the expected set shrank
# to match the derived set. A real-tree comparison alone agrees with itself.
#
# WHY THE DERIVATION IS DUPLICATED RATHER THAN SHARED. harness/test-printed-
# commands.sh:148-165 carries derive_chapters, scripts/build-docs.sh now
# carries derive_exercise_chapters, and Part 1 below carries a third copy. The
# third one is deliberate and is not drift: a test that imported the
# generator's own derivation could not catch a narrowed glob, which is the
# exact failure tla-i3zu planted. The first two are duplication the bead's
# Files: line forced, and they are flagged in both files.
#
# THE REAL docs/ IS NEVER TOUCHED. Every generator run here happens in a
# throwaway mini-repo built out of symlinks, with an EMPTY puzzles/ so the
# 107-puzzle pass and its python3 calls do not run. That keeps the suite in
# the fast tier and keeps a developer's docs/ tree out of it. It also means
# the generator is exercised through its real entry point rather than through
# a knob added for the test: it resolves its root from the path it was invoked
# by, so a mini-repo is enough to redirect it. A generator that hardcoded
# /home/frank/repos/tla-puzzles would fail Part 2 outright.
#
# THE LINK CHECKER HAS A NEGATIVE CONTROL. Every link assertion is of the form
# "this resolves", and a checker that extracted nothing would report a clean
# sweep. Part 3 runs the same checker over a page carrying a deliberately dead
# relative link and requires it to report that link. Without that control the
# third half of the invariant could pass on an empty scan.
#
# WHAT IS DELIBERATELY NOT REWRITTEN. The printed shell commands in an
# EXERCISES.md are correct for a delivered practice tree and are gated, line
# for line, by harness/test-printed-commands.sh. Rewriting them for the web
# would put the site and that gate in disagreement. So Part 1 asserts every
# `How to run:` line survives into the page byte for byte, which protects that
# gate from this generator.
#
# Usage:  harness/test-build-docs-exercises.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

GENERATOR="scripts/build-docs.sh"
TEST_RUNNER="scripts/test"

# The URL bases the generator is expected to rewrite relative links to. Pinned
# here on purpose: the whole point of the rewrite is that the published form is
# predictable, so the test names it rather than accepting whatever appears.
GH_BLOB="https://github.com/fkberthold/tla-puzzles/blob/main"
GH_TREE="https://github.com/fkberthold/tla-puzzles/tree/main"

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }
note() { printf "  NOTE  %s\n" "$1"; }

TMP_ROOT=$(mktemp -d)
cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# mk_minirepo <dest> <exercises-source-or-empty>
#
# Builds the smallest tree scripts/build-docs.sh will run in: symlinks for
# everything it reads, a real empty puzzles/ so the puzzle pass is a no-op,
# and either a symlink to a given exercises/ tree or none at all.
#
# puzzles/ is empty rather than absent so the script's `puzzles/*/` glob stays
# literal and its `[ -f "$dir/README.md" ]` guard drops it, which is the same
# path an unmatched glob takes.
# ---------------------------------------------------------------------------
mk_minirepo() {
  local d="$1" ex="$2" f
  mkdir -p "$d/scripts" "$d/puzzles"
  ln -s "$REPO_ROOT/scripts/build-docs.sh" "$d/scripts/build-docs.sh"
  ln -s "$REPO_ROOT/scripts/setup" "$d/scripts/setup"
  if [ -f "$REPO_ROOT/scripts/build-concept-index.py" ]; then
    ln -s "$REPO_ROOT/scripts/build-concept-index.py" "$d/scripts/build-concept-index.py"
  fi
  for f in README.md QUALITY_GATE.md CURRICULUM_MAP.md JUDGMENTS.md SCAFFOLDING_MAP.md LICENSE; do
    ln -s "$REPO_ROOT/$f" "$d/$f"
  done
  ln -s "$REPO_ROOT/module-docs" "$d/module-docs"
  if [ -n "$ex" ]; then
    ln -s "$ex" "$d/exercises"
  fi
}

# ---------------------------------------------------------------------------
# derive_pages <docs-exercises-dir>
#
# Sets PAGES to the chapter numbers that have a page in the built section,
# ascending. Independent of the generator's own derivation on purpose.
# ---------------------------------------------------------------------------
PAGES=()
derive_pages() {
  local d="$1" f n
  PAGES=()
  for f in "$d"/ch[0-9][0-9].md; do
    [ -f "$f" ] || continue
    n="${f##*/ch}"
    n="${n%.md}"
    PAGES+=("$n")
  done
}

# ---------------------------------------------------------------------------
# derive_sources <exercises-root>
#
# Sets SOURCES to the chapter numbers under the root that carry an
# EXERCISES.md, ascending. This is the suite's own oracle. It is a third copy
# of the glob in harness/test-printed-commands.sh and scripts/build-docs.sh,
# and the header says why it has to be.
# ---------------------------------------------------------------------------
SOURCES=()
derive_sources() {
  local root="$1" dir n
  SOURCES=()
  for dir in "$root"/ch[0-9][0-9]/; do
    [ -f "$dir/EXERCISES.md" ] || continue
    n="${dir%/}"
    n="${n##*/ch}"
    SOURCES+=("$n")
  done
}

# ---------------------------------------------------------------------------
# check_links <docs-dir>
#
# Sets BAD_LINKS to the "<page>: <target>" pairs whose relative link does not
# resolve to a file inside the built tree. A link is a candidate when its text
# is non-empty and its target carries no whitespace, which is what keeps TLA+
# written inside backticks out of the scan: `[](rung' = rung + 1)` has empty
# text AND a target with spaces, and `<>[](ENABLED ...)` the same.
#
# http, https, mailto and in-page anchors are out of scope. A site-absolute
# target is reported, since mkdocs resolves those against the site root and
# this generator never writes one.
# ---------------------------------------------------------------------------
BAD_LINKS=()
check_links() {
  local d="$1" page raw target base
  BAD_LINKS=()
  for page in "$d"/*.md; do
    [ -f "$page" ] || continue
    base=$(dirname "$page")
    while IFS= read -r raw; do
      [ -n "$raw" ] || continue
      target="${raw#*](}"
      target="${target%)}"
      case "$target" in
      http://*|https://*|mailto:*) continue ;;
      '#'*) continue ;;
      esac
      # Drop a trailing anchor. What has to resolve is the file.
      target="${target%%#*}"
      # A target that was nothing but an anchor is already handled above. An
      # empty one here means `](#frag)` reached us some other way. Skip it.
      [ -n "$target" ] || continue
      if [ ! -e "$base/$target" ]; then
        BAD_LINKS+=("$(basename "$page"): $raw")
      fi
    done < <(grep -oE '\[[^]]+\]\([^) 	]+\)' "$page" 2>/dev/null)
  done
}

# ---------------------------------------------------------------------------
# Part 1: the real exercises/ tree
# ---------------------------------------------------------------------------
echo "Part 1: every real chapter with an EXERCISES.md gets a page"

REAL=$TMP_ROOT/real
mk_minirepo "$REAL" "$REPO_ROOT/exercises"

if bash "$REAL/scripts/build-docs.sh" >"$TMP_ROOT/real.out" 2>"$TMP_ROOT/real.err"; then
  ok "generator ran clean against the real exercises/ tree"
else
  nope "generator exited non-zero against the real exercises/ tree. stderr: $(tail -3 "$TMP_ROOT/real.err")"
fi

REAL_DOCS=$REAL/docs/exercises

derive_sources "$REPO_ROOT/exercises"
REAL_SOURCES=("${SOURCES[@]}")

# Non-vacuity floor, not an equality. An empty derivation would make every
# per-chapter assertion below vacuous and the suite would report a clean
# sweep. Ten is a floor the tree passed long before this bead and is not a
# claim about how many chapters exist.
if [ "${#REAL_SOURCES[@]}" -ge 10 ]; then
  ok "real tree derives ${#REAL_SOURCES[@]} chapters, at or above the floor of 10"
else
  nope "real tree derives only ${#REAL_SOURCES[@]} chapters, so the per-chapter assertions below would be vacuous"
fi

if [ -d "$REAL_DOCS" ]; then
  ok "docs/exercises/ exists"
else
  nope "docs/exercises/ does not exist"
fi

derive_pages "$REAL_DOCS"
if [ "${PAGES[*]}" = "${REAL_SOURCES[*]}" ]; then
  ok "page set equals the derived chapter set (${REAL_SOURCES[*]})"
else
  nope "page set [${PAGES[*]}] does not equal the derived chapter set [${REAL_SOURCES[*]}]"
fi

if [ -e "$REAL_DOCS/templates.md" ]; then
  nope "exercises/templates/ got a page, and it carries an EXERCISES.md without being a chapter"
else
  ok "exercises/templates/ got no page"
fi

for ch in "${REAL_SOURCES[@]}"; do
  src="$REPO_ROOT/exercises/ch$ch"
  page="$REAL_DOCS/ch$ch.md"

  if [ ! -f "$page" ]; then
    nope "ch$ch: no page at docs/exercises/ch$ch.md"
    continue
  fi
  ok "ch$ch: page exists"

  src_h1=$(grep -m1 '^# ' "$src/EXERCISES.md")
  page_h1=$(grep -m1 '^# ' "$page")
  if [ "$src_h1" = "$page_h1" ]; then
    ok "ch$ch: page H1 is the source H1 verbatim"
  else
    nope "ch$ch: page H1 [$page_h1] is not the source H1 [$src_h1]"
  fi

  # Every printed harness command survives byte for byte. This is the
  # assertion that protects harness/test-printed-commands.sh from this
  # generator.
  #
  # The line is selected by the harness it names rather than by the `How to
  # run:` label. Four chapters put the label and the command on one line and
  # three put the command on the next line, so a label match reads zero
  # commands in ch07, ch12 and ch13 and reports a clean sweep over them.
  runlines=$(grep -c 'verdict\.sh' "$src/EXERCISES.md")
  missing=0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    if ! grep -qxF -- "$line" "$page"; then
      missing=$((missing + 1))
    fi
  done < <(grep 'verdict\.sh' "$src/EXERCISES.md")
  if [ "$runlines" -lt 3 ]; then
    nope "ch$ch: only $runlines lines naming verdict.sh in the source, too few to be checking anything"
  elif [ "$missing" -eq 0 ]; then
    ok "ch$ch: all $runlines printed harness commands survive into the page verbatim"
  else
    nope "ch$ch: $missing of $runlines printed harness commands did not survive into the page"
  fi

  # The TLA+ guard. A box operator written inside backticks, `[](rung' = rung
  # + 1)`, is link-shaped to a line-based rewriter. Count the shapes whose
  # target holds whitespace in both files and require the count to be equal,
  # so a rewriter that mangled one is caught without naming how many there are.
  #
  # The page carries the cheat sheet too, and two of ch12's four shapes live
  # there, so both source files count.
  # Count occurrences, not matching lines. `grep -c` counts lines even with
  # -o, and ch12 puts two of these on one line.
  src_tla=$(grep -hoE '\]\([^)]*[[:space:]][^)]*\)' "$src/EXERCISES.md" "$src/CHEATSHEET.md" 2>/dev/null | wc -l)
  page_tla=$(grep -hoE '\]\([^)]*[[:space:]][^)]*\)' "$page" | wc -l)
  if [ "$src_tla" -eq "$page_tla" ]; then
    ok "ch$ch: $src_tla link-shaped TLA+ expressions preserved"
  else
    nope "ch$ch: $src_tla link-shaped TLA+ expressions in the source, $page_tla in the page"
  fi

  if [ -f "$src/CHEATSHEET.md" ]; then
    if grep -qF '## Cheat sheet' "$page"; then
      ok "ch$ch: page carries the chapter cheat sheet"
    else
      nope "ch$ch: CHEATSHEET.md exists but the page has no '## Cheat sheet' section"
    fi
  fi
done

if [ -f "$REAL_DOCS/index.md" ]; then
  ok "docs/exercises/index.md exists"
  idx_missing=0
  for ch in "${REAL_SOURCES[@]}"; do
    grep -qF "ch$ch.md" "$REAL_DOCS/index.md" || idx_missing=$((idx_missing + 1))
  done
  if [ "$idx_missing" -eq 0 ]; then
    ok "docs/exercises/index.md links every chapter page"
  else
    nope "docs/exercises/index.md is missing $idx_missing chapter links"
  fi
else
  nope "docs/exercises/index.md does not exist"
fi

if [ -f "$REAL_DOCS/.pages" ]; then
  ok "docs/exercises/.pages exists"
  nav_missing=0
  for ch in "${REAL_SOURCES[@]}"; do
    grep -qF "ch$ch.md" "$REAL_DOCS/.pages" || nav_missing=$((nav_missing + 1))
  done
  if [ "$nav_missing" -eq 0 ]; then
    ok "docs/exercises/.pages lists every chapter page"
  else
    nope "docs/exercises/.pages is missing $nav_missing chapter entries"
  fi
else
  nope "docs/exercises/.pages does not exist"
fi

if [ -f "$REAL/docs/.pages" ]; then
  if grep -qE '^[[:space:]]*-[[:space:]]*exercises[[:space:]]*$' "$REAL/docs/.pages"; then
    ok "top-level docs/.pages carries the exercises section"
  else
    nope "top-level docs/.pages does not carry an 'exercises' nav entry"
  fi
else
  nope "top-level docs/.pages does not exist"
fi

check_links "$REAL_DOCS"
if [ "${#BAD_LINKS[@]}" -eq 0 ]; then
  ok "no relative link in the real section resolves to nothing"
else
  nope "${#BAD_LINKS[@]} dead relative link(s) in the real section: ${BAD_LINKS[0]}"
fi

# ---------------------------------------------------------------------------
# Part 2: the derivation, performed on a fixture tree
# ---------------------------------------------------------------------------
echo
echo "Part 2: the chapter list comes from the tree, not from a list"

FIX_EX=$TMP_ROOT/fixture-exercises
mkdir -p "$FIX_EX/ch07/starters" "$FIX_EX/ch09" "$FIX_EX/ch14" \
         "$FIX_EX/templates" "$FIX_EX/appendix"

# ch07: a full chapter. Carries a cheat sheet, a starter, and one planted link
# of every shape the rewrite has to handle.
cat > "$FIX_EX/ch07/EXERCISES.md" <<'FIXTURE'
# Chapter 07 exercises: Fixture Topic

A fixture chapter. Edit [the starter](starters/Ex1Fixture.tla), the rest of
them live in [starters](starters), and the [cheat sheet](CHEATSHEET.md) names
the constructs. This page is [itself](EXERCISES.md) and chapter fourteen is
[next door](../ch14/EXERCISES.md). One starter is
[Ex2+Fix.tla](starters/Ex2+Fix.tla), whose name carries a regex
metacharacter.

A box operator is link-shaped and must survive: `RungUp == [](rung = 1)`.

## Exercise 1

- Title: `Fixture one`
- How to run: `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex1Fixture.tla`

## Exercise 2

- Title: `Fixture two`
- How to run: `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex2Fixture.tla`

## Exercise 3

- Title: `Fixture three`
- How to run: `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex3Fixture.tla`
FIXTURE

cat > "$FIX_EX/ch07/CHEATSHEET.md" <<'FIXTURE'
# Chapter 07 cheat sheet: Fixture Topic

## Constructs introduced

- Construct: `Fixture construct`
FIXTURE

echo '---- MODULE Ex1Fixture ----' > "$FIX_EX/ch07/starters/Ex1Fixture.tla"
# A filename carrying a regex metacharacter. The rewrite builds an ERE pattern
# out of the target, so an unescaped + would make this link match nothing and
# ship relative.
echo '---- MODULE Ex2Fix ----' > "$FIX_EX/ch07/starters/Ex2+Fix.tla"

# ch09 carries no EXERCISES.md, so it is not a chapter for this purpose.
echo 'notes' > "$FIX_EX/ch09/NOTES.md"

# ch14 does not exist in the real repo. A generator carrying a literal list of
# today's chapters passes Part 1 and fails here.
cat > "$FIX_EX/ch14/EXERCISES.md" <<'FIXTURE'
# Chapter 14 exercises: Not Yet Real

A chapter that does not exist in the repo today.

## Exercise 1

- How to run: `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex1.tla`
FIXTURE

# templates/ carries an EXERCISES.md and is not a chapter. appendix/ is the
# shape nobody has created yet. Neither may get a page. The LOUD audit for an
# unexpected non-chapter directory lives in harness/test-printed-commands.sh
# (audit_non_chapters); this suite only pins that the generator does not
# publish one.
echo '# Template exercise set' > "$FIX_EX/templates/EXERCISES.md"
echo '# Appendix' > "$FIX_EX/appendix/EXERCISES.md"

FIXREPO=$TMP_ROOT/fixrepo
mk_minirepo "$FIXREPO" "$FIX_EX"

if bash "$FIXREPO/scripts/build-docs.sh" >"$TMP_ROOT/fix.out" 2>"$TMP_ROOT/fix.err"; then
  ok "generator ran clean against the fixture tree"
else
  nope "generator exited non-zero against the fixture tree. stderr: $(tail -3 "$TMP_ROOT/fix.err")"
fi

FIX_DOCS=$FIXREPO/docs/exercises

derive_pages "$FIX_DOCS"
if [ "${PAGES[*]}" = "07 14" ]; then
  ok "fixture derivation gives exactly 07 14"
else
  nope "fixture derivation gives [${PAGES[*]}], expected [07 14]"
fi

for unwanted in ch09 templates appendix; do
  if [ -e "$FIX_DOCS/$unwanted.md" ]; then
    nope "fixture: $unwanted got a page and must not have"
  else
    ok "fixture: $unwanted got no page"
  fi
done

if [ -f "$FIX_DOCS/.pages" ] && grep -qF 'ch14.md' "$FIX_DOCS/.pages"; then
  ok "fixture: .pages lists ch14.md"
else
  nope "fixture: .pages does not list ch14.md"
fi

# Now add a chapter with the generator untouched.
mkdir -p "$FIX_EX/ch15"
cat > "$FIX_EX/ch15/EXERCISES.md" <<'FIXTURE'
# Chapter 15 exercises: Added Mid-Suite

Created after the first build, with the generator untouched.

## Exercise 1

- How to run: `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ex1.tla`
FIXTURE

if bash "$FIXREPO/scripts/build-docs.sh" >>"$TMP_ROOT/fix.out" 2>>"$TMP_ROOT/fix.err"; then
  ok "generator ran clean after a chapter was added"
else
  nope "generator exited non-zero after a chapter was added"
fi

derive_pages "$FIX_DOCS"
if [ "${PAGES[*]}" = "07 14 15" ]; then
  ok "a new chapter produces a page with no generator change (07 14 15)"
else
  nope "after adding ch15 the page set is [${PAGES[*]}], expected [07 14 15]"
fi

if [ -f "$FIX_DOCS/.pages" ] && grep -qF 'ch15.md' "$FIX_DOCS/.pages"; then
  ok "nav picks up the new chapter too"
else
  nope "nav did not pick up ch15.md"
fi

# ---------------------------------------------------------------------------
# Part 3: the link rewrite, and a negative control for the checker
# ---------------------------------------------------------------------------
echo
echo "Part 3: delivered-tree links become links that work on the web"

FIXPAGE=$FIX_DOCS/ch07.md
if [ -f "$FIXPAGE" ]; then
  ok "fixture ch07 page exists to check links on"

  if grep -qF "[the starter]($GH_BLOB/exercises/ch07/starters/Ex1Fixture.tla)" "$FIXPAGE"; then
    ok "a starter file link points at the file on GitHub"
  else
    nope "a starter file link was not rewritten to $GH_BLOB/exercises/ch07/starters/Ex1Fixture.tla"
  fi

  if grep -qF "[Ex2+Fix.tla]($GH_BLOB/exercises/ch07/starters/Ex2+Fix.tla)" "$FIXPAGE"; then
    ok "a target carrying a regex metacharacter is escaped before it is matched"
  else
    nope "a target named Ex2+Fix.tla was not rewritten, so the ERE escape is wrong"
  fi

  # The whole link, text included. The page's own banner carries the same URL,
  # so a bare URL match passes whether the rewrite ran or not.
  if grep -qF "[starters]($GH_TREE/exercises/ch07/starters)" "$FIXPAGE"; then
    ok "a starters directory link points at the tree on GitHub"
  else
    nope "a starters directory link was not rewritten to $GH_TREE/exercises/ch07/starters"
  fi

  if grep -qF '](#cheat-sheet)' "$FIXPAGE"; then
    ok "a CHEATSHEET.md link becomes the in-page cheat-sheet anchor"
  else
    nope "a CHEATSHEET.md link was not rewritten to the in-page anchor"
  fi

  if grep -qF '](ch07.md)' "$FIXPAGE"; then
    ok "a link to the chapter's own EXERCISES.md becomes the page itself"
  else
    nope "a link to the chapter's own EXERCISES.md was not rewritten to ch07.md"
  fi

  if grep -qF '](ch14.md)' "$FIXPAGE"; then
    ok "a cross-chapter EXERCISES.md link becomes that chapter's page"
  else
    nope "a cross-chapter EXERCISES.md link was not rewritten to ch14.md"
  fi

  if grep -qF 'RungUp == [](rung = 1)' "$FIXPAGE"; then
    ok "a link-shaped TLA+ box operator survived the rewrite"
  else
    nope "the rewrite mangled a link-shaped TLA+ box operator"
  fi

  if grep -qF '## Cheat sheet' "$FIXPAGE"; then
    ok "the #cheat-sheet anchor has a heading to land on"
  else
    nope "the page points at #cheat-sheet and carries no such heading"
  fi
else
  nope "fixture ch07 page does not exist, so no link assertion ran"
fi

check_links "$FIX_DOCS"
if [ "${#BAD_LINKS[@]}" -eq 0 ]; then
  ok "no relative link in the fixture section resolves to nothing"
else
  nope "${#BAD_LINKS[@]} dead relative link(s) in the fixture section: ${BAD_LINKS[*]}"
fi

# Negative control. Every assertion above is "this resolves", so a checker that
# matched nothing would report a clean sweep. Give it a page that is dead on
# purpose and require it to say so.
CONTROL=$TMP_ROOT/control
mkdir -p "$CONTROL"
cat > "$CONTROL/page.md" <<'CONTROLDOC'
# Control

This is [a dead link](nosuchfile.md) and this is
[a live one](page.md). Neither `[](a = b)` nor <https://example.com> is a
candidate.
CONTROLDOC

check_links "$CONTROL"
if [ "${#BAD_LINKS[@]}" -eq 1 ]; then
  ok "the link checker reports the one deliberately dead link and not the live one"
else
  nope "the link checker reported ${#BAD_LINKS[@]} dead links on the control page, expected 1: ${BAD_LINKS[*]}"
fi

# ---------------------------------------------------------------------------
# Part 4: structural
# ---------------------------------------------------------------------------
echo
echo "Part 4: structural"

if [ -f "$GENERATOR" ]; then
  ok "$GENERATOR exists"
else
  nope "$GENERATOR does not exist"
fi

# The generator must not carry a literal chapter list. A grep is a weak check
# next to Part 2, and it is here for the error message rather than the
# coverage: a reviewer who adds a list gets told which rule it breaks.
#
# Comment lines are stripped first. The generator's own comment block explains
# why the list is derived, and it names ch02 and ch13 to do that, so a scan
# over the whole file fires on the explanation.
CODE_ONLY=$(grep -vE '^[[:space:]]*#' "$GENERATOR")
if grep -qE 'ch(02|03)[^0-9].*ch(12|13)[^0-9]' <<<"$CODE_ONLY"; then
  nope "$GENERATOR looks like it carries a literal chapter list"
else
  ok "$GENERATOR carries no literal chapter list"
fi

# Read the SUITES array rather than the whole file, so a mention of this suite
# in a comment cannot stand in for a row that actually runs it.
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"fast[|][^|]*[|][^|]*[|]\./harness/test-build-docs-exercises\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif grep -qE -- "$SUITE_ROW" <<<"$SUITES_BLOCK"; then
  ok "SUITES carries a fast-tier row for ./harness/test-build-docs-exercises.sh"
else
  nope "SUITES carries no fast-tier row for ./harness/test-build-docs-exercises.sh"
  note "scripts/test is outside this bead's Files: line. Central adds the row."
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
