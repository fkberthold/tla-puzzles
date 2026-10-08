#!/usr/bin/env bash
# run-labels.sh — check the prose model's actions against the diagram's edge
# LABELS, which is a separate question from whether the graphs agree.
#
# The graph question is MCDiagram.cfg (PROPERTY Refines). It comes back rc=0.
# These rows ask which prose action sits on which labelled edge, and that is
# where the two documents part company.
#
# Expectations are declared per row, same reason as run-probes.sh.
set -uo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

ROWS=(
  "MCDiagram       MCDiagram.cfg          0"
  "MCDiagram       label-failedquery.cfg 13"
  "MCDiagram       label-giveup.cfg       0"
  "MCDiagram       label-retryloop.cfg    0"
  "MCWedgedDiagram MCWedgedDiagram.cfg    0"
)

printf 'module\tcfg\ttoken\trc\texpected\tagrees\n'
fails=0
for row in "${ROWS[@]}"; do
  # Word-splitting on a three-field row is the intent here.
  # shellcheck disable=SC2086
  set -- $row
  mod="$1"; cfg="$2"; want="$3"
  token="$(bash "$HERE/run-check.sh" "$mod" "$cfg")"
  rc=$?
  agrees="yes"
  if [ "$rc" != "$want" ]; then
    agrees="DISAGREE"
    fails=$((fails + 1))
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$mod" "$cfg" "$token" "$rc" "$want" "$agrees"
done

printf '\n%s row(s) disagreed with the declared expectation\n' "$fails"
exit 0
