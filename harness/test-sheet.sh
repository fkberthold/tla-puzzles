#!/usr/bin/env bash
# Gate for drill/SHEET.md and the generator that writes it.
#
# THE INVARIANT. drill/SHEET.md carries one entry per `- Construct:` line in
# `exercises/ch*/CHEATSHEET.md`, each with its syntax shape and its chapter,
# sorted by the K id, and `scripts/gen-sheet.sh --check` exits nonzero when a
# cheat sheet moves and the sheet does not.
#
# WHY THE FILE NEEDS A GATE AT ALL. The sheet is a copy of material that lives
# somewhere else, and a stale copy reads exactly like a fresh one. Worse than
# stale: the sheet is what a study session reaches for when a construct will
# not come, so a shape that was edited in the cheat sheet and not here teaches
# the old shape. So the file is generated and this suite proves the generated
# form is the form on disk.
#
# WHAT MUTATION BUYS OVER A GREEN RUN. A gate over a generated file is easy to
# write vacuously, because the generator and the gate agree with each other by
# construction. Most of the assertions below are controls: they break a copy of
# the real tree one defect at a time and require the gate to redden. A control
# that passes means the check is blind to that defect, and it is reported as a
# failure.
#
# THREE CONTROLS ARE THE OTHER WAY ROUND and they matter as much. A changed
# `Section anchor:`, a changed `Toolbox equivalent:` and a changed inventory
# weight all have to leave --check CLEAN, because none of them is material this
# file carries. Without those three, "the gate reddens on everything" would
# pass the suite and the sheet would churn on every unrelated cheat-sheet edit.
#
# THE MIRROR. Mutation runs against a copy of the twelve cheat sheets, the
# inventory and the sheet, 102 KB measured 2026-10-16. The real tree is never
# written. The figure is a description rather than a check, since it tracks the
# corpus, and the mirror's faithfulness is asserted against the live file count
# instead of against a size.
#
# Lineage: bead tla-ucbs.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GEN="$REPO_ROOT/scripts/gen-sheet.sh"
SHEET="$REPO_ROOT/drill/SHEET.md"
INVENTORY="$REPO_ROOT/drill/INVENTORY.md"
EXERCISES="$REPO_ROOT/exercises"

PASS=0
FAIL=0
SKIP=0

ok()   { PASS=$((PASS+1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf '  FAIL %s\n' "$1"; }
skip() { SKIP=$((SKIP+1)); printf '  skip %s\n' "$1"; }

# Indents a captured block under a FAIL line. awk rather than
# `sed 's/^/       /'`, which shellcheck flags as SC2001 every time it sees a
# here-string on the left.
indent() { awk '{ print "       " $0 }' <<<"$1"; }

# How many non-blank lines a captured block holds.
lines() { awk 'NF > 0 { n++ } END { print n+0 }' <<<"$1"; }

# A control reddened the gate, which is what a control is for.
ctl_ok()  { ok "control: $1"; }
ctl_bad() { bad "control: $1 was accepted, so the check is blind to it"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------------------
# Part 0: the pieces exist and run.
# ---------------------------------------------------------------------------
echo "part 0: the generator and the sheet"

if [ -f "$GEN" ] && [ -x "$GEN" ]; then
  ok "scripts/gen-sheet.sh exists and is executable"
else
  bad "scripts/gen-sheet.sh is missing or not executable"
  printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
  exit 1
fi

if [ -f "$SHEET" ]; then
  ok "drill/SHEET.md exists"
else
  bad "drill/SHEET.md is missing"
  printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
  exit 1
fi

# NO LITERAL REPO PATH IN CODE. scripts/gen-curriculum-map.sh used to open with
# `cd /home/frank/repos/tla-puzzles`, so running it from a worktree wrote its
# output into the MAIN checkout. A footprint check cannot see that, because it
# happens inside the script. (bead tla-1hf)
#
# COMMENTS ARE EXEMPT, and they have to be. The generator's own header quotes
# the path that caused tla-1hf so a reader knows what the hazard looked like,
# and a check that reddened on the quote would push the next author to delete
# the explanation. So the scan drops comment lines first.
hardcoded="$(sed 's/#.*$//' "$GEN" | grep -nE '/(home|Users)/[A-Za-z0-9_.-]+/')" || hardcoded=""
if [ -z "$hardcoded" ]; then
  ok "the generator carries no literal home-directory path"
else
  bad "the generator carries a literal path, which writes across checkouts:"
  printf '       %s\n' "$hardcoded"
fi

if grep -qE 'BASH_SOURCE' "$GEN"; then
  ok "the generator resolves its root from BASH_SOURCE"
else
  bad "the generator does not resolve its root from BASH_SOURCE"
fi

if "$GEN" --help >/dev/null 2>&1; then
  ok "--help exits 0"
else
  bad "--help does not exit 0"
fi

# A FLAG WITH NO VALUE HAS TO SAY SO. The obvious `--root) ROOT="${2:-}"; shift`
# spelling exits 1 and prints nothing, because the loop's trailing `shift` runs
# with no arguments left and `set -e` kills the script before the guard. That
# was live in this generator until it was measured, and it is live in
# scripts/gen-coverage.sh today on three flags. A silent rc 1 from a generator
# is indistinguishable from a real failure, so it gets an assertion.
for arg_case in "--root" "--root:"; do
  label="${arg_case}"
  if [ "$arg_case" = "--root:" ]; then
    out="$("$GEN" --root "" 2>&1)" && rc=0 || rc=$?
    label="--root with an empty value"
  else
    out="$("$GEN" --root 2>&1)" && rc=0 || rc=$?
    label="--root with no value"
  fi
  if [ "$rc" = "2" ] && grep -qF -- 'needs a directory' <<<"$out"; then
    ok "$label exits 2 and says what is missing"
  else
    bad "$label exits $rc with output [$out]"
  fi
done

out="$("$GEN" --nonsense 2>&1)" && rc=0 || rc=$?
if [ "$rc" = "2" ] && grep -qF -- 'unknown argument' <<<"$out"; then
  ok "an unknown flag exits 2 and names itself"
else
  bad "an unknown flag exits $rc"
fi

# THE DEFECT CHANNEL IS APPEND-MODE. Two awk passes report into one file, and
# awk's `>` truncates on the first write of each run, so a `>` in the join pass
# deletes everything the flatten pass found. That cost a real finding on this
# script's first run. Part 6 proves it behaviorally; this is the cheap static
# companion, because the behavioral control needs a 21-entry mutation to fire.
#
# The negated class here is safe because this file runs under a bash shebang,
# which gets GNU grep. The Bash tool's own `grep` is ugrep, where a negated
# class next to an anchor returns 0, so the same expression typed
# interactively would have reported clean on a broken file.
# (.claude/rules/dispatched-agents.md)
n_trunc="$(grep -cE '[^>]> DEFECTS' "$GEN")" || n_trunc=0
if [ "${n_trunc:-0}" -eq 0 ]; then
  ok "every defect write uses >> rather than >, so neither awk pass truncates the other"
else
  bad "$n_trunc defect write(s) use > and will truncate the other pass's findings"
fi

# ---------------------------------------------------------------------------
# Part 1: the shape of the live file.
#
# THE EXPECTED COUNT IS DERIVED, NEVER PINNED. A literal 105 here reddens this
# gate the day a thirteenth chapter lands, and it takes every control below
# with it, because the next assertion would read "--check reddens on the
# unmutated mirror, so every control below is meaningless". The count is a
# property of the cheat sheets, so ask them.
# ---------------------------------------------------------------------------
echo
echo "part 1: the shape of drill/SHEET.md"

sheet_files() {
  find "$1" -mindepth 2 -maxdepth 2 -type f -name CHEATSHEET.md \
    -path "$1/ch*/CHEATSHEET.md" ! -path "$1/.*" ! -path "$1/*/.*" | LC_ALL=C sort
}

construct_count() {
  local -a files=()
  local f
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    files+=("$f")
  done < <(sheet_files "$1")
  if [ "${#files[@]}" -eq 0 ]; then
    echo 0
    return
  fi
  awk '/^- Construct: / { n++ } END { print n+0 }' "${files[@]}"
}

EXPECTED="$(construct_count "$EXERCISES")"
N_SHEETS="$(sheet_files "$EXERCISES" | sed -n '$=')"
echo "  (the cheat sheets declare $EXPECTED construct(s) across ${N_SHEETS:-0} file(s))"

if [ "$EXPECTED" -gt 0 ]; then
  ok "the cheat sheets were found and declare $EXPECTED construct(s)"
else
  bad "no construct entry found under $EXERCISES, so every count below is meaningless"
  printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
  exit 1
fi

awk -F'\t' '$1 == "ROW" { print $2 }' "$INVENTORY" | LC_ALL=C sort > "$WORK/inv-ids"

# sheet_defects <sheet> <expected-count>. One "<code> <detail>" line per defect
# found, and nothing at all on a clean file.
#
# FACTORED INTO A FUNCTION so the same code runs against the live file and
# against deliberately broken copies. A shape check that only ever sees a good
# file is a check nobody has watched fail.
sheet_defects() {
  local file="$1" want="$2" n
  n="$(awk '/^- K/ { n++ } END { print n+0 }' "$file")"
  [ "$n" -eq "$want" ] || printf 'ENTRYCOUNT %s entries, expected %s\n' "$n" "$want"

  # Every entry line is `- KNNN  chNN  <name>` and the line under it is the
  # shape, indented two spaces and not empty.
  awk '
    /^- K/ {
      id = $2
      if ($0 !~ /^- K[0-9][0-9][0-9]  ch[0-9][0-9]  ./) printf "BADENTRY %s\n", $0
      want_shape = 1
      next
    }
    want_shape {
      want_shape = 0
      if ($0 !~ /^  [^ ]/) printf "NOSHAPE %s is followed by [%s]\n", id, $0
      next
    }
  ' "$file"

  awk '/^- K/ { print $2 }' "$file" > "$WORK/sheet-ids-raw"
  LC_ALL=C sort "$WORK/sheet-ids-raw" > "$WORK/sheet-ids"
  if ! diff -q "$WORK/sheet-ids-raw" "$WORK/sheet-ids" >/dev/null; then
    printf 'UNSORTED the entries are not in ascending K order\n'
  fi
  LC_ALL=C sort "$WORK/sheet-ids-raw" | uniq -d | sed 's/^/DUPID /'

  # Every id in the sheet is an inventory row, and every inventory row is in
  # the sheet. Both directions, because either one alone is satisfied by a
  # subset.
  comm -23 "$WORK/sheet-ids" "$WORK/inv-ids" | sed 's/^/PHANTOMID /'
  comm -13 "$WORK/sheet-ids" "$WORK/inv-ids" | sed 's/^/MISSINGID /'
}

live="$(sheet_defects "$SHEET" "$EXPECTED")"
if [ -z "$live" ]; then
  ok "$EXPECTED entries, a shape on every one, ascending unique K ids, all of them inventory rows"
else
  bad "the live sheet has $(lines "$live") shape defect(s):"
  indent "$live"
fi

# THE BACKTICK STRIP IS LOAD-BEARING, asserted rather than assumed. Field 4 is
# the cheat sheet's construct text with the markup removed, so a generator that
# compared raw text would redden on every row where the sheet backticks part of
# the name. If that count ever reaches 0 the stripping is dead code, and this
# assertion is what would say so.
n_stripped=0
while IFS=$'\t' read -r id name src; do
  [ -n "$id" ] || continue
  f="${src%:*}"
  ln="${src##*:}"
  raw="$(sed -n "${ln}p" "$REPO_ROOT/$f")"
  raw="${raw#- Construct: }"
  [ "$raw" != "$name" ] && n_stripped=$((n_stripped+1))
done < <(awk -F'\t' '$1 == "ROW" { print $2 "\t" $4 "\t" $5 }' "$INVENTORY")
if [ "$n_stripped" -gt 0 ]; then
  ok "$n_stripped row(s) differ from their source line before the backticks come off"
else
  bad "no row differs from its source line, so the backtick strip is dead code"
fi

echo
echo "part 1b: controls on the shape check"

# `sheet_ctl <code> <label> <awk-program>` writes a broken copy of the live
# sheet, runs the shape check over it, and requires the named defect code back.
sheet_ctl() {
  local code="$1" label="$2" prog="$3" out
  awk "$prog" "$SHEET" > "$WORK/broken"
  out="$(sheet_defects "$WORK/broken" "$EXPECTED")"
  if grep -qE "^${code} " <<<"$out"; then
    ctl_ok "$label"
  else
    ctl_bad "$label"
  fi
}

# The controls sit in a function so one directive covers all of them. The
# single quotes are load-bearing: every program's `$0` and `$2` are awk
# references and must not reach awk already expanded by the shell.
# shellcheck disable=SC2016
sheet_controls() {
  sheet_ctl ENTRYCOUNT "an entry deleted outright" \
    '/^- K001  / { getline; next } { print }'
  sheet_ctl NOSHAPE "an entry whose shape line is gone" \
    '/^- K001  / { print; getline; next } { print }'
  sheet_ctl BADENTRY "an entry line with no chapter field" \
    '/^- K001  / { print "- K001  Operator definition"; next } { print }'
  sheet_ctl PHANTOMID "an id that is in no inventory row" \
    '/^- K001  / { sub(/K001/, "K999"); print; next } { print }'
}
sheet_controls

# UNSORTED needs a real reordering rather than an awk one-liner, so it runs on
# its own: move the last entry to the front, which keeps the set and breaks the
# order. That distinction is the whole point of the control, since a gate that
# compared sets would pass this.
awk '
  /^- K/ { n++ }
  n == 1 { first = first $0 "\n"; next }
  { rest = rest $0 "\n" }
  END { printf "%s", rest; printf "%s", first }
' "$SHEET" > "$WORK/reordered"
out="$(sheet_defects "$WORK/reordered" "$EXPECTED")"
if grep -qE '^UNSORTED ' <<<"$out"; then
  ctl_ok "the first entry moved to the end, so the set is unchanged and the order is not"
else
  ctl_bad "the first entry moved to the end"
fi

# ---------------------------------------------------------------------------
# Part 2: the live file matches the live cheat sheets.
# ---------------------------------------------------------------------------
echo
echo "part 2: the generator reproduces the live file"

if out="$("$GEN" --check 2>&1)"; then
  ok "gen-sheet.sh --check is clean against the real cheat sheets"
else
  bad "gen-sheet.sh --check reports drift. Regenerate with bash scripts/gen-sheet.sh"
  indent "$out"
fi

# ---------------------------------------------------------------------------
# The mirror. The twelve cheat sheets, the inventory and the sheet, so a
# mutation is cheap and the real tree is never touched.
# ---------------------------------------------------------------------------
build_mirror() {
  local dest="$1" rel d f
  rm -rf "$dest"
  mkdir -p "$dest/drill"
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    rel="${f#"$REPO_ROOT"/}"
    d="$dest/${rel%/*}"
    mkdir -p "$d"
    cp "$f" "$d/"
  done < <(sheet_files "$EXERCISES")
  cp "$INVENTORY" "$dest/drill/INVENTORY.md"
  cp "$SHEET" "$dest/drill/SHEET.md"
}

# Runs the generator against a mirror and leaves its exit code in $GEN_RC and
# its combined output in $GEN_OUT.
#
# IT SETS GLOBALS AND RETURNS NOTHING ON STDOUT, on purpose. A `rc="$(run_gen
# ...)"` call form is a SUBSHELL, so GEN_OUT assigned inside it never reaches
# the caller, and the next check then reads a GEN_OUT left over from the
# previous control. harness/test-coverage-map.sh carries a note about the same
# trap, one of its two instances having reported in the passing direction.
#
# WRITE MODE TAKES NO FLAG, so the mode argument is `write` here and becomes an
# empty argv slot. The first draft passed `write` straight through and got
# `unknown argument write`, rc 2, which the part 7 assertions read as a
# generator failure. A mode name that is not a flag has to be translated rather
# than forwarded.
GEN_OUT=""
GEN_RC=0
run_gen() {
  local dest="$1" mode="$2"
  GEN_RC=0
  if [ "$mode" = "write" ]; then
    GEN_OUT="$("$GEN" --root "$dest" 2>&1)" || GEN_RC=$?
  else
    GEN_OUT="$("$GEN" "$mode" --root "$dest" 2>&1)" || GEN_RC=$?
  fi
}

build_mirror "$WORK/base"

echo
echo "part 2b: the mirror is a faithful copy"

n_mirror="$(sheet_files "$WORK/base/exercises" | sed -n '$=')"
if [ "${n_mirror:-0}" -eq "${N_SHEETS:-0}" ]; then
  ok "the mirror holds every cheat sheet the tree does, ${n_mirror:-0}"
else
  bad "the mirror holds ${n_mirror:-0} cheat sheet(s), the tree has ${N_SHEETS:-0}"
fi

run_gen "$WORK/base" --check
if [ "$GEN_RC" = "0" ]; then
  ok "--check is clean against the unmutated mirror"
else
  bad "--check reddens on the unmutated mirror, so every control below is meaningless"
  indent "$GEN_OUT"
fi

# ---------------------------------------------------------------------------
# Part 3: controls that change a cheat sheet.
#
# 3a IS THE BEAD'S RED LINE VERBATIM: a cheat sheet changes and the sheet does
# not. Everything else in this part is a neighbor of it.
# ---------------------------------------------------------------------------
echo
echo "part 3: controls that change a cheat sheet"

CH="exercises/ch02/CHEATSHEET.md"

# `redden <dir> <label>` requires --check to fail against that mirror.
#
# NO VACUITY GUARD HERE, and it does not need one. If a mutation pattern stops
# matching, nothing changes, --check comes back clean and this reports ctl_bad.
# A red-direction control catches its own dead pattern. stay_clean below cannot,
# which is why only that one carries the guard.
redden() {
  run_gen "$1" --check
  if [ "$GEN_RC" != "0" ]; then ctl_ok "$2"; else ctl_bad "$2"; fi
}

# `stay_clean <dir> <label> <mutated-file-relpath>` requires --check to pass
# against that mirror.
#
# IT CHECKS THAT THE MUTATION LANDED FIRST, and without that this whole control
# class is vacuous. These three mutations are awk substitutions keyed on a
# literal line, so a pattern that stops matching changes nothing, --check comes
# back clean, and the control reports a pass for the wrong reason. A control in
# the green direction cannot tell a correct answer from an absent edit, so it
# has to prove the edit happened.
stay_clean() {
  local dest="$1" label="$2" rel="$3"
  if diff -q "$dest/$rel" "$WORK/base/$rel" >/dev/null 2>&1; then
    bad "control setup: $label did not change $rel, so the check below is vacuous"
    return
  fi
  run_gen "$dest" --check
  if [ "$GEN_RC" = "0" ]; then
    ok "$label"
  else
    bad "$label reddened --check, so the sheet churns on an edit it does not carry"
    indent "$GEN_OUT"
  fi
}

# 3a. A syntax shape edited in a cheat sheet. THE BEAD'S RED.
cp -r "$WORK/base" "$WORK/c3a"
awk '
  /^  Syntax shape: `IF cond THEN a ELSE b`$/ { print "  Syntax shape: `IF c THEN x ELSE y`"; next }
  { print }' "$WORK/c3a/$CH" > "$WORK/t" && mv "$WORK/t" "$WORK/c3a/$CH"
redden "$WORK/c3a" "K002's syntax shape edited in the cheat sheet, sheet not regenerated"

# 3b. A continuation line deleted from a multi-line shape. This is the control
# that proves the fold is real. Four constructs carry a shape that runs past
# its own `Syntax shape:` line, and a generator reading only the first line
# would truncate them and never notice this edit.
cp -r "$WORK/base" "$WORK/c3b"
awk '
  /^  the right of the `=`, no quotes and no digits, is a model value\.$/ { next }
  { print }' "$WORK/c3b/exercises/ch05/CHEATSHEET.md" > "$WORK/t" \
  && mv "$WORK/t" "$WORK/c3b/exercises/ch05/CHEATSHEET.md"
redden "$WORK/c3b" "K041's shape continuation line deleted, so the fold is load-bearing"

# 3c. A construct renamed in the cheat sheet. The inventory's field 4 no longer
# agrees, and the generator has to refuse by name rather than absorb it.
cp -r "$WORK/base" "$WORK/c3c"
awk '
  /^- Construct: `IF-THEN-ELSE`$/ { print "- Construct: `IF-THEN-OTHERWISE`"; next }
  { print }' "$WORK/c3c/$CH" > "$WORK/t" && mv "$WORK/t" "$WORK/c3c/$CH"
run_gen "$WORK/c3c" --check
if [ "$GEN_RC" != "0" ] && grep -qF -- 'DISAGREE' <<<"$GEN_OUT"; then
  ctl_ok "a renamed construct is refused by name, not absorbed"
elif [ "$GEN_RC" != "0" ]; then
  ctl_bad "a renamed construct reddened for some other reason than the name"
else
  ctl_bad "a renamed construct"
fi

# 3d. A construct entry added with no inventory row. This is the silent
# direction: the generated sheet would still carry 105 correct entries.
cp -r "$WORK/base" "$WORK/c3d"
awk '
  /^- Construct: `IF-THEN-ELSE`$/ && !done {
    print "- Construct: `IF-THEN-MAYBE`"
    print "  Syntax shape: `IF c THEN x`"
    print "  Section anchor: `operators#maybe`"
    print ""
    done = 1
  }
  { print }' "$WORK/c3d/$CH" > "$WORK/t" && mv "$WORK/t" "$WORK/c3d/$CH"
run_gen "$WORK/c3d" --check
if [ "$GEN_RC" != "0" ] && grep -qF -- 'UNCLAIMED' <<<"$GEN_OUT"; then
  ctl_ok "a construct with no inventory row is named rather than quietly dropped"
elif [ "$GEN_RC" != "0" ]; then
  ctl_bad "an unclaimed construct reddened for some other reason"
else
  ctl_bad "a construct added with no inventory row"
fi

# 3e. A construct entry deleted from a cheat sheet.
cp -r "$WORK/base" "$WORK/c3e"
awk '
  /^- Construct: `IF-THEN-ELSE`$/ { skip = 4 }
  skip > 0 { skip--; next }
  { print }' "$WORK/c3e/$CH" > "$WORK/t" && mv "$WORK/t" "$WORK/c3e/$CH"
redden "$WORK/c3e" "K002's whole entry deleted from the cheat sheet"

# 3f. A line inserted above an entry, which shifts every later field 5 off its
# target. The text comparison is what catches it, so this control also proves
# field 5 is being resolved rather than trusted.
cp -r "$WORK/base" "$WORK/c3f"
awk 'NR == 9 { print "An inserted line." } { print }' "$WORK/c3f/$CH" > "$WORK/t" \
  && mv "$WORK/t" "$WORK/c3f/$CH"
run_gen "$WORK/c3f" --check
if [ "$GEN_RC" != "0" ] && grep -qE 'DISAGREE|UNRESOLVED' <<<"$GEN_OUT"; then
  ctl_ok "a line inserted above an entry shifts field 5 and is caught by name"
elif [ "$GEN_RC" != "0" ]; then
  ctl_bad "a shifted field 5 reddened for some other reason"
else
  ctl_bad "a line inserted above an entry"
fi

# 3g and 3h. The other direction. Neither of these is material the sheet
# carries, so both have to leave --check clean.
cp -r "$WORK/base" "$WORK/c3g"
awk '
  /^  Section anchor: `operators#if_tla`$/ { print "  Section anchor: `operators#moved`"; next }
  { print }' "$WORK/c3g/$CH" > "$WORK/t" && mv "$WORK/t" "$WORK/c3g/$CH"
stay_clean "$WORK/c3g" "a changed Section anchor" "$CH"

cp -r "$WORK/base" "$WORK/c3h"
awk '
  /^  Toolbox equivalent: / { print "  Toolbox equivalent: `X <- [something else]`"; next }
  { print }' "$WORK/c3h/exercises/ch05/CHEATSHEET.md" > "$WORK/t" \
  && mv "$WORK/t" "$WORK/c3h/exercises/ch05/CHEATSHEET.md"
stay_clean "$WORK/c3h" "a changed Toolbox equivalent, which this file does not carry" "exercises/ch05/CHEATSHEET.md"

# ---------------------------------------------------------------------------
# Part 4: controls that change the sheet itself.
# ---------------------------------------------------------------------------
echo
echo "part 4: controls that hand-edit drill/SHEET.md"

MSHEET="drill/SHEET.md"

# `poke_sheet <dir> <awk-program>` rewrites the mirror's sheet in place.
poke_sheet() {
  local dest="$1" prog="$2"
  awk "$prog" "$dest/$MSHEET" > "$dest/sheet.tmp"
  mv "$dest/sheet.tmp" "$dest/$MSHEET"
}

# The four programs sit in one function so one directive covers them. The
# single quotes are load-bearing: `$0` is awk's whole record.
# shellcheck disable=SC2016
sheet_edit_controls() {
  cp -r "$WORK/base" "$WORK/c4a"
  poke_sheet "$WORK/c4a" '/^- K050  / { getline; next } { print }'
  redden "$WORK/c4a" "an entry deleted from the sheet by hand"

  cp -r "$WORK/base" "$WORK/c4b"
  poke_sheet "$WORK/c4b" '/^- K050  / { print; getline; print "  `nonsense`"; next } { print }'
  redden "$WORK/c4b" "a shape rewritten in the sheet by hand"

  cp -r "$WORK/base" "$WORK/c4c"
  poke_sheet "$WORK/c4c" '/^- K050  / { sub(/ch06/, "ch99"); print; next } { print }'
  redden "$WORK/c4c" "a chapter field rewritten in the sheet by hand"

  cp -r "$WORK/base" "$WORK/c4d"
  poke_sheet "$WORK/c4d" '/^105 entries, sorted/ { sub(/^105/, "99"); print; next } { print }'
  redden "$WORK/c4d" "the header's entry count rewritten in the sheet by hand"
}
sheet_edit_controls

# The sheet deleted outright. --check has to say so rather than crash.
cp -r "$WORK/base" "$WORK/c4e"
rm -f "$WORK/c4e/$MSHEET"
run_gen "$WORK/c4e" --check
if [ "$GEN_RC" != "0" ] && grep -qF -- 'no sheet at' <<<"$GEN_OUT"; then
  ctl_ok "the sheet deleted outright is reported by name"
elif [ "$GEN_RC" != "0" ]; then
  ctl_bad "a missing sheet reddened for some other reason than being missing"
else
  ctl_bad "the sheet deleted outright"
fi

# ---------------------------------------------------------------------------
# Part 5: controls that change the inventory.
#
# The inventory is the join. A row that stops pointing at its own construct
# line has to be named, because the alternative is a sheet entry carrying
# another construct's shape, which is the worst output this file can produce.
# ---------------------------------------------------------------------------
echo
echo "part 5: controls that change drill/INVENTORY.md"

MINV="drill/INVENTORY.md"

poke_inv() {
  local dest="$1" prog="$2"
  awk -F'\t' -v OFS='\t' "$prog" "$dest/$MINV" > "$dest/inv.tmp"
  mv "$dest/inv.tmp" "$dest/$MINV"
}

# shellcheck disable=SC2016
inv_controls() {
  # 5a. Two rows naming the same source line.
  cp -r "$WORK/base" "$WORK/c5a"
  poke_inv "$WORK/c5a" '$1 == "ROW" && $2 == "K002" { $5 = "exercises/ch02/CHEATSHEET.md:11" } { print }'
  run_gen "$WORK/c5a" --check
  if [ "$GEN_RC" != "0" ] && grep -qF -- 'DUPSOURCE' <<<"$GEN_OUT"; then
    ctl_ok "two rows naming one construct line"
  elif [ "$GEN_RC" != "0" ]; then
    ctl_bad "two rows naming one construct line reddened for some other reason"
  else
    ctl_bad "two rows naming one construct line"
  fi

  # 5b. A K id that is not three digits. A plain sort only orders KNNN, so the
  # generator names a wider id rather than mis-ordering the file in silence.
  cp -r "$WORK/base" "$WORK/c5b"
  poke_inv "$WORK/c5b" '$1 == "ROW" && $2 == "K002" { $2 = "K2" } { print }'
  run_gen "$WORK/c5b" --check
  if [ "$GEN_RC" != "0" ] && grep -qF -- 'BADID' <<<"$GEN_OUT"; then
    ctl_ok "a K id outside KNNN, which a plain sort would mis-order"
  elif [ "$GEN_RC" != "0" ]; then
    ctl_bad "a malformed K id reddened for some other reason"
  else
    ctl_bad "a K id outside KNNN"
  fi

  # 5c. A row deleted. The construct it covered is then unclaimed.
  cp -r "$WORK/base" "$WORK/c5c"
  poke_inv "$WORK/c5c" '$1 == "ROW" && $2 == "K002" { next } { print }'
  redden "$WORK/c5c" "an inventory row deleted outright"

  # 5d. Field 5 pointing at a line that is not a construct line.
  cp -r "$WORK/base" "$WORK/c5d"
  poke_inv "$WORK/c5d" '$1 == "ROW" && $2 == "K002" { $5 = "exercises/ch02/CHEATSHEET.md:1" } { print }'
  run_gen "$WORK/c5d" --check
  if [ "$GEN_RC" != "0" ] && grep -qF -- 'UNRESOLVED' <<<"$GEN_OUT"; then
    ctl_ok "field 5 pointing at a line that is not a construct line"
  elif [ "$GEN_RC" != "0" ]; then
    ctl_bad "an unresolvable field 5 reddened for some other reason"
  else
    ctl_bad "field 5 pointing at a line that is not a construct line"
  fi

  # 5e. The other direction. A hand-authored field the sheet does not carry has
  # to leave --check clean.
  cp -r "$WORK/base" "$WORK/c5e"
  poke_inv "$WORK/c5e" '$1 == "ROW" && $2 == "K002" { $6 = "low" } { print }'
  stay_clean "$WORK/c5e" "a changed inventory weight, which this file does not carry" "$MINV"
}
inv_controls

# ---------------------------------------------------------------------------
# Part 6: both awk passes report their findings.
#
# Two awk runs write into one defects file, and awk's `>` truncates on the
# first write of each run, so a `>` in the join pass deletes everything the
# flatten pass found. That is not hypothetical: it happened on this script's
# first run and a BADCHAPTER line was written and then deleted before anybody
# read it. The failure direction is a lost finding, which reads exactly like a
# clean run.
#
# The control plants a chapter directory named `chAB`. It matches the `ch*`
# glob, so the flatten pass finds it and reports BADCHAPTER, and its entries
# have no inventory rows, so the join pass reports COUNT. Both codes have to
# come back from one run.
# ---------------------------------------------------------------------------
echo
echo "part 6: a finding from the first awk pass survives the second"

cp -r "$WORK/base" "$WORK/c6"
mkdir -p "$WORK/c6/exercises/chAB"
cp "$WORK/c6/$CH" "$WORK/c6/exercises/chAB/CHEATSHEET.md"
run_gen "$WORK/c6" --check
if [ "$GEN_RC" = "0" ]; then
  ctl_bad "a chapter directory named chAB"
else
  has_chap=no
  has_count=no
  grep -qF -- 'BADCHAPTER' <<<"$GEN_OUT" && has_chap=yes
  grep -qF -- 'COUNT' <<<"$GEN_OUT" && has_count=yes
  if [ "$has_chap" = yes ] && [ "$has_count" = yes ]; then
    ctl_ok "chAB reports BADCHAPTER from the flatten pass and COUNT from the join pass, in one run"
  else
    bad "only one pass's findings survived: BADCHAPTER $has_chap, COUNT $has_count"
    indent "$GEN_OUT"
  fi
fi

# ---------------------------------------------------------------------------
# Part 7: the generator is the authority, not a differ.
# ---------------------------------------------------------------------------
echo
echo "part 7: the sheet rebuilds from nothing, byte for byte"

# DELETE THE SHEET FIRST. Running --check against a mirror that already
# carries the answer passes whether or not the generator can build it. Deleting
# it forces the run to rebuild from the cheat sheets, which is the thing being
# measured.
cp -r "$WORK/base" "$WORK/c7"
rm -f "$WORK/c7/$MSHEET"
run_gen "$WORK/c7" write
if [ "$GEN_RC" != "0" ]; then
  bad "write mode failed against a mirror with no sheet, rc $GEN_RC"
  indent "$GEN_OUT"
elif diff -u "$SHEET" "$WORK/c7/$MSHEET" > "$WORK/rebuild-diff"; then
  ok "a sheet rebuilt from nothing matches the live file byte for byte"
else
  bad "a sheet rebuilt from nothing differs from the live file:"
  indent "$(cat "$WORK/rebuild-diff")"
fi

# A dot directory in the path. An unanchored `! -path '*/.*'` in the file sweep
# would match the worktree's own `.claude/worktrees/agent-*` and find no cheat
# sheet at all. That run comes back with an empty sheet rather than a crash, so
# nothing but a control catches it.
echo
echo "part 7b: a dot directory in the path does not hide the cheat sheets"

mkdir -p "$WORK/.hidden"
cp -r "$WORK/base" "$WORK/.hidden/tree"
rm -f "$WORK/.hidden/tree/$MSHEET"
run_gen "$WORK/.hidden/tree" write
if [ "$GEN_RC" != "0" ]; then
  bad "write mode failed with the tree under a dot directory, rc $GEN_RC"
  indent "$GEN_OUT"
elif diff -q "$SHEET" "$WORK/.hidden/tree/$MSHEET" >/dev/null; then
  ok "a sheet rebuilt under a dot directory matches the live file"
else
  bad "a dot directory in the path changed the generator's answer"
fi

# --stdout changes nothing on disk.
echo
echo "part 7c: --stdout writes nothing"

cp -r "$WORK/base" "$WORK/c7c"
before="$(cksum < "$WORK/c7c/$MSHEET")"
run_gen "$WORK/c7c" --stdout
after="$(cksum < "$WORK/c7c/$MSHEET")"
n_out="$(awk '/^- K/ { n++ } END { print n+0 }' <<<"$GEN_OUT")"
if [ "$GEN_RC" = "0" ] && [ "$before" = "$after" ] && [ "$n_out" -eq "$EXPECTED" ]; then
  ok "--stdout printed $n_out entries and left the file alone"
else
  bad "--stdout printed $n_out entries (want $EXPECTED), rc $GEN_RC, file changed: $([ "$before" = "$after" ] && echo no || echo yes)"
fi

printf '\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
