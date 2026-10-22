#!/usr/bin/env bash
# test-build-docs-core-language.sh: executable spec for the core-language
# section of scripts/build-docs.sh, and for the claim that every authoring
# family has a page (bead tla-9y4s.9, epic tla-9y4s).
#
# TWO INVARIANTS, AND THE SECOND IS THE ONE WITH HISTORY BEHIND IT.
#
#   GIVEN drill/INVENTORY.md naming a family in field 3 WHEN that family has
#   no page under core-language-docs/ THEN this suite fails and names it.
#
#   GIVEN a page added to core-language-docs/ WHEN the generator runs THEN the
#   page publishes and reaches the nav without anybody editing a list.
#
# WHY THE FIRST ONE IS DERIVED RATHER THAN A LIST OF EIGHT. The epic shipped
# eight pages for the eight families the inventory partitions 105 constructs
# into. A ninth family is a thing that can happen: the inventory already has
# two recorded holes, bead tla-aj8c records five constructs with no row at
# all, and the family boundary between pluscal and temporal is the one
# INVENTORY.md itself flags as decided by judgment. So the set is read out of
# field 3 on every run. New rows in a family that already has a page change
# nothing here, which matters because the inventory is edited far more often
# than this section is.
#
# AND WHY THE FLOOR UNDER IT DOES REAL WORK. "Every family has a page" is
# true of no families at all. A derivation that silently came back empty would
# report a clean sweep, which is this project's recorded failure shape rather
# than a hypothetical: harness/test-spelling.sh and scripts/lint have each
# reported green over a tree they never read, three times between them, and
# .claude/rules/dispatched-agents.md carries the write-up. Part 3 plants a
# malformed inventory and requires the derivation to come back empty, so the
# floor is watched failing rather than assumed.
#
# THE TSV HAZARD, SPELLED OUT BECAUSE IT BITES SILENTLY. INVENTORY.md rows are
# tab-delimited and fields 8 and 9 are often empty. `IFS=$'\t' read` treats a
# tab as IFS whitespace, so an empty field vanishes and every later field
# shifts left: field 3 comes back holding something else and the family set is
# wrong without any error. Every read of a row here goes through `awk -F'\t'`,
# which does not collapse the delimiter.
#
# FIELDS 8 AND 9 ARE NEVER READ, let alone published. They hold the drill and
# reading item slugs per construct, and a published reverse index from
# construct into both corpora is the leak scripts/deliver-exercises.sh and the
# collapsed cheat-sheet block both exist to manage. This suite reads field 3
# and nothing else.
#
# Usage:  harness/test-build-docs-core-language.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

SRC_DIR="core-language-docs"
INVENTORY="drill/INVENTORY.md"
PUBLISHED="reference/core-language"
NAV_LINE="  - Core Language: core-language"

# Non-vacuity floors. Neither is a claim about how many of anything exists:
# eight families and eight pages is today's count, and a ninth of either is
# expected to pass. These stop an empty derivation from making every
# assertion below vacuously true.
FAMILY_FLOOR=6
PAGE_FLOOR=6

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }
note() { printf "  NOTE  %s\n" "$1"; }

TMP_ROOT=$(mktemp -d -t tla_core_language.XXXXXX)
cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# derive_families <inventory-file>
#
# Sets INV_FAMILIES to the distinct values of field 3 over the rows carrying
# the literal first field ROW, ascending. The suite's own oracle, and a second
# copy of nothing: the generator does not read the inventory at all, so this
# is the only reader and the assertion it feeds is a real cross-check between
# two trees rather than one file agreeing with itself.
#
# `awk -F'\t'` throughout, for the reason in the header. The ROW guard is what
# keeps prose in that file from ever being read as data, and INVENTORY.md's own
# "For the gate author" section states the contract.
# ---------------------------------------------------------------------------
INV_FAMILIES=()
derive_families() {
  local inv="$1" line
  INV_FAMILIES=()
  [ -f "$inv" ] || return 0
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    INV_FAMILIES+=("$line")
  done < <(awk -F'\t' '$1 == "ROW" && $3 != "" { print $3 }' "$inv" | sort -u)
  return 0
}

# ---------------------------------------------------------------------------
# derive_pages <source-dir>
#
# Sets SRC_PAGES to the page names of the markdown files directly under the
# directory, ascending, with index excluded. Independent of the generator's
# own derivation on purpose: a test that imported it could not catch a
# narrowed one, which is what bead tla-i3zu measured.
# ---------------------------------------------------------------------------
SRC_PAGES=()
derive_pages() {
  local d="$1" f n
  SRC_PAGES=()
  for f in "$d"/*.md; do
    [ -f "$f" ] || continue
    n=$(basename "$f" .md)
    if [ "$n" = "index" ]; then
      continue
    fi
    SRC_PAGES+=("$n")
  done
  return 0
}

# ---------------------------------------------------------------------------
# uncovered_families <inventory-file> <source-dir>
#
# Sets UNCOVERED to the families named in field 3 that have no page of that
# name. This is the check the first invariant is about, written as a function
# so part 3 can drive it over a planted ninth family and over a tree with a
# page taken away. A check that only ever runs over the real tree reports
# "found nothing" whether it works or not.
# ---------------------------------------------------------------------------
UNCOVERED=""
uncovered_families() {
  local inv="$1" d="$2" fam
  UNCOVERED=""
  derive_families "$inv"
  for fam in ${INV_FAMILIES[@]+"${INV_FAMILIES[@]}"}; do
    if [ ! -f "$d/$fam.md" ]; then
      UNCOVERED="$UNCOVERED $fam"
    fi
  done
  return 0
}

# ---------------------------------------------------------------------------
# mk_minirepo <dest> <core-language-source-or-empty>
#
# The smallest tree scripts/build-docs.sh will run in. Symlinks for what it
# reads, a real empty puzzles/ so the puzzle pass is a no-op, and either a
# symlink to a given core-language-docs/ tree or none at all.
#
# puzzles/ is empty rather than absent so the script's `puzzles/*/` glob stays
# literal and its README guard drops it, which is the path an unmatched glob
# takes anyway. exercises/, reading/ and swipe/ are absent for the same
# reason, and they are three sibling suites' business rather than this one's.
#
# chapter/ IS HERE, and it is the one exception. Four of the eight pages link
# ../../chapter/refinement.md, which is the only cross-section link the
# section has and the one the epic's own note asked somebody to check once the
# copy step existed. Leave chapter/ out and the link check has nothing to
# resolve against, so it reports four dead links that are only dead in the
# fixture. Measured: that is exactly what the first run of this suite did.
# ---------------------------------------------------------------------------
mk_minirepo() {
  local d="$1" cld="$2" f
  mkdir -p "$d/scripts" "$d/puzzles"
  ln -s "$REPO_ROOT/chapter" "$d/chapter"
  ln -s "$REPO_ROOT/scripts/build-docs.sh" "$d/scripts/build-docs.sh"
  ln -s "$REPO_ROOT/scripts/setup" "$d/scripts/setup"
  if [ -f "$REPO_ROOT/scripts/build-concept-index.py" ]; then
    ln -s "$REPO_ROOT/scripts/build-concept-index.py" "$d/scripts/build-concept-index.py"
  fi
  for f in README.md QUALITY_GATE.md CURRICULUM_MAP.md JUDGMENTS.md SCAFFOLDING_MAP.md LICENSE; do
    ln -s "$REPO_ROOT/$f" "$d/$f"
  done
  ln -s "$REPO_ROOT/module-docs" "$d/module-docs"
  if [ -n "$cld" ]; then
    ln -s "$cld" "$d/core-language-docs"
  fi
}

# ---------------------------------------------------------------------------
# Part 1: every family in the inventory has a page
# ---------------------------------------------------------------------------
echo "Part 1: every family in $INVENTORY field 3 has a page under $SRC_DIR/"

derive_families "$INVENTORY"
REAL_FAMILIES=("${INV_FAMILIES[@]}")

if [ "${#REAL_FAMILIES[@]}" -ge "$FAMILY_FLOOR" ]; then
  ok "inventory derives ${#REAL_FAMILIES[@]} families, at or above the floor of $FAMILY_FLOOR"
else
  nope "inventory derives only ${#REAL_FAMILIES[@]} families (floor $FAMILY_FLOOR), so every assertion below would be vacuous"
fi

derive_pages "$SRC_DIR"
if [ "${#SRC_PAGES[@]}" -ge "$PAGE_FLOOR" ]; then
  ok "$SRC_DIR/ derives ${#SRC_PAGES[@]} pages, at or above the floor of $PAGE_FLOOR"
else
  nope "$SRC_DIR/ derives only ${#SRC_PAGES[@]} pages (floor $PAGE_FLOOR), so the publish assertions below would be vacuous"
fi

uncovered_families "$INVENTORY" "$SRC_DIR"
if [ -z "$UNCOVERED" ]; then
  ok "every one of the ${#REAL_FAMILIES[@]} families has a page"
else
  nope "family named in $INVENTORY with no page under $SRC_DIR/:$UNCOVERED"
fi

# The other direction. A page for a family the inventory does not name is not
# a defect, since the inventory has recorded holes and the sequences page was
# deliberately sourced from the standard module rather than from it. So this
# reports rather than fails, and a reader of the output can tell the two
# directions apart.
extra=""
for page in "${SRC_PAGES[@]}"; do
  found=0
  for fam in "${REAL_FAMILIES[@]}"; do
    [ "$page" = "$fam" ] && found=1
  done
  [ "$found" = "1" ] || extra="$extra $page"
done
if [ -z "$extra" ]; then
  ok "every page names a family the inventory carries"
else
  note "page with no family row in the inventory:$extra"
  ok "pages beyond the inventory are allowed and are reported, not failed"
fi

# The index is the section's landing page. Without it reference/core-language/
# opens on whichever page sorts first, and the reference nav already carries
# one entry whose page 404s on the live site.
if [ -f "$SRC_DIR/index.md" ]; then
  ok "$SRC_DIR/index.md exists"
else
  nope "$SRC_DIR/index.md is missing, so the published section has no landing page"
fi

# The index is the one page a reader lands on without choosing it, so it has
# to name every family page. A page it misses is a page reachable only through
# the nav.
if [ -f "$SRC_DIR/index.md" ]; then
  idx=$(cat "$SRC_DIR/index.md")
  missing=""
  for page in "${SRC_PAGES[@]}"; do
    if ! grep -qF -- "($page.md)" <<<"$idx"; then
      missing="$missing $page"
    fi
  done
  if [ -z "$missing" ]; then
    ok "the index links all ${#SRC_PAGES[@]} family pages"
  else
    nope "the index links no page for:$missing"
  fi

  # Fields 8 and 9 hold the item slugs. The index must carry none of them.
  # Checked against the real slugs rather than against the column header,
  # because the ban is on the data and not on the word.
  leaked=""
  while IFS= read -r slug; do
    [ -n "$slug" ] || continue
    if grep -qF -- "$slug" <<<"$idx"; then
      leaked="$leaked $slug"
    fi
  done < <(awk -F'\t' '$1 == "ROW" { print $8 "," $9 }' "$INVENTORY" \
           | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | sort -u)
  if [ -z "$leaked" ]; then
    ok "the index publishes no field 8 or field 9 item slug"
  else
    nope "the index carries drill or reading item slugs, which is the reverse index the ban exists to stop:$leaked"
  fi
fi

# ---------------------------------------------------------------------------
# Part 2: the generator publishes the section
# ---------------------------------------------------------------------------
echo
echo "Part 2: the generator publishes $SRC_DIR/ to docs/$PUBLISHED/"

REAL=$TMP_ROOT/real
mk_minirepo "$REAL" "$REPO_ROOT/$SRC_DIR"

if bash "$REAL/scripts/build-docs.sh" >"$TMP_ROOT/real.out" 2>"$TMP_ROOT/real.err"; then
  ok "generator ran clean against the real $SRC_DIR/ tree"
else
  nope "generator exited non-zero against the real tree. stderr: $(tail -3 "$TMP_ROOT/real.err")"
fi

# The generator's complaint about a missing index goes to stderr, and a
# section published without one is quietly short of something.
if [ -s "$TMP_ROOT/real.err" ]; then
  nope "generator warned on stderr against the real tree: $(tr '\n' ' ' <"$TMP_ROOT/real.err")"
else
  ok "generator wrote nothing to stderr against the real tree"
fi

REAL_DOCS="$REAL/docs/$PUBLISHED"

if [ -d "$REAL_DOCS" ]; then
  ok "docs/$PUBLISHED/ exists"
else
  nope "docs/$PUBLISHED/ does not exist"
fi

# EVERY PAGE, BYTE FOR BYTE. The chapter and reading sections both rewrite
# something on the way through and this one rewrites nothing, because the
# pages were authored against the published location. A generator that grew a
# rewrite would publish something the snippet runner never checked, which is
# the rule recorded at the chapter section.
drifted=""
absent=""
for page in "${SRC_PAGES[@]}" index; do
  if [ ! -f "$REAL_DOCS/$page.md" ]; then
    absent="$absent $page"
    continue
  fi
  if ! cmp -s "$SRC_DIR/$page.md" "$REAL_DOCS/$page.md"; then
    drifted="$drifted $page"
  fi
done
if [ -z "$absent" ]; then
  ok "all ${#SRC_PAGES[@]} family pages and the index published"
else
  nope "page did not publish:$absent"
fi
if [ -z "$drifted" ]; then
  ok "every published page is byte-identical to its source"
else
  nope "published page differs from its source, so the generator is rewriting content:$drifted"
fi

# Nothing else. A stray file under the published directory is either a page
# nobody authored or a leftover from a previous run.
stray=""
for f in "$REAL_DOCS"/*.md; do
  [ -f "$f" ] || continue
  n=$(basename "$f" .md)
  if [ ! -f "$SRC_DIR/$n.md" ]; then
    stray="$stray $n"
  fi
done
if [ -z "$stray" ]; then
  ok "no published page without a source file"
else
  nope "published page with no source under $SRC_DIR/:$stray"
fi

# ---- the section .pages ----
SECTION_PAGES="$REAL_DOCS/.pages"
if [ -f "$SECTION_PAGES" ]; then
  ok "docs/$PUBLISHED/.pages was written"
  pages_body=$(cat "$SECTION_PAGES")

  if grep -qF -- "title: Core Language" <<<"$pages_body"; then
    ok ".pages carries the section title"
  else
    nope ".pages has no 'title: Core Language'"
  fi

  # The index first, because that is what makes the section's own URL a
  # destination under the theme's navigation.indexes feature.
  first_entry=$(awk '/^nav:/ { on = 1; next } on && /^  - / { print; exit }' <<<"$pages_body")
  if [ "$first_entry" = "  - index.md" ]; then
    ok ".pages lists index.md first"
  else
    nope ".pages first nav entry is [$first_entry], wanted [  - index.md]"
  fi

  # Every page, and a bare filename for each so the nav label is the page's
  # own H1 rather than a label table that can drift from it.
  nav_missing=""
  for page in "${SRC_PAGES[@]}"; do
    if ! grep -qxF -- "  - $page.md" <<<"$pages_body"; then
      nav_missing="$nav_missing $page"
    fi
  done
  if [ -z "$nav_missing" ]; then
    ok ".pages lists every family page as a bare filename"
  else
    nope ".pages is missing a bare-filename entry for:$nav_missing"
  fi

  nav_count=$(awk '/^nav:/ { on = 1; next } on && /^  - / { n += 1 } END { print n + 0 }' <<<"$pages_body")
  want=$(( ${#SRC_PAGES[@]} + 1 ))
  if [ "$nav_count" -eq "$want" ]; then
    ok ".pages lists exactly $want entries, the index plus ${#SRC_PAGES[@]} pages"
  else
    nope ".pages lists $nav_count entries, wanted $want"
  fi
else
  nope "docs/$PUBLISHED/.pages was not written, so the section has no nav order"
fi

# ---- the reference nav ----
REF_PAGES="$REAL/docs/reference/.pages"
if [ -f "$REF_PAGES" ]; then
  ref_body=$(cat "$REF_PAGES")
  if grep -qxF -- "$NAV_LINE" <<<"$ref_body"; then
    ok "the reference nav carries the Core Language entry"
  else
    nope "the reference nav has no [$NAV_LINE] line, so the section is unreachable from the nav"
  fi
  # Ahead of Standard Modules: the language comes before the library it is
  # written in, and both lines name something called modules.
  cl_at=$(awk -v want="$NAV_LINE" '$0 == want { print NR; exit }' <<<"$ref_body")
  sm_at=$(awk '/^  - Standard Modules:/ { print NR; exit }' <<<"$ref_body")
  if [ -n "$cl_at" ] && [ -n "$sm_at" ] && [ "$cl_at" -lt "$sm_at" ]; then
    ok "Core Language sits ahead of Standard Modules in the reference nav"
  else
    nope "reference nav order is wrong: Core Language at line [$cl_at], Standard Modules at [$sm_at]"
  fi
else
  nope "docs/reference/.pages was not written"
fi

# ---- links ----
#
# Every relative link on a published page has to resolve inside the built
# tree. The section needs no link-rewrite program precisely because the pages
# were authored against this location, and this is the assertion that keeps
# that true rather than lucky. Bead tla-9t76 is open on nothing in this repo
# running `mkdocs build --strict`, so a broken link ships green today.
link_fail=""
link_seen=0
for page in "${SRC_PAGES[@]}" index; do
  [ -f "$REAL_DOCS/$page.md" ] || continue
  raw=$(grep -ohE '\[[^]]+\]\([^)[:space:]]+\)' "$REAL_DOCS/$page.md" 2>/dev/null || true)
  [ -n "$raw" ] || continue
  targets=$(sed -E 's/^.*\]\(//; s/\)$//' <<<"$raw" | LC_ALL=C sort -u)
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    case "$t" in
    http://* | https://* | mailto:* | '#'* | /*) continue ;;
    esac
    path="${t%%#*}"
    [ -n "$path" ] || continue
    link_seen=$((link_seen + 1))
    if [ ! -e "$REAL_DOCS/$path" ]; then
      link_fail="$link_fail
      $page.md -> $t"
    fi
  done <<<"$targets"
done
if [ "$link_seen" -eq 0 ]; then
  nope "found no relative links to resolve, so the link check below is vacuous"
elif [ -z "$link_fail" ]; then
  ok "all $link_seen relative link targets resolve inside the built tree"
else
  nope "relative link does not resolve from docs/$PUBLISHED/:$link_fail"
fi

# ---------------------------------------------------------------------------
# Part 3: the checks themselves still bite
#
# Every assertion in part 1 is of the form "found nothing uncovered", which is
# also what a derivation that quietly stopped working reports. These plant the
# failures in synthetic trees and require both directions.
# ---------------------------------------------------------------------------
echo
echo "Part 3: the family derivation and the coverage check still bite"

CTRL=$TMP_ROOT/control
mkdir -p "$CTRL"

# A ninth family, one row, tab-delimited like the real file, with fields 8 and
# 9 EMPTY. That pair of empty fields is the whole reason this file reads rows
# with awk: under `IFS=$'\t' read` they collapse and field 3 comes back
# holding field 5.
FIX_INV="$CTRL/INVENTORY-ninth.md"
{
  printf '# prose that must never be read as data\n'
  printf 'ROW is a word in this sentence and this line is not a row.\n'
  printf 'ROW\tK001\tcore\toperator definition\tfile:1\thigh\tA\t\t\tneither\n'
  printf 'ROW\tK002\tsets\tset literal\tfile:2\thigh\tA\t\t\tneither\n'
  printf 'ROW\tK003\tzebra\tstripe operator\tfile:3\tlow\tA\t\t\tneither\n'
} >"$FIX_INV"

FIX_SRC="$CTRL/pages"
mkdir -p "$FIX_SRC"
printf '# Core operators\n' >"$FIX_SRC/core.md"
printf '# Sets\n' >"$FIX_SRC/sets.md"
printf '# Core Language\n' >"$FIX_SRC/index.md"

derive_families "$FIX_INV"
if [ "${#INV_FAMILIES[@]}" -eq 3 ]; then
  ok "control: the derivation reads 3 families off a fixture with empty fields 8 and 9"
else
  nope "control: the derivation read ${#INV_FAMILIES[@]} families off a 3-family fixture, so the tab handling is wrong: ${INV_FAMILIES[*]+${INV_FAMILIES[*]}}"
fi

# The prose line opening with the word ROW must contribute nothing. Field 3 of
# a space-delimited line is the whole line under awk -F tab, so a derivation
# that dropped the ROW guard would pick up a sentence.
sentence_read=0
for fam in ${INV_FAMILIES[@]+"${INV_FAMILIES[@]}"}; do
  case "$fam" in *' '*) sentence_read=1 ;; esac
done
if [ "$sentence_read" -eq 0 ]; then
  ok "control: a prose line beginning with the word ROW is not read as a row"
else
  nope "control: prose was read as a family name, so the ROW guard is not holding"
fi

uncovered_families "$FIX_INV" "$FIX_SRC"
if [ "$UNCOVERED" = " zebra" ]; then
  ok "control: a ninth family with no page is DETECTED and named"
else
  nope "control: a planted uncovered family came back as [$UNCOVERED], wanted [ zebra] — the coverage check is vacuous"
fi

# The other half of the same check: take a page away from a family that has
# one. This is the shape the brief asks to see red before the gate is
# believed, and it is the shape a page rename produces.
mv "$FIX_SRC/sets.md" "$FIX_SRC/sets-renamed.md"
uncovered_families "$FIX_INV" "$FIX_SRC"
case "$UNCOVERED" in
*sets*) ok "control: a renamed page leaves its family uncovered, and that is DETECTED" ;;
*) nope "control: renaming sets.md left UNCOVERED as [$UNCOVERED], so a page rename would go unnoticed" ;;
esac
mv "$FIX_SRC/sets-renamed.md" "$FIX_SRC/sets.md"

# And the clean direction, so the check is not simply always red.
uncovered_families "$FIX_INV" "$FIX_SRC"
if [ "$UNCOVERED" = " zebra" ]; then
  ok "control: restoring the page clears it, leaving only the planted family"
else
  nope "control: after restore UNCOVERED is [$UNCOVERED], wanted [ zebra]"
fi

# THE FLOOR, WATCHED FAILING. A rows file whose delimiter is a space rather
# than a tab is the realistic way this derivation goes silently empty, since
# a reformat is the one thing INVENTORY.md asks readers not to do.
FIX_BAD="$CTRL/INVENTORY-spaces.md"
{
  printf 'ROW K001 core operator definition file:1 high A neither\n'
  printf 'ROW K002 sets set literal file:2 high A neither\n'
} >"$FIX_BAD"
derive_families "$FIX_BAD"
if [ "${#INV_FAMILIES[@]}" -lt "$FAMILY_FLOOR" ]; then
  ok "control: a space-delimited inventory derives ${#INV_FAMILIES[@]} families, which the floor of $FAMILY_FLOOR catches"
else
  nope "control: a space-delimited inventory derived ${#INV_FAMILIES[@]} families and slipped past the floor"
fi

# ---------------------------------------------------------------------------
# Part 4: the page list follows the tree
#
# The derived-not-written rule, driven the way bead tla-i3zu says to: add a
# page with the generator untouched and require it to publish and reach the
# nav. A narrowed derivation passes part 2 on today's eight names.
# ---------------------------------------------------------------------------
echo
echo "Part 4: a page added to the tree publishes with the generator untouched"

GROW=$TMP_ROOT/grow
GROW_SRC="$GROW/src"
mkdir -p "$GROW_SRC"
printf '# Core operators\n\nFixture.\n' >"$GROW_SRC/core.md"
printf '# Core Language\n\nFixture index linking [Core operators](core.md).\n' >"$GROW_SRC/index.md"
# A name that sorts after every real page, so a generator ordering by anything
# other than the tree puts it somewhere this suite can see.
printf '# Zebra\n\nFixture.\n' >"$GROW_SRC/zebra.md"

mk_minirepo "$GROW/repo" "$GROW_SRC"
if bash "$GROW/repo/scripts/build-docs.sh" >"$TMP_ROOT/grow.out" 2>"$TMP_ROOT/grow.err"; then
  ok "generator ran clean against a two-page fixture tree"
else
  nope "generator exited non-zero against the fixture tree. stderr: $(tail -3 "$TMP_ROOT/grow.err")"
fi

GROW_DOCS="$GROW/repo/docs/$PUBLISHED"
grow_pages=$(cat "$GROW_DOCS/.pages" 2>/dev/null || true)
if [ -f "$GROW_DOCS/zebra.md" ]; then
  ok "a page the generator has never heard of publishes"
else
  nope "zebra.md did not publish, so the page list is not derived from the tree"
fi
if grep -qxF -- "  - zebra.md" <<<"$grow_pages"; then
  ok "that page reaches the nav without anybody editing a list"
else
  nope "zebra.md is not in .pages, so the nav list is hand-kept somewhere"
fi
grow_count=$(awk '/^nav:/ { on = 1; next } on && /^  - / { n += 1 } END { print n + 0 }' <<<"$grow_pages")
if [ "$grow_count" -eq 3 ]; then
  ok "the fixture section's nav lists 3 entries, the index plus two pages"
else
  nope "the fixture section's nav lists $grow_count entries, wanted 3"
fi

# A tree with no index. The generator warns and publishes the rest, because a
# section short of its landing page is better than no section, and the warning
# is what says so.
NOIDX=$TMP_ROOT/noindex
NOIDX_SRC="$NOIDX/src"
mkdir -p "$NOIDX_SRC"
printf '# Core operators\n' >"$NOIDX_SRC/core.md"
mk_minirepo "$NOIDX/repo" "$NOIDX_SRC"
bash "$NOIDX/repo/scripts/build-docs.sh" >"$TMP_ROOT/noidx.out" 2>"$TMP_ROOT/noidx.err" || true
noidx_err=$(cat "$TMP_ROOT/noidx.err")
if grep -qF -- "index.md is missing" <<<"$noidx_err"; then
  ok "a tree with no index.md draws a warning on stderr"
else
  nope "a tree with no index.md drew no warning. stderr: $(tr '\n' ' ' <<<"$noidx_err")"
fi

# No tree at all. The nav entry has to go with it, or the reference section
# carries a second link to a 404.
NOTREE=$TMP_ROOT/notree
mk_minirepo "$NOTREE/repo" ""
bash "$NOTREE/repo/scripts/build-docs.sh" >"$TMP_ROOT/notree.out" 2>"$TMP_ROOT/notree.err" || true
notree_ref=$(cat "$NOTREE/repo/docs/reference/.pages" 2>/dev/null || true)
if grep -qxF -- "$NAV_LINE" <<<"$notree_ref"; then
  nope "the reference nav still names Core Language with no $SRC_DIR/ in the tree, which is a nav entry pointing at a 404"
else
  ok "with no $SRC_DIR/ in the tree the reference nav omits the Core Language entry"
fi
if grep -qF -- "Standard Modules" <<<"$notree_ref"; then
  ok "the rest of the reference nav is unaffected"
else
  nope "the reference nav lost Standard Modules, so the conditional took out more than its own line"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
