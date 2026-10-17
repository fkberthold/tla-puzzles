#!/usr/bin/env bash
# deliver-drill.sh: deliver the blank-page drill prompts into a practice tree,
# without handing over the worked answer, an item's own construct list, or the
# modules that prove the answer checks.
#
# Usage:  scripts/deliver-drill.sh [--check] [--refresh-prompts] [dest-root]
#         scripts/deliver-drill.sh --study [--check] [study-root]
#
#   --check            resolve everything and print what would be delivered.
#                      Writes nothing.
#   --refresh-prompts  replace a delivered PROMPT.md whose content differs from
#                      the source. OFF BY DEFAULT. A run without it reaches no
#                      code that can overwrite a prompt, so a plain delivery
#                      cannot replace one. Read "WHY --refresh-prompts EXISTS"
#                      below before you reach for it.
#   --study            deliver the study-side configuration instead of the
#                      prompts. Read "THE STUDY MODE" below. The root must
#                      already exist and is never created here.
#   dest-root          where to deliver into (default: $HOME/tla-practice/drill)
#
# Env:    DELIVER_DRILL_SRC_ROOT   override the source repo root (default: the
#                                  repo this script lives in)
#         DRILL_STUDY_ROOT         --study only: where the study tree lives
#                                  (default: $HOME/Study/tla-drills)
#
# Exit:   0 on success, including a run that only skipped prompts already there
#         1 on a usage error, a source tree holding no item, an item carrying
#           no PROMPT.md, or a failed copy
#
# ---------------------------------------------------------------------------
# WHAT LANDS AND WHAT NEVER DOES
#
# One file per item lands, at <dest-root>/<family>/<NN-slug>/PROMPT.md, under
# the item's own source name. Every other top-level entry of the item stays
# behind, and each one is reported on stdout, so a withholding is visible
# rather than silent.
#
# Three stay behind across the corpus as it stands:
#
#   ANSWER.md   the worked answer and the variants that count as correct
#   META.md     every construct the item drills, and the trap it sets
#   verify/     the modules and configs that prove the answer checks
#
# META.md is the one worth being deliberate about. It names the trap in a
# single line, so reading it answers the question the drill asks. An item
# delivered with its META.md beside it is not a blank page any more.
#
# A drill item has no position on a ramp, so there is no ORDER file here and no
# renumbering. scripts/deliver-problems.sh carries both and neither applies:
# the number inside a family is an authoring order rather than a difficulty
# ramp, so the destination directory name is the source directory name.
#
# Five files land at the drill root rather than inside an item: the runner, the
# readme and the three reference files. Each gets its own section below.
#
# ---------------------------------------------------------------------------
# WHY THIS SCRIPT NAMES A FILE, AND ITS SIBLING REFUSES TO
#
# Read scripts/deliver-problems.sh's header before this section. It says at
# length that its manifest is the <name>/statement/ tree and that a filename
# appears nowhere in it. On 2026-10-02 a guessed manifest deleted 39 delivered
# files, among them bonded-store's BondedStore.tla, river-call's RiverCall.cfg
# and assay-office's AssayOffice.tla. Two problems then got read as
# half-attempted when what was being read was the shipped starter.
#
# This script deviates from that rule, and the deviation is deliberate. A drill
# item has no statement/ subdirectory to use as a tree manifest, so the three
# ways to say what lands are these:
#
#   Deliver the item's whole tree. Hands over ANSWER.md. Not an option.
#
#   Deliver everything EXCEPT a withheld name list. Fails UNSAFE. A new
#   answer-bearing file lands by default, and the list drifts from the tree the
#   moment somebody adds one.
#
#   Deliver PROMPT.md by name. Fails SAFE. A new file is missed rather than
#   leaked, and a missed file surfaces as a prompt that reads short.
#
# The third is what this script does, and the failure direction is the whole
# reason. A leak cannot be taken back once the learner has read it. A miss
# costs one more run after somebody says so.
#
# THE GATE IS WHAT MAKES THE DEVIATION SAFE. harness/test-drill.sh asserts
# that every item's top-level entry set is exactly ANSWER.md, META.md,
# PROMPT.md and verify. A fifth entry reddens the suite and names itself, which
# forces whoever adds it to decide whether it is deliverable before it can
# land. So the convention cannot drift quietly, which is the one thing a
# filename in a script otherwise guarantees. In 2026-10 the problems corpus was
# non-uniform AND ungated. The drill corpus is uniform AND gated, and I would
# not name a file here without the second half.
#
# A hidden entry counts. Both this script and the gate read the item directory
# with the dotfiles included, so a stray one is withheld here and reported
# there rather than being quietly tolerated by one of the two.
#
# ---------------------------------------------------------------------------
# NEVER OVERWRITE A PROMPT, AND NEVER DELETE ANYTHING
#
# ~/tla-practice is not a git repo and it holds the only copy of the work done
# in it, so a clobbered file does not come back. Every prompt this script
# places is checked for existence first. An existing one is left alone and
# reported on stdout as "skipped (exists): <path>", and the run still exits 0,
# because a second delivery over a tree already carrying the corpus is the
# normal case rather than an error.
#
# THE RULE IS PER FILE CLASS NOW, AND THE RUNNER IS THE EXCEPTION. Read the
# next section before you read this one as universal.
#
# A PROMPT CAN BE REPLACED, BUT ONLY WHEN THE RUN ASKS FOR IT BY NAME.
# --refresh-prompts is the one route, it is off by default, and the section
# after next is the whole argument for it.
#
# Nothing is removed, at any point, under any flag. This script has no delete
# path at all.
#
# ---------------------------------------------------------------------------
# THREE FILE CLASSES, THREE POLICIES
#
# Until 2026-10-14 this script placed PROMPT.md and nothing else, so one rule
# covered everything it wrote: never overwrite. The drill runner is the first
# non-item file it delivers, and one rule stopped fitting the moment there
# were two kinds of file. Frank ruled the split the same day, which is what
# bead tla-emzu was blocked on.
#
#   PROMPT.md      NEVER overwritten unless the run asks for it with
#                  --refresh-prompts. It is the learner's page. He works in
#                  the directory it sits in, and by the time a second delivery
#                  runs a prompt may carry his notes.
#
#   the runner     ALWAYS overwritten. It is tooling. The repo is the source
#                  of truth for it, nothing he does edits it, and a fix to it
#                  is worth nothing if it cannot reach him. A delivered copy
#                  that can never be refreshed is the stale-copy problem
#                  tla-emzu's own notes describe from the other end.
#
#   PROGRESS.tsv   NEVER written, read or touched here, under any flag. They
#   LAST-SERVED    are his record of what he has done, the runner owns them,
#                  and nothing in this script has any business near them. The
#                  practice tree holds the only copy.
#
# WHAT DECIDES WHICH CLASS A FILE IS IN: could the learner have edited it. If
# he could, refuse to overwrite. If the repo is the source of truth and he
# never edits it, refresh it. The never-overwrite rule exists to protect work
# that has no git behind it, and the runner carries none.
#
# SO AN ALWAYS-OVERWRITE PATH LIVES IN THIS SCRIPT NOW, and it is named rather
# than hidden. install_runner() below is the only place it is, deliver_file()
# still refuses, and they are separate functions so neither can be reached by
# accident. Anyone who reads deliver_file() and concludes that this script
# never overwrites would be right about that function and wrong about the
# script, which is why this section sits above both.
#
# A source tree with no drill.sh is NOT an error. The prompts still land and
# the run reports that no runner was found. A corpus that predates the runner
# is a tree that was fine yesterday, not a defect today.
#
# ---------------------------------------------------------------------------
# WHY --refresh-prompts EXISTS, AND WHY IT IS A FLAG
#
# Never-overwrite kept the practice tree safe, it also kept it stale, and until
# 2026-10-14 nobody had measured by how much. Against the repo that day: 15 of
# 64 delivered prompts differed, 49 were byte for byte.
#
# Most of the 15 were a spelling normalization. Two were content fixes, and
# they are why the flag exists:
#
#   sequences/07-pneumatic-tube          the delivered copy still carried a
#                                        sentence that gave away the item's
#                                        whole lesson, cut that morning and
#                                        replaced by a published state count.
#   modules/07-the-hoist-and-the-crates  the delivered copy still defined
#                                        RECURSIVE in question 1, with only
#                                        the keyword removed.
#
# So the tree served the telegraphed version of two drills whose telegraphs had
# been cut, and under never-overwrite it always would. A drill that tells you
# its own answer is not a blank page.
#
# WHY IT IS A FLAG RATHER THAN THE NEW DEFAULT. The never-overwrite rule is
# there to protect work that has no git behind it, and a prompt is the one
# delivered file he can annotate. The asymmetry the manifest section argues
# about leaks applies here in the same direction: a stale prompt costs one more
# run once somebody says so, and an annotation written over does not come back.
# So the default stays never-overwrite, and a refresh has to be asked for by
# name on the command line. I would not have taken this as a change in the
# default even with the 15 in hand.
#
# IT REPLACES ONLY A FILE THAT DIFFERS, which cmp -s decides. A file that is
# byte for byte is not opened at all, so its mtime does not move either. That
# is about the report rather than about the copying: a run that replaces 15 of
# 64 should say 15, and a run that rewrote all 64 to the same bytes would say
# nothing worth reading.
#
# WHAT THE FLAG DOES NOT CHANGE. ANSWER.md, META.md and verify/ are withheld
# under it exactly as they are without it. PROGRESS.tsv and LAST-SERVED are
# still never written. There is still no delete path. --check composes with it
# and reports what it would replace without writing anything.
#
# ---------------------------------------------------------------------------
# A FOURTH FILE CLASS: THE README
#
# drill/README.md lands at <dest-root>/README.md, and it is in the runner's
# class rather than the prompt's: always overwritten, because the repo is the
# source of truth for it and he never edits it.
#
# Until 2026-10-14 no script delivered it at all, which is bead tla-nc6f. The
# copy in the practice tree was placed by hand on 2026-10-12 and then went
# stale on its own: it read "32 blank-page drills, four families" against 64
# items in eight families, and it was the file he opened when he sat down to
# practice. A document nothing refreshes is a document that lies eventually.
#
# A source with no drill/README.md is NOT an error, for the same reason a
# source with no runner is not.
#
# ---------------------------------------------------------------------------
# THE THREE REFERENCE FILES, IN THE README'S CLASS
#
# Bead tla-wn0z. Three more files sit at the drill root beside the readme, and
# a plain run lands all three, always overwriting:
#
#   drill/SHEET.md      -> <dest-root>/SHEET.md
#   drill/INVENTORY.md  -> <dest-root>/INVENTORY.md
#   drill/COLD-LIST.md  -> <dest-root>/COLD-LIST.md
#
# They are not a fifth file class. The section above asks one question: is the
# repo the source of truth, and does he never edit the delivered copy. All
# three answer it the same way as the readme. SHEET.md is generated by
# scripts/gen-sheet.sh and gated by harness/test-sheet.sh, and INVENTORY.md's
# coverage fields are generated by scripts/gen-coverage.sh and gated by
# harness/test-coverage-map.sh. Neither is hand-authored, so neither is a file
# he could have edited and had kept.
#
# WHY ALL THREE AND NOT JUST THE SHEET. The cold list says what you cannot
# write from a blank page. The sheet gives the shape of what you could not
# write, and the inventory says which items reach it. All three carry the same
# K001 to K105 ids in the same order, and the id is the join. Deliver one and
# the join has nothing on the other end.
#
# WHAT LEAVING THEM BEHIND COST. On 2026-10-16 Frank spent an hour on a
# construct whose syntax shape was already written down in drill/SHEET.md. The
# file was in the repo and not in the tree he works in. recall/recall.sh looks
# for $HOME/tla-practice/drill/SHEET.md and finds nothing, so a wrong answer
# there loses one layer of three. Until bead tla-wn0z
# harness/test-deliver-drill.sh asserted that two of the three never land. That
# was a true statement about items, written when an item was the only thing a
# delivery carried, and it was never a ruling about reference material.
#
# THE COLD LIST IS THE ONE I AM LEAST SURE OF, and it is worth saying so here
# rather than leaving the next reader to find it. Its first line asks him to
# tick every construct he could write cold. So it is the one of the three he
# has a reason to edit, and "could he have edited it" is the test this script
# uses to put a file in the prompt's class instead. It is here because the tick
# list is one pass he has not made yet, and because the corpus is still growing
# under it. If he starts ticking the delivered copy, reopen this.
#
# A source missing one of them is NOT an error, for the reason a source with no
# runner is not. Each is resolved and reported on its own, the way --study
# reports the style pair, because "the reference files did not land" would not
# say which.
#
# WHAT THE INVENTORY HANDS OVER, WHICH THE BEAD DID NOT WEIGH AND I THINK A
# READER SHOULD. Its field 8 is drill item slugs, so inverting it on a slug
# returns every construct that item drills. Measured 2026-10-16 against
# core/06-can-pyramid: 22 constructs out of the inventory, which is exactly the
# 10 plus 12 that item's META.md declares. The same pass says SHEET.md and
# COLD-LIST.md name 0 of 64 item slugs and INVENTORY.md names 64 of 64.
#
# META.md is withheld by name above because reading it answers the question the
# drill asks. So delivering the inventory moves that answer into the directory
# he practices in.
#
# IT IS STILL DELIVERED, and the reason is the one
# harness/test-deliver-drill.sh already states about the refusal contract: the
# withholding here is a delivery BOUNDARY rather than an access boundary, and
# the withheld files sit one absolute path away. drill/README.md tells him
# where they are. So this moves the construct list closer to hand rather than
# disclosing something he could not reach, and the coverage answer is what the
# file is for.
#
# The sheet carries none of this, which is why drill/README.md points him at
# the sheet mid-drill and at the inventory for coverage. That claim is gated:
# harness/test-deliver-drill.sh asserts SHEET.md and COLD-LIST.md name no item
# slug, with the inventory as the control that the scan can see one.
#
# If that trade reads wrong to you, the inventory is the one to pull, and
# pulling it is two entries out of REFERENCE_NAMES and REFERENCE_LABELS plus
# the rows that name it.
#
# ---------------------------------------------------------------------------
# THE STUDY MODE
#
# Bead tla-ytv2.3. --study delivers the study-side configuration INSTEAD of the
# prompts, into a different root, and the two modes share no destination.
#
#   drill/study/CLAUDE.md              -> <root>/CLAUDE.md
#   drill/study/.claude/commands/*.md  -> <root>/.claude/commands/*.md
#   drill/study/check                  -> <root>/check, mode 0755
#   drill/study/STYLE.md               -> <root>/STYLE.md
#   drill/study/style                  -> <root>/style, mode 0755
#
# All five are ALWAYS overwritten. They are tooling in the runner's class, and
# CLAUDE.md is a refusal contract, so a fix to it that cannot reach him is
# worth nothing.
#
# THE STYLE PAIR, added 2026-10-15 by bead tla-iiow.3, is the register a
# session reads style against and the script that does the measuring. They are
# a pair rather than one file for the reason the checker is not the config:
# the script measures and the model interprets, and a model running under
# `--tools ""` can do neither without being handed both. drill/drill.sh
# --style is what hands them over.
#
# NEITHER IS AN ERROR WHEN ABSENT, and that is load-bearing rather than
# tolerant. Beads tla-iiow.1 and tla-iiow.2 write those two files and this
# half shipped before them, so the only honest thing a delivery can do over a
# source that has one and not the other is deliver what is there and name
# what is not. The same rule the checker already has, for the same reason.
#
# IT IS A SEPARATE MODE RATHER THAN AN ADDITION TO A PLAIN RUN, because the two
# roots differ and so does the rule about creating them. The prompt tree is
# created on demand. The study root is REFUSED when it is absent.
#
# WHY THE REFUSAL. <root>/<slug>/ holds the attempts. That tree is not a git
# repo and it is in no backup, so it is the only artifact in this system with
# no copy anywhere. drill/drill.sh creates the root when it serves a drill, so
# a missing root means no drill has been served yet, and creating one here
# would put the configuration somewhere he never asked for and would not think
# to look. Nothing under <root>/<slug>/ is written, read or removed at any
# point, and every work directory the run finds is named on stdout so the
# promise is visible rather than asserted.
#
# WHY THE SOURCE MIRRORS THE DESTINATION, DOT AND ALL. The commands land under
# .claude/commands/ because that is where Claude Code reads a project slash
# command from. The source carries the same path, so the delivery is a plain
# copy with no rename to get wrong.
#
# It also has to carry it. An item is a directory two levels under drill/, and
# four scripts resolve one with the same find: this one, harness/drill-gate.sh,
# harness/test-drill.sh, and the count helpers in harness/test-deliver-drill.sh.
# A visible drill/study/commands/ reads as an item to all four. Measured before
# the layout moved: drill-gate.sh reported 65 items with 5 findings and rc 1,
# harness/test-drill.sh failed its shape row, this script exited 1 calling
# study/commands an item with no PROMPT.md, and the suite failed three rows on
# 65 against 64. Under a leading dot all four skip it on the `! -name '.*'`
# predicate they already carry, and not one of them needed changing.
#
# So the dot is load-bearing for four files. harness/test-deliver-drill.sh
# asserts that drill/study/ carries no visible subdirectory, which is where the
# tree goes red if somebody adds one.
#
# --study AND --refresh-prompts DO NOT COMPOSE. That flag is about prompts and
# this mode delivers none, so the pair is a usage error rather than a no-op. A
# silently ignored flag is how somebody comes away believing a prompt was
# refreshed.

set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<USAGE >&2
Usage: $0 [--check] [--refresh-prompts] [dest-root]
       $0 --study [--check] [study-root]

  --check            print what would be delivered, and write nothing
  --refresh-prompts  replace a delivered PROMPT.md that differs from the
                     source. Off by default, and nothing else is overwritten.
  --study            deliver the study-side configuration instead of the
                     prompts. The root must already exist.
  dest-root          where to deliver into (default: \$HOME/tla-practice/drill)
  study-root         --study only (default: \$HOME/Study/tla-drills)

Env:
  DELIVER_DRILL_SRC_ROOT   override the source repo root (default: $REPO_ROOT)
  DRILL_STUDY_ROOT         --study only: the study tree's root
USAGE
}

SRC_ROOT="${DELIVER_DRILL_SRC_ROOT:-$REPO_ROOT}"

# The one file an item hands over. Read the manifest section above before
# changing this, and change harness/test-drill.sh in the same commit.
PROMPT_NAME="PROMPT.md"

# The runner, which is the one thing this script delivers that is not an item.
# It lands without its extension so the command reads `./drill`, and it is
# ALWAYS overwritten. Read "THREE FILE CLASSES, THREE POLICIES" above before
# changing either name.
RUNNER_SRC_NAME="drill.sh"
RUNNER_DEST_NAME="drill"

# The learner's record. Named so the run can say what it leaves alone, and
# never opened.
LEARNER_RECORD_NAMES=("PROGRESS.tsv" "LAST-SERVED")

# The study tree, which --study delivers and a plain run never looks at. It
# sits at drill/study, where a family sits, and its one subdirectory is hidden
# on purpose. Read "THE STUDY MODE" above before changing either name.
STUDY_DIR_NAME="study"
STUDY_CONFIG_NAME="CLAUDE.md"
STUDY_COMMANDS_REL=".claude/commands"
STUDY_CHECK_NAME="check"
# The style pair. The register is prose and the script is executable, so they
# take two names and two verbs rather than one of each. drill/drill.sh --style
# reads both off the study root under exactly these names.
STUDY_REGISTER_NAME="STYLE.md"
STUDY_STYLE_NAME="style"

# The corpus readme, in the runner's file class. Read "A FOURTH FILE CLASS"
# above before changing this.
README_NAME="README.md"

# The three drill-root reference files, in the readme's class rather than the
# prompt's. The two lists are positional and have to stay the same length: the
# label is the verb a run prints, so a reader can tell which of the three
# landed. Read "THE THREE REFERENCE FILES" above before changing either.
REFERENCE_NAMES=("SHEET.md" "INVENTORY.md" "COLD-LIST.md")
REFERENCE_LABELS=("construct sheet" "coverage inventory" "cold list")

CHECK_ONLY=0
REFRESH_PROMPTS=0
STUDY_MODE=0
DEST_ROOT=""
POSITIONAL=0

take_positional() {
  POSITIONAL=$((POSITIONAL + 1))
  case "$POSITIONAL" in
    1) DEST_ROOT="$1" ;;
    *)
      echo "$0: unexpected extra argument: $1" >&2
      usage
      exit 1
      ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check)
      CHECK_ONLY=1
      shift
      ;;
    --refresh-prompts)
      REFRESH_PROMPTS=1
      shift
      ;;
    --study)
      STUDY_MODE=1
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "$0: unknown option: $1" >&2
      usage
      exit 1
      ;;
    *)
      take_positional "$1"
      shift
      ;;
  esac
done

# Anything after a bare `--` is still an argument.
while [ "$#" -gt 0 ]; do
  take_positional "$1"
  shift
done

SRC_DRILL="$SRC_ROOT/drill"

# ---------------------------------------------------------------------------
# THE STUDY MODE, dispatched here and exiting here.
#
# It runs BEFORE the item resolution below, on purpose. The study tree is not
# an item corpus, so a source carrying no item is nothing to this mode, and
# running it through a resolution that is fatal on an empty corpus would have
# coupled two modes that share no destination.
#
# install_study_file <src> <dest> <label>
#
# The always-overwrite path, and the third one in this script after
# install_runner() and refresh_prompt(). It is separate from both for the
# reason install_runner()'s own comment gives: a flag on the function that
# holds the never-overwrite rule is one typo away from clobbering a prompt.
#
# Returns 0 for a file that landed and 3 for one that replaced a copy already
# there, matching the codes the prompt loop above counts off.
# ---------------------------------------------------------------------------

install_study_file() {
  local src="$1" dest="$2" label="$3" existed=0
  if [ -e "$dest" ]; then
    existed=1
  fi
  mkdir -p -- "$(dirname -- "$dest")" || return 1
  cp -- "$src" "$dest" || return 1
  if [ "$existed" -eq 1 ]; then
    echo "$label refreshed, overwriting the copy already there: $dest"
    return 3
  fi
  echo "$label delivered: $dest"
  return 0
}

if [ "$STUDY_MODE" -eq 1 ]; then
  # A silently ignored flag is how somebody comes away believing a prompt was
  # refreshed, so the pair is refused rather than tolerated.
  if [ "$REFRESH_PROMPTS" -eq 1 ]; then
    echo "$0: --refresh-prompts is about prompts, and --study delivers none." >&2
    echo "$0: run them as two commands." >&2
    exit 1
  fi

  STUDY_ROOT="$DEST_ROOT"
  if [ -z "$STUDY_ROOT" ]; then
    STUDY_ROOT="${DRILL_STUDY_ROOT:-}"
  fi
  if [ -z "$STUDY_ROOT" ]; then
    STUDY_ROOT="$HOME/Study/tla-drills"
  fi

  SRC_STUDY="$SRC_DRILL/$STUDY_DIR_NAME"

  if [ ! -d "$SRC_STUDY" ]; then
    echo "$0: no study configuration at $SRC_STUDY" >&2
    echo "$0: set DELIVER_DRILL_SRC_ROOT to the repo root that carries drill/." >&2
    exit 1
  fi

  # THE REFUSAL. drill/drill.sh creates the root when it serves a drill, so an
  # absent one means no drill has been served yet. Creating it here would put
  # the configuration somewhere he never asked for.
  if [ ! -d "$STUDY_ROOT" ]; then
    echo "$0: no study root at $STUDY_ROOT" >&2
    echo "$0: it does not create one. Serve a drill with ./drill first, or pass a root that exists." >&2
    exit 1
  fi

  echo "study source: $SRC_STUDY"
  echo "study destination: $STUDY_ROOT"

  # Every work directory, named before anything is written. The promise that
  # this mode never writes into one is worth more said out loud than asserted,
  # and .claude/ is this script's own and not his.
  while IFS= read -r work_dir; do
    [ -n "$work_dir" ] || continue
    echo "left alone (your work, never written here): $work_dir"
  done < <(find "$STUDY_ROOT" -mindepth 1 -maxdepth 1 -type d \
    ! -name '.claude' | LC_ALL=C sort)

  # Resolve what lands before anything is written, so --check and a real run
  # read the same list and a fatal path leaves the tree as it found it.
  study_srcs=()
  study_dests=()
  study_labels=()

  if [ -f "$SRC_STUDY/$STUDY_CONFIG_NAME" ]; then
    study_srcs+=("$SRC_STUDY/$STUDY_CONFIG_NAME")
    study_dests+=("$STUDY_ROOT/$STUDY_CONFIG_NAME")
    study_labels+=("configuration")
  else
    echo "no configuration at $SRC_STUDY/$STUDY_CONFIG_NAME, so none lands"
  fi

  study_cmd_count=0
  while IFS= read -r cmd; do
    [ -n "$cmd" ] || continue
    study_cmd_count=$((study_cmd_count + 1))
    study_srcs+=("$cmd")
    study_dests+=("$STUDY_ROOT/$STUDY_COMMANDS_REL/${cmd##*/}")
    study_labels+=("command")
  done < <(find "$SRC_STUDY/$STUDY_COMMANDS_REL" -mindepth 1 -maxdepth 1 \
    -type f -name '*.md' 2>/dev/null | LC_ALL=C sort)

  if [ "$study_cmd_count" -eq 0 ]; then
    echo "no commands at $SRC_STUDY/$STUDY_COMMANDS_REL, so none land"
  fi

  # A source with no checker is not an error. Bead tla-ytv2.2 owns that file
  # and a tree that predates it was fine yesterday.
  HAVE_STUDY_CHECK=0
  if [ -f "$SRC_STUDY/$STUDY_CHECK_NAME" ]; then
    HAVE_STUDY_CHECK=1
    study_srcs+=("$SRC_STUDY/$STUDY_CHECK_NAME")
    study_dests+=("$STUDY_ROOT/$STUDY_CHECK_NAME")
    study_labels+=("checker")
  else
    echo "no checker at $SRC_STUDY/$STUDY_CHECK_NAME, so none lands"
  fi

  # The style pair, bead tla-iiow.3. Each is reported on its own, because a
  # source can carry one and not the other while the two beads that write them
  # land separately, and "the style pair did not land" would not say which.
  if [ -f "$SRC_STUDY/$STUDY_REGISTER_NAME" ]; then
    study_srcs+=("$SRC_STUDY/$STUDY_REGISTER_NAME")
    study_dests+=("$STUDY_ROOT/$STUDY_REGISTER_NAME")
    study_labels+=("style register")
  else
    echo "no style register at $SRC_STUDY/$STUDY_REGISTER_NAME, so none lands"
  fi

  HAVE_STUDY_STYLE=0
  if [ -f "$SRC_STUDY/$STUDY_STYLE_NAME" ]; then
    HAVE_STUDY_STYLE=1
    study_srcs+=("$SRC_STUDY/$STUDY_STYLE_NAME")
    study_dests+=("$STUDY_ROOT/$STUDY_STYLE_NAME")
    study_labels+=("style script")
  else
    echo "no style script at $SRC_STUDY/$STUDY_STYLE_NAME, so none lands"
  fi

  if [ "$CHECK_ONLY" -eq 1 ]; then
    study_to_land=0
    study_to_overwrite=0
    i=0
    while [ "$i" -lt "${#study_dests[@]}" ]; do
      if [ -e "${study_dests[$i]}" ]; then
        echo "would deliver, OVERWRITING the copy already there: ${study_dests[$i]}"
        study_to_overwrite=$((study_to_overwrite + 1))
      else
        echo "would deliver: ${study_dests[$i]}"
        study_to_land=$((study_to_land + 1))
      fi
      i=$((i + 1))
    done
    echo "$study_to_land study file(s) to land, $study_to_overwrite to overwrite"
    exit 0
  fi

  study_rc=0
  study_landed=0
  study_overwritten=0
  i=0
  while [ "$i" -lt "${#study_dests[@]}" ]; do
    install_study_file "${study_srcs[$i]}" "${study_dests[$i]}" "${study_labels[$i]}"
    outcome=$?
    case "$outcome" in
      0) study_landed=$((study_landed + 1)) ;;
      3) study_overwritten=$((study_overwritten + 1)) ;;
      *)
        echo "$0: failed to deliver: ${study_dests[$i]}" >&2
        study_rc=1
        ;;
    esac
    i=$((i + 1))
  done

  # He runs it as ./check, so the bit matters. Set after the copy, because cp
  # onto an existing file keeps the destination's mode rather than the source's.
  if [ "$HAVE_STUDY_CHECK" -eq 1 ] && [ -f "$STUDY_ROOT/$STUDY_CHECK_NAME" ]; then
    if ! chmod 0755 -- "$STUDY_ROOT/$STUDY_CHECK_NAME"; then
      echo "$0: delivered the checker but could not make it executable: $STUDY_ROOT/$STUDY_CHECK_NAME" >&2
      study_rc=1
    fi
  fi

  # drill/drill.sh execs the style script and refuses when it is not
  # executable, so the same chmod the checker needs, after the copy and for
  # the same reason. The register is prose and needs none.
  if [ "$HAVE_STUDY_STYLE" -eq 1 ] && [ -f "$STUDY_ROOT/$STUDY_STYLE_NAME" ]; then
    if ! chmod 0755 -- "$STUDY_ROOT/$STUDY_STYLE_NAME"; then
      echo "$0: delivered the style script but could not make it executable: $STUDY_ROOT/$STUDY_STYLE_NAME" >&2
      study_rc=1
    fi
  fi

  echo "$study_landed study file(s) landed, $study_overwritten overwritten"
  exit "$study_rc"
fi

if [ -z "$DEST_ROOT" ]; then
  DEST_ROOT="$HOME/tla-practice/drill"
fi

# ---------------------------------------------------------------------------
# Resolve the source, before the destination is created, so every fatal path
# below leaves the filesystem exactly as it found it.
# ---------------------------------------------------------------------------

if [ ! -d "$SRC_DRILL" ]; then
  echo "$0: no drill corpus at $SRC_DRILL" >&2
  echo "$0: set DELIVER_DRILL_SRC_ROOT to the repo root that carries drill/." >&2
  exit 1
fi

# An item is a directory two levels under drill/, which makes drill/ itself the
# manifest at the item level. drill/INVENTORY.md and drill/COLD-LIST.md sit one
# level up and are not families. They are delivered, by the reference block
# further down and never by this walk.
#
# The hidden-directory predicate is ANCHORED at the drill root, the way
# harness/test-drill.sh anchors its own. A bare `-not -path '*/.*'` matches
# REPO_ROOT itself for every agent working under .claude/worktrees/agent-*, and
# the item list comes back empty on a tree that is fine.
items=()
while IFS= read -r item_dir; do
  [ -n "$item_dir" ] || continue
  items+=("${item_dir#"$SRC_DRILL/"}")
done < <(find "$SRC_DRILL" -mindepth 2 -maxdepth 2 -type d \
  ! -name '.*' ! -path "$SRC_DRILL/.*" | LC_ALL=C sort)

if [ "${#items[@]}" -eq 0 ]; then
  echo "$0: $SRC_DRILL holds no item, so there is nothing to deliver." >&2
  echo "$0: an item is a directory at drill/<family>/<NN-slug>." >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Split every item's top-level entries into the prompt and the withholding.
#
# An item with no prompt is a defect in the item rather than in the run, so it
# is named on stderr and its siblings still land. The run exits 1 all the same:
# a delivery that quietly handed over 31 prompts out of 32 and reported success
# is the failure this bead exists to make loud.
# ---------------------------------------------------------------------------

deliver_items=()
withheld_paths=()
missing_prompt=()

for rel in "${items[@]}"; do
  if [ -f "$SRC_DRILL/$rel/$PROMPT_NAME" ]; then
    deliver_items+=("$rel")
  else
    missing_prompt+=("$rel")
  fi
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    base="${entry##*/}"
    [ "$base" = "$PROMPT_NAME" ] && continue
    withheld_paths+=("$rel/$base")
  done < <(find "$SRC_DRILL/$rel" -mindepth 1 -maxdepth 1 | LC_ALL=C sort)
done

# ---------------------------------------------------------------------------
# Report the withholding either way, so it is never silent.
# ---------------------------------------------------------------------------

for rel in "${withheld_paths[@]}"; do
  echo "withheld (not $PROMPT_NAME): $SRC_DRILL/$rel"
done

for rel in "${missing_prompt[@]}"; do
  echo "$0: $SRC_DRILL/$rel carries no $PROMPT_NAME, so it has nothing to deliver." >&2
done

echo "source: $SRC_DRILL"
echo "destination: $DEST_ROOT"

# ---------------------------------------------------------------------------
# The runner, resolved beside the items and reported either way.
#
# It sits at the drill root rather than inside an item, so none of the item
# walking above sees it and it is not a withheld path. harness/drill-gate.sh
# and harness/test-drill.sh both read items at depth two, so a file here is
# outside the four-entry shape assertion as well.
# ---------------------------------------------------------------------------

RUNNER_SRC="$SRC_DRILL/$RUNNER_SRC_NAME"
RUNNER_DEST="$DEST_ROOT/$RUNNER_DEST_NAME"

HAVE_RUNNER=0
if [ -f "$RUNNER_SRC" ]; then
  HAVE_RUNNER=1
  echo "runner source: $RUNNER_SRC"
else
  echo "no runner at $RUNNER_SRC, so none lands"
fi

# The readme, resolved beside the runner and in the same file class. Read
# "A FOURTH FILE CLASS: THE README" above for why it is always overwritten.
README_SRC="$SRC_DRILL/$README_NAME"
README_DEST="$DEST_ROOT/$README_NAME"

HAVE_README=0
if [ -f "$README_SRC" ]; then
  HAVE_README=1
  echo "readme source: $README_SRC"
else
  echo "no readme at $README_SRC, so none lands"
fi

# The reference files, resolved beside the readme and in the same class. Read
# "THE THREE REFERENCE FILES" above for why all three travel together and why
# a missing one is not an error.
#
# Resolved into three parallel arrays before anything is written, so --check
# and a real run read the same list, the way the study mode does.
reference_srcs=()
reference_dests=()
reference_labels=()

ref_i=0
while [ "$ref_i" -lt "${#REFERENCE_NAMES[@]}" ]; do
  ref_name="${REFERENCE_NAMES[$ref_i]}"
  ref_label="${REFERENCE_LABELS[$ref_i]}"
  ref_src="$SRC_DRILL/$ref_name"
  if [ -f "$ref_src" ]; then
    reference_srcs+=("$ref_src")
    reference_dests+=("$DEST_ROOT/$ref_name")
    reference_labels+=("$ref_label")
    echo "$ref_label source: $ref_src"
  else
    echo "no $ref_label at $ref_src, so none lands"
  fi
  ref_i=$((ref_i + 1))
done

for record_name in "${LEARNER_RECORD_NAMES[@]}"; do
  echo "left alone (the learner's record, never written here): $DEST_ROOT/$record_name"
done

if [ "$CHECK_ONLY" -eq 1 ]; then
  to_land=0
  to_replace=0
  already=0
  # Under --refresh-prompts this reads the destination's prompts to compare
  # them. Reading is all it does: every arm below prints and counts, and the
  # only two writing calls in this script sit past the exit at the bottom of
  # this block.
  for rel in "${deliver_items[@]}"; do
    dest_prompt="$DEST_ROOT/$rel/$PROMPT_NAME"
    if [ ! -e "$dest_prompt" ]; then
      echo "would deliver: $dest_prompt"
      to_land=$((to_land + 1))
    elif [ "$REFRESH_PROMPTS" -eq 0 ]; then
      echo "would skip (exists): $dest_prompt"
      already=$((already + 1))
    elif [ ! -f "$dest_prompt" ]; then
      echo "would leave alone (exists and is not a regular file): $dest_prompt"
      already=$((already + 1))
    elif cmp -s -- "$SRC_DRILL/$rel/$PROMPT_NAME" "$dest_prompt"; then
      echo "would leave alone (identical to the source): $dest_prompt"
      already=$((already + 1))
    else
      echo "would replace (the source differs): $dest_prompt"
      to_replace=$((to_replace + 1))
    fi
  done
  # Says whether it would overwrite, because that is the one thing about the
  # runner a reader cannot infer from the prompt policy above it.
  if [ "$HAVE_RUNNER" -eq 1 ]; then
    if [ -e "$RUNNER_DEST" ]; then
      echo "would deliver runner, OVERWRITING the copy already there: $RUNNER_DEST"
    else
      echo "would deliver runner: $RUNNER_DEST"
    fi
  fi
  if [ "$HAVE_README" -eq 1 ]; then
    if [ -e "$README_DEST" ]; then
      echo "would deliver readme, OVERWRITING the copy already there: $README_DEST"
    else
      echo "would deliver readme: $README_DEST"
    fi
  fi
  # The reference files, each under its own verb and each saying whether it
  # would overwrite. Same reason the runner's line says it.
  ref_i=0
  while [ "$ref_i" -lt "${#reference_dests[@]}" ]; do
    if [ -e "${reference_dests[$ref_i]}" ]; then
      echo "would deliver ${reference_labels[$ref_i]}, OVERWRITING the copy already there: ${reference_dests[$ref_i]}"
    else
      echo "would deliver ${reference_labels[$ref_i]}: ${reference_dests[$ref_i]}"
    fi
    ref_i=$((ref_i + 1))
  done
  # Two counts lines, because the refresh has a third outcome and a plain run
  # does not. A plain run that printed "0 replaced" would read as a run that
  # considered replacing something, which is the one thing it cannot do.
  if [ "$REFRESH_PROMPTS" -eq 1 ]; then
    echo "$to_land prompt(s) to land, $to_replace to replace, $already left alone, ${#withheld_paths[@]} path(s) withheld"
  else
    echo "$to_land prompt(s) to land, $already already there, ${#withheld_paths[@]} path(s) withheld"
  fi
  [ "${#missing_prompt[@]}" -eq 0 ] || exit 1
  exit 0
fi

# ---------------------------------------------------------------------------
# Deliver.
#
# deliver_file <src> <dest>
#
# The default path, and the one place the never-overwrite rule lives. Every
# file goes through here one at a time, so an item the learner has already
# started is left alone without holding back the items beside it.
#
# Returns 0 for a file that landed and 2 for one left alone. The caller counts
# off those two codes, so a third outcome needs a third code rather than a
# flag on either function.
# ---------------------------------------------------------------------------

deliver_file() {
  local src="$1" dest="$2"
  if [ -e "$dest" ]; then
    echo "skipped (exists): $dest"
    return 2
  fi
  mkdir -p -- "$(dirname -- "$dest")" || return 1
  cp -- "$src" "$dest" || return 1
}

# refresh_prompt <src> <dest>
#
# What --refresh-prompts runs instead of deliver_file(), and the second of the
# two overwriting paths in this script. Read "WHY --refresh-prompts EXISTS"
# above for why it is a flag.
#
# It is a separate function for the same reason install_runner() is: a flag on
# the function holding the never-overwrite rule is one typo away from
# clobbering a prompt on an ordinary run, and two functions cannot be confused
# that way. deliver_file() above still refuses, unconditionally, and nothing
# below reaches it.
#
# Returns 0 for a file that landed, 2 for one left alone, 3 for one replaced.
#
# The cmp -s is what makes the report worth reading, and it is also the reason
# an untouched file's mtime does not move. A destination entry that exists and
# is not a regular file is left alone rather than copied onto: cp onto a
# directory writes inside it, which would put a prompt somewhere nobody asked
# for and report success.
refresh_prompt() {
  local src="$1" dest="$2"
  if [ ! -e "$dest" ]; then
    mkdir -p -- "$(dirname -- "$dest")" || return 1
    cp -- "$src" "$dest" || return 1
    return 0
  fi
  if [ ! -f "$dest" ]; then
    echo "left alone (exists and is not a regular file): $dest"
    return 2
  fi
  if cmp -s -- "$src" "$dest"; then
    echo "left alone (identical to the source): $dest"
    return 2
  fi
  cp -- "$src" "$dest" || return 1
  echo "replaced (the source differs): $dest"
  return 3
}

# install_runner <src> <dest>
#
# The one always-overwrite path in this script, and the only one there will
# ever be unless somebody argues another file class into the section above.
# It is deliberately NOT deliver_file() with a flag: a flag on the function
# that holds the never-overwrite rule is one typo away from clobbering a
# prompt, and two functions cannot be confused that way.
#
# It says which of the two things it did, because a refresh and a first
# delivery are different events and he should be able to tell them apart in
# the output.
install_runner() {
  local src="$1" dest="$2" existed=0
  if [ -e "$dest" ]; then
    existed=1
  fi
  mkdir -p -- "$(dirname -- "$dest")" || return 1
  cp -- "$src" "$dest" || return 1
  chmod 0755 -- "$dest" || return 1
  if [ "$existed" -eq 1 ]; then
    echo "runner refreshed, overwriting the copy already there: $dest"
  else
    echo "runner delivered: $dest"
  fi
}

rc=0
landed=0
skipped=0
replaced=0

# The outcome is captured into a variable rather than read off $? after the
# fi, so which function ran and what it returned are two separate things a
# reader can see.
for rel in "${deliver_items[@]}"; do
  if [ "$REFRESH_PROMPTS" -eq 1 ]; then
    refresh_prompt "$SRC_DRILL/$rel/$PROMPT_NAME" "$DEST_ROOT/$rel/$PROMPT_NAME"
    outcome=$?
  else
    deliver_file "$SRC_DRILL/$rel/$PROMPT_NAME" "$DEST_ROOT/$rel/$PROMPT_NAME"
    outcome=$?
  fi
  case "$outcome" in
    0) landed=$((landed + 1)) ;;
    2) skipped=$((skipped + 1)) ;;
    3) replaced=$((replaced + 1)) ;;
    *)
      echo "$0: failed to deliver: $DEST_ROOT/$rel/$PROMPT_NAME" >&2
      rc=1
      ;;
  esac
done

if [ "$HAVE_RUNNER" -eq 1 ]; then
  if ! install_runner "$RUNNER_SRC" "$RUNNER_DEST"; then
    echo "$0: failed to deliver the runner: $RUNNER_DEST" >&2
    rc=1
  fi
fi

# The readme goes through install_study_file() rather than install_runner(),
# because it needs no executable bit and the wording it prints is the one the
# study files print. Both are always-overwrite paths and neither is
# deliver_file(), which still refuses unconditionally.
if [ "$HAVE_README" -eq 1 ]; then
  install_study_file "$README_SRC" "$README_DEST" "readme"
  readme_outcome=$?
  if [ "$readme_outcome" -ne 0 ] && [ "$readme_outcome" -ne 3 ]; then
    echo "$0: failed to deliver the readme: $README_DEST" >&2
    rc=1
  fi
fi

# The reference files, through the same always-overwrite path for the same
# reason. A failure on one does not hold back the other two: they are three
# separate files and he should get whichever ones can be written.
ref_i=0
while [ "$ref_i" -lt "${#reference_dests[@]}" ]; do
  install_study_file "${reference_srcs[$ref_i]}" "${reference_dests[$ref_i]}" \
    "${reference_labels[$ref_i]}"
  ref_outcome=$?
  if [ "$ref_outcome" -ne 0 ] && [ "$ref_outcome" -ne 3 ]; then
    echo "$0: failed to deliver the ${reference_labels[$ref_i]}: ${reference_dests[$ref_i]}" >&2
    rc=1
  fi
  ref_i=$((ref_i + 1))
done

if [ "$REFRESH_PROMPTS" -eq 1 ]; then
  echo "$landed prompt(s) landed, $replaced replaced, $skipped left alone, ${#withheld_paths[@]} path(s) withheld"
else
  echo "$landed prompt(s) landed, $skipped skipped, ${#withheld_paths[@]} path(s) withheld"
fi

[ "${#missing_prompt[@]}" -eq 0 ] || rc=1

exit "$rc"
