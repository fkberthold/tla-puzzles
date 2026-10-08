#!/usr/bin/env bash
# test-build-docs-chapter.sh: executable spec for the chapter section of
# scripts/build-docs.sh (bead tla-jaob.5).
#
# Pins the RED invariant from the bead:
#
#   every markdown file directly under chapter/ has a page in the built site,
#   adding one without touching the generator produces a page for it, every
#   file under chapter/snippets/ is reachable by a link from the section, and
#   no page in that section contains a relative link that resolves to nothing.
#
# The bead this suite closes is not "a page is missing". chapter/refinement.md
# and chapter/worked-example.md were written under tla-kl5.1, verified under
# tla-kl5.2, and then sat dark for five weeks with every gate in this repo
# green, because no gate looked at whether the generator had heard of them.
# That is the failure this file is here to make impossible a second time.
#
# THREE THINGS ARE PERFORMED RATHER THAN ASSERTED, and they are the reason
# this is more than a file-exists check.
#
# THE PAGE SET. Nothing below names refinement or worked-example. Part 1
# derives the expected set from the real tree with its own glob, so it is an
# independent oracle rather than the generator agreeing with itself. Part 2
# then builds a fixture chapter/ the real repo does not have and requires the
# page set to follow it, including after a page is created mid-run with the
# generator untouched. Bead tla-i3zu measured why that second half is needed:
# narrowing a derivation left its real-tree assertion passing, because the
# expected set shrank to match the derived set.
#
# THE READING ORDER. A chapter names the one that follows it — refinement.md
# ends in a "## Next" section linking worked-example.md — so the order is
# derivable and this suite requires it to be derived. Part 1 checks the
# invariant on the real tree (a page that links to another precedes it in the
# nav), and Part 2 checks it on a fixture where alphabetical order gets it
# WRONG. Alphabetical passes Part 1 today by luck, which is exactly why Part 1
# alone is not the assertion.
#
# THE LINK CHECKER HAS A NEGATIVE CONTROL. Every link assertion is of the form
# "this resolves", and a checker that extracted nothing would report a clean
# sweep. Part 3 runs the same checker over a page carrying a deliberately dead
# relative link and requires it to report that link.
#
# THE SNIPPET REACHABILITY CHECK IS THE POINT, NOT A NICETY. Both chapters
# link `snippets/` as a directory and link no file inside it, so without a
# per-file list a reader reaches a module only by browsing GitHub, and a
# module that stopped being referenced would go dark the same way the two
# chapters did. Part 1 requires every file under chapter/snippets/ to be named
# by a link on the section's index page, and Part 2 proves the list is globbed
# from the tree by adding a file to a fixture mid-run.
#
# WHAT IS DELIBERATELY NOT REWRITTEN. The content of a chapter page is passed
# through byte for byte apart from its relative links.
# chapter/snippets/check-blocks.py reconciles every ```tla block on these
# pages against the module it came from, and chapter/snippets/run-all.sh runs
# that reconciliation as a suite in this gate, so a generator that reflowed a
# block would put the site and that gate in disagreement. Part 1 asserts the
# H1 and the fenced-block count survive, which protects that gate from this
# generator.
#
# THE REAL docs/ IS NEVER TOUCHED. Every generator run here happens in a
# throwaway mini-repo built out of symlinks, with an EMPTY puzzles/ so the
# 107-puzzle pass and its python3 calls do not run, and no exercises/ at all.
# That keeps the suite in the fast tier and keeps a developer's docs/ tree out
# of it. It also exercises the generator through its real entry point: it
# resolves its root from the path it was invoked by, so a mini-repo is enough
# to redirect it, and a generator that hardcoded a checkout path would fail
# Part 2 outright. Bead tla-1hf fixed exactly that bug in a sibling script.
#
# Usage:  harness/test-build-docs-chapter.sh
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
# mk_minirepo <dest> <chapter-source-or-empty>
#
# Builds the smallest tree scripts/build-docs.sh will run in: symlinks for
# everything it reads, a real empty puzzles/ so the puzzle pass is a no-op,
# and either a symlink to a given chapter/ tree or none at all.
#
# puzzles/ is empty rather than absent so the script's `puzzles/*/` glob stays
# literal and its `[ -f "$dir/README.md" ]` guard drops it, which is the same
# path an unmatched glob takes. exercises/ is absent for the same reason: the
# exercise section's own glob stays literal and the section is skipped, which
# is harness/test-build-docs-exercises.sh's business rather than this one's.
# ---------------------------------------------------------------------------
mk_minirepo() {
  local d="$1" ch="$2" f
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
  if [ -n "$ch" ]; then
    ln -s "$ch" "$d/chapter"
  fi
}

# ---------------------------------------------------------------------------
# derive_sources <chapter-root>
#
# Sets SOURCES to the page names directly under the root, ascending. This is
# the suite's own oracle and is a second copy of the generator's glob on
# purpose: a test that imported the generator's derivation could not catch a
# narrowed one.
#
# index.md is excluded because the section generates its own index page, so a
# source file of that name is not a chapter.
# ---------------------------------------------------------------------------
SOURCES=()
derive_sources() {
  local root="$1" f n
  SOURCES=()
  for f in "$root"/*.md; do
    [ -f "$f" ] || continue
    n=$(basename "$f" .md)
    if [ "$n" != "index" ]; then
      SOURCES+=("$n")
    fi
  done
}

# ---------------------------------------------------------------------------
# derive_pages <docs-chapter-dir>
#
# Sets PAGES to the page names in the built section, ascending, excluding the
# generated index. Independent of the generator's own derivation.
# ---------------------------------------------------------------------------
PAGES=()
derive_pages() {
  local d="$1" f n
  PAGES=()
  for f in "$d"/*.md; do
    [ -f "$f" ] || continue
    n=$(basename "$f" .md)
    if [ "$n" != "index" ]; then
      PAGES+=("$n")
    fi
  done
}

# ---------------------------------------------------------------------------
# read_nav_order <.pages-file>
#
# Sets NAV_ORDER to the page names the nav lists, in the order it lists them,
# with the index dropped. Both the bare `- name.md` form and the quoted
# `- "Title": name.md` form are read, so this does not depend on which the
# generator chose.
# ---------------------------------------------------------------------------
NAV_ORDER=()
read_nav_order() {
  local f="$1" line t
  NAV_ORDER=()
  while IFS= read -r line; do
    case "$line" in
    *.md*) ;;
    *) continue ;;
    esac
    t="${line##*: }"
    t="${t##*- }"
    t="${t%%[[:space:]]*}"
    case "$t" in
    index.md) continue ;;
    *.md) NAV_ORDER+=("${t%.md}") ;;
    esac
  done < "$f"
}

# ---------------------------------------------------------------------------
# nav_index <page-name>
#
# Prints the 0-based position of a page in NAV_ORDER, or -1 if it is absent.
# ---------------------------------------------------------------------------
nav_index() {
  local want="$1" i
  for i in "${!NAV_ORDER[@]}"; do
    if [ "${NAV_ORDER[$i]}" = "$want" ]; then
      printf '%s' "$i"
      return 0
    fi
  done
  printf '%s' "-1"
}

# ---------------------------------------------------------------------------
# check_order <chapter-root> <.pages-file>
#
# Sets ORDER_VIOLATIONS to the "A before B" pairs the nav gets backwards, and
# ORDER_PAIRS to the number of pairs it checked. A page that links to another
# page in the same section is naming what comes after it, so it has to come
# first in the nav.
#
# ORDER_PAIRS is reported so a zero can be seen for what it is. With no links
# between pages there is nothing to check here, and a clean sweep over nothing
# is not evidence.
# ---------------------------------------------------------------------------
ORDER_VIOLATIONS=()
ORDER_PAIRS=0
check_order() {
  local root="$1" pagesfile="$2" a b ia ib
  ORDER_VIOLATIONS=()
  ORDER_PAIRS=0
  derive_sources "$root"
  read_nav_order "$pagesfile"
  for a in "${SOURCES[@]}"; do
    for b in "${SOURCES[@]}"; do
      if [ "$a" = "$b" ]; then
        continue
      fi
      if grep -qF -- "]($b.md)" "$root/$a.md"; then
        ORDER_PAIRS=$((ORDER_PAIRS + 1))
        ia=$(nav_index "$a")
        ib=$(nav_index "$b")
        if [ "$ia" -lt 0 ] || [ "$ib" -lt 0 ] || [ "$ia" -gt "$ib" ]; then
          ORDER_VIOLATIONS+=("$a should precede $b")
        fi
      fi
    done
  done
}

# ---------------------------------------------------------------------------
# check_links <docs-dir>
#
# Sets BAD_LINKS to the "<page>: <target>" pairs whose relative link does not
# resolve to a file inside the built tree. A link is a candidate when its text
# is non-empty and its target carries no whitespace, which is what keeps TLA+
# written inside backticks out of the scan: `[](rung' = rung + 1)` has empty
# text AND a target with spaces.
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
      target="${target%%#*}"
      [ -n "$target" ] || continue
      if [ ! -e "$base/$target" ]; then
        BAD_LINKS+=("$(basename "$page"): $raw")
      fi
    done < <(grep -oE '\[[^]]+\]\([^)[:space:]]+\)' "$page" 2>/dev/null)
  done
}

# ---------------------------------------------------------------------------
# Part 1: the real chapter/ tree
# ---------------------------------------------------------------------------
echo "Part 1: every markdown file under chapter/ gets a page"

REAL=$TMP_ROOT/real
mk_minirepo "$REAL" "$REPO_ROOT/chapter"

if bash "$REAL/scripts/build-docs.sh" >"$TMP_ROOT/real.out" 2>"$TMP_ROOT/real.err"; then
  ok "generator ran clean against the real chapter/ tree"
else
  nope "generator exited non-zero against the real chapter/ tree. stderr: $(tail -3 "$TMP_ROOT/real.err")"
fi

REAL_DOCS=$REAL/docs/chapter

derive_sources "$REPO_ROOT/chapter"
REAL_SOURCES=("${SOURCES[@]}")

# Non-vacuity floor, not an equality. An empty derivation would make every
# per-page assertion below vacuous and the suite would report a clean sweep.
# Two is the number the tree has carried since tla-kl5.1 and is a floor rather
# than a claim about how many chapters exist.
if [ "${#REAL_SOURCES[@]}" -ge 2 ]; then
  ok "real tree derives ${#REAL_SOURCES[@]} chapter pages, at or above the floor of 2"
else
  nope "real tree derives only ${#REAL_SOURCES[@]} chapter pages, so the per-page assertions below would be vacuous"
fi

if [ -d "$REAL_DOCS" ]; then
  ok "docs/chapter/ exists"
else
  nope "docs/chapter/ does not exist"
fi

derive_pages "$REAL_DOCS"
if [ "${PAGES[*]}" = "${REAL_SOURCES[*]}" ]; then
  ok "page set equals the derived source set (${REAL_SOURCES[*]})"
else
  nope "page set [${PAGES[*]}] does not equal the derived source set [${REAL_SOURCES[*]}]"
fi

if [ -e "$REAL_DOCS/snippets" ]; then
  nope "chapter/snippets/ is a directory of modules and got published as a page"
else
  ok "chapter/snippets/ got no page of its own"
fi

for page in "${REAL_SOURCES[@]}"; do
  src="$REPO_ROOT/chapter/$page.md"
  built="$REAL_DOCS/$page.md"

  if [ ! -f "$built" ]; then
    nope "$page: no page at docs/chapter/$page.md"
    continue
  fi
  ok "$page: page exists"

  src_h1=$(grep -m1 '^# ' "$src")
  page_h1=$(grep -m1 '^# ' "$built")
  if [ "$src_h1" = "$page_h1" ]; then
    ok "$page: page H1 is the source H1 verbatim"
  else
    nope "$page: page H1 [$page_h1] is not the source H1 [$src_h1]"
  fi

  # The fenced-block count survives. chapter/snippets/check-blocks.py traces
  # every ```tla block on the source page to a module, and run-all.sh runs it
  # in this gate. A generator that dropped, merged or reflowed a block would
  # publish something that gate never saw.
  src_fences=$(grep -c '^```' "$src")
  page_fences=$(grep -c '^```' "$built")
  if [ "$src_fences" -lt 10 ]; then
    nope "$page: only $src_fences fence lines in the source, too few to be checking anything"
  elif [ "$src_fences" -eq "$page_fences" ]; then
    ok "$page: all $src_fences fence lines survive into the page"
  else
    nope "$page: $src_fences fence lines in the source, $page_fences in the page"
  fi

  # Line count too. Taken together with the H1 and the fences this says the
  # page is the source file and not a rebuild of it: the rewrite is in-place
  # on single lines, so it cannot change how many there are.
  src_lines=$(wc -l < "$src")
  page_lines=$(wc -l < "$built")
  if [ "$src_lines" -eq "$page_lines" ]; then
    ok "$page: all $src_lines lines survive into the page"
  else
    nope "$page: $src_lines lines in the source, $page_lines in the page"
  fi
done

if [ -f "$REAL_DOCS/index.md" ]; then
  ok "docs/chapter/index.md exists"
  idx_missing=0
  for page in "${REAL_SOURCES[@]}"; do
    grep -qF -- "]($page.md)" "$REAL_DOCS/index.md" || idx_missing=$((idx_missing + 1))
  done
  if [ "$idx_missing" -eq 0 ]; then
    ok "docs/chapter/index.md links every chapter page"
  else
    nope "docs/chapter/index.md is missing $idx_missing chapter page links"
  fi

  # Snippet reachability. The two chapters link the directory and no file
  # inside it, so this list is the only thing that makes a module reachable in
  # one hop — and the only thing that would go red if a module went dark.
  snip_total=0
  snip_missing=0
  snip_first=""
  for f in "$REPO_ROOT"/chapter/snippets/*; do
    [ -f "$f" ] || continue
    snip_total=$((snip_total + 1))
    if ! grep -qF -- "/chapter/snippets/$(basename "$f")" "$REAL_DOCS/index.md"; then
      snip_missing=$((snip_missing + 1))
      if [ -z "$snip_first" ]; then
        snip_first=$(basename "$f")
      fi
    fi
  done
  if [ "$snip_total" -lt 20 ]; then
    nope "only $snip_total files under chapter/snippets/, too few for the reachability check to mean anything"
  elif [ "$snip_missing" -eq 0 ]; then
    ok "all $snip_total files under chapter/snippets/ are linked from the index"
  else
    nope "$snip_missing of $snip_total files under chapter/snippets/ are not linked from the index, e.g. $snip_first"
  fi
else
  nope "docs/chapter/index.md does not exist"
fi

if [ -f "$REAL_DOCS/.pages" ]; then
  ok "docs/chapter/.pages exists"
  nav_missing=0
  for page in "${REAL_SOURCES[@]}"; do
    grep -qF -- "$page.md" "$REAL_DOCS/.pages" || nav_missing=$((nav_missing + 1))
  done
  if [ "$nav_missing" -eq 0 ]; then
    ok "docs/chapter/.pages lists every chapter page"
  else
    nope "docs/chapter/.pages is missing $nav_missing chapter entries"
  fi

  check_order "$REPO_ROOT/chapter" "$REAL_DOCS/.pages"
  if [ "$ORDER_PAIRS" -lt 1 ]; then
    nope "no page in the real tree links to another, so the reading-order check ran on nothing"
  elif [ "${#ORDER_VIOLATIONS[@]}" -eq 0 ]; then
    ok "nav reading order respects all $ORDER_PAIRS link(s) between pages"
  else
    nope "${#ORDER_VIOLATIONS[@]} nav ordering violation(s): ${ORDER_VIOLATIONS[*]}"
  fi
else
  nope "docs/chapter/.pages does not exist"
fi

if [ -f "$REAL/docs/.pages" ]; then
  if grep -qE '^[[:space:]]*-[[:space:]]*chapter[[:space:]]*$' "$REAL/docs/.pages"; then
    ok "top-level docs/.pages carries the chapter section"
  else
    nope "top-level docs/.pages does not carry a 'chapter' nav entry"
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
echo "Part 2: the page list and the reading order come from the tree"

# The fixture names are chosen so ALPHABETICAL ORDER IS WRONG. zulu links to
# alpha as what follows it, so the nav has to read zulu then alpha. A
# generator that sorted the pages passes Part 1 on the real tree, where
# refinement happens to sort before worked-example, and fails here.
FIX_CH=$TMP_ROOT/fixture-chapter
mkdir -p "$FIX_CH/snippets" "$FIX_CH/notes"

cat > "$FIX_CH/zulu.md" <<'FIXTURE'
# Zulu, which is read first

A fixture chapter. The modules are in [`snippets/`](snippets/) and one of
them is [Fix.tla](snippets/Fix.tla). A file whose name carries a regex
metacharacter is [Fix+Two.tla](snippets/Fix+Two.tla). The sub-directory is
[notes](notes/).

An external link is [learntla](https://learntla.com/topics/aux-vars/).

```tla
---- MODULE Fix ----
Init == x = 0
====
```

## Next

The [alpha chapter](alpha.md) follows this one.
FIXTURE

cat > "$FIX_CH/alpha.md" <<'FIXTURE'
# Alpha, which is read second

Sorts first and is read second, which is the whole point of this fixture.

```tla
---- MODULE Fix ----
Init == x = 0
====
```
FIXTURE

# A source index.md is not a chapter: the section generates its own index, and
# publishing this one would overwrite it or be overwritten by it.
echo '# A source index that is not a chapter' > "$FIX_CH/index.md"

# Not markdown, so not a page.
echo 'not a page' > "$FIX_CH/README.txt"
# A sub-directory other than snippets/, so the directory handling is not
# special-cased to one name.
echo '# Notes' > "$FIX_CH/notes/NOTES.md"

echo '---- MODULE Fix ----' > "$FIX_CH/snippets/Fix.tla"
echo '---- MODULE FixTwo ----' > "$FIX_CH/snippets/Fix+Two.tla"
echo 'Expected: rc=0' > "$FIX_CH/snippets/Fix.cfg"

FIXREPO=$TMP_ROOT/fixrepo
mk_minirepo "$FIXREPO" "$FIX_CH"

if bash "$FIXREPO/scripts/build-docs.sh" >"$TMP_ROOT/fix.out" 2>"$TMP_ROOT/fix.err"; then
  ok "generator ran clean against the fixture tree"
else
  nope "generator exited non-zero against the fixture tree. stderr: $(tail -3 "$TMP_ROOT/fix.err")"
fi

FIX_DOCS=$FIXREPO/docs/chapter

derive_pages "$FIX_DOCS"
if [ "${PAGES[*]}" = "alpha zulu" ]; then
  ok "fixture derivation gives exactly alpha zulu"
else
  nope "fixture derivation gives [${PAGES[*]}], expected [alpha zulu]"
fi

if [ -e "$FIX_DOCS/README.txt" ] || [ -e "$FIX_DOCS/README.md" ]; then
  nope "fixture: a non-markdown file under chapter/ got published"
else
  ok "fixture: a non-markdown file under chapter/ got no page"
fi

for unwanted in notes snippets; do
  if [ -e "$FIX_DOCS/$unwanted.md" ]; then
    nope "fixture: the $unwanted/ directory got a page and must not have"
  else
    ok "fixture: the $unwanted/ directory got no page"
  fi
done

if [ -f "$FIX_DOCS/index.md" ] && grep -qF 'A source index that is not a chapter' "$FIX_DOCS/index.md"; then
  nope "fixture: a source chapter/index.md was published as the section index"
else
  ok "fixture: the section index is the generated one, not a source index.md"
fi

read_nav_order "$FIX_DOCS/.pages"
if [ "${NAV_ORDER[*]}" = "zulu alpha" ]; then
  ok "fixture nav reads zulu then alpha, which is the link chain and not the alphabet"
else
  nope "fixture nav reads [${NAV_ORDER[*]}], expected [zulu alpha] from the link chain"
fi

check_order "$FIX_CH" "$FIX_DOCS/.pages"
if [ "$ORDER_PAIRS" -ge 1 ] && [ "${#ORDER_VIOLATIONS[@]}" -eq 0 ]; then
  ok "fixture nav order respects its $ORDER_PAIRS link(s) between pages"
else
  nope "fixture nav order checked $ORDER_PAIRS pair(s) with ${#ORDER_VIOLATIONS[@]} violation(s): ${ORDER_VIOLATIONS[*]}"
fi

# Now add a page and a snippet with the generator untouched.
cat > "$FIX_CH/mid-suite.md" <<'FIXTURE'
# Added mid-suite

Created after the first build, with the generator untouched.

```tla
---- MODULE Mid ----
Init == x = 0
====
```
FIXTURE
echo '---- MODULE Added ----' > "$FIX_CH/snippets/Added.tla"

if bash "$FIXREPO/scripts/build-docs.sh" >>"$TMP_ROOT/fix.out" 2>>"$TMP_ROOT/fix.err"; then
  ok "generator ran clean after a page and a snippet were added"
else
  nope "generator exited non-zero after a page and a snippet were added"
fi

derive_pages "$FIX_DOCS"
if [ "${PAGES[*]}" = "alpha mid-suite zulu" ]; then
  ok "a new page produces a page with no generator change (alpha mid-suite zulu)"
else
  nope "after adding mid-suite.md the page set is [${PAGES[*]}], expected [alpha mid-suite zulu]"
fi

if [ -f "$FIX_DOCS/.pages" ] && grep -qF -- 'mid-suite.md' "$FIX_DOCS/.pages"; then
  ok "nav picks up the new page too"
else
  nope "nav did not pick up mid-suite.md"
fi

if grep -qF -- '/chapter/snippets/Added.tla' "$FIX_DOCS/index.md"; then
  ok "the snippet list is globbed from the tree and picks up a new module"
else
  nope "a snippet added mid-run is not linked from the index, so the list is not globbed"
fi

# ---------------------------------------------------------------------------
# Part 3: the link rewrite, and a negative control for the checker
# ---------------------------------------------------------------------------
echo
echo "Part 3: repo-relative links become links that work on the web"

FIXPAGE=$FIX_DOCS/zulu.md
if [ -f "$FIXPAGE" ]; then
  ok "fixture zulu page exists to check links on"

  if grep -qF -- "[\`snippets/\`]($GH_TREE/chapter/snippets)" "$FIXPAGE"; then
    ok "a snippets directory link points at the tree on GitHub"
  else
    nope "a snippets directory link was not rewritten to $GH_TREE/chapter/snippets"
  fi

  if grep -qF -- "[Fix.tla]($GH_BLOB/chapter/snippets/Fix.tla)" "$FIXPAGE"; then
    ok "a snippet file link points at the file on GitHub"
  else
    nope "a snippet file link was not rewritten to $GH_BLOB/chapter/snippets/Fix.tla"
  fi

  if grep -qF -- "[Fix+Two.tla]($GH_BLOB/chapter/snippets/Fix+Two.tla)" "$FIXPAGE"; then
    ok "a target carrying a regex metacharacter is escaped before it is matched"
  else
    nope "a target named Fix+Two.tla was not rewritten, so the ERE escape is wrong"
  fi

  if grep -qF -- "[notes]($GH_TREE/chapter/notes)" "$FIXPAGE"; then
    ok "a sub-directory link points at the tree on GitHub"
  else
    nope "a sub-directory link was not rewritten to $GH_TREE/chapter/notes"
  fi

  if grep -qF -- '[alpha chapter](alpha.md)' "$FIXPAGE"; then
    ok "a link to a sibling chapter page stays relative, since both land in one directory"
  else
    nope "a link to a sibling chapter page was rewritten and must not have been"
  fi

  if grep -qF -- '[learntla](https://learntla.com/topics/aux-vars/)' "$FIXPAGE"; then
    ok "an external link is left alone"
  else
    nope "an external link was rewritten"
  fi
else
  nope "fixture zulu page does not exist, so no link assertion ran"
fi

check_links "$FIX_DOCS"
if [ "${#BAD_LINKS[@]}" -eq 0 ]; then
  ok "no relative link in the fixture section resolves to nothing"
else
  nope "${#BAD_LINKS[@]} dead relative link(s) in the fixture section: ${BAD_LINKS[*]}"
fi

# A link to a target that is not in chapter/ at all. The generator must leave
# it relative rather than invent a destination, and the checker must report it.
# This is the direction the error has to run: a dead link is a content bug, and
# a generator that guessed a plausible URL for one would hide it.
DEAD_CH=$TMP_ROOT/dead-chapter
mkdir -p "$DEAD_CH"
cat > "$DEAD_CH/solo.md" <<'FIXTURE'
# Solo

This points at [nothing at all](snippets/NoSuchModule.tla).
FIXTURE

DEADREPO=$TMP_ROOT/deadrepo
mk_minirepo "$DEADREPO" "$DEAD_CH"
bash "$DEADREPO/scripts/build-docs.sh" >"$TMP_ROOT/dead.out" 2>"$TMP_ROOT/dead.err"

if grep -qF -- 'NoSuchModule.tla' "$TMP_ROOT/dead.err"; then
  ok "the generator warns on a link that resolves to nothing in chapter/"
else
  nope "the generator said nothing about a link that resolves to nothing in chapter/"
fi

check_links "$DEADREPO/docs/chapter"
if [ "${#BAD_LINKS[@]}" -eq 1 ]; then
  ok "the link checker reports the dead link the generator refused to invent a target for"
else
  nope "the link checker reported ${#BAD_LINKS[@]} dead links on the dead-link page, expected 1: ${BAD_LINKS[*]}"
fi

# Negative control for the checker itself. Every assertion above is "this
# resolves", so a checker that matched nothing would report a clean sweep.
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

# The generator must not carry a literal page list. A grep is a weak check next
# to Part 2, and it is here for the error message rather than the coverage: a
# reviewer who writes a list gets told which rule it breaks.
#
# Comment lines are stripped first, because the generator's own comment block
# names both chapters to explain why the list is derived.
CODE_ONLY=$(grep -vE '^[[:space:]]*#' "$GENERATOR")
if grep -qE 'refinement\.md|worked-example' <<<"$CODE_ONLY"; then
  nope "$GENERATOR names a chapter page in code, so it looks like it carries a literal list"
else
  ok "$GENERATOR carries no literal chapter page list"
fi

# Read the SUITES array rather than the whole file, so a mention of this suite
# in a comment cannot stand in for a row that actually runs it.
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"fast[|][^|]*[|][^|]*[|]\./harness/test-build-docs-chapter\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif grep -qE -- "$SUITE_ROW" <<<"$SUITES_BLOCK"; then
  ok "SUITES carries a fast-tier row for ./harness/test-build-docs-chapter.sh"
else
  nope "SUITES carries no fast-tier row for ./harness/test-build-docs-chapter.sh"
  note "scripts/test is in this bead's Files: line, so this row is this bead's to add."
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
