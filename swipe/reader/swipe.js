/*
 * swipe.js -- the swipe reader (beads tla-7xql.12 and tla-7xql.14, epic
 * tla-7xql).
 *
 * Published by scripts/build-docs.sh to docs/javascripts/swipe.js and wired
 * through mkdocs.yml's extra_javascript, so it loads on every page of the
 * site and does nothing on all but one of them. The guard is the root
 * element: no #swipe-app, no reader.
 *
 * ========================================================================
 * NO MODEL CHECKER RUNS HERE
 * ========================================================================
 *
 * TLC ran once, at bake time, on a dev box. Each level's bake.sh measured
 * every verdict and wrote it into field 6 of its ITEMS.tsv. This page reads
 * a baked table. There is no server, no JVM and no round trip, which is what
 * lets a static page on GitHub Pages grade an answer at all.
 *
 * The model screens are baked too, by swipe/reader/render-screens.sh, for a
 * second reason that is nothing to do with the phone: the deploy runner has
 * no Java on it. That script's header carries the argument.
 *
 * ========================================================================
 * THREE LEVELS, AND ONLY TWO OF THEM HAVE A MODEL SCREEN
 * ========================================================================
 *
 * A level 0 item is one line of constant TLA+ and needs no model at all,
 * which is why the epic built that rung first. A level 1 item pins a STATE
 * and a level 2 item pins a STEP, and both put the model on screen with its
 * obligations stripped. That is decisions D2 and D7 on the epic: show the
 * definitions, the CONSTANTS and the pin, and not Init, Next, Spec or the
 * fairness conjunct, because showing the machine invites a reachability
 * check that is not the question and has no feedback channel.
 *
 * So a card is one of three shapes, and the level field decides which.
 *
 * ========================================================================
 * THE LAYOUT PROBLEM, WHICH IS THE REAL ONE AT THESE RUNGS
 * ========================================================================
 *
 * Frank ruled on 2026-10-18 that the phone is the only target. Measured over
 * the two corpora: the tallest model screen is 29 lines and the widest line
 * is 73 characters, and 73 characters does not fit 390 CSS pixels at any
 * readable monospace size. A level 2 pin adds up to 7 more rows under it.
 *
 * None of that fits a 390x844 viewport at once, and pretending otherwise is
 * how the reader ends up scrolling to find the question on every item. The
 * reader does not need both halves at once either: the epic's mechanic is
 * "a model, then a stream of single lines", ten to twenty lines per model.
 *
 * THE PAGE AROUND THE READER IS NOT MEASURABLE FROM HERE. mkdocs-material
 * puts a sticky header, an h1 and a lead-in paragraph above #swipe-app, and
 * how tall that is depends on the theme version, the font and the viewport.
 * A layout that budgets for it is a layout that is wrong after the next
 * theme bump. So the design does not budget for it:
 *
 *   THE QUESTION IS DOCKED. The ask, the claim and the three answer buttons
 *   sit in one block stuck to the bottom of the viewport. Whatever is above
 *   them, and however tall it is, the reader can read the question and
 *   answer it without scrolling. That is an invariant rather than an
 *   arithmetic result, which is the only kind worth having here.
 *
 *   THE PREMISE SCROLLS. The model screen and the pin sit above the dock and
 *   move with the page. The screen is a collapsible panel, capped in
 *   viewport units and scrolling inside itself both ways, so one model can
 *   never push another layout around.
 *
 *   THE STREAM IS SERVED IN BUCKETS, one per level and model, so the screen
 *   stays put across a run of items and the reader reads it once.
 *
 * A sideways scroll of the model and a left swipe are then two gestures on
 * one pixel, so the gesture handler declines a touch that starts inside the
 * screen body. The buttons still work there.
 *
 * ========================================================================
 * navigation.instant, AND WHY A PLAIN SCRIPT WOULD BE WRONG HERE
 * ========================================================================
 *
 * mkdocs.yml turns on the theme's navigation.instant feature, which loads
 * pages the way a single-page application does: the document is never
 * replaced, so a script that runs on load runs exactly once, on whichever
 * page the reader happened to open first. Arriving at the swipe page from
 * the nav would then find a dead page.
 *
 * mkdocs-material publishes window.document$ for this. It is an observable
 * that emits the current document on first load and again after every
 * instant navigation, and the theme's own documentation uses it to set up
 * third-party scripts. extra_javascript is injected after the theme bundle
 * (material/templates/base.html:253 then :254), so the observable is in
 * scope by the time this file runs.
 *
 * Two consequences the subscription brings with it, both handled in boot():
 * the callback can fire more than once over one page's life, so booting is
 * idempotent, and listeners bound to `document` rather than to the replaced
 * container would otherwise accumulate one copy per navigation.
 *
 * ========================================================================
 * THE ITEM ID NEVER REACHES THE CARD
 * ========================================================================
 *
 * swipe/README.md records that ids ran in kind order inside each template
 * for the first sixteen items of each one, so L0-T1-09 carries its own
 * answer in its name. harness/swipe/stemblind.sh hashes the id rather than
 * emitting it for that reason.
 *
 * The log needs the id and the card must never print it. renderCard() below
 * writes the ask tag and the claim and nothing else, and
 * harness/test-swipe-reader.sh asserts that no id reaches a card element.
 *
 * The MODEL name does reach the screen panel, and that is not the same
 * thing. A module name is the premise the reader is asked to read, and the
 * stem-blind instrument withholds it from a JUDGE for exactly the reason it
 * has to be shown to a reader.
 *
 * ========================================================================
 * THE DELIVERY ORDER IS NOT THE FILE ORDER
 * ========================================================================
 *
 * swipe/README.md: "The delivery order must still not be the id order, and
 * the file order is not it either: items sit in their authoring groups, so
 * a true item and its matched false item are next to each other for
 * review." Serving a corpus top to bottom would put a matched pair back to
 * back and hand over the second one.
 *
 * So the next item is drawn uniformly at random from the unanswered items of
 * the current bucket, and a new bucket is drawn at random when the current
 * one runs out. Resume falls out of that with no cursor to keep: the pool is
 * the corpus minus the log, so a log imported from a file resumes exactly
 * where the file left off.
 *
 * The bucket is what tla-7xql.14 adds and it narrows the draw rather than
 * replacing it. Matched items share a model, so a bucket run can put two
 * halves of a pair closer together than the whole-corpus draw would. At the
 * pinned rungs that is the lesson rather than a leak: six pairs per template
 * carry the SAME claim text at two pins with opposite answers, and meeting
 * both says what the rung is for, which is that the claim does not decide
 * and the state does.
 *
 * ========================================================================
 * localStorage IS A CACHE AND THE EXPORTED FILE IS THE RECORD
 * ========================================================================
 *
 * Frank ruled on 2026-10-18 that the round trip is export AND import. That
 * inverts which side is authoritative. ~/tla-practice/swipe/SWIPE.tsv is
 * the durable store, which puts this channel inside the convention every
 * other channel in the project follows, and a cleared browser stops being
 * data loss and becomes an import.
 *
 * So: an empty store is an ordinary state rather than a first run, the page
 * says so and reaches the import control from it, the exported format
 * carries a version marker, and an import that cannot read a file refuses
 * and says why instead of silently starting over. Silently starting over is
 * indistinguishable from working, which is the failure shape this project
 * keeps finding.
 *
 * THE LOG FORMAT DID NOT HAVE TO MOVE FOR THE TWO NEW RUNGS, because field 2
 * is an item id and an id already carries its level: L0-, L1-, L2-. A
 * SWIPE.tsv exported by the level 0 reader imports into this one unchanged.
 */

(function () {
  "use strict";

  /* The cache key. It read "tla-swipe-level0" while level 0 was the whole
     corpus, and a name that says level0 over a three-level record is a name
     that lies. The old key is read once and migrated below rather than
     abandoned, because a browser holding work is not a reason to lose it. */
  var STORAGE_KEY = "tla-swipe";
  var LEGACY_STORAGE_KEY = "tla-swipe-level0";

  /* The version of the state this page keeps in localStorage. Separate from
     LOG_FORMAT below, which versions the exported file. One is a private
     cache and the other is a contract with a file Frank edits, so they are
     free to move independently. */
  var STATE_VERSION = 1;

  /* The version written into the exported SWIPE.tsv and demanded of any file
     offered to the import. Moving it means teaching importLog() to read both.
     It stays at 1 across the two new rungs: the id carries the level, so no
     field moved. */
  var LOG_FORMAT = 1;

  /* The payload_version swipe/reader/emit-items.sh writes. A payload this
     page does not know is refused rather than guessed at. 1 was level 0
     alone; 2 adds the level field, the pinned rungs and the screens map. */
  var PAYLOAD_VERSION = 2;

  /* Pixels of travel before a touch counts as a swipe rather than a tap. */
  var SWIPE_THRESHOLD = 55;

  var SWIPES = ["right", "left", "down"];

  var LABELS = {
    right: "true",
    left: "false",
    down: "not a claim"
  };

  /* What the ask tag means as a question, per rung. A tag with no entry is
     shown as itself, which is what a new question kind does until somebody
     writes its line. */
  var PROMPTS = {
    holds: "does this hold",
    implies: "does this follow here",
    enabled: "does this fire here",
    terminal: "is this where it stops",
    step: "does this hold across the step",
    always: "does this hold all the way"
  };

  /* Cached across instant navigations so leaving the page and coming back
     does not refetch the payload. */
  var corpus = null;
  var corpusError = null;

  /* The live view state, rebuilt on every boot. */
  var view = null;

  /* The one listener this file binds outside the replaced container. Material
     keeps the document across an instant navigation, so without removing the
     previous one a reader who visits the page twice answers every item twice. */
  var keyHandler = null;

  /* ------------------------------------------------------------------ */
  /* localStorage, wrapped                                               */
  /*                                                                     */
  /* Private browsing, a blocked origin and a full quota all throw rather */
  /* than returning nothing, so every access is guarded. A browser that   */
  /* cannot store is not a broken page here: it is a page whose record    */
  /* lives entirely in the exported file, which is the ruling anyway.     */
  /* ------------------------------------------------------------------ */

  function readKey(key) {
    try {
      return window.localStorage.getItem(key);
    } catch (e) {
      return undefined;
    }
  }

  function loadState() {
    var raw = readKey(STORAGE_KEY);
    if (raw === undefined) {
      return { version: STATE_VERSION, log: [], storable: false };
    }
    var migrated = false;
    if (!raw) {
      /* A cache written by the level 0 reader under the old key. Read it,
         keep it, and let the next save write it under the new one. */
      raw = readKey(LEGACY_STORAGE_KEY);
      migrated = Boolean(raw);
    }
    if (!raw) {
      return { version: STATE_VERSION, log: [], storable: true };
    }
    var parsed;
    try {
      parsed = JSON.parse(raw);
    } catch (e) {
      /* A corrupt cache is not a reason to lose the session. It is reported
         on the page rather than cleared behind the reader's back. */
      return { version: STATE_VERSION, log: [], storable: true, corrupt: true };
    }
    if (!parsed || parsed.version !== STATE_VERSION || !Array.isArray(parsed.log)) {
      return { version: STATE_VERSION, log: [], storable: true, corrupt: true };
    }
    return { version: STATE_VERSION, log: parsed.log, storable: true, migrated: migrated };
  }

  function saveState(state) {
    if (!state.storable) {
      return false;
    }
    try {
      window.localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({ version: STATE_VERSION, log: state.log })
      );
      return true;
    } catch (e) {
      state.storable = false;
      return false;
    }
  }

  /* ------------------------------------------------------------------ */
  /* The log                                                             */
  /*                                                                     */
  /* One row is {i: item id, t: ISO 8601 UTC, s: the swipe given, v: hit  */
  /* or miss}. One table serves three uses, which is why it holds all     */
  /* four: resume reads which ids are in it, the review queue reads the   */
  /* misses, and bead tla-7xql.6 reads the whole thing against the recall */
  /* rung's own record.                                                   */
  /* ------------------------------------------------------------------ */

  function answeredIds(log) {
    var seen = {};
    for (var i = 0; i < log.length; i++) {
      seen[log[i].i] = true;
    }
    return seen;
  }

  /* The items whose MOST RECENT answer was a miss. Re-answering an item
     appends a row rather than replacing one, so the queue has to read the
     last row per item rather than any row. */
  function missedIds(log) {
    var last = {};
    for (var i = 0; i < log.length; i++) {
      last[log[i].i] = log[i].v;
    }
    var out = {};
    for (var id in last) {
      if (Object.prototype.hasOwnProperty.call(last, id) && last[id] === "miss") {
        out[id] = true;
      }
    }
    return out;
  }

  function nowStamp() {
    return new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
  }

  /* ------------------------------------------------------------------ */
  /* Buckets                                                             */
  /*                                                                     */
  /* A bucket is the set of items that share one model screen. At level 0 */
  /* there is no screen, so the whole rung is one bucket keyed "0". At    */
  /* the pinned rungs the key is the level and the model, which is also   */
  /* the key the payload files its screens under.                         */
  /*                                                                     */
  /* This is the epic's mechanic made mechanical: a model, then a stream  */
  /* of single lines about it. Without it a 29-line screen is redrawn for */
  /* every item and a reader crosses 17 models in 17 items.               */
  /* ------------------------------------------------------------------ */

  function bucketKey(item) {
    if (item.level === 0 || !item.model) {
      return String(item.level);
    }
    return item.level + ":" + item.model;
  }

  function bucketsOf(items) {
    var out = {};
    for (var i = 0; i < items.length; i++) {
      var k = bucketKey(items[i]);
      if (!out[k]) {
        out[k] = [];
      }
      out[k].push(items[i]);
    }
    return out;
  }

  /* ------------------------------------------------------------------ */
  /* The export format                                                   */
  /*                                                                     */
  /* Tab-delimited with a literal marker in field 1, which is the shape   */
  /* every table in this project uses, so prose in the file can never be  */
  /* read as data. The header prose is part of the contract rather than   */
  /* decoration: this file lands in ~/tla-practice, which is where Frank  */
  /* works, so it will get opened and it has to say what it is.           */
  /* ------------------------------------------------------------------ */

  function exportText(log, siteUrl) {
    var hits = 0;
    var misses = 0;
    var i;
    for (i = 0; i < log.length; i++) {
      if (log[i].v === "hit") {
        hits += 1;
      } else {
        misses += 1;
      }
    }

    var lines = [
      "# The swipe log (beads tla-7xql.12 and tla-7xql.14, epic tla-7xql).",
      "#",
      "# Written by the swipe reader at",
      "# " + siteUrl,
      "# and read back by that page's import control. It belongs at",
      "# ~/tla-practice/swipe/SWIPE.tsv, beside the other channels' tables.",
      "#",
      "# THIS FILE IS THE RECORD AND THE BROWSER IS A CACHE. Frank ruled on",
      "# 2026-10-18 that the round trip is export and import, which makes a",
      "# cleared browser an import rather than data loss.",
      "#",
      "# Rows are tab-delimited and carry a literal marker in field 1, so prose",
      "# in this file can never be read as data. Read rows with awk -F'\\t' or",
      "# cut, never with IFS=$'\\t' read: tab is IFS whitespace, so a run of",
      "# tabs collapses and an empty field vanishes.",
      "#",
      "# THE FORMAT IS A CONTRACT RATHER THAN A DUMP. The SWIPEFMT row carries",
      "# the version, and the import refuses a file without it instead of",
      "# starting over silently. Hand-edit the rows freely: comments, blank",
      "# lines and row order are all tolerated, and the import MERGES rather",
      "# than replaces, so nothing already in the browser is lost.",
      "#",
      "# A SWIPE ROW. Five fields, in order:",
      "#",
      "#   1  marker   the literal SWIPE",
      "#   2  item     an item id. Its L0, L1 or L2 prefix is the level, which",
      "#                is why three rungs needed no new field",
      "#   3  at       ISO 8601 UTC, when the swipe was given",
      "#   4  swipe    right, left or down",
      "#   5  verdict  hit or miss, against field 6 of the level's ITEMS.tsv",
      "#",
      "#   awk -F'\\t' '$1 == \"SWIPE\" && $5 == \"miss\"' SWIPE.tsv",
      "#   grep '^SWIPE' SWIPE.tsv | cut -f4 | sort | uniq -c",
      "#",
      "# FIELD 5 IS DERIVED. The import recomputes it from field 4 against the",
      "# corpus and reports how many rows it had to correct, so correcting a",
      "# swipe by hand needs no second edit.",
      "#",
      "# Exported " + nowStamp() + ". " + log.length + " rows, " +
        hits + " hit, " + misses + " miss.",
      "SWIPEFMT\t" + LOG_FORMAT
    ];

    for (i = 0; i < log.length; i++) {
      lines.push("SWIPE\t" + log[i].i + "\t" + log[i].t + "\t" + log[i].s + "\t" + log[i].v);
    }
    return lines.join("\n") + "\n";
  }

  /* ------------------------------------------------------------------ */
  /* The import                                                          */
  /*                                                                     */
  /* ALL OR NOTHING. A structural failure returns a refusal naming the    */
  /* line and nothing is written, because a partial import that reported  */
  /* success would be indistinguishable from a working one. What is       */
  /* TOLERATED is everything a hand edit does: comments, blank lines,     */
  /* CRLF endings, trailing whitespace and any row order.                 */
  /*                                                                     */
  /* Two things are accepted and REPORTED rather than refused. An id this */
  /* corpus does not carry is kept, because the corpus can lose an item   */
  /* and the log still has to round-trip. A verdict that disagrees with   */
  /* the baked one is recomputed, because field 5 is derived and          */
  /* correcting a swipe by hand should not need a second edit.            */
  /* ------------------------------------------------------------------ */

  function parseLog(text, byId) {
    var lines = text.split(/\r?\n/);
    var rows = [];
    var sawFormat = false;
    var unknown = 0;
    var corrected = 0;

    for (var n = 0; n < lines.length; n++) {
      var line = lines[n].replace(/\s+$/, "");
      if (line === "" || line.charAt(0) === "#") {
        continue;
      }
      var f = line.split("\t");
      var marker = f[0];

      /* An editor that saved the file with the tabs expanded leaves a row
         that reads right and parses as one field. Naming that is worth a
         case of its own, because the row LOOKS correct to the person who
         opened it and the generic marker refusal would send them hunting
         for a typo that is not there. */
      if (f.length === 1 && /^SWIPE(FMT)?[  ]/.test(line)) {
        return {
          error: "Line " + (n + 1) + " has spaces where its tabs should be, so it " +
            "reads as one field. An editor that expands tabs on save does this. " +
            "Nothing was imported."
        };
      }

      if (marker === "SWIPEFMT") {
        if (f.length < 2 || f[1] === "") {
          return { error: "Line " + (n + 1) + " is a SWIPEFMT row with no version on it." };
        }
        if (f[1] !== String(LOG_FORMAT)) {
          return {
            error: "This file is swipe log format " + f[1] + " and this page reads " +
              "format " + LOG_FORMAT + " only. Nothing was imported."
          };
        }
        sawFormat = true;
        continue;
      }

      if (marker !== "SWIPE") {
        return {
          error: "Line " + (n + 1) + " starts with \"" + marker.slice(0, 20) +
            "\", which is not a row this page reads. Nothing was imported."
        };
      }

      if (f.length < 5) {
        return {
          error: "Line " + (n + 1) + " has " + f.length + " fields and a SWIPE row " +
            "needs 5. An editor that turned the tabs into spaces does this. " +
            "Nothing was imported."
        };
      }

      var id = f[1];
      var at = f[2];
      var swipe = f[3];

      if (id === "") {
        return { error: "Line " + (n + 1) + " has an empty item id. Nothing was imported." };
      }
      if (at === "") {
        return { error: "Line " + (n + 1) + " has an empty timestamp. Nothing was imported." };
      }
      if (SWIPES.indexOf(swipe) === -1) {
        return {
          error: "Line " + (n + 1) + " has swipe \"" + swipe.slice(0, 20) +
            "\", which is not right, left or down. Nothing was imported."
        };
      }

      var item = byId[id];
      var verdict;
      if (!item) {
        unknown += 1;
        verdict = f[4] === "miss" ? "miss" : "hit";
      } else {
        verdict = swipe === item.swipe ? "hit" : "miss";
        if (verdict !== f[4]) {
          corrected += 1;
        }
      }
      rows.push({ i: id, t: at, s: swipe, v: verdict });
    }

    if (!sawFormat) {
      return {
        error: "This file carries no SWIPEFMT row, so it is not a swipe log this " +
          "page wrote. Nothing was imported."
      };
    }
    return { rows: rows, unknown: unknown, corrected: corrected };
  }

  /* Merge on (item, timestamp). An export re-imported is a no-op, and local
     work is never destroyed by reading a file. */
  function mergeLog(existing, incoming) {
    var seen = {};
    var out = existing.slice();
    var i;
    for (i = 0; i < existing.length; i++) {
      seen[existing[i].i + "\u0000" + existing[i].t] = true;
    }
    var added = 0;
    for (i = 0; i < incoming.length; i++) {
      var key = incoming[i].i + "\u0000" + incoming[i].t;
      if (seen[key]) {
        continue;
      }
      seen[key] = true;
      out.push(incoming[i]);
      added += 1;
    }
    out.sort(function (a, b) {
      return a.t < b.t ? -1 : (a.t > b.t ? 1 : 0);
    });
    return { log: out, added: added, duplicates: incoming.length - added };
  }

  /* ------------------------------------------------------------------ */
  /* Rendering                                                           */
  /* ------------------------------------------------------------------ */

  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) {
      e.className = cls;
    }
    if (text !== undefined && text !== null) {
      e.textContent = text;
    }
    return e;
  }

  function clear(node) {
    while (node.firstChild) {
      node.removeChild(node.firstChild);
    }
  }

  function pct(hits, total) {
    if (total === 0) {
      return "--";
    }
    return String(Math.round((hits / total) * 100)) + "%";
  }

  function templateName(item) {
    var v = view;
    var k = item.level + ":" + item.template;
    return v.templates[k] || item.template;
  }

  function render() {
    var v = view;
    clear(v.root);

    v.root.appendChild(renderStatus());

    if (v.panel === "stats") {
      v.root.appendChild(renderStats());
    } else if (v.panel === "review") {
      v.root.appendChild(renderReview());
    } else if (v.panel === "message") {
      v.root.appendChild(renderMessage());
    } else if (v.flash) {
      v.root.appendChild(renderFlash());
    } else if (v.current) {
      /* The premise first and the question last, which is both the reading
         order and the stacking order: the premise scrolls and the question
         is docked to the bottom of the viewport. */
      var screen = renderScreen(v.current);
      if (screen) {
        v.root.appendChild(screen);
      }
      if (v.current.level !== 0) {
        v.root.appendChild(renderPin(v.current));
      }
      v.root.appendChild(renderCard());
    } else {
      v.root.appendChild(renderDone());
    }

    v.root.appendChild(renderControls());
  }

  function renderStatus() {
    var v = view;
    var box = el("div", "swipe-status");
    var answered = Object.keys(answeredIds(v.state.log)).length;
    var remaining = v.items.length - answered;

    if (v.state.log.length === 0) {
      box.appendChild(el("p", "swipe-status-empty",
        "No record in this browser. The record lives in SWIPE.tsv, so import " +
        "one below to pick up where you left off, or just start."));
    }
    if (v.state.corrupt) {
      box.appendChild(el("p", "swipe-status-warn",
        "This browser held a record this page could not read, so it is being " +
        "ignored rather than deleted. Import your SWIPE.tsv."));
    }
    if (!v.state.storable) {
      box.appendChild(el("p", "swipe-status-warn",
        "This browser is not letting the page store anything, so nothing here " +
        "survives a reload. Export before you leave."));
    }

    var line = el("p", "swipe-counts");
    var hits = 0;
    for (var i = 0; i < v.state.log.length; i++) {
      if (v.state.log[i].v === "hit") {
        hits += 1;
      }
    }
    line.textContent = v.state.log.length + " answered, " + pct(hits, v.state.log.length) +
      " right, " + remaining + " of " + v.items.length + " unseen" +
      (v.level === null ? "" : ", level " + v.level + " only") +
      (v.mode === "misses" ? ", reviewing misses" : "");
    box.appendChild(line);
    return box;
  }

  /* ------------------------------------------------------------------ */
  /* The model screen                                                    */
  /*                                                                     */
  /* Returns null for a level 0 item, which has no model. The panel is    */
  /* collapsible and its state is remembered per bucket for this visit,   */
  /* so a reader who has read the model gets the whole viewport for the   */
  /* stream and can bring it back with one tap.                           */
  /*                                                                     */
  /* The body is NOT a swipe surface. See bindGestures().                 */
  /* ------------------------------------------------------------------ */
  function renderScreen(item) {
    var v = view;
    if (item.level === 0 || !item.model) {
      return null;
    }
    var key = bucketKey(item);
    var text = v.screens[key];
    if (!text) {
      /* Unreachable through the published payload, which withholds an item
         whose model has no screen. Kept because a hand-edited items.json is
         a thing that can happen, and a card with no premise should say so
         rather than pose a question it has removed the subject of. */
      var warn = el("div", "swipe-screen");
      warn.appendChild(el("p", "swipe-status-warn",
        "The model for this item did not ship a screen, so there is nothing " +
        "to read it against. Skip it."));
      return warn;
    }
    var collapsed = Boolean(v.collapsed[key]);

    var box = el("div", "swipe-screen");
    box.setAttribute("data-swipe-screen", "1");

    var head = el("button", "swipe-screen-head");
    head.type = "button";
    head.appendChild(el("span", "swipe-screen-name", item.model));
    head.appendChild(el("span", "swipe-screen-toggle", collapsed ? "show" : "hide"));
    head.addEventListener("click", function () {
      v.collapsed[key] = !collapsed;
      render();
    });
    box.appendChild(head);

    if (!collapsed) {
      box.appendChild(el("pre", "swipe-screen-body", text));
    }
    return box;
  }

  /* The pin, which is the question's subject. Level 1 pins one state and
     level 2 pins a step, so one rung draws one block and the other draws
     three. The labels are the renderers' own, from swipe/level1/render.sh
     and swipe/level2/render.sh, so a reader who has seen a terminal render
     sees the same words on the page. */
  function renderPin(item) {
    var box = el("div", "swipe-pin");
    if (item.level === 1) {
      box.appendChild(pinBlock("pinned at", item.pin));
      return box;
    }
    box.appendChild(pinBlock("from", item.pre));
    box.appendChild(pinBlock("steps to", item.post));
    if (item.binds && item.binds.length > 0) {
      box.appendChild(pinBlock("where", item.binds));
    }
    return box;
  }

  function pinBlock(label, rows) {
    var g = el("div", "swipe-pin-group");
    g.appendChild(el("p", "swipe-pin-label", label));
    g.appendChild(el("pre", "swipe-pin-body", (rows || []).join("\n")));
    return g;
  }

  /* THE CARD IS THE DOCK, and it writes the ask tag, the claim and the three
     answer buttons and nothing else. No item id, for the reason in this
     file's header, and no template name either: the claim already says what
     family it is in and the tag is the only label decision D5 asks for.

     The pin is NOT in here. It is premise, it scrolls, and a 7-row level 2
     pin inside the dock would be a dock taller than half the viewport. */
  function renderCard() {
    var v = view;
    var item = v.current;
    var card = el("div", "swipe-card");
    card.setAttribute("data-swipe-card", "1");

    card.appendChild(el("p", "swipe-ask", PROMPTS[item.ask] || item.ask));
    card.appendChild(el("pre", "swipe-claim", item.claim));

    var answers = el("div", "swipe-answers");
    for (var i = 0; i < SWIPES.length; i++) {
      answers.appendChild(answerButton(SWIPES[i]));
    }
    card.appendChild(answers);

    /* One line, and short, because every pixel here is a pixel of premise
       the reader does not get. The long form is on the page itself and in
       the status block on a cold start. */
    card.appendChild(el("p", "swipe-hint", "up for the last one you got wrong"));
    return card;
  }

  function renderFlash() {
    var v = view;
    var box = el("div", "swipe-flash swipe-flash-" + v.flash.verdict);
    box.setAttribute("data-swipe-flash", "1");

    box.appendChild(el("p", "swipe-verdict",
      v.flash.verdict === "hit"
        ? "Right. It is " + LABELS[v.flash.item.swipe] + "."
        : "No. You said " + LABELS[v.flash.given] + " and it is " +
          LABELS[v.flash.item.swipe] + "."));
    /* THE PIN GOES WITH THE CORRECTION at the pinned rungs. A level 1
       correction reads "the open count is 1, so Pop's first conjunct holds",
       and that sentence is unreadable without the state it is about. The
       model screen does NOT come along: it is 29 lines at worst and the
       flash is the feedback L2 measured, so it gets the screen to itself. */
    if (v.flash.item.level !== 0) {
      box.appendChild(renderPin(v.flash.item));
    }
    box.appendChild(el("pre", "swipe-claim", v.flash.item.claim));
    box.appendChild(el("p", "swipe-correction", v.flash.item.flash));
    box.appendChild(el("p", "swipe-hint", "Tap anywhere here for the next one."));

    box.addEventListener("click", function () {
      advance();
    });
    return box;
  }

  /* Decision D4: swipe up carries the explanation of the last WRONG answer,
     held until the next wrong one. The explanation a wrong answer has is its
     flash, which is field 11. At the pinned rungs the pin goes with it, since
     a claim without its pin says nothing. */
  function renderReview() {
    var v = view;
    var box = el("div", "swipe-review");
    if (!v.lastMiss) {
      box.appendChild(el("p", "swipe-hint",
        "Nothing to review yet. This holds the last answer you got wrong."));
    } else {
      var item = v.lastMiss.item;
      box.appendChild(el("p", "swipe-verdict",
        "You said " + LABELS[v.lastMiss.given] + ". It is " +
        LABELS[item.swipe] + "."));
      if (item.level !== 0) {
        box.appendChild(el("p", "swipe-hint", item.model));
        box.appendChild(renderPin(item));
      }
      box.appendChild(el("pre", "swipe-claim", item.claim));
      box.appendChild(el("p", "swipe-correction", item.flash));
    }
    var back = el("button", "swipe-btn", "back");
    back.type = "button";
    back.addEventListener("click", function () {
      v.panel = null;
      render();
    });
    box.appendChild(back);
    return box;
  }

  function renderStats() {
    var v = view;
    var box = el("div", "swipe-stats");
    var byTemplate = {};
    var i;
    var byId = v.byId;

    for (i = 0; i < v.state.log.length; i++) {
      var row = v.state.log[i];
      var item = byId[row.i];
      var t = item ? item.level + ":" + item.template : "?";
      if (!byTemplate[t]) {
        byTemplate[t] = { n: 0, hits: 0 };
      }
      byTemplate[t].n += 1;
      if (row.v === "hit") {
        byTemplate[t].hits += 1;
      }
    }

    var table = el("table", "swipe-table");
    var head = el("tr");
    head.appendChild(el("th", null, "level"));
    head.appendChild(el("th", null, "family"));
    head.appendChild(el("th", null, "answered"));
    head.appendChild(el("th", null, "right"));
    table.appendChild(head);

    var keys = Object.keys(byTemplate).sort();
    if (keys.length === 0) {
      box.appendChild(el("p", "swipe-hint", "Nothing answered yet."));
    } else {
      for (i = 0; i < keys.length; i++) {
        var k = keys[i];
        var tr = el("tr");
        tr.appendChild(el("td", null, k.split(":")[0]));
        tr.appendChild(el("td", null, v.templates[k] || k));
        tr.appendChild(el("td", null, String(byTemplate[k].n)));
        tr.appendChild(el("td", null, pct(byTemplate[k].hits, byTemplate[k].n)));
        table.appendChild(tr);
      }
      box.appendChild(table);
    }

    var missing = Object.keys(missedIds(v.state.log)).length;
    box.appendChild(el("p", "swipe-hint",
      missing + " items are standing wrong. The review queue serves those."));

    /* THE WITHHELD BLOCK IS SHOWN TO THE READER AND NOT ONLY TO THE BUILD
       LOG. A model whose screen renders empty has its items dropped by
       swipe/reader/emit-items.sh, which says so on stderr. A reader counting
       items on the page would otherwise find a number nobody can explain. */
    if (v.withheld && v.withheld.length > 0) {
      var dropped = 0;
      var names = [];
      for (i = 0; i < v.withheld.length; i++) {
        dropped += v.withheld[i].items;
        names.push(v.withheld[i].model + " at level " + v.withheld[i].level);
      }
      box.appendChild(el("p", "swipe-hint",
        dropped + " items are not served, because " + names.join(", ") +
        " renders no model screen: " + v.withheld[0].reason + "."));
    }

    var back = el("button", "swipe-btn", "back");
    back.type = "button";
    back.addEventListener("click", function () {
      v.panel = null;
      render();
    });
    box.appendChild(back);
    return box;
  }

  function renderMessage() {
    var v = view;
    var box = el("div", "swipe-message swipe-message-" + (v.message.kind || "info"));
    box.appendChild(el("p", "swipe-verdict", v.message.title));
    var lines = v.message.body || [];
    for (var i = 0; i < lines.length; i++) {
      box.appendChild(el("p", null, lines[i]));
    }
    var back = el("button", "swipe-btn", "back");
    back.type = "button";
    back.addEventListener("click", function () {
      v.panel = null;
      v.message = null;
      render();
    });
    box.appendChild(back);
    return box;
  }

  function renderDone() {
    var v = view;
    var box = el("div", "swipe-done");
    if (v.mode === "misses") {
      box.appendChild(el("p", "swipe-verdict", "Nothing is standing wrong."));
      box.appendChild(el("p", null,
        "The review queue is empty. Switch back to the main stream below."));
    } else if (v.level !== null) {
      box.appendChild(el("p", "swipe-verdict", "Level " + v.level + " is done."));
      box.appendChild(el("p", null,
        "Switch to all levels below, or export the record."));
    } else {
      box.appendChild(el("p", "swipe-verdict", "That is all " + v.items.length + "."));
      box.appendChild(el("p", null,
        "Export the record, then run the review queue over whatever is still " +
        "standing wrong."));
    }
    return box;
  }

  /* The menu, which is everything that is not an answer. The three answer
     buttons live in the dock with the claim, so they cannot be scrolled away
     from the question they answer. */
  function renderControls() {
    var v = view;
    var box = el("div", "swipe-controls");

    var menu = el("div", "swipe-menu");

    menu.appendChild(menuButton("review", function () {
      v.panel = "review";
      render();
    }));
    menu.appendChild(menuButton("stats", function () {
      v.panel = "stats";
      render();
    }));
    menu.appendChild(menuButton(
      v.mode === "misses" ? "all items" : "misses only",
      function () {
        v.mode = v.mode === "misses" ? "all" : "misses";
        v.panel = null;
        v.flash = null;
        v.bucket = null;
        nextItem();
        render();
      }
    ));
    /* The level filter, so one rung can be drilled on its own. It cycles
       rather than opening a picker, because three rungs and "all" is four
       taps round the loop and a picker is a panel. */
    menu.appendChild(menuButton(
      v.level === null ? "all levels" : "level " + v.level,
      function () {
        var i = v.levels.indexOf(v.level);
        v.level = v.levels[(i + 1) % v.levels.length];
        v.panel = null;
        v.flash = null;
        v.bucket = null;
        nextItem();
        render();
      }
    ));
    menu.appendChild(menuButton("export", doExport));

    var label = el("label", "swipe-btn swipe-import", "import");
    var input = el("input");
    input.type = "file";
    input.accept = ".tsv,.txt,text/plain,text/tab-separated-values";
    input.className = "swipe-file";
    input.addEventListener("change", function (ev) {
      var file = ev.target.files && ev.target.files[0];
      if (file) {
        doImport(file);
      }
      ev.target.value = "";
    });
    label.appendChild(input);
    menu.appendChild(label);

    box.appendChild(menu);
    return box;
  }

  function answerButton(swipe) {
    var b = el("button", "swipe-btn swipe-answer swipe-answer-" + swipe, LABELS[swipe]);
    b.type = "button";
    b.disabled = !view.current || view.panel !== null;
    b.addEventListener("click", function () {
      answer(swipe);
    });
    return b;
  }

  function menuButton(text, fn) {
    var b = el("button", "swipe-btn", text);
    b.type = "button";
    b.addEventListener("click", fn);
    return b;
  }

  /* ------------------------------------------------------------------ */
  /* The stream                                                          */
  /* ------------------------------------------------------------------ */

  /* Every item this browser still owes an answer for, under the current
     mode and level filter. */
  function pool() {
    var v = view;
    var out = [];
    var i;
    var pick = v.mode === "misses" ? missedIds(v.state.log) : null;
    var seen = pick ? null : answeredIds(v.state.log);
    for (i = 0; i < v.items.length; i++) {
      var it = v.items[i];
      if (v.level !== null && it.level !== v.level) {
        continue;
      }
      if (pick) {
        if (pick[it.id]) {
          out.push(it);
        }
      } else if (!seen[it.id]) {
        out.push(it);
      }
    }
    return out;
  }

  /* The next item comes from the bucket the last one came from, while that
     bucket still owes answers. That keeps the model screen still across a
     run, which is the epic's mechanic. The draw INSIDE a bucket is uniform
     at random, which is the property tla-7xql.12 built the random draw for:
     the file order puts a matched pair back to back. */
  function nextItem() {
    var v = view;
    var p = pool();
    if (p.length === 0) {
      v.current = null;
      v.bucket = null;
      return;
    }
    var buckets = bucketsOf(p);
    var key = v.bucket;
    if (!key || !buckets[key]) {
      var keys = Object.keys(buckets);
      key = keys[Math.floor(Math.random() * keys.length)];
      v.bucket = key;
    }
    var b = buckets[key];
    v.current = b[Math.floor(Math.random() * b.length)];
  }

  function answer(swipe) {
    var v = view;
    if (!v.current || v.panel !== null || v.flash) {
      return;
    }
    var item = v.current;
    var verdict = swipe === item.swipe ? "hit" : "miss";
    v.state.log.push({ i: item.id, t: nowStamp(), s: swipe, v: verdict });
    saveState(v.state);
    if (verdict === "miss") {
      v.lastMiss = { item: item, given: swipe };
    }
    v.flash = { item: item, given: swipe, verdict: verdict };
    render();
  }

  function advance() {
    view.flash = null;
    nextItem();
    render();
  }

  /* ------------------------------------------------------------------ */
  /* Export and import                                                   */
  /* ------------------------------------------------------------------ */

  function doExport() {
    var v = view;
    var text = exportText(v.state.log, window.location.href);
    var blob = new Blob([text], { type: "text/tab-separated-values;charset=utf-8" });
    var url = URL.createObjectURL(blob);
    var a = document.createElement("a");
    a.href = url;
    a.download = "SWIPE.tsv";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    /* Revoked on a timer rather than straight away, because a mobile browser
       that hands the blob to a download manager may not have read it yet. */
    window.setTimeout(function () {
      URL.revokeObjectURL(url);
    }, 30000);

    v.panel = "message";
    v.message = {
      kind: "info",
      title: "Exported " + v.state.log.length + " rows.",
      body: ["Put it at ~/tla-practice/swipe/SWIPE.tsv. That file is the record and this browser is a cache."]
    };
    render();
  }

  function doImport(file) {
    var v = view;
    var reader = new FileReader();
    reader.onerror = function () {
      v.panel = "message";
      v.message = {
        kind: "error",
        title: "That file could not be read.",
        body: ["Nothing was imported."]
      };
      render();
    };
    reader.onload = function () {
      var parsed = parseLog(String(reader.result), v.byId);
      if (parsed.error) {
        v.panel = "message";
        v.message = {
          kind: "error",
          title: "Refused.",
          body: [parsed.error]
        };
        render();
        return;
      }
      var merged = mergeLog(v.state.log, parsed.rows);
      v.state.log = merged.log;
      var stored = saveState(v.state);

      var body = [
        "Read " + parsed.rows.length + " rows. Added " + merged.added +
          ", already had " + merged.duplicates + "."
      ];
      if (parsed.corrected > 0) {
        body.push(parsed.corrected + " rows carried a verdict that disagreed with the " +
          "baked one, and were recomputed from the swipe.");
      }
      if (parsed.unknown > 0) {
        body.push(parsed.unknown + " rows name items this corpus does not carry. They " +
          "were kept, so the log still round-trips.");
      }
      if (!stored) {
        body.push("This browser would not store the result, so it holds for this " +
          "visit only.");
      }
      v.panel = "message";
      v.message = { kind: "info", title: "Imported.", body: body };
      v.flash = null;
      v.bucket = null;
      rebuildLastMiss();
      nextItem();
      render();
    };
    reader.readAsText(file);
  }

  /* After an import the review queue should point at something, so the last
     miss is recovered from the log rather than left at whatever this visit
     happened to produce. */
  function rebuildLastMiss() {
    var v = view;
    v.lastMiss = null;
    for (var i = v.state.log.length - 1; i >= 0; i--) {
      if (v.state.log[i].v === "miss") {
        var item = v.byId[v.state.log[i].i];
        if (item) {
          v.lastMiss = { item: item, given: v.state.log[i].s };
          return;
        }
      }
    }
  }

  /* ------------------------------------------------------------------ */
  /* Gestures                                                            */
  /* ------------------------------------------------------------------ */

  function bindGestures(root) {
    var startX = 0;
    var startY = 0;
    var tracking = false;

    root.addEventListener("touchstart", function (ev) {
      if (ev.touches.length !== 1) {
        tracking = false;
        return;
      }
      /* THE MODEL SCREEN IS NOT A SWIPE SURFACE. The widest screen line is
         73 characters, which does not fit 390 CSS pixels at any readable
         size, so the body scrolls sideways. A left swipe and a sideways
         scroll would then be the same gesture on the same pixel, and the
         reader would answer "false" every time they looked along a line. */
      var t = ev.target;
      if (t && t.closest && t.closest(".swipe-screen-body")) {
        tracking = false;
        return;
      }
      tracking = true;
      startX = ev.touches[0].clientX;
      startY = ev.touches[0].clientY;
    }, { passive: true });

    root.addEventListener("touchend", function (ev) {
      if (!tracking) {
        return;
      }
      tracking = false;
      var t = ev.changedTouches[0];
      var dx = t.clientX - startX;
      var dy = t.clientY - startY;
      if (Math.abs(dx) < SWIPE_THRESHOLD && Math.abs(dy) < SWIPE_THRESHOLD) {
        return;
      }
      if (Math.abs(dx) > Math.abs(dy)) {
        gesture(dx > 0 ? "right" : "left");
      } else {
        gesture(dy > 0 ? "down" : "up");
      }
    }, { passive: true });
  }

  function gesture(dir) {
    var v = view;
    if (v.panel !== null) {
      return;
    }
    if (v.flash) {
      advance();
      return;
    }
    if (dir === "up") {
      v.panel = "review";
      render();
      return;
    }
    answer(dir);
  }

  function bindKeys() {
    if (keyHandler) {
      document.removeEventListener("keydown", keyHandler);
      keyHandler = null;
    }
    keyHandler = function (ev) {
      if (!view || !view.root.isConnected) {
        return;
      }
      var map = {
        ArrowRight: "right",
        ArrowLeft: "left",
        ArrowDown: "down",
        ArrowUp: "up"
      };
      var dir = map[ev.key];
      if (!dir) {
        return;
      }
      ev.preventDefault();
      gesture(dir);
    };
    document.addEventListener("keydown", keyHandler);
  }

  /* ------------------------------------------------------------------ */
  /* Boot                                                                */
  /* ------------------------------------------------------------------ */

  function fail(root, title, detail) {
    clear(root);
    var box = el("div", "swipe-message swipe-message-error");
    box.appendChild(el("p", "swipe-verdict", title));
    box.appendChild(el("p", null, detail));
    root.appendChild(box);
  }

  function start(root, data) {
    /* The level cycle for the filter button. Read off the payload rather
       than written here, so a fourth rung joins the cycle the day it ships.
       null is "all levels" and leads the list. */
    var levels = [null];
    var declared = Array.isArray(data.levels) ? data.levels : [];
    for (var j = 0; j < declared.length; j++) {
      levels.push(declared[j]);
    }

    view = {
      root: root,
      items: data.items,
      templates: data.templates || {},
      screens: data.screens || {},
      withheld: data.withheld || [],
      levels: levels,
      level: null,
      byId: {},
      state: loadState(),
      current: null,
      bucket: null,
      collapsed: {},
      flash: null,
      lastMiss: null,
      panel: null,
      message: null,
      mode: "all"
    };
    for (var i = 0; i < data.items.length; i++) {
      view.byId[data.items[i].id] = data.items[i];
    }
    rebuildLastMiss();
    nextItem();
    bindGestures(root);
    bindKeys();
    render();
  }

  function boot(doc) {
    var d = doc || document;
    var root = d.getElementById("swipe-app");
    if (!root) {
      /* Any other page on the site. Drop the document-level key listener so
         it does not answer items from a page that has none. */
      if (keyHandler) {
        document.removeEventListener("keydown", keyHandler);
        keyHandler = null;
      }
      view = null;
      return;
    }

    if (corpusError) {
      fail(root, "The items did not load.", corpusError);
      return;
    }
    if (corpus) {
      start(root, corpus);
      return;
    }

    var src = root.getAttribute("data-items") || "items.json";
    var url;
    try {
      url = new URL(src, window.location.href).href;
    } catch (e) {
      url = src;
    }

    clear(root);
    root.appendChild(el("p", "swipe-hint", "Loading the items..."));

    window.fetch(url, { credentials: "same-origin" })
      .then(function (res) {
        if (!res.ok) {
          throw new Error("the server answered " + res.status + " for " + src);
        }
        return res.json();
      })
      .then(function (data) {
        if (!data || data.payload_version !== PAYLOAD_VERSION) {
          throw new Error(
            "the item file is payload version " +
            (data && data.payload_version) + " and this page reads " +
            PAYLOAD_VERSION + " only"
          );
        }
        if (!Array.isArray(data.items) || data.items.length === 0) {
          throw new Error("the item file carries no items");
        }
        corpus = data;
        if (document.getElementById("swipe-app")) {
          start(document.getElementById("swipe-app"), corpus);
        }
      })
      .catch(function (err) {
        corpusError = String(err && err.message ? err.message : err);
        var live = document.getElementById("swipe-app");
        if (live) {
          fail(live, "The items did not load.", corpusError);
        }
      });
  }

  /* THE PARSE, EXPORT AND BUCKET HALVES ARE PURE, SO A GATE CAN EXERCISE
     THEM WITH NO BROWSER. harness/test-swipe-reader.sh requires this file
     through a script runtime and drives the refusal paths and the bucket
     split directly rather than grepping for a message. These lines are the
     only place in this file that knows a module system exists, and a browser
     takes neither branch. */
  if (typeof module === "object" && module && module.exports) {
    module.exports = {
      parseLog: parseLog,
      mergeLog: mergeLog,
      exportText: exportText,
      bucketsOf: bucketsOf,
      bucketKey: bucketKey,
      LOG_FORMAT: LOG_FORMAT,
      PAYLOAD_VERSION: PAYLOAD_VERSION
    };
    return;
  }

  if (window.document$ && typeof window.document$.subscribe === "function") {
    window.document$.subscribe(boot);
  } else if (document.readyState === "loading") {
    /* No theme bundle, so no instant navigation and one page load. */
    document.addEventListener("DOMContentLoaded", function () {
      boot(document);
    });
  } else {
    boot(document);
  }
})();
