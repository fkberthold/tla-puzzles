#!/usr/bin/env python3
"""Reconcile the chapter's fenced code blocks against the modules in this directory.

The invariant this enforces, which is the acceptance criterion of bead tla-kl5.2:

  Every ```tla-fenced block in chapter/*.md traces to a module in chapter/snippets/;
  every module/config pair the chapter shows a transcript for is asserted in
  run-all.sh at the exit code the transcript prints; and every .cfg's own
  `Expected: rc=` header agrees with the exit code run-all.sh asserts for it.

Untagged fences (```) are transcripts, error messages, .cfg listings and algebraic
expansions -- exempt from the module trace by construction.  Tagging a block
```tla is the author's assertion that it is real, runnable TLA+; this script is
what makes that assertion cost something.

Matching is per definition and whitespace-insensitive, because the chapter
legitimately reflows a bulleted conjunction onto one line and trims the dash runs
in a module header.  The one further equivalence allowed is a dropped leading
`/\\` (`/\\ A /\\ B` and `A /\\ B` are the same formula).  Nothing else: a renamed
operator, a changed guard or an operator the module does not define is a failure.

Deliberately pure Python with no subprocesses and no shell pipelines: a chatty
producer feeding a matcher through a live pipe takes SIGPIPE and returns 141,
which inside an `if` reads as "no match" (see bead tla-kr9).

  ./check-blocks.py          check
  ./check-blocks.py -v       also list every block and the module it traced to

Exits 0 if everything reconciles, 1 otherwise.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CHAPTER = os.path.dirname(HERE)
DOCS = ("refinement.md", "worked-example.md")

verbose = "-v" in sys.argv[1:]
problems = []


def fail(msg):
    problems.append(msg)


# ---------------------------------------------------------------- normalizing

def decomment(text):
    """Strip `\\*` line comments and (* ... *) block comments."""
    text = re.sub(r"\(\*.*?\*\)", " ", text, flags=re.S)
    return "\n".join(re.sub(r"\\\*.*$", "", l) for l in text.split("\n"))


def squash(s):
    """All whitespace removed, and a leading `/\\` dropped."""
    s = re.sub(r"\s+", "", s)
    return s[2:] if s.startswith("/\\") else s


def canon_plain(line):
    """Canonical form of a non-definition line (EXTENDS, VARIABLES, header, footer)."""
    s = " ".join(line.split())
    m = re.match(r"^-{4,}\s*MODULE\s+([A-Za-z_][A-Za-z0-9_]*)\s*-{4,}$", s)
    if m:
        return "MODULE " + m.group(1)
    if re.match(r"^={4,}$", s):
        return "===="
    return s


DEFSTART = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*(\([^)]*\))?\s*==(.*)$")


def parse(text):
    """Split TLA+ source into ({name: squashed body}, [canonical non-definition lines]).

    A definition starts at a line matching `Name ==` or `Name(args) ==` and runs
    until the next such line or a line that is clearly not part of it."""
    text = decomment(text)
    defs = {}
    plain = []
    cur = None
    buf = []
    for raw in text.split("\n"):
        if not raw.strip():
            continue
        m = DEFSTART.match(raw)
        starts_def = bool(m) and not raw[0].isspace()
        if starts_def:
            if cur:
                defs[cur] = squash("".join(buf))
            cur = m.group(1) + (re.sub(r"\s+", "", m.group(2)) if m.group(2) else "")
            buf = [m.group(3)]
            continue
        if raw[0].isspace() and cur is not None:
            buf.append(raw)
            continue
        if cur:
            defs[cur] = squash("".join(buf))
            cur, buf = None, []
        plain.append(canon_plain(raw))
    if cur:
        defs[cur] = squash("".join(buf))
    return defs, plain


# ------------------------------------------------------------------ inventory

def read_fences(path, doc):
    """[(start_line, end_line, lang, [body lines])]"""
    lines = open(path, encoding="utf-8").read().split("\n")
    out = []
    inblk = False
    start = 0
    for i, ln in enumerate(lines, 1):
        if ln.startswith("```"):
            if not inblk:
                inblk, start, lang, body = True, i, ln[3:].strip(), []
            else:
                inblk = False
                out.append((start, i, lang, body))
        elif inblk:
            body.append(ln)
    if inblk:
        fail("%s: unclosed fence opened at line %d" % (doc, start))
    return out


modules = {}       # Foo.tla -> (defs, plain lines, squashed stream, instantiated)
for fn in sorted(os.listdir(HERE)):
    if fn.endswith(".tla"):
        src = open(os.path.join(HERE, fn), encoding="utf-8").read()
        d, p = parse(src)
        inst = set(m + ".tla" for m in
                   re.findall(r"\bINSTANCE\s+([A-Za-z_][A-Za-z0-9_]*)", decomment(src)))
        modules[fn] = (d, set(p), squash(decomment(src)), inst)

configs = sorted(f for f in os.listdir(HERE) if f.endswith(".cfg"))


def read_cases():
    """(module, cfg) -> expected rc, parsed out of run-all.sh's CASES array."""
    text = open(os.path.join(HERE, "run-all.sh"), encoding="utf-8").read()
    return {(m.group(1), m.group(2)): int(m.group(3))
            for m in re.finditer(r'^\s*"([^"|]+)\|([^"|]+)\|(\d+)\|([^"]*)"\s*$',
                                 text, re.M)}


CASES = read_cases()
if not CASES:
    fail("run-all.sh: could not parse a CASES table -- the reconciler is blind")


# ------------------------------------------- check 1: ```tla blocks trace to a module

def trace(defs, plain, stream):
    """Modules that account for every definition and every plain line of a block.

    A block with no definitions of its own is a bare formula quoted out of a
    definition's right-hand side (`Till!Spec` is `Init /\\ [][Next]_vars`); it is
    matched as a substring of the module rather than line by line."""
    hits = []
    for fn, (mdefs, mplain, mstream, _) in modules.items():
        if not defs:
            if stream and stream in mstream:
                hits.append(fn)
            continue
        if (all(name in mdefs and mdefs[name] == body for name, body in defs.items())
                and all(p in mplain for p in plain)):
            hits.append(fn)
    return hits


tla_blocks = 0
for doc in DOCS:
    for start, end, lang, body in read_fences(os.path.join(CHAPTER, doc), doc):
        if lang != "tla":
            continue
        tla_blocks += 1
        defs, plain = parse("\n".join(body))
        stream = squash(decomment("\n".join(body)))
        hits = trace(defs, plain, stream)
        if hits:
            if verbose:
                print("ok    %s:%d-%d -> %s" % (doc, start, end, ", ".join(sorted(hits))))
            continue
        # localize the drift: which module comes closest, and on what
        best, why = None, ["block defines: " + (", ".join(sorted(defs)) or "(nothing)")]
        for fn, (mdefs, mplain, _, _i) in modules.items():
            bad = [n for n, b in defs.items() if n not in mdefs or mdefs[n] != b]
            bad += ["(line) " + p for p in plain if p not in mplain]
            if best is None or len(bad) < len(why):
                best, why = fn, bad
        fail("%s:%d-%d: ```tla block traces to no module in snippets/\n"
             "        closest: %s\n%s"
             % (doc, start, end, best,
                "\n".join("          mismatched: %s" % w for w in why[:8])))


# ---------- check 2: a printed .cfg only names operators the document has shown

# The failure this catches: a module listing is abridged, a .cfg listing further
# down names an operator the abridgement dropped, and a reader who copies both
# out of the page gets rc=151 from a chapter that promised everything runs.

CFGKW = re.compile(r"^\s*(CONSTANTS?|SPECIFICATION|INVARIANTS?|PROPERT(?:Y|IES)"
                   r"|ALIAS|CHECK_DEADLOCK|CONSTRAINTS?|VIEW|SYMMETRY)\b(.*)$")
NAMED_KW = {"SPECIFICATION", "INVARIANT", "INVARIANTS",
            "PROPERTY", "PROPERTIES", "ALIAS"}
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")

for doc in DOCS:
    shown = set()
    for start, end, lang, body in read_fences(os.path.join(CHAPTER, doc), doc):
        if lang == "tla":
            d, _p = parse("\n".join(body))
            shown |= set(re.sub(r"\(.*", "", n) for n in d)
            continue
        collecting = None
        wants = []          # (identifier, line number)
        looks_like_cfg = False
        for off, line in enumerate(body):
            m = CFGKW.match(line)
            if m:
                looks_like_cfg = True
                kw, rest = m.group(1), m.group(2)
                collecting = kw if kw in NAMED_KW else None
                if collecting:
                    wants += [(i, start + 1 + off) for i in IDENT.findall(rest)]
                continue
            if collecting and line.strip():
                wants += [(i, start + 1 + off) for i in IDENT.findall(line)]
        if not looks_like_cfg:
            continue
        for name, ln in wants:
            if name not in shown:
                fail("%s:%d: printed .cfg names `%s`, which no ```tla block in "
                     "this document defines" % (doc, ln, name))


# ------------------------------- check 3: transcripts name a pair run-all asserts

RUNLINE = re.compile(r"\./run\.sh\s+(\S+\.tla)(?:\s+(\S+\.cfg))?")
ECHOLINE = re.compile(r"^===\s+(\S+\.tla)\s+\((\S+\.cfg)\)\s+rc=(\d+)")
RC = re.compile(r"rc=(\d+)")

for doc in DOCS:
    for start, end, lang, body in read_fences(os.path.join(CHAPTER, doc), doc):
        for off, line in enumerate(body):
            ln = start + 1 + off
            m = RUNLINE.search(line)
            if m:
                mod = m.group(1)
                cfg = m.group(2) or (mod[:-4] + ".cfg")
                if (mod, cfg) not in CASES:
                    fail("%s:%d: transcript runs %s (%s) but run-all.sh asserts no rc"
                         % (doc, ln, mod, cfg))
                else:
                    rc = RC.search(line)
                    if rc and int(rc.group(1)) != CASES[(mod, cfg)]:
                        fail("%s:%d: claims rc=%s for %s (%s); run-all.sh asserts rc=%d"
                             % (doc, ln, rc.group(1), mod, cfg, CASES[(mod, cfg)]))
            e = ECHOLINE.match(line)
            if e:
                key = (e.group(1), e.group(2))
                if key not in CASES:
                    fail("%s:%d: transcript echoes %s (%s) but run-all.sh asserts no rc"
                         % (doc, ln, key[0], key[1]))
                elif CASES[key] != int(e.group(3)):
                    fail("%s:%d: echoes rc=%s for %s (%s); run-all.sh asserts rc=%d"
                         % (doc, ln, e.group(3), key[0], key[1], CASES[key]))


# ----------------------------- check 4: each .cfg's own Expected: rc= is truthful

EXPECTED = re.compile(r"Expected:\s*rc=(\d+)")

for cfg in configs:
    head = open(os.path.join(HERE, cfg), encoding="utf-8").read()
    rows = [(mod, c) for (mod, c) in CASES if c == cfg]
    if not rows:
        fail("%s: no row in run-all.sh's CASES table -- this config is never run" % cfg)
        continue
    m = EXPECTED.search(head)
    if not m:
        fail("%s: header states no `Expected: rc=` -- a reader has nothing to check" % cfg)
        continue
    for mod, c in rows:
        if CASES[(mod, c)] != int(m.group(1)):
            fail("%s: header says `Expected: rc=%s`, run-all.sh asserts rc=%d for %s"
                 % (cfg, m.group(1), CASES[(mod, c)], mod))


# --------------------------------- check 5: every module is exercised by some run

exercised = set(mod for mod, _ in CASES)
instantiated = set()
for fn, (_d, _p, _s, inst) in modules.items():
    if fn in exercised:
        instantiated |= inst
for fn in sorted(modules):
    if fn not in exercised and fn not in instantiated:
        fail("%s: never run by run-all.sh and never INSTANCEd by a module that is" % fn)


# ----------------------------------------------------------------------- report

print("check-blocks: %d ```tla blocks, %d modules, %d configs, %d asserted pairs"
      % (tla_blocks, len(modules), len(configs), len(CASES)))
if problems:
    print()
    for p in problems:
        print("FAIL  " + p)
    print("\n%d problem(s)" % len(problems))
    sys.exit(1)
print("check-blocks: all blocks reconcile")
