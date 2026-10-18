/*
 * swipe.js -- the level 0 swipe reader (bead tla-7xql.12, epic tla-7xql).
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
 * TLC ran once, at bake time, on a dev box. swipe/level0/bake.sh measured
 * every verdict and wrote it into field 6 of swipe/level0/ITEMS.tsv. This
 * page reads a baked table. There is no server, no JVM and no round trip,
 * which is what lets a static page on GitHub Pages grade an answer at all.
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
 * ========================================================================
 * THE DELIVERY ORDER IS NOT THE FILE ORDER
 * ========================================================================
 *
 * swipe/README.md: "The delivery order must still not be the id order, and
 * the file order is not it either: items sit in their authoring groups, so
 * a true item and its matched false item are next to each other for
 * review." Serving the corpus top to bottom would put a matched pair back
 * to back and hand over the second one.
 *
 * So the next item is drawn uniformly at random from the items this browser
 * has no answer for. Resume falls out of that with no cursor to keep: the
 * pool is the corpus minus the log, so a log imported from a file resumes
 * exactly where the file left off.
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
 */

(function () {
  "use strict";

  var STORAGE_KEY = "tla-swipe-level0";

  /* The version of the state this page keeps in localStorage. Separate from
     LOG_FORMAT below, which versions the exported file. One is a private
     cache and the other is a contract with a file Frank edits, so they are
     free to move independently. */
  var STATE_VERSION = 1;

  /* The version written into the exported SWIPE.tsv and demanded of any file
     offered to the import. Moving it means teaching importLog() to read both. */
  var LOG_FORMAT = 1;

  /* The payload_version swipe/reader/emit-items.sh writes. A payload this
     page does not know is refused rather than guessed at. */
  var PAYLOAD_VERSION = 1;

  /* Pixels of travel before a touch counts as a swipe rather than a tap. */
  var SWIPE_THRESHOLD = 55;

  var SWIPES = ["right", "left", "down"];

  var LABELS = {
    right: "true",
    left: "false",
    down: "not a claim"
  };

  /* Cached across instant navigations so leaving the page and coming back
     does not refetch 51 KB. */
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

  function loadState() {
    var raw = null;
    try {
      raw = window.localStorage.getItem(STORAGE_KEY);
    } catch (e) {
      return { version: STATE_VERSION, log: [], storable: false };
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
    return { version: STATE_VERSION, log: parsed.log, storable: true };
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
      "# The swipe log (bead tla-7xql.12, epic tla-7xql).",
      "#",
      "# Written by the level 0 swipe reader at",
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
      "#   2  item     an item id, resolving to a row in swipe/level0/ITEMS.tsv",
      "#   3  at       ISO 8601 UTC, when the swipe was given",
      "#   4  swipe    right, left or down",
      "#   5  verdict  hit or miss, against field 6 of ITEMS.tsv",
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
      if (f.length === 1 && /^SWIPE(FMT)?[  ]/.test(line)) {
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
      (v.mode === "misses" ? ", reviewing misses" : "");
    box.appendChild(line);
    return box;
  }

  /* THE CARD WRITES THE ASK TAG AND THE CLAIM AND NOTHING ELSE. No item id,
     for the reason in this file's header, and no template name either: the
     claim already says what family it is in and the tag is the only label
     decision D5 asks for. */
  function renderCard() {
    var v = view;
    var card = el("div", "swipe-card");
    card.setAttribute("data-swipe-card", "1");

    card.appendChild(el("p", "swipe-ask", v.current.ask));
    card.appendChild(el("pre", "swipe-claim", v.current.claim));
    card.appendChild(el("p", "swipe-hint",
      "Swipe right if it holds, left if it is false, down if it is not a " +
      "true-or-false claim at all. Swipe up for the last one you got wrong."));
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
    box.appendChild(el("pre", "swipe-claim", v.flash.item.claim));
    box.appendChild(el("p", "swipe-correction", v.flash.item.flash));
    box.appendChild(el("p", "swipe-hint", "Tap anywhere here for the next one."));

    box.addEventListener("click", function () {
      advance();
    });
    return box;
  }

  /* Decision D4: swipe up carries the explanation of the last WRONG answer,
     held until the next wrong one. At level 0 the explanation a wrong answer
     has is its flash, which is field 11 and is the correction. */
  function renderReview() {
    var v = view;
    var box = el("div", "swipe-review");
    if (!v.lastMiss) {
      box.appendChild(el("p", "swipe-hint",
        "Nothing to review yet. This holds the last answer you got wrong."));
    } else {
      box.appendChild(el("p", "swipe-verdict",
        "You said " + LABELS[v.lastMiss.given] + ". It is " +
        LABELS[v.lastMiss.item.swipe] + "."));
      box.appendChild(el("pre", "swipe-claim", v.lastMiss.item.claim));
      box.appendChild(el("p", "swipe-correction", v.lastMiss.item.flash));
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
      var t = item ? item.template : "?";
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
    } else {
      box.appendChild(el("p", "swipe-verdict", "That is all 240."));
      box.appendChild(el("p", null,
        "Export the record, then run the review queue over whatever is still " +
        "standing wrong."));
    }
    return box;
  }

  function renderControls() {
    var v = view;
    var box = el("div", "swipe-controls");

    var answers = el("div", "swipe-answers");
    for (var i = 0; i < SWIPES.length; i++) {
      answers.appendChild(answerButton(SWIPES[i]));
    }
    box.appendChild(answers);

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

  function pool() {
    var v = view;
    var out = [];
    var i;
    if (v.mode === "misses") {
      var missed = missedIds(v.state.log);
      for (i = 0; i < v.items.length; i++) {
        if (missed[v.items[i].id]) {
          out.push(v.items[i]);
        }
      }
      return out;
    }
    var seen = answeredIds(v.state.log);
    for (i = 0; i < v.items.length; i++) {
      if (!seen[v.items[i].id]) {
        out.push(v.items[i]);
      }
    }
    return out;
  }

  function nextItem() {
    var p = pool();
    if (p.length === 0) {
      view.current = null;
      return;
    }
    view.current = p[Math.floor(Math.random() * p.length)];
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
    view = {
      root: root,
      items: data.items,
      templates: data.templates || {},
      byId: {},
      state: loadState(),
      current: null,
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

  /* THE PARSE AND EXPORT HALVES ARE PURE, SO A GATE CAN EXERCISE THEM WITH
     NO BROWSER. harness/test-swipe-reader.sh requires this file through a
     script runtime and drives the refusal paths directly, which is the only
     way the "an import that cannot read a file refuses" contract gets
     checked by something that runs on every commit. These four lines are
     the only place in this file that knows a module system exists, and a
     browser takes neither branch. */
  if (typeof module === "object" && module && module.exports) {
    module.exports = {
      parseLog: parseLog,
      mergeLog: mergeLog,
      exportText: exportText,
      LOG_FORMAT: LOG_FORMAT
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
