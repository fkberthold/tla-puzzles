#!/usr/bin/env bash
# test-build-docs-reading.sh: executable spec for the reading section of
# scripts/build-docs.sh (bead tla-n7dv).
#
# Pins the RED invariant from the bead:
#
#   GIVEN scripts/build-docs.sh with the properties-rest-on block removed from
#   its reading section WHEN the suite runs THEN it fails and names the block.
#
# WHY THIS FILE EXISTS, AND IT IS NOT "A BLOCK IS MISSING". Bead tla-fwkz.2.8
# found that the probe prose sat in 16 USES.md files and reached the published
# page from none of them: reading_subject() took `Subject:` to the next blank
# line, reading_constructs() took the first `## ` to the end, and the region
# between the two anchors fell down the gap. That bead normalised all 25
# source files onto one heading and taught the generator to publish it, and
# harness/reading-gate.sh check 6 now gates the SOURCE shape. Nothing gated
# the PUBLISHER. A refactor of this section would keep check 6 green and stop
# publishing the block, which is the same failure a second time, and the only
# verification that ever caught it was a hand-run grep -- the advisory shape
# gate-don't-advise rules out. The reading section is about 220 lines of
# generator that had no suite at all, so this file covers the section rather
# than the one block.
#
# FOUR THINGS ARE PERFORMED RATHER THAN ASSERTED, and they are the reason this
# is more than a file-exists check.
#
# THE FAMILY AND ITEM SETS. Nothing below names temporal, or pluscal, or
# twenty-five. Part 1 derives both from the real tree with its own globs, so
# it is an independent oracle rather than the generator agreeing with itself.
# Part 2 then builds a fixture reading/ carrying a `zebra` family the real
# repo does not have, a `hollow` family with no items, and a `yak` created
# mid-run with the generator untouched, and requires the page set to follow.
# Bead tla-i3zu measured why the second half is needed: narrowing a derivation
# left its real-tree assertion passing, because the expected set shrank to
# match the derived set. A real-tree comparison alone agrees with itself.
#
# THE FAMILY LABEL IS CHECKED FOR CONSISTENCY, NOT AGAINST A COPIED MAP.
# reading_family_label() is a case map with a fall-through to the slug, so a
# literal list of labels in the generator is correct by design and Part 4
# cannot ban one the way the sibling suites ban a chapter list. What is
# checkable is that the label reaches all three places that emit it -- the
# page H1, the `.pages` nav title and the index link text -- and that they
# agree. A generator that relabelled a family in one of the three would be
# publishing a page whose nav entry names something else.
#
# THE PROBE ASSERTION HAS A NEGATIVE CONTROL. "Every line of the probe region
# reaches the page" passes vacuously over an extractor that returns nothing,
# which is this bead's own defect wearing a green tick. So Part 1 carries a
# corpus-wide floor on how many probe lines were actually compared, and Part 2
# plants an item whose USES.md has no such heading and requires the block to
# be ABSENT from its section and the generator to say so on stderr. Only the
# pair says the assertion discriminates.
#
# THE LINK CHECKER HAS A NEGATIVE CONTROL, for the same reason and in the same
# shape as its two siblings. Every link assertion is "this resolves", so a
# checker that extracted nothing would report a clean sweep. Part 3 runs the
# same checker over a page carrying a deliberately dead relative link and
# requires it to report that link.
#
# THE SPEC COMPARISON IS cmp, NOT A GREP. The published spec is `cat` from the
# verified .tla so that the page and harness/reading-gate.sh check the same
# bytes. A summary check -- the module header is present, the line count
# matches -- would pass over a generator that reflowed the body. So the fenced
# block is extracted and handed to cmp against the file on disk.
#
# THE REAL docs/ IS NEVER TOUCHED. Every generator run here happens in a
# throwaway mini-repo built out of symlinks, with an EMPTY puzzles/ and no
# chapter/ or exercises/ at all, so the 107-puzzle pass and its python3 calls
# do not run and neither sibling section is built. That keeps the suite in the
# fast tier and keeps a developer's docs/ tree out of it. It also exercises
# the generator through its real entry point: it resolves its root from the
# path it was invoked by, so a mini-repo is enough to redirect it, and a
# generator that hardcoded a checkout path would fail Part 2 outright. Bead
# tla-1hf fixed exactly that bug in a sibling script.
#
# NO TLC. Every item in reading/ is model-checked by harness/reading-gate.sh,
# which is a slow-tier suite of its own. This one reads the published bytes
# and runs no JVM, so it belongs in the fast tier by the rule in
# scripts/test's header: the tier boundary is the model checker.
#
# Usage:  harness/test-build-docs-reading.sh
# Exit:   0 if all assertions hold, 1 otherwise.

set -uo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel)
cd "$REPO_ROOT" || exit 1

GENERATOR="scripts/build-docs.sh"
TEST_RUNNER="scripts/test"

# The URL base the generator is expected to build the per-item source links
# from. Pinned here on purpose: the whole point of the link is that the
# published form is predictable, so the test names it rather than accepting
# whatever appears.
GH_TREE="https://github.com/fkberthold/tla-puzzles/tree/main"

# The three collapsed blocks, in the order the index page's "How to read one"
# section tells a reader to open them. The middle one is bead tla-fwkz.2.8's
# and the reason this suite exists.
BLOCK_PROBE='??? note "What the properties rest on"'
BLOCK_CONSTRUCTS='??? note "Constructs, and the recorded exit code"'

pass_count=0
fail_count=0

ok()   { printf "  PASS  %s\n" "$1"; pass_count=$((pass_count + 1)); }
nope() { printf "  FAIL  %s\n" "$1"; fail_count=$((fail_count + 1)); }
note() { printf "  NOTE  %s\n" "$1"; }

TMP_ROOT=$(mktemp -d)
cleanup() { rm -rf "$TMP_ROOT"; }
trap cleanup EXIT

# ---------------------------------------------------------------------------
# mk_minirepo <dest> <reading-source-or-empty>
#
# Builds the smallest tree scripts/build-docs.sh will run in: symlinks for
# everything it reads, a real empty puzzles/ so the puzzle pass is a no-op,
# and either a symlink to a given reading/ tree or none at all.
#
# puzzles/ is empty rather than absent so the script's `puzzles/*/` glob stays
# literal and its `[ -f "$dir/README.md" ]` guard drops it, which is the same
# path an unmatched glob takes. chapter/ and exercises/ are absent for the
# same reason: their globs stay literal, their sections are skipped, and they
# are the business of the two sibling suites rather than this one's.
# ---------------------------------------------------------------------------
mk_minirepo() {
  local d="$1" rd="$2" f
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
  if [ -n "$rd" ]; then
    ln -s "$rd" "$d/reading"
  fi
}

# ---------------------------------------------------------------------------
# derive_families <reading-root>
#
# Sets FAMILIES to the family slugs under the root that carry at least one
# item directory, ascending. This is the suite's own oracle and is a second
# copy of the generator's glob on purpose: a test that imported the
# generator's derivation could not catch a narrowed one.
#
# A family with no item directory is excluded, matching the generator's stated
# rule that an empty directory is not a content decision. Part 2 plants one.
# ---------------------------------------------------------------------------
FAMILIES=()
derive_families() {
  local root="$1" fam_dir fam item_dir found
  FAMILIES=()
  for fam_dir in "$root"/*/; do
    [ -d "$fam_dir" ] || continue
    fam="${fam_dir%/}"
    fam="${fam##*/}"
    found=0
    for item_dir in "$fam_dir"*/; do
      [ -d "$item_dir" ] && found=1
    done
    [ "$found" = "1" ] || continue
    FAMILIES+=("$fam")
  done
}

# ---------------------------------------------------------------------------
# derive_pages <docs-reading-dir>
#
# Sets PAGES to the family page names in the built section, ascending,
# excluding the generated index. Independent of the generator's derivation.
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
# derive_items <reading-root> <family>
#
# Sets ITEM_DIRS, ITEM_RELS and ITEM_NAMES in lockstep: the item directories
# of a family in directory order, the path each one is PUBLISHED under, and
# the module name each one publishes as, which is the basename of its single
# .tla. An item with no .tla contributes nothing, which is what the generator
# does too -- Part 2 plants one and checks the warning.
#
# ITEM_DIRS is on-disk and may be anywhere, since the fixture tree in Part 2
# lives outside the repo. ITEM_RELS is `reading/<family>/<dir>`, which is what
# the generator sees because it cds to its own root and globs `reading/*/*/`.
# The two are not interchangeable, and conflating them put an absolute path
# inside a github.com URL on the first run of this suite.
#
# DIRECTORY ORDER, NOT MODULE-NAME ORDER, and the distinction is load-bearing.
# The directories are numbered (01-, 02-, ...) and that numbering is a reading
# order, while the module names are not in it: reading/pluscal/ runs Euclid,
# Interleave, Contend, Ring, Collatz, Bubble, which sorts differently. So a
# generator that published its sections alphabetically would scramble a
# sequence the corpus author chose, and the real tree discriminates without a
# fixture. Part 2 plants the same disagreement anyway, so the check does not
# depend on pluscal/ keeping its current names.
# ---------------------------------------------------------------------------
ITEM_DIRS=()
ITEM_RELS=()
ITEM_NAMES=()
derive_items() {
  local root="$1" fam="$2" item_dir item modfile t
  ITEM_DIRS=()
  ITEM_RELS=()
  ITEM_NAMES=()
  for item_dir in "$root/$fam"/*/; do
    [ -d "$item_dir" ] || continue
    item="${item_dir%/}"
    modfile=""
    for t in "$item"/*.tla; do
      [ -f "$t" ] && modfile="$t"
    done
    [ -n "$modfile" ] || continue
    ITEM_DIRS+=("$item")
    ITEM_RELS+=("reading/$fam/$(basename "$item")")
    ITEM_NAMES+=("$(basename "$modfile" .tla)")
  done
}

# ---------------------------------------------------------------------------
# page_sections <page>
#
# Prints the page's H2 headings with the `## ` stripped, in page order. These
# are the item sections. A page that does not exist prints nothing rather than
# letting sed write to stderr, so a red run's own message is not buried under
# a diagnostic from the tool.
# ---------------------------------------------------------------------------
page_sections() {
  [ -f "$1" ] || return 0
  sed -n 's/^## //p' "$1"
}

# ---------------------------------------------------------------------------
# extract_section <page> <module-name> <outfile>
#
# Writes the one item section to outfile: its `## <name>` heading through to
# the next H2 or end of file. Returns 1 when there is no such heading.
# ---------------------------------------------------------------------------
extract_section() {
  local page="$1" name="$2" out="$3"
  awk -v want="## $name" '
    $0 == want { on = 1; print; next }
    on && /^## / { exit }
    on { print }
  ' "$page" > "$out"
  [ -s "$out" ]
}

# ---------------------------------------------------------------------------
# extract_spec <section-file> <outfile>
#
# Writes the contents of the section's first ```tla fence to outfile, with the
# fence lines dropped and nothing else touched, so the result is byte
# comparable against the module on disk. No reading/ module contains a fence
# line of its own, which was checked before this was written.
# ---------------------------------------------------------------------------
extract_spec() {
  local sec="$1" out="$2"
  awk '
    !on && $0 == "```tla" { on = 1; next }
    on && $0 == "```" { exit }
    on { print }
  ' "$sec" > "$out"
}

# ---------------------------------------------------------------------------
# note_block_kinds <section-file>
#
# Prints one word per collapsed block in the section, in page order: `cfg`,
# `probe`, `constructs`, or `unknown` for a block title this suite does not
# recognise. The kind sequence is what the order assertion compares, so a
# retitled block reads as `unknown` and fails loudly rather than silently
# dropping out of the comparison.
# ---------------------------------------------------------------------------
note_block_kinds() {
  local line
  while IFS= read -r line; do
    case "$line" in
    '??? note '*) ;;
    *) continue ;;
    esac
    case "$line" in
    *'.cfg`'*'what TLC is told to check'*) echo "cfg" ;;
    "$BLOCK_PROBE") echo "probe" ;;
    "$BLOCK_CONSTRUCTS") echo "constructs" ;;
    *) echo "unknown" ;;
    esac
  done < "$1"
}

# ---------------------------------------------------------------------------
# extract_block <section-file> <block-title>
#
# Prints the body of one collapsed block with the four-space admonition indent
# removed, so it can be compared against the source it came from. A
# non-indented non-blank line closes the block.
#
# Written against a literal title rather than a pattern so that the probe
# block's body cannot be confused with the constructs block's: before bead
# tla-fwkz.2.8 the probe prose published DEMOTED INSIDE the constructs block,
# and a check that accepted "somewhere in a collapsed block" would have
# called that a pass.
# ---------------------------------------------------------------------------
extract_block() {
  local sec="$1" title="$2"
  awk -v t="$title" '
    /^[?][?][?] note / { on = ($0 == t); next }
    !on { next }
    /^$/ { print ""; next }
    /^    / { print substr($0, 5); next }
    { on = 0 }
  ' "$sec"
}

# ---------------------------------------------------------------------------
# probe_source_lines <uses-file>
#
# Prints the non-blank lines of the USES.md region headed
# `## What the properties rest on`, verbatim. A THIRD copy of that selection
# -- the generator has reading_probe() and harness/reading-gate.sh check 6 has
# its own -- and deliberately so, for the reason the sibling suites give about
# their chapter globs: a test that imported the generator's extractor could
# not catch a narrowed one.
#
# Only non-blank lines are kept, because what this suite asserts is that each
# one REACHED the page. Where the generator's interior blank lines land is
# formatting rather than content, and asserting on it would make the suite
# fail on a change that lost nothing.
# ---------------------------------------------------------------------------
probe_source_lines() {
  awk '
    /^## / { on = ($0 == "## What the properties rest on"); next }
    !on { next }
    /[^[:space:]]/ { print }
  ' "$1"
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
#
# Copied from harness/test-build-docs-chapter.sh, whose header explains the
# negative control the shape needs. The duplication is the sibling suites'
# existing convention rather than something this bead introduced.
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
# Part 1: the real reading/ tree
# ---------------------------------------------------------------------------
echo "Part 1: every family and every item reaches the published section"

REAL=$TMP_ROOT/real
mk_minirepo "$REAL" "$REPO_ROOT/reading"

if bash "$REAL/scripts/build-docs.sh" >"$TMP_ROOT/real.out" 2>"$TMP_ROOT/real.err"; then
  ok "generator ran clean against the real reading/ tree"
else
  nope "generator exited non-zero against the real reading/ tree. stderr: $(tail -3 "$TMP_ROOT/real.err")"
fi

# The generator's own complaints about the corpus go to stderr: an item with no
# .tla, a USES.md with no Subject:, a USES.md with no probe section. Each of
# those publishes a page that is quietly short of something, so a clean run is
# part of the invariant rather than a nicety.
if [ -s "$TMP_ROOT/real.err" ]; then
  nope "generator warned on stderr against the real tree: $(tr '\n' ' ' < "$TMP_ROOT/real.err")"
else
  ok "generator wrote nothing to stderr against the real tree"
fi

REAL_DOCS=$REAL/docs/reading

derive_families "$REPO_ROOT/reading"
REAL_FAMILIES=("${FAMILIES[@]}")

# Non-vacuity floor, not an equality. An empty derivation would make every
# per-family assertion below vacuous and the suite would report a clean sweep.
# Six is a floor the tree passed before this bead and is not a claim about how
# many families exist.
if [ "${#REAL_FAMILIES[@]}" -ge 6 ]; then
  ok "real tree derives ${#REAL_FAMILIES[@]} families, at or above the floor of 6"
else
  nope "real tree derives only ${#REAL_FAMILIES[@]} families, so the per-family assertions below would be vacuous"
fi

if [ -d "$REAL_DOCS" ]; then
  ok "docs/reading/ exists"
else
  nope "docs/reading/ does not exist"
fi

derive_pages "$REAL_DOCS"
if [ "${PAGES[*]}" = "${REAL_FAMILIES[*]}" ]; then
  ok "family page set equals the derived family set (${REAL_FAMILIES[*]})"
else
  nope "family page set [${PAGES[*]}] does not equal the derived family set [${REAL_FAMILIES[*]}]"
fi

# Counters for the corpus-wide floors. Each one guards a per-item assertion
# against going vacuous across the whole tree at once.
total_items=0
total_probe_lines=0
total_cfg_lines=0

for fam in "${REAL_FAMILIES[@]}"; do
  page="$REAL_DOCS/$fam.md"
  if [ ! -f "$page" ]; then
    nope "$fam: no page at docs/reading/$fam.md"
    continue
  fi

  label=$(sed -n '1s/^# //p' "$page")
  if [ -n "$label" ]; then
    ok "$fam: page carries an H1 label ($label)"
  else
    nope "$fam: page has no H1"
    continue
  fi

  # The label reaches all three emitters and they agree. See the header for
  # why this replaces a copy of reading_family_label()'s case map.
  if grep -qxF -- "  - \"$label\": $fam.md" "$REAL_DOCS/.pages"; then
    ok "$fam: the nav entry names the page under the same label"
  else
    nope "$fam: docs/reading/.pages carries no '  - \"$label\": $fam.md' entry"
  fi

  derive_items "$REPO_ROOT/reading" "$fam"
  fam_dirs=("${ITEM_DIRS[@]}")
  fam_rels=("${ITEM_RELS[@]}")
  fam_names=("${ITEM_NAMES[@]}")

  if [ "${#fam_names[@]}" -ge 1 ]; then
    ok "$fam: derives ${#fam_names[@]} item(s) from the tree"
  else
    nope "$fam: derives no items, yet it has a page"
    continue
  fi

  if grep -qxF -- "- [$label]($fam.md) — ${#fam_names[@]}" "$REAL_DOCS/index.md"; then
    ok "$fam: the index links the page under the same label and the derived item count"
  else
    nope "$fam: docs/reading/index.md carries no '- [$label]($fam.md) — ${#fam_names[@]}' line"
  fi

  sections=$(page_sections "$page")
  if [ "$sections" = "$(printf '%s\n' "${fam_names[@]}")" ]; then
    ok "$fam: item sections are exactly the derived modules, in directory order"
  else
    nope "$fam: item sections [$(tr '\n' ' ' <<<"$sections")] are not the derived modules in directory order [${fam_names[*]}]"
  fi

  for i in "${!fam_names[@]}"; do
    item="${fam_dirs[$i]}"
    rel="${fam_rels[$i]}"
    name="${fam_names[$i]}"
    modfile="$item/$name.tla"
    cfgfile="$item/$name.cfg"
    usesfile="$item/USES.md"
    total_items=$((total_items + 1))

    sec="$TMP_ROOT/sec.$fam.$name"
    if ! extract_section "$page" "$name" "$sec"; then
      nope "$fam/$name: no '## $name' section on the page"
      continue
    fi

    # ASSERTION 3: the spec is copied, not re-typed. cmp, not a summary.
    spec="$TMP_ROOT/spec.$fam.$name"
    extract_spec "$sec" "$spec"
    if cmp -s "$spec" "$modfile"; then
      ok "$fam/$name: published spec is $rel/$name.tla byte for byte"
    else
      # cmp names both operands, one of which is a temp path nobody can act
      # on. What a reader needs is where they diverge, so only that half is
      # reported.
      cmpout=$(cmp "$spec" "$modfile" 2>&1)
      nope "$fam/$name: published spec differs from $rel/$name.tla — ${cmpout##*differ: }"
    fi

    # ASSERTION 4: all three blocks, in the order the index page promises.
    kinds=$(note_block_kinds "$sec")
    want_kinds=$(printf '%s\n' cfg probe constructs)
    if [ "$kinds" = "$want_kinds" ]; then
      ok "$fam/$name: collapsed blocks are cfg, probe, constructs in that order"
    else
      nope "$fam/$name: collapsed blocks are [$(tr '\n' ' ' <<<"$kinds")], wanted [cfg probe constructs]"
    fi

    # The cfg block names this module's config and carries its bytes.
    if grep -qF -- "??? note \"\`$name.cfg\`" "$sec"; then
      ok "$fam/$name: the cfg block names $name.cfg"
    else
      nope "$fam/$name: the cfg block does not name $name.cfg"
    fi

    # Every non-blank config line, in the form the admonition indent gives it,
    # must be on the page. ONE grep per item rather than one per line, with
    # the section as the pattern file and the wanted lines as the input: the
    # per-line form cost 500 process spawns across the corpus and 2 seconds of
    # the suite's 3.
    cfg_want="$TMP_ROOT/cfgwant.$fam.$name"
    sed -n 's/^\(.*[^[:space:]].*\)$/    \1/p' "$cfgfile" > "$cfg_want"
    cfg_seen=$(wc -l < "$cfg_want")
    cfg_absent=$(grep -vxFf "$sec" "$cfg_want")
    total_cfg_lines=$((total_cfg_lines + cfg_seen))
    if [ "$cfg_seen" -eq 0 ]; then
      nope "$fam/$name: $rel/$name.cfg has no non-blank line, so the cfg comparison is vacuous"
    elif [ -z "$cfg_absent" ]; then
      ok "$fam/$name: all $cfg_seen config lines reach the page verbatim"
    else
      nope "$fam/$name: config line(s) did not reach the page: $(tr '\n' '|' <<<"$cfg_absent")"
    fi

    # ASSERTION 5, THE REGRESSION. Every line of the USES.md probe region
    # reaches the page, and reaches it INSIDE the probe block rather than
    # demoted into the constructs block, which is where it used to go.
    probe_want="$TMP_ROOT/probewant.$fam.$name"
    probe_body="$TMP_ROOT/probe.$fam.$name"
    probe_source_lines "$usesfile" > "$probe_want"
    extract_block "$sec" "$BLOCK_PROBE" > "$probe_body"
    probe_seen=$(wc -l < "$probe_want")
    if [ "$probe_seen" -eq 0 ]; then
      nope "$fam/$name: $rel/USES.md has no '## What the properties rest on' region, so the probe assertion is vacuous (harness/reading-gate.sh check 6 gates the source side)"
    else
      # Same one-grep-per-item form as the config comparison above, and here
      # the pattern file is the BLOCK BODY rather than the whole section. That
      # is the difference between "the prose is somewhere on the page" and
      # "the prose is in the block that is supposed to hold it", and before
      # bead tla-fwkz.2.8 the looser reading would have passed on prose
      # demoted into the constructs block.
      probe_absent=$(grep -vxFf "$probe_body" "$probe_want")
      total_probe_lines=$((total_probe_lines + probe_seen))
      if [ -z "$probe_absent" ]; then
        ok "$fam/$name: all $probe_seen probe lines reach the page inside the properties-rest-on block"
      else
        probe_n=$(wc -l <<<"$probe_absent")
        nope "$fam/$name: $probe_n of $probe_seen probe lines did not reach the properties-rest-on block, first: ${probe_absent%%$'\n'*}"
      fi
    fi

    # The recorded exit code, in the block whose title promises it.
    rc=$(sed -n 's/^[-*[:space:]]*rc:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*$/\1/p' "$usesfile" | sed -n '1p')
    cons_body="$TMP_ROOT/constructs.$fam.$name"
    extract_block "$sec" "$BLOCK_CONSTRUCTS" > "$cons_body"
    if [ -z "$rc" ]; then
      nope "$fam/$name: $usesfile records no rc:"
    elif grep -qxF -- "TLC exit code $rc, reproduced by \`harness/reading-gate.sh\`." "$cons_body"; then
      ok "$fam/$name: the constructs block records rc $rc"
    else
      nope "$fam/$name: the constructs block does not record rc $rc"
    fi

    # The link back to the source directory, so a reader can run the item.
    if grep -qxF -- "[\`$rel/\`]($GH_TREE/$rel)" "$sec"; then
      ok "$fam/$name: the section links $rel/ on GitHub"
    else
      nope "$fam/$name: the section carries no [\`$rel/\`]($GH_TREE/$rel) link"
    fi
  done
done

# The corpus-wide floors. Each per-item assertion above can only be trusted if
# something actually went through it, and a broken extractor makes all of them
# report a clean sweep at once.
if [ "$total_items" -ge 20 ]; then
  ok "$total_items items were checked, at or above the floor of 20"
else
  nope "only $total_items items were checked, below the floor of 20"
fi

if [ "$total_probe_lines" -ge 50 ]; then
  ok "$total_probe_lines probe lines were compared, at or above the floor of 50"
else
  nope "only $total_probe_lines probe lines were compared, below the floor of 50 — the probe extractor is reading almost nothing"
fi

if [ "$total_cfg_lines" -ge 50 ]; then
  ok "$total_cfg_lines config lines were compared, at or above the floor of 50"
else
  nope "only $total_cfg_lines config lines were compared, below the floor of 50"
fi

# THE NAMED REGRESSION. Bead tla-fwkz.2.8 measured this exact sentence: on
# 2026-10-13 `grep -c 'Swapping it for' docs/reading/temporal.md` returned 0
# while reading/temporal/04-contention/USES.md carried it. It is pinned by
# name alongside the derived sweep above, because a named failure that was
# once real is cheaper to read in a suite's output than a count.
SENTINEL='Swapping it for'
if [ -f "$REAL_DOCS/temporal.md" ]; then
  n=$(grep -cF -- "$SENTINEL" "$REAL_DOCS/temporal.md")
  if [ "$n" = "1" ]; then
    ok "the sentence dropped before 2026-10-13 is on docs/reading/temporal.md exactly once"
  else
    nope "'$SENTINEL' appears $n times on docs/reading/temporal.md, expected 1 (bead tla-fwkz.2.8 measured 0 before the fix)"
  fi
else
  nope "docs/reading/temporal.md does not exist, so the named regression did not run"
fi

if [ -f "$REAL_DOCS/index.md" ]; then
  ok "docs/reading/index.md exists"
else
  nope "docs/reading/index.md does not exist"
fi

if [ -f "$REAL_DOCS/.pages" ]; then
  ok "docs/reading/.pages exists"
  nav_missing=0
  for fam in "${REAL_FAMILIES[@]}"; do
    grep -qF -- "$fam.md" "$REAL_DOCS/.pages" || nav_missing=$((nav_missing + 1))
  done
  if [ "$nav_missing" -eq 0 ]; then
    ok "docs/reading/.pages lists every family page"
  else
    nope "docs/reading/.pages is missing $nav_missing family entries"
  fi
else
  nope "docs/reading/.pages does not exist"
fi

if [ -f "$REAL/docs/.pages" ]; then
  if grep -qE '^[[:space:]]*-[[:space:]]*reading[[:space:]]*$' "$REAL/docs/.pages"; then
    ok "top-level docs/.pages carries the reading section"
  else
    nope "top-level docs/.pages does not carry a 'reading' nav entry"
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
# Part 2: the family and item lists come from the tree, not from a list
# ---------------------------------------------------------------------------
echo
echo "Part 2: the family and item lists come from the tree, not from a list"

FIX_RD=$TMP_ROOT/fixture-reading
mkdir -p "$FIX_RD/core/01-zulu" "$FIX_RD/core/02-alpha" "$FIX_RD/core/03-nospec" \
         "$FIX_RD/zebra/01-stripes" "$FIX_RD/zebra/02-noprobe" \
         "$FIX_RD/hollow"

# core/01-zulu publishes module Alpha and core/02-alpha publishes module Zulu,
# so directory order and module-name order disagree. A generator that sorted
# its sections by module name passes Part 1 by luck on today's pluscal/ names
# and fails here.
cat > "$FIX_RD/core/01-zulu/Alpha.tla" <<'FIXTURE'
---- MODULE Alpha ----
EXTENDS Naturals

VARIABLE step
vars == <<step>>

TypeOK == step \in 0..2

Init == step = 0
Tick == step' = (step + 1) % 3
Next == Tick

Spec == Init /\ [][Next]_vars

Bounded == step < 3
====
FIXTURE

cat > "$FIX_RD/core/01-zulu/Alpha.cfg" <<'FIXTURE'
SPECIFICATION Spec

INVARIANT TypeOK
INVARIANT Bounded
FIXTURE

cat > "$FIX_RD/core/01-zulu/USES.md" <<'FIXTURE'
# USES: core/01-zulu

Subject: A fixture counter that wraps at three.

rc: 0

## What the properties rest on

FIXTURE-PROBE-ALPHA. The modulus is what keeps `Bounded` true.
Raising it to four gives rc 12 on the first wrap.

## Constructs

- ' (prime, next-state value)
FIXTURE

cat > "$FIX_RD/core/02-alpha/Zulu.tla" <<'FIXTURE'
---- MODULE Zulu ----
VARIABLE flag
vars == <<flag>>
TypeOK == flag \in BOOLEAN
Init == flag = FALSE
Next == flag' = ~flag
Spec == Init /\ [][Next]_vars
====
FIXTURE

cat > "$FIX_RD/core/02-alpha/Zulu.cfg" <<'FIXTURE'
SPECIFICATION Spec

INVARIANT TypeOK
FIXTURE

cat > "$FIX_RD/core/02-alpha/USES.md" <<'FIXTURE'
# USES: core/02-alpha

Subject: A fixture flag that flips.

rc: 0

## What the properties rest on

FIXTURE-PROBE-ZULU. Dropping the negation leaves one state.

## Constructs

- BOOLEAN
FIXTURE

# An item with no .tla. The generator publishes no section for it and says so
# on stderr, and this suite's own derivation drops it the same way.
cat > "$FIX_RD/core/03-nospec/USES.md" <<'FIXTURE'
# USES: core/03-nospec

Subject: An item whose module never landed.

rc: 0

## What the properties rest on

FIXTURE-PROBE-ORPHAN. There is no module here to probe.
FIXTURE

# zebra is a family slug the label map has never heard of, so its label falls
# through to the slug itself. A generator carrying a literal list of today's
# families publishes nothing for it.
#
# THE INDENTATION IS DELIBERATE. The byte comparison in Part 1 is what catches
# a generator that reflows a published spec, and the first version of this
# fixture had no multi-space run in it at all, so a whitespace-collapsing
# filter planted in the generator failed all 25 real items and passed here.
# A fixture that cannot reproduce the failure it is paired with is decoration.
cat > "$FIX_RD/zebra/01-stripes/Stripes.tla" <<'FIXTURE'
---- MODULE Stripes ----
EXTENDS Naturals

VARIABLE stripes
vars == <<stripes>>

TypeOK ==
  /\ stripes \in 0..3
  /\ stripes >= 0

Init == stripes = 0
Paint == stripes' = (stripes + 1) % 4
Next == Paint

Spec == Init /\ [][Next]_vars

FixtureSentinel == stripes >= 0
====
FIXTURE

cat > "$FIX_RD/zebra/01-stripes/Stripes.cfg" <<'FIXTURE'
SPECIFICATION Spec

INVARIANT TypeOK
INVARIANT FixtureSentinel
FIXTURE

cat > "$FIX_RD/zebra/01-stripes/USES.md" <<'FIXTURE'
# USES: zebra/01-stripes

Subject: A fixture family the label map has never heard of.

rc: 0

## What the properties rest on

FIXTURE-PROBE-STRIPES. The sentinel rests on the modulus and on
nothing else.

## Constructs

- % (modulo)

## Constructs from other families, also exercised

- Operator definition
FIXTURE

# THE NEGATIVE CONTROL FOR THE PROBE ASSERTION. A USES.md with no such
# heading. Its section must carry the cfg and constructs blocks and NOT the
# probe block, and the generator must say so on stderr. Without this, "every
# probe line reaches the page" would pass over an extractor that returns
# nothing -- which is this bead's own defect wearing a green tick.
cat > "$FIX_RD/zebra/02-noprobe/Quiet.tla" <<'FIXTURE'
---- MODULE Quiet ----
VARIABLE hush
vars == <<hush>>
TypeOK == hush \in BOOLEAN
Init == hush = TRUE
Next == UNCHANGED vars
Spec == Init /\ [][Next]_vars
====
FIXTURE

cat > "$FIX_RD/zebra/02-noprobe/Quiet.cfg" <<'FIXTURE'
SPECIFICATION Spec

INVARIANT TypeOK
FIXTURE

cat > "$FIX_RD/zebra/02-noprobe/USES.md" <<'FIXTURE'
# USES: zebra/02-noprobe

Subject: An item that never got a probe paragraph.

rc: 0

## Constructs

- UNCHANGED
FIXTURE

# hollow carries no item directory. An empty family is not a content decision
# and a nav entry pointing at an empty page is worse than no entry.
echo 'not an item' > "$FIX_RD/hollow/NOTES.md"

FIXREPO=$TMP_ROOT/fixrepo
mk_minirepo "$FIXREPO" "$FIX_RD"

if bash "$FIXREPO/scripts/build-docs.sh" >"$TMP_ROOT/fix.out" 2>"$TMP_ROOT/fix.err"; then
  ok "generator ran clean against the fixture tree"
else
  nope "generator exited non-zero against the fixture tree. stderr: $(tail -3 "$TMP_ROOT/fix.err")"
fi

FIX_DOCS=$FIXREPO/docs/reading

derive_pages "$FIX_DOCS"
if [ "${PAGES[*]}" = "core zebra" ]; then
  ok "fixture derivation gives exactly core zebra"
else
  nope "fixture derivation gives [${PAGES[*]}], expected [core zebra]"
fi

if [ -e "$FIX_DOCS/hollow.md" ]; then
  nope "fixture: a family with no item directory got a page"
else
  ok "fixture: a family with no item directory got no page"
fi

if grep -qxF -- '# zebra' "$FIX_DOCS/zebra.md"; then
  ok "fixture: an unmapped family slug publishes under the slug as its label"
else
  nope "fixture: docs/reading/zebra.md does not carry '# zebra' as its H1"
fi

fix_sections=$(page_sections "$FIX_DOCS/core.md")
if [ "$fix_sections" = "$(printf '%s\n' Alpha Zulu)" ]; then
  ok "fixture: core sections follow directory order (Alpha from 01-zulu, Zulu from 02-alpha)"
else
  nope "fixture: core sections are [$(tr '\n' ' ' <<<"$fix_sections")], expected [Alpha Zulu] in directory order"
fi

# Two greps on two lines rather than one `A || grep -q B`. The second `|` of a
# `||` matches harness/test-pipefail.sh's ban pattern, which is written for a
# pipe into an early-exiting consumer, and this line has no pipe at all. The
# failure direction is a false FAIL rather than a false PASS, so the pattern is
# reported rather than quieted, and the line is written so as not to need it.
orphan_leak=0
grep -qF -- 'Nospec' "$FIX_DOCS/core.md" && orphan_leak=1
grep -qF -- 'FIXTURE-PROBE-ORPHAN' "$FIX_DOCS/core.md" && orphan_leak=1
if [ "$orphan_leak" = "1" ]; then
  nope "fixture: an item with no .tla got a section"
else
  ok "fixture: an item with no .tla got no section"
fi

if grep -qF -- 'core/03-nospec has no .tla' "$TMP_ROOT/fix.err"; then
  ok "fixture: the generator named the item with no .tla on stderr"
else
  nope "fixture: the generator did not name core/03-nospec on stderr: $(tr '\n' ' ' < "$TMP_ROOT/fix.err")"
fi

# The planted spec, byte for byte, through the same comparison Part 1 uses.
fsec=$TMP_ROOT/fixsec.stripes
if extract_section "$FIX_DOCS/zebra.md" Stripes "$fsec"; then
  ok "fixture: the Stripes section exists"
  fspec=$TMP_ROOT/fixspec.stripes
  extract_spec "$fsec" "$fspec"
  if cmp -s "$fspec" "$FIX_RD/zebra/01-stripes/Stripes.tla"; then
    ok "fixture: the planted spec is published byte for byte"
  else
    fcmpout=$(cmp "$fspec" "$FIX_RD/zebra/01-stripes/Stripes.tla" 2>&1)
    nope "fixture: the planted spec was altered — ${fcmpout##*differ: }"
  fi

  fkinds=$(note_block_kinds "$fsec")
  if [ "$fkinds" = "$(printf '%s\n' cfg probe constructs)" ]; then
    ok "fixture: the planted item carries cfg, probe, constructs in that order"
  else
    nope "fixture: the planted item's blocks are [$(tr '\n' ' ' <<<"$fkinds")], wanted [cfg probe constructs]"
  fi

  # The planted line carries no backtick, which is not an accident: a markdown
  # code span inside a single-quoted shell string raises SC2016 and the
  # project's lint gate is green. Every backticked probe line in the corpus is
  # covered by the derived sweep in Part 1, so nothing is lost here.
  if grep -qxF -- 'FIXTURE-PROBE-STRIPES. The sentinel rests on the modulus and on' \
      <(extract_block "$fsec" "$BLOCK_PROBE"); then
    ok "fixture: the planted probe prose lands inside the properties-rest-on block"
  else
    nope "fixture: the planted probe prose is not inside the properties-rest-on block"
  fi

  # Where it must NOT land. Before bead tla-fwkz.2.8 this prose published
  # demoted inside the constructs block, which is the failure a looser
  # "somewhere on the page" check would call a pass.
  if grep -qF -- 'FIXTURE-PROBE-STRIPES' <(extract_block "$fsec" "$BLOCK_CONSTRUCTS"); then
    nope "fixture: the probe prose leaked into the constructs block"
  else
    ok "fixture: the probe prose did not leak into the constructs block"
  fi
else
  nope "fixture: no Stripes section, so the planted-spec assertions did not run"
fi

# The negative control. An item with no probe region must publish the other
# two blocks and not this one, and the generator must say so.
qsec=$TMP_ROOT/fixsec.quiet
if extract_section "$FIX_DOCS/zebra.md" Quiet "$qsec"; then
  qkinds=$(note_block_kinds "$qsec")
  if [ "$qkinds" = "$(printf '%s\n' cfg constructs)" ]; then
    ok "control: an item with no probe region publishes cfg and constructs and no probe block"
  else
    nope "control: an item with no probe region published blocks [$(tr '\n' ' ' <<<"$qkinds")], wanted [cfg constructs]"
  fi
  if [ -z "$(extract_block "$qsec" "$BLOCK_PROBE")" ]; then
    ok "control: the probe extractor reports nothing for that item, so it discriminates"
  else
    nope "control: the probe extractor found a body in an item that has no probe region"
  fi
else
  nope "control: no Quiet section, so the negative control did not run"
fi

if grep -qF -- "has no 'What the properties rest on' section" "$TMP_ROOT/fix.err"; then
  ok "control: the generator named the item with no probe region on stderr"
else
  nope "control: the generator said nothing about the item with no probe region: $(tr '\n' ' ' < "$TMP_ROOT/fix.err")"
fi

# Now add a family with the generator untouched.
mkdir -p "$FIX_RD/yak/01-hair"
cat > "$FIX_RD/yak/01-hair/Hair.tla" <<'FIXTURE'
---- MODULE Hair ----
VARIABLE shorn
vars == <<shorn>>
TypeOK == shorn \in BOOLEAN
Init == shorn = FALSE
Next == shorn' = TRUE
Spec == Init /\ [][Next]_vars
====
FIXTURE

cat > "$FIX_RD/yak/01-hair/Hair.cfg" <<'FIXTURE'
SPECIFICATION Spec

INVARIANT TypeOK
FIXTURE

cat > "$FIX_RD/yak/01-hair/USES.md" <<'FIXTURE'
# USES: yak/01-hair

Subject: A family created after the first build.

rc: 0

## What the properties rest on

FIXTURE-PROBE-HAIR. Nothing rests on anything here.

## Constructs

- ' (prime, next-state value)
FIXTURE

if bash "$FIXREPO/scripts/build-docs.sh" >>"$TMP_ROOT/fix.out" 2>>"$TMP_ROOT/fix.err"; then
  ok "generator ran clean after a family was added"
else
  nope "generator exited non-zero after a family was added"
fi

derive_pages "$FIX_DOCS"
if [ "${PAGES[*]}" = "core yak zebra" ]; then
  ok "a new family produces a page with no generator change (core yak zebra)"
else
  nope "after adding yak the page set is [${PAGES[*]}], expected [core yak zebra]"
fi

if grep -qF -- 'yak.md' "$FIX_DOCS/.pages"; then
  ok "nav picks up the new family too"
else
  nope "nav did not pick up yak.md"
fi

if grep -qF -- '](yak.md)' "$FIX_DOCS/index.md"; then
  ok "the index picks up the new family too"
else
  nope "the index did not pick up yak.md"
fi

if grep -qF -- 'FIXTURE-PROBE-HAIR' "$FIX_DOCS/yak.md"; then
  ok "the new family's probe prose reached its page on the first build that saw it"
else
  nope "the new family's probe prose did not reach docs/reading/yak.md"
fi

# Now add an item to an existing family, still with the generator untouched.
mkdir -p "$FIX_RD/yak/02-wool"
cat > "$FIX_RD/yak/02-wool/Wool.tla" <<'FIXTURE'
---- MODULE Wool ----
VARIABLE spun
vars == <<spun>>
TypeOK == spun \in BOOLEAN
Init == spun = FALSE
Next == spun' = TRUE
Spec == Init /\ [][Next]_vars
====
FIXTURE

cat > "$FIX_RD/yak/02-wool/Wool.cfg" <<'FIXTURE'
SPECIFICATION Spec

INVARIANT TypeOK
FIXTURE

cat > "$FIX_RD/yak/02-wool/USES.md" <<'FIXTURE'
# USES: yak/02-wool

Subject: An item added to an existing family.

rc: 0

## What the properties rest on

FIXTURE-PROBE-WOOL. Added after the family already had a page.

## Constructs

- ' (prime, next-state value)
FIXTURE

if bash "$FIXREPO/scripts/build-docs.sh" >>"$TMP_ROOT/fix.out" 2>>"$TMP_ROOT/fix.err"; then
  ok "generator ran clean after an item was added to an existing family"
else
  nope "generator exited non-zero after an item was added to an existing family"
fi

yak_sections=$(page_sections "$FIX_DOCS/yak.md")
if [ "$yak_sections" = "$(printf '%s\n' Hair Wool)" ]; then
  ok "a new item produces a section with no generator change (Hair Wool)"
else
  nope "after adding 02-wool the yak sections are [$(tr '\n' ' ' <<<"$yak_sections")], expected [Hair Wool]"
fi

if grep -qxF -- '- [yak](yak.md) — 2' "$FIX_DOCS/index.md"; then
  ok "the index item count follows the tree (yak is now 2)"
else
  nope "the index does not record yak at 2 items"
fi

# ---------------------------------------------------------------------------
# Part 3: links, and a negative control for the checker
# ---------------------------------------------------------------------------
echo
echo "Part 3: links, and a negative control for the checker"

check_links "$FIX_DOCS"
if [ "${#BAD_LINKS[@]}" -eq 0 ]; then
  ok "no relative link in the fixture section resolves to nothing"
else
  nope "${#BAD_LINKS[@]} dead relative link(s) in the fixture section: ${BAD_LINKS[*]}"
fi

if grep -qxF -- "[\`reading/zebra/01-stripes/\`]($GH_TREE/reading/zebra/01-stripes)" "$FIX_DOCS/zebra.md"; then
  ok "an item's source link is built from the item path under $GH_TREE"
else
  nope "an item's source link was not built as $GH_TREE/reading/zebra/01-stripes"
fi

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

# The index page tells the reader to open the blocks in a particular order,
# and Part 1 asserts the generator emits them in that order. If the page's
# promise and the emission disagree, one of the two is wrong and neither
# assertion alone can say so. This is the cheap half of that pair.
if grep -qF -- 'the config,' "$REAL_DOCS/index.md" &&
   grep -qF -- 'what the properties rest on, and the construct list.' "$REAL_DOCS/index.md"; then
  ok "the index page names the three blocks in the order Part 1 requires"
else
  nope "the index page no longer names the three blocks in the order Part 1 requires"
fi

# Read the SUITES array rather than the whole file, so a mention of this suite
# in a comment cannot stand in for a row that actually runs it.
SUITES_BLOCK=$(sed -n '/^SUITES=(/,/^)/p' "$TEST_RUNNER")
SUITE_ROW='^[[:space:]]*"fast[|][^|]*[|][^|]*[|]\./harness/test-build-docs-reading\.sh"'

if [ -z "$SUITES_BLOCK" ]; then
  nope "SUITES registration. No SUITES=( ... ) block found in $TEST_RUNNER"
elif grep -qE -- "$SUITE_ROW" <<<"$SUITES_BLOCK"; then
  ok "SUITES carries a fast-tier row for ./harness/test-build-docs-reading.sh"
else
  nope "SUITES carries no fast-tier row for ./harness/test-build-docs-reading.sh"
  note "a suite that exists and is not registered is not a gate"
fi

echo
if [ "$fail_count" -ne 0 ]; then
  printf "FAILED: %d passed, %d failed\n" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf "OK: %d assertions passed\n" "$pass_count"
