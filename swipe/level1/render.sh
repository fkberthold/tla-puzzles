#!/usr/bin/env bash
# render.sh -- the model screen a level 1 swipe item shows (bead tla-7xql.4,
# epic tla-7xql).
#
# A level 1 item pins a state and asks a question about it, so unlike level 0
# it needs a screen. Decision D7 on the epic says what goes on it: the
# definitions, the CONSTANTS and the pin, and not Init, not Next, not Spec and
# not the fairness conjunct. Decision D2 says the model is shown with its
# INVARIANT and PROPERTY declarations stripped, from the .cfg and the .tla
# both, because a model that ships its obligations asserts its own answers.
#
# THE STRIP IS TRANSITIVE, AND THAT IS THE RULE THIS FILE EXISTS FOR.
#
# D2 names the obligations and stops there. Obligations have helpers. Brackets
# defines Opens and Closes, which are free definitions rather than
# obligations, so field 8 of harness/levels/levels.sh keeps them. They are
# used by Surplus and PrefixSound and by nothing else, so leaving them in
# puts two definitions on a phone screen that no question can ever be about.
# Contention is the same shape one definition over: Holder is free and only
# TypeOK uses it.
#
# So the kept set is computed forward from what the reader may be asked about
# rather than backward from what D2 removes:
#
#   SHOWN ROOTS  every level 2 definition this module declares, except Next
#                and the SPECIFICATION formula. That is every action, and
#                FINDING 2 on this bead is that it has to be every action
#                rather than the ones a claim names. On a terminal item the
#                reader needs all of them and on an ENABLED item one, so a
#                shown set that tracked the claim would itself carry the
#                answer.
#
#   KEPT         the shown roots plus every definition they transitively use.
#
#   STRIPPED     everything else: the obligations, their helpers, Init, Next,
#                Spec, the fairness conjunct, vars, and any definition the
#                module declares and nothing reaches.
#
# Computing it forward also strips a definition nothing uses at all, which the
# backward reading leaves on the screen, and it needs no special case for
# Init, Next or Spec: Init is level 1 and the other two are level 3, so
# neither is a shown root to begin with. Next is excluded by name because it
# IS level 2, and D7 names it.
#
# THE CLAIM MAY ONLY NAME A SHOWN DEFINITION. A terminal item asks
# ~ENABLED (Push \/ Pop) and never ~ENABLED Next, because Next is not on the
# screen and a reader cannot evaluate a name they have not been given. The
# gate asserts this over the corpus; this file provides --list-shown so it
# can.
#
# USAGE
#   swipe/level1/render.sh --model PATH [OPTIONS]
#   swipe/level1/render.sh --item ID [OPTIONS]
#
#   --model PATH      a reading/ module. Its .cfg is read from beside it
#   --model-path NAME print where a module NAME lives and stop. One place
#                     resolves a name to a path, and this is how a caller
#                     reaches it rather than writing a second find
#   --item ID         render a whole item from swipe/level1/ITEMS.tsv
#   --items FILE      read a different item table
#   --list-shown      print the kept definition names, one per line
#   --list-stripped   print the stripped ones, with the reason
#   --screen          the model screen only, with no pin and no question
#   -h, --help        this text
#
# EXIT
#   0  rendered
#   1  the module declares no action, or the item id is not in the table
#   2  usage error

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LEVELS="$ROOT/harness/levels/levels.sh"
ITEMS="$ROOT/swipe/level1/ITEMS.tsv"

MODEL=""
ITEM=""
MODE="full"
PATHOF=""

usage() {
  awk 'NR == 1 { next } /^[^#]/ { exit } { print }' "${BASH_SOURCE[0]}"
}

die() { printf 'render.sh: %s\n' "$1" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --model)          MODEL="${2:-}"; shift 2 ;;
    --model-path)     PATHOF="${2:-}"; shift 2 ;;
    --item)           ITEM="${2:-}"; shift 2 ;;
    --items)          ITEMS="${2:-}"; shift 2 ;;
    --list-shown)     MODE="shown"; shift ;;
    --list-stripped)  MODE="stripped"; shift ;;
    --screen)         MODE="screen"; shift ;;
    -h|--help)        usage; exit 0 ;;
    *) die "unknown option: $1" ;;
  esac
done

# ---------------------------------------------------------------------------
# Resolving a model name to its path. The item table carries the module name
# rather than the path, so one place has to do the lookup and this is it.
# ---------------------------------------------------------------------------
# The first line comes out by parameter expansion rather than by a pipe into
# head. A producer piped into an early-exiting consumer returns 141 under
# pipefail: head closes the pipe after one line, sort takes SIGPIPE, and
# inside an `if` that reads as a clean false rather than as an error.
model_path() {
  local name="$1" hits
  hits="$(find "$ROOT/reading" -name "$name.tla" -type f | LC_ALL=C sort)"
  [ -n "$hits" ] || die "no reading/ module called $name"
  printf '%s\n' "${hits%%$'\n'*}"
}

if [ -n "$PATHOF" ]; then
  model_path "$PATHOF"
  exit 0
fi

ASK="" CLAIM="" PIN="" MODELNAME=""
if [ -n "$ITEM" ]; then
  row="$(awk -F'\t' -v id="$ITEM" '$1 == "ITEM" && $2 == id' "$ITEMS")"
  [ -n "$row" ] || { printf 'render.sh: no item %s in %s\n' "$ITEM" "$ITEMS" >&2; exit 1; }
  mapfile -t F < <(awk -F'\t' '{for (i = 1; i <= NF; i++) print $i}' <<<"$row")
  ASK="${F[3]}"
  CLAIM="${F[8]}"
  MODELNAME="${F[11]}"
  PIN="${F[12]}"
  MODEL="$(model_path "$MODELNAME")"
fi

[ -n "$MODEL" ] || die "need --model PATH or --item ID"
[ -f "$MODEL" ] || die "no such module: $MODEL"

MODULE="$(basename "$MODEL" .tla)"
CFG="${MODEL%.tla}.cfg"

# ---------------------------------------------------------------------------
# The level table. levels.sh reads SANY's semantic tree, so the level of a
# definition is read rather than guessed from its text. Bead tla-7xql.3 built
# it for exactly this.
# ---------------------------------------------------------------------------
LEVELROWS="$("$LEVELS" --defs-only "$MODEL")" || die "levels.sh refused $MODEL"

# The SPECIFICATION formula, so it is never a shown root even though it is
# level 3 and would not be one anyway. Named here because a module may call it
# something other than Spec.
SPECNAME="$(awk '$1 == "SPECIFICATION" { print $2; exit }' "$CFG")"
[ -n "$SPECNAME" ] || SPECNAME="Spec"

# ---------------------------------------------------------------------------
# The definition spans, read off the module text.
#
# A top-level construct starts at any line whose first character is neither a
# space nor a tab, and a construct runs until the next one. A column-0 comment
# belongs to the construct it sits above, which is how the authored notes in
# Nim and Josephus stay attached to the definition they explain.
#
# A nested module is skipped whole. Fences declares one, and its definitions
# are not the outer module's to show.
# ---------------------------------------------------------------------------
spans() {
  awk '
    function flush(   i) {
      if (start > 0) printf("SPAN\t%s\t%d\t%d\t%s\n", kind, start, NR - 1, name)
      start = 0; kind = ""; name = ""
    }
    /^----+[ ]*MODULE/ {
      nmod++
      if (nmod > 1) { flush(); nested = 1 }
      next
    }
    nested && /^====/ { nested = 0; next }
    nested { next }
    /^[ \t]*$/ { next }
    /^[ \t]/ { next }
    /^\\\*/ {
      if (pend == 0) { pend = NR }
      next
    }
    {
      flush()
      start = (pend > 0) ? pend : NR
      pend = 0
      name = ""
      if ($0 ~ /^(VARIABLES?)[ \t]/)      { kind = "vars" }
      else if ($0 ~ /^(CONSTANTS?)[ \t]*/) { kind = "consts" }
      else if ($0 ~ /^(EXTENDS|ASSUME|THEOREM|RECURSIVE|LOCAL|INSTANCE)[ \t]/) { kind = "other" }
      else if ($0 ~ /^====/)               { kind = "end" }
      else if ($0 ~ /^[A-Za-z_][A-Za-z0-9_]*[ \t]*(\([^)]*\))?[ \t]*==/) {
        kind = "def"
        name = $0
        sub(/[ \t]*(\([^)]*\))?[ \t]*==.*$/, "", name)
      }
      else { kind = "other" }
    }
    END { flush() }
  ' "$MODEL"
}

SPANS="$(spans)"

# Every definition name this module declares, so the use scan below can tell a
# sibling definition from an operator the EXTENDS brought in.
DEFNAMES="$(awk -F'\t' '$2 == "def" { print $5 }' <<<"$SPANS")"

# ---------------------------------------------------------------------------
# The shown roots, and then the closure.
# ---------------------------------------------------------------------------
ROOTS="$(awk -F'\t' -v mod="$MODULE" -v spec="$SPECNAME" '
  $1 == "DEF" && $4 == 2 && $6 == mod && $3 != "Next" && $3 != spec && $3 !~ /!/ { print $3 }
' <<<"$LEVELROWS" | LC_ALL=C sort -u)"

if [ -z "$ROOTS" ]; then
  printf 'render.sh: %s declares no action, so there is nothing to show\n' "$MODULE" >&2
  exit 1
fi

# The body of one definition, comments and string literals removed, so a name
# inside a comment never counts as a use.
body_of() {
  local name="$1" s e
  s="$(awk -F'\t' -v n="$name" '$2 == "def" && $5 == n { print $3; exit }' <<<"$SPANS")"
  e="$(awk -F'\t' -v n="$name" '$2 == "def" && $5 == n { print $4; exit }' <<<"$SPANS")"
  [ -n "$s" ] || return 0
  sed -n "${s},${e}p" "$MODEL" | sed 's/\\\*.*$//' | sed 's/"[^"]*"/ /g'
}

KEPT="$ROOTS"
# A closure over at most as many definitions as the module declares, so the
# loop is bounded by the module rather than by a guess at a depth.
ROUNDS="$(grep -c . <<<"$DEFNAMES" || true)"
i=0
while [ "$i" -le "$ROUNDS" ]; do
  i=$((i + 1))
  ADDED=""
  while IFS= read -r k; do
    [ -n "$k" ] || continue
    uses="$(body_of "$k" | grep -oE '[A-Za-z_][A-Za-z0-9_]*' | LC_ALL=C sort -u || true)"
    while IFS= read -r u; do
      [ -n "$u" ] || continue
      case $'\n'"$DEFNAMES"$'\n' in *$'\n'"$u"$'\n'*) ;; *) continue ;; esac
      [ "$u" = "$k" ] && continue
      case $'\n'"$KEPT"$'\n' in *$'\n'"$u"$'\n'*) continue ;; esac
      ADDED="$ADDED$u"$'\n'
    done <<<"$uses"
  done <<<"$KEPT"
  [ -n "$ADDED" ] || break
  KEPT="$(printf '%s\n%s' "$KEPT" "${ADDED%$'\n'}" | grep -c . >/dev/null 2>&1 || true; printf '%s\n%s' "$KEPT" "${ADDED%$'\n'}")"
  KEPT="$(LC_ALL=C sort -u <<<"$KEPT" | grep -v '^$' || true)"
done

if [ "$MODE" = "shown" ]; then
  printf '%s\n' "$KEPT"
  exit 0
fi

if [ "$MODE" = "stripped" ]; then
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    case $'\n'"$KEPT"$'\n' in *$'\n'"$d"$'\n'*) continue ;; esac
    reason="not reached from any action"
    if awk -F'\t' -v n="$d" '$1 == "DEF" && $3 == n && $8 == "obligation" { found = 1 } END { exit !found }' <<<"$LEVELROWS"; then
      reason="an obligation the .cfg declares (D2)"
    elif [ "$d" = "Init" ] || [ "$d" = "Next" ] || [ "$d" = "$SPECNAME" ]; then
      reason="the machine, which D7 withholds"
    fi
    printf '%s\t%s\n' "$d" "$reason"
  done <<<"$DEFNAMES"
  exit 0
fi

# ---------------------------------------------------------------------------
# The screen itself.
# ---------------------------------------------------------------------------
indent() { sed 's/^/   /'; }

# A span ends at the line before the next construct, so it carries whatever
# blank lines the author left between the two. Trimming them here rather than
# in spans() keeps the span honest about where the construct ends.
trim_trailing_blanks() {
  awk '{ buf[++n] = $0 } END { while (n > 0 && buf[n] ~ /^[ \t]*$/) n--; for (i = 1; i <= n; i++) print buf[i] }'
}

screen() {
  # The CONSTANTS come from the .cfg, which is where their values live, and
  # D1 says they stay visible because they change every answer. The block is
  # copied rather than reformatted, so a CONSTANTS list over several lines
  # arrives the way its author wrote it.
  awk '
    /^[[:space:]]*CONSTANTS?([[:space:]]|$)/ { inb = 1; print; next }
    inb && /^[[:space:]]+[^[:space:]]/ { print; next }
    inb { inb = 0 }
  ' "$CFG"

  awk -F'\t' '$2 == "vars" { print $3, $4 }' <<<"$SPANS" | while read -r s e; do
    sed -n "${s},${e}p" "$MODEL" | trim_trailing_blanks
  done

  while IFS=$'\t' read -r _ kind s e name; do
    [ "$kind" = "def" ] || continue
    case $'\n'"$KEPT"$'\n' in *$'\n'"$name"$'\n'*) ;; *) continue ;; esac
    printf '\n'
    sed -n "${s},${e}p" "$MODEL" | trim_trailing_blanks
  done < <(awk -F'\t' '{print}' <<<"$SPANS")
}

screen | indent

[ "$MODE" = "screen" ] && exit 0
[ -n "$ITEM" ] || exit 0

RULE='   ------------------------------'

printf '\n%s pinned at\n' "$RULE"
printf '%s\n' "$PIN" | sed 's/ *\/\\ */\n/g' | sed '/^$/d' | indent
printf '%s\n' "$RULE"

case "$ASK" in
  enabled)  prompt="does this fire here" ;;
  terminal) prompt="is this where it stops" ;;
  implies)  prompt="does this follow here" ;;
  *)        prompt="$ASK" ;;
esac
printf '\n   %s\n\n' "$prompt"
printf '      %s\n' "$CLAIM"
