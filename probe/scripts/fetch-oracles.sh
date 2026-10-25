#!/usr/bin/env bash
# fetch-oracles.sh: put each probe item's requirement module next to its
# brief, fetched from the published repository at a pinned commit.
#
# WHY THE MODULES ARE NOT IN THIS REPO
#
# Bead tla-16je is open about redistributing corpus specifications without a
# license, and bead tla-9bnj rules that the probe's requirement modules get
# fetched at setup rather than committed. So this script ships and the files
# do not. .gitignore names both of them by path, and harness/probe-gate.sh
# asserts that it still does, which is the part that would otherwise rot.
#
# Worth recording, because it narrows the worry rather than settling it: both
# of these two files are MIT licensed, so committing them with their copyright
# notice would have been allowed. The five unlicensed repositories tla-16je
# names are a different set. I am fetching anyway, because the rule the bead
# wrote is the rule, and because a fetch keeps the pin honest in a way a
# committed copy does not.
#
# THE DIGEST IS THE POINT, NOT THE SHA
#
# A commit SHA says which tree GitHub was asked for. The digest says what
# arrived. A proxy, a truncated download or a retargeted tag all pass the
# first check and fail the second, so the digest is what decides. A mismatch
# refuses and keeps nothing.
#
# Usage:  probe/scripts/fetch-oracles.sh [--verify] [dest-root]
#
#   dest-root   the probe tree to fetch into. Defaults to the one this script
#               sits in, which is the repo's own probe/.
#   --verify    check what is already there and write nothing. Exit 0 when
#               every module is present and matches, 3 when one is missing or
#               differs, 1 on an error.
#
# Exit: 0 all present and matching, 1 an error, 3 a fetch is owed (--verify).

set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROBE_ROOT=$(cd "$HERE/.." && pwd)

# item | destination filename | url | sha256
#
# The BlockingQueue SHA is the one corpus/manifest.tsv and
# .claude/rules/tla-practice.md both record, so this item reads the same
# snapshot the corpus survey read. The Examples SHA is NOT: the survey read
# ceeaa90 and this is the tip as of 2026-10-25, because an abbreviated SHA is
# not a reliable raw.githubusercontent path. The digest below is what makes
# that safe either way.
ORACLES=(
  "p1-commit|TCommit.tla|https://raw.githubusercontent.com/tlaplus/Examples/0cab2b3fbfefc6d48a9f84a432f5bb5498738d46/specifications/transaction_commit/TCommit.tla|98974d8c5ee007f4f62188737c20c7dcdb05af099cc53a59c8b8651331fd925d"
  "p2-queue|BlockingQueue.tla|https://raw.githubusercontent.com/lemmy/BlockingQueue/68715979666344cbcc66fa621b27039f281bdd5c/BlockingQueue.tla|f69a5717596f1989cd5a5b933005f3ea6cccadada4e45438a8cf4500ee68935a"
)

VERIFY=0
DEST_ROOT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --verify) VERIFY=1; shift ;;
    -h|--help) sed -n '/^# Usage:/,/^# Exit:/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "$0: unknown option: $1" >&2; exit 1 ;;
    *)  [ -z "$DEST_ROOT" ] || { echo "$0: one dest-root, not two" >&2; exit 1; }
        DEST_ROOT="$1"; shift ;;
  esac
done
[ -n "$DEST_ROOT" ] || DEST_ROOT="$PROBE_ROOT"
DEST_ROOT="${DEST_ROOT%/}"

command -v sha256sum >/dev/null 2>&1 || { echo "$0: sha256sum is not on the path" >&2; exit 1; }
if [ "$VERIFY" -eq 0 ]; then
  command -v curl >/dev/null 2>&1 || { echo "$0: curl is not on the path" >&2; exit 1; }
fi

digest_of() {   # digest_of <file>
  local out
  out=$(sha256sum "$1") || return 1
  printf '%s\n' "${out%% *}"
}

RC=0
OWED=0

for row in "${ORACLES[@]}"; do
  item="${row%%|*}"; rest="${row#*|}"
  name="${rest%%|*}";  rest="${rest#*|}"
  url="${rest%%|*}"
  want="${rest##*|}"

  dir="$DEST_ROOT/$item"
  dest="$dir/$name"

  if [ ! -d "$dir" ]; then
    echo "MISSING ITEM: no $dir, so $name has nowhere to land" >&2
    RC=1
    continue
  fi

  if [ -f "$dest" ]; then
    have=$(digest_of "$dest") || { echo "ERROR: cannot read $dest" >&2; RC=1; continue; }
    if [ "$have" = "$want" ]; then
      echo "ok       $item/$name"
      continue
    fi
    if [ "$VERIFY" -eq 1 ]; then
      echo "DIFFERS  $item/$name"
      echo "         have $have"
      echo "         want $want"
      OWED=1
      continue
    fi
    echo "replacing $item/$name, which does not match its recorded digest"
  elif [ "$VERIFY" -eq 1 ]; then
    echo "ABSENT   $item/$name"
    OWED=1
    continue
  fi

  tmp="$dest.fetching"
  if ! curl -sSfL --max-time 60 -o "$tmp" "$url"; then
    echo "ERROR: fetch failed for $item/$name" >&2
    echo "       $url" >&2
    rm -f "$tmp"
    RC=1
    continue
  fi
  have=$(digest_of "$tmp") || { echo "ERROR: cannot read what was fetched" >&2; rm -f "$tmp"; RC=1; continue; }
  if [ "$have" != "$want" ]; then
    echo "REFUSED: $item/$name arrived with the wrong digest, so it is not what this" >&2
    echo "         probe was built against. Keeping nothing." >&2
    echo "         have $have" >&2
    echo "         want $want" >&2
    rm -f "$tmp"
    RC=1
    continue
  fi
  mv "$tmp" "$dest" || { echo "ERROR: cannot write $dest" >&2; rm -f "$tmp"; RC=1; continue; }
  echo "fetched  $item/$name"
done

if [ "$RC" -ne 0 ]; then
  exit "$RC"
fi
if [ "$VERIFY" -eq 1 ] && [ "$OWED" -eq 1 ]; then
  echo
  echo "A fetch is owed. Run this script without --verify."
  exit 3
fi
exit 0
