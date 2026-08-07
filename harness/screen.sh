#!/usr/bin/env bash
#
# screen.sh — V2-PLAN.md §5.7, the MECHANISM-COLLISION screen.
#
#   "Has someone already solved this?"
#
# This is ONE of the two screens every candidate problem must pass. The other
# is §5.7b, puzzle-versus-system — "is it even the right KIND of thing?" — and
# it is NOT implemented here, on purpose. It is a judgment rubric, shipped as
# harness/PUZZLE-SCREEN.md, run by a human. A script that returned a confident
# verdict on "is this a system?" would be worse than the checklist, because it
# would be believed.
#
# A candidate can pass this screen cleanly and still be useless. Every run of
# this tool ends by saying so.
#
# The screen has two steps, and the SECOND is the one that catches the misses:
#
#   step 1  NAME       gh code-search for the spec name. >3 hits => BURNED.
#   step 2  MECHANISM  grep the MECHANISM, not the name, against the
#                      tlaplus/Examples README table, then code-search any
#                      mechanism the README does not already settle.
#
#                      NAME NOVELTY IS NOT MECHANISM NOVELTY. "Warehouse robot
#                      coordination" is MisraReachability + mutual exclusion.
#                      "Seat reservation" is the allocator. "Leader failover"
#                      is Paxos. Nobody has published RestaurantSeating.tla and
#                      it is burned all the same.
#
# USAGE
#   harness/screen.sh <candidate phrase> [<candidate phrase> ...]
#   harness/screen.sh --offline <candidate>     cache only; no network at all
#   harness/screen.sh --name <SpecName> <cand>  override the derived spec name
#   harness/screen.sh --refresh                 re-fetch the Examples README
#   harness/screen.sh --list-suspicions         print the seeded §2.2 table
#   harness/screen.sh --selftest                run the fixture-driven tests
#
# EXIT CODES
#   0  CLEAR    no name collision, no mechanism collision
#   1  SUSPECT  a §2.2 suspicion stands unresolved — a human must look
#   2  BURNED   name or mechanism already in the corpus
#   64 usage error
#   (multiple candidates: the worst verdict wins)
#
# ENVIRONMENT (all optional; the self-test drives every one of them)
#   SCREEN_GH         gh binary                    default: gh
#   SCREEN_README     cached Examples README       default: fixtures/screen/examples-README.md
#   SCREEN_CACHE_DIR  code-search count cache      default: $XDG_CACHE_HOME/tla-puzzles-screen
#   SCREEN_SLEEP      seconds between searches     default: 7 (GitHub code search
#                                                   allows 10 requests/minute)

set -uo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE_DIR="$HARNESS_DIR/fixtures/screen"

GH="${SCREEN_GH:-gh}"
README_CACHE="${SCREEN_README:-$FIXTURE_DIR/examples-README.md}"
CACHE_DIR="${SCREEN_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/tla-puzzles-screen}"
SLEEP="${SCREEN_SLEEP:-7}"

BURNED_AT=3 # ">3 hits as burned" — 4 burns, 3 does not
MAX_ROWS=6  # README hits printed per mechanism term before eliding

OFFLINE=0
NAME_OVERRIDE=""

# ---------------------------------------------------------------------------
# §2.2 PRE-SCREEN SUSPICIONS — seeded so the screen is never run blind.
#
# Transcribed from V2-PLAN.md §2.2 ("Pre-screen suspicions — record these so
# §5.7 is not run blind"). Fields are ~-separated:
#
#   <ERE matched against the candidate phrase> ~ <kind> ~ <domain label> ~ <note>
#
#   MECHANISM  a §5.7 suspicion; feeds this screen
#   PUZZLE     NOT a §5.7 problem — fails §5.7b instead; referred, never
#              decided here
#   CRISPNESS  NOT a §5.7 problem — a §3.2 statement risk
# ---------------------------------------------------------------------------
suspicions() {
	cat <<-'EOF'
		restaurant|table combin|party size~MECHANISM~restaurant seating with table combining~bin-packing / knapsack — 56 public `Knapsack` specs
		library hold|hold queue|community garden|airline standby|standby~MECHANISM~library hold queues · community garden plots · airline standby~the `Resource Allocator` spec in different dress
		orchestra audition|audition round~MECHANISM~orchestra audition rounds~tournament ranking — same mechanism as brackets, so at most one of the two survives
		change-ringing|change ringing|method rules~PUZZLE~change-ringing method rules~fails the §5.7b puzzle screen, not the §5.7 collision screen. The rules (permutation, adjacent-swap only, no repeats, start and end on rounds) are the complete action set, stated in the domain's own terms before you write a line — and it does not scale (a full extent on 7 bells is 5,040 rows, on 8 it is 40,320). It is rescuable by the §5.7b agents-and-fallibility pattern — a band of ringers who mistime, refining the method — but do not put that in batch one.
		beekeeping|hive split~CRISPNESS~beekeeping hive splits~rules may be too biologically fuzzy to state crisply enough for §3.2
	EOF
}

# ---------------------------------------------------------------------------
# CANDIDATE PHRASE -> MECHANISM TERMS
#
# This table is the whole point of step 2. It is deliberately a map from
# DOMAIN VOCABULARY to MECHANISM VOCABULARY, because the domain word is what a
# candidate arrives wearing and the mechanism word is what is already in the
# corpus. Extend it whenever a new candidate teaches you a synonym.
#
#   <ERE matched against the candidate phrase> ~ <comma-separated mechanisms>
# ---------------------------------------------------------------------------
mechanism_map() {
	cat <<-'EOF'
		restaurant|table combin|party size~knapsack,bin-packing,allocation,assignment problem
		seat~allocation,assignment problem
		library hold|hold queue|waitlist|wait list~allocation,queue
		community garden|plot allocation~allocation,assignment problem
		standby|upgrade list~allocation,queue
		reservation|booking~allocation
		tournament|bracket|audition~tournament ranking
		warehouse|robot~reachability,mutual exclusion
		failover|leader|primary election~leader election,consensus,paxos
		sign-off|signoff|sign off|permit review|parallel department~atomic commitment,two-phase commit
		cohort assignment|clinical trial~assignment problem,allocation
		museum|exhibit loan|conservation limit~allocation
		blood bank|inventory|expiry|type compatibility~allocation,matching
		seed library|return obligation~allocation,queue
		escape room|reset time~allocation,scheduling
	EOF
}

# ---------------------------------------------------------------------------
# MECHANISM TERM -> ERE grepped against the cached Examples README table.
# A term with no entry here is code-searched only.
# ---------------------------------------------------------------------------
mechanism_grep() {
	cat <<-'EOF'
		allocation~allocat
		assignment problem~assignment problem
		mutual exclusion~mutual exclusion|mutex
		reachability~reachab
		leader election~leader election|election
		consensus~consensus
		paxos~paxos
		atomic commitment~atomic commit|commitment
		two-phase commit~two-phase|transaction commit
		queue~queue
		matching~matching
		scheduling~schedul
		knapsack~knapsack
		bin-packing~bin.?pack
		tournament ranking~tournament|bracket
	EOF
}

# --- helpers ----------------------------------------------------------------

die() {
	printf 'screen.sh: %s\n' "$1" >&2
	exit "${2:-64}"
}

# "assignment problem" -> "AssignmentProblem"
camel() {
	printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]' ' ' |
		awk '{ for (i = 1; i <= NF; i++) printf "%s%s", toupper(substr($i,1,1)), substr($i,2); print "" }'
}

# Derive the spec name a solution of this candidate would plausibly be called.
# Printed with the query so a human can rerun or override it with --name.
derive_name() {
	printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c '[:alnum:]' ' ' |
		awk '{
			n = 0
			for (i = 1; i <= NF; i++) {
				w = $i
				if (w ~ /^(with|and|the|a|an|of|for|in|on|by|to|its|per|from|at|or)$/) continue
				printf "%s%s", toupper(substr(w,1,1)), substr(w,2)
				if (++n == 2) break
			}
			print ""
		}'
}

# GitHub code-search count for "<term> language:tla", memoized on disk.
# Echoes an integer, or "ERR" if the search could not be run.
gh_count() {
	local term="$1" q key file n
	q="$term language:tla"
	key="$(printf '%s' "$q" | tr -c '[:alnum:]' '_')"
	file="$CACHE_DIR/$key"

	if [ -f "$file" ]; then
		cat "$file"
		return 0
	fi

	n="$("$GH" api -X GET search/code -f "q=$q" --jq '.total_count' 2>/dev/null)"
	if ! grep -qE '^[0-9]+$' <<<"$n"; then
		printf 'ERR'
		return 1
	fi

	mkdir -p "$CACHE_DIR" 2>/dev/null
	printf '%s' "$n" >"$file" 2>/dev/null
	printf '%s' "$n"

	if [ "$SLEEP" != "0" ]; then sleep "$SLEEP"; fi
}

# Rows of the Examples README table matching an ERE, rendered "Name (path)".
readme_rows() {
	grep -iE "$1" "$README_CACHE" 2>/dev/null |
		grep '^|' |
		sed -E -e 's/^\| *\[([^]]*)\]\(([^)]*)\).*/\1 (\2)/' \
			-e 't' \
			-e 's/^\| *([^|]*) *\|.*/\1/' \
			-e 's/ *$//'
}

require_readme() {
	[ -f "$README_CACHE" ] || die "no cached Examples README at $README_CACHE — run: harness/screen.sh --refresh"
}

# --- modes ------------------------------------------------------------------

do_refresh() {
	local tmp
	tmp="$(mktemp)"
	if ! "$GH" api repos/tlaplus/Examples/contents/README.md --jq '.content' | base64 -d >"$tmp" 2>/dev/null; then
		rm -f "$tmp"
		die "refresh failed — could not fetch repos/tlaplus/Examples/contents/README.md" 1
	fi
	[ -s "$tmp" ] || {
		rm -f "$tmp"
		die "refresh produced an empty README" 1
	}

	mkdir -p "$(dirname "$README_CACHE")"
	mv "$tmp" "$README_CACHE"

	local prov="${README_CACHE%.md}.provenance.txt"
	{
		printf 'Cached copy of https://github.com/tlaplus/Examples/blob/master/README.md\n\n'
		printf 'Fetched as BYTES, never through WebFetch (V2-PLAN.md §4.5 — WebFetch runs a\n'
		printf 'summarizer and returns paraphrase, so a WebFetch quotation is unsourced):\n\n'
		printf "    gh api repos/tlaplus/Examples/contents/README.md --jq '.content' | base64 -d \\\\\n"
		printf '      > %s\n\n' "$README_CACHE"
		printf 'fetched:  %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
		printf 'sha256:   %s\n' "$(sha256sum "$README_CACHE" | cut -d' ' -f1)"
		printf 'bytes:    %s\n' "$(wc -c <"$README_CACHE" | tr -d ' ')"
		printf 'lines:    %s\n' "$(wc -l <"$README_CACHE" | tr -d ' ')"
		printf '\nThe file is stored byte-for-byte as upstream serves it — no header, no edits —\n'
		printf 'so this record, not a comment inside the file, is where provenance lives.\n\n'
		# The backticks are literal markdown for whoever reads the provenance
		# file, not a command substitution waiting to happen.
		# shellcheck disable=SC2016
		printf 'Refresh with `harness/screen.sh --refresh`, which reruns exactly that command.\n'
		printf 'This file is simultaneously:\n\n'
		printf "  - the screen's CACHE, so screening N candidates is not N network calls; and\n"
		printf "  - the self-test's FIXTURE, so the test cannot fail merely because GitHub is\n"
		printf '    unreachable.\n'
	} >"$prov" 2>/dev/null

	printf 'refreshed %s (%s bytes)\n' "$README_CACHE" "$(wc -c <"$README_CACHE" | tr -d ' ')"
	return 0
}

do_list_suspicions() {
	printf '§2.2 pre-screen suspicions (V2-PLAN.md §2.2) — seeded so §5.7 is never run blind\n\n'
	while IFS='~' read -r pat kind label note; do
		[ -n "${pat:-}" ] || continue
		printf '  [%s] %s\n' "$kind" "$label"
		printf '        %s\n\n' "$note"
	done < <(suspicions)
	printf 'MECHANISM feeds this screen. PUZZLE and CRISPNESS do NOT — they are referred\n'
	printf 'to §5.7b (harness/PUZZLE-SCREEN.md) and §3.2 respectively, and a MECHANISM\n'
	printf 'CLEAR here says nothing about them.\n'
	return 0
}

# --- the screen -------------------------------------------------------------

screen_one() {
	local cand="$1"
	local lc name hits pat kind label note terms t re rows n cs
	local name_verdict mech_verdict verdict
	local -a mech_terms=()
	local suspicion_kind=""

	lc="$(printf '%s' "$cand" | tr '[:upper:]' '[:lower:]')"

	printf '=== CANDIDATE: %s\n' "$cand"

	# ---- seeded §2.2 suspicions --------------------------------------------
	local printed_suspicion=0
	while IFS='~' read -r pat kind label note; do
		[ -n "${pat:-}" ] || continue
		# Here-string, never `printf ... | grep -qi`. `$lc` is the whole
		# lowercased candidate; under `pipefail` grep -q exits at the first
		# match, the producer dies of SIGPIPE, and the pipeline reports 141 --
		# which `|| continue` reads as "no match" and SKIPS a suspicion that
		# did fire. A silent false negative in the screen itself, and an
		# intermittent one. Bead tla-kr9.
		grep -qiE "$pat" <<<"$lc" || continue
		if [ "$printed_suspicion" = 0 ]; then
			printf -- '--- §2.2 pre-screen suspicion\n'
			printed_suspicion=1
		fi
		printf '    [%s] %s\n' "$kind" "$label"
		printf '          %s\n' "$note"
		case "$kind" in
		MECHANISM) suspicion_kind="MECHANISM" ;;
		PUZZLE)
			printf '    ^ that is a §5.7b verdict, not a §5.7 one. This tool does not decide it.\n'
			printf '      Run the rubric: harness/PUZZLE-SCREEN.md\n'
			;;
		CRISPNESS)
			printf '    ^ that is a §3.2 statement risk, not a §5.7 collision.\n'
			;;
		esac
	done < <(suspicions)

	# ---- step 1: name ------------------------------------------------------
	name="${NAME_OVERRIDE:-$(derive_name "$cand")}"
	name_verdict="CLEAR"
	printf -- '--- step 1: NAME collision\n'
	if [ -z "$name" ]; then
		printf '    (no name derivable from the candidate; pass --name)\n'
		name_verdict="SKIPPED"
	elif [ "$OFFLINE" = 1 ]; then
		printf "    query: '%s language:tla'  — skipped (offline)\n" "$name"
		name_verdict="SKIPPED"
	else
		printf "    query: '%s language:tla'\n" "$name"
		hits="$(gh_count "$name")"
		if [ "$hits" = "ERR" ]; then
			printf '    hits: ERROR (code search unavailable) -> SKIPPED\n'
			name_verdict="SKIPPED"
		elif [ "$hits" -gt "$BURNED_AT" ]; then
			printf '    hits: %s -> BURNED (>%s)\n' "$hits" "$BURNED_AT"
			name_verdict="BURNED"
		else
			printf '    hits: %s -> clear (<=%s)\n' "$hits" "$BURNED_AT"
		fi
	fi

	# ---- step 2: mechanism -------------------------------------------------
	printf -- '--- step 2: MECHANISM collision  (name novelty is not mechanism novelty)\n'
	while IFS='~' read -r pat terms; do
		[ -n "${pat:-}" ] || continue
		# Here-string, not a pipe — same SIGPIPE-under-pipefail trap as the
		# §2.2 loop above; a 141 here would silently drop a mechanism term.
		grep -qiE "$pat" <<<"$lc" || continue
		while IFS= read -r t; do
			[ -n "$t" ] || continue
			local seen=0 m
			for m in ${mech_terms[@]+"${mech_terms[@]}"}; do
				[ "$m" = "$t" ] && seen=1
			done
			[ "$seen" = 0 ] && mech_terms+=("$t")
		done < <(printf '%s\n' "$terms" | tr ',' '\n' | sed 's/^ *//; s/ *$//')
	done < <(mechanism_map)

	mech_verdict="CLEAR"

	if [ "${#mech_terms[@]}" -eq 0 ]; then
		printf '    no mechanism derived from this phrasing.\n'
		printf '    NOT a clean bill: it may mean the mechanism vocabulary in this script is\n'
		printf '    missing a synonym. Name the mechanism yourself before trusting a CLEAR.\n'
	else
		printf '    mechanism terms: %s\n' "$(
			IFS=', '
			printf '%s' "${mech_terms[*]}"
		)"
		printf '    tlaplus/Examples README (cache: %s):\n' "$README_CACHE"

		local -a unsettled=()
		for t in "${mech_terms[@]}"; do
			re=""
			while IFS='~' read -r mt mre; do
				[ "$mt" = "$t" ] && re="$mre"
			done < <(mechanism_grep)

			if [ -z "$re" ]; then
				unsettled+=("$t")
				continue
			fi

			rows="$(readme_rows "$re")"
			if [ -z "$rows" ]; then
				printf '      %-20s no README row\n' "$t"
				unsettled+=("$t")
			else
				n="$(grep -c . <<<"$rows")"
				printf '      %-20s %s README row(s) -> BURNED\n' "$t" "$n"
				# `printf ... | head -n N` is the SIGPIPE shape too: head
				# closes the pipe after N lines and the producer takes 141.
				# Slice with a here-string so no pipe is live. Bead tla-kr9.
				head -n "$MAX_ROWS" <<<"$rows" | sed 's/^/                             /'
				[ "$n" -gt "$MAX_ROWS" ] && printf '                             ... and %s more\n' "$((n - MAX_ROWS))"
				mech_verdict="BURNED"
			fi
		done

		# Mechanisms the README does not settle still get a code search — that
		# is the channel that finds the 56 Knapsack specs, which have no row in
		# the Examples table at all.
		if [ "${#unsettled[@]}" -gt 0 ]; then
			if [ "$OFFLINE" = 1 ]; then
				printf '    mechanism code-search: skipped (offline) for: %s\n' "$(
					IFS=', '
					printf '%s' "${unsettled[*]}"
				)"
			else
				printf '    mechanism code-search (README did not settle these):\n'
				for t in "${unsettled[@]}"; do
					cs="$(camel "$t")"
					n="$(gh_count "$cs")"
					if [ "$n" = "ERR" ]; then
						printf '      %-20s ERROR (code search unavailable)\n' "$cs"
					elif [ "$n" -gt "$BURNED_AT" ]; then
						printf '      %-20s %s hits -> BURNED (>%s)\n' "$cs" "$n" "$BURNED_AT"
						mech_verdict="BURNED"
					else
						printf '      %-20s %s hits -> clear (<=%s)\n' "$cs" "$n" "$BURNED_AT"
					fi
				done
			fi
		fi
	fi

	if [ "$mech_verdict" = "CLEAR" ] && [ "$suspicion_kind" = "MECHANISM" ]; then
		mech_verdict="SUSPECT"
		printf '    a §2.2 MECHANISM suspicion is on record and this run found no corpus\n'
		printf '    evidence either way -> SUSPECT, not CLEAR. A human resolves it.\n'
	fi

	# ---- verdict -----------------------------------------------------------
	verdict="CLEAR"
	case "$name_verdict$mech_verdict" in
	*BURNED*) verdict="BURNED" ;;
	*SUSPECT*) verdict="SUSPECT" ;;
	esac

	printf -- '--- §5.7 VERDICT: %s   (name: %s | mechanism: %s)\n' "$verdict" "$name_verdict" "$mech_verdict"
	printf -- '--- §5.7b is a SEPARATE screen and is NOT run here.\n'
	printf '    "Has someone already solved this?" is not "is it even the right KIND of\n'
	printf '    thing?" A candidate can pass §5.7 cleanly and still be useless.\n'
	printf '    Run the rubric by hand, at domain-selection time AND again at statement\n'
	printf '    time (§6 step 4): harness/PUZZLE-SCREEN.md\n'
	printf '\n'

	case "$verdict" in
	BURNED) return 2 ;;
	SUSPECT) return 1 ;;
	*) return 0 ;;
	esac
}

# --- main -------------------------------------------------------------------

main() {
	local -a candidates=()

	while [ $# -gt 0 ]; do
		case "$1" in
		--offline)
			OFFLINE=1
			shift
			;;
		--name)
			[ $# -ge 2 ] || die "--name needs an argument"
			NAME_OVERRIDE="$2"
			shift 2
			;;
		--refresh)
			do_refresh
			exit $?
			;;
		--list-suspicions)
			do_list_suspicions
			exit $?
			;;
		--selftest)
			exec "$FIXTURE_DIR/selftest.sh"
			;;
		-h | --help)
			sed -n '2,60p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
			exit 0
			;;
		-*) die "unknown option: $1" ;;
		*)
			candidates+=("$1")
			shift
			;;
		esac
	done

	[ "${#candidates[@]}" -gt 0 ] || die "no candidate given (try --help)"
	require_readme

	local worst=0 rc
	for c in "${candidates[@]}"; do
		screen_one "$c"
		rc=$?
		[ "$rc" -gt "$worst" ] && worst=$rc
	done
	exit "$worst"
}

main "$@"
