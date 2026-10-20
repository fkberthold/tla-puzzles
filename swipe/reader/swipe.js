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
 *   arithmetic result, which is the only kind worth having here. Since bead
 *   tla-7xql.18 the dock is the RESTING view's and a step replaces it
 *   entirely. See A STEP IS THE WHOLE PAGE.
 *
 *   THE PREMISE IS A STACK THE READER WALKS UP. At rest the card is the
 *   question and nothing else, so the premise cannot sit behind the dock
 *   because none of it is drawn. Swipe up for one step deeper and tap for
 *   one step back. See THE STACK below.
 *
 *   THE STREAM IS SERVED IN BUCKETS, one per level and model, so the screen
 *   stays put across a run of items and the reader reads it once.
 *
 * A sideways scroll of the model and a left swipe are then two gestures on
 * one pixel, so the gesture handler declines a touch that starts inside the
 * screen body WHEN THAT BODY IS ACTUALLY SCROLLING SIDEWAYS. The buttons
 * still work there. See R1 under A STEP IS THE WHOLE PAGE below for why the
 * reading has to be conditional.
 *
 * ========================================================================
 * THE STACK, AND THE FIVE GESTURES
 * ========================================================================
 *
 * Bead tla-7xql.15. Measured in a real browser at a true 390x844 viewport on
 * 2026-10-19: a level 2 item drew a 296-pixel model screen and a 327-pixel
 * pin above a dock that left 575 pixels of room, so 198 pixels of pin sat
 * BEHIND the dock the moment the item appeared. The reader landed on a
 * "steps to" label with its content covered and nothing to say so.
 *
 * Frank ruled against tuning those heights. The premise leaves the resting
 * view instead and becomes a stack:
 *
 *   level 0   1 = the explanation of the last wrong answer
 *   level 1   1 = the pinned state, 2 = the model, 3 = the explanation
 *   level 2   1 = from, steps to and where, 2 = the model, 3 = the same
 *
 * The list is built from what the item carries rather than from its level,
 * so an item with no model skips that step instead of drawing an empty one.
 * stepsFor() is the whole rule.
 *
 * EVERY GESTURE KEEPS ONE MEANING IN EVERY STATE, and that is the point
 * rather than a nicety:
 *
 *   right, left, down   it is true, it is false, it says nothing
 *   up                  one step deeper
 *   tap                 one step back
 *
 * An earlier draft had down mean "back" while the stack was open. It was
 * dropped because a reader wrong about which mode they were in would file a
 * vacuity verdict on an item that is a claim, and the log cannot tell that
 * from a reader who meant it.
 *
 * THE ANSWERS GO DEAD AT THE LAST STEP ONLY. Steps 1 and 2 are the item on
 * screen, so an answer there is an answer to the question the reader is being
 * asked. The last step is the explanation of a DIFFERENT item, the last one
 * answered wrong, so the answers go dead and that is the one mode change.
 *
 * EVERY STEP DRAWS ITS OWN BACK BUTTON. Tap anywhere is the convenience and
 * the button is the guarantee, because a touch over the model box is declined
 * whatever it does and a touch inside the model body is declined when it
 * scrolls the model. At level 2 that is most of the page. A tap surface with a
 * hole in it where the reader's thumb has just been is not a way out on its
 * own.
 *
 * ========================================================================
 * A STEP IS THE WHOLE PAGE, AND IT TOOK THREE BEADS TO GET HERE
 * ========================================================================
 *
 * Bead tla-7xql.18. The stack above kept the dock drawn while a step was
 * open, on the argument that reading the premise with the claim hidden is the
 * working-memory test the dock exists to prevent. That argument was right and
 * the arithmetic underneath it was not.
 *
 * Read in Chrome at a true 390x844 against the published build, with a record
 * present and the model step open. Every child of #swipe-app is flex: 0 0 auto
 * except .swipe-step, so the step is the ONLY shrinkable thing and absorbs
 * whatever is left over:
 *
 *   the counts      29.6
 *   the step       276.4
 *   the card       304
 *   the menu       172
 *   padding+gaps    62
 *                  844 exactly
 *
 * Inside that 276.4 the model screen got 66.3 pixels against the 438 its
 * content wanted. Frank, on his phone: "It isn't showing the model." It was
 * showing the model, through a slot one line tall. Hiding the menu alone took
 * the step to 462.4 and the screen to 252.3, which is what said the chrome was
 * the whole deficit rather than the payload. The payload was checked and
 * cleared: 24 screen keys against 24 non-zero bucket keys, nothing missing.
 *
 * SO A STEP IS THE WHOLE PAGE. At depth the counts, the card and the menu are
 * not drawn at all, and the step gets 824 of the 844.
 *
 *   D1  chromeAt() is the whole rule and it is ONE PURE FUNCTION. render()
 *       asks it rather than carrying three conditions, because what has to be
 *       true is a table over every state and no pattern over render()'s source
 *       can see a table. harness/test-swipe-reader.sh drives all 30.
 *
 *   D2  ONE LINE OF THE CLAIM STAYS, at the foot of the step view, on the
 *       dock's own .swipe-claim type. REVERSED THE SAME DAY by bead
 *       tla-7xql.19, and the reversal is recorded here rather than the
 *       decision being edited away, because the two readings together are
 *       what the next author needs. See THE CLAIM LEAVES THE STEP below.
 *
 *   D3  THE MENU COLLAPSES BEHIND ONE CONTROL AT REST TOO. Eight controls
 *       touched once a session against one touched every item. It is the third
 *       value of v.panel rather than a new mechanism, so it inherits the rule
 *       that a swipe is declined while a panel is open. Three rows of buttons
 *       become one, which is 120 pixels: a 2.6rem button and a 0.4rem gap at
 *       20px to the rem put three rows at exactly the 172 that was measured.
 *       At the resting card those 120 are free space the dock was not using
 *       anyway. What takes them is every view that flexes with the menu still
 *       drawn, which is the flash and the three panels.
 *
 *   D4  THE GESTURE TABLE DOES NOT MOVE. A swipe right at the model step still
 *       files "true" with no button on screen. answersLive() is untouched: the
 *       buttons going away removes the affordance, not the answer.
 *
 * R1, WHICH THIS CHANGE CREATES. The screen-body decline above was
 * unconditional. At 66 of 844 pixels that cost almost nothing, and full-page
 * it is most of the phone, where the back button would be the only way out.
 * So the decline reads the axis it is about: scrollWidth against clientWidth,
 * the sideways form of the test .swipe-step-body already used. A model that
 * fits keeps the whole page for tap and swipe, and most of them now do.
 *
 * THE 660 THAT USED TO BE WRITTEN HERE WAS ARITHMETIC AND IT WAS WRONG. It
 * read "824 less the step's own furniture leaves about 660 for the model
 * body". A browser read the body at 480.0 with the claim drawn and 613.9
 * without it, under bead tla-7xql.19, so the inference was 180 pixels over
 * even before the claim came out. The lesson is the one this file keeps
 * learning: the chrome around the body is the theme's, so subtracting a
 * guess at it is not a reading.
 *
 * scrollerDeclining() holds all three declines so the table can be driven with
 * no browser, in both directions. A decline that always fires and a decline
 * that never fires both pass a one-sided check, and the first of those is the
 * defect this bead removes.
 *
 * ========================================================================
 * THE CLAIM LEAVES THE STEP, AND THE MODEL STOPS BEING COLLAPSIBLE
 * ========================================================================
 *
 * Bead tla-7xql.19, the same afternoon as tla-7xql.18. Frank read a model on
 * his phone and reversed D2: "I think we will be better off having to flick
 * back and forth for the problem." To re-read the claim you tap back to the
 * question and swipe up again.
 *
 * THE REVERSAL IS THE USEFUL PART, so it is written down rather than tidied
 * away. D2's argument was that a reader checking a claim against a step in
 * front of them should not be holding it in their head, and nothing refuted
 * that. It lost to a measurement nobody had taken yet. Read in Chrome at a
 * true 390x844 against the published build, model step open on 1:Fences, with
 * the claim line set to display: none and the body re-read:
 *
 *   model body with the claim      480.0
 *   model body without it          613.9
 *   returned                       133.9
 *
 * Over all 24 published screens, at 21.28 pixels per line and 12 of bottom
 * padding, that is five overflowing vertically with the claim and one without.
 * The one left is 1:Shelves at 29 lines, which wants about 629 against 613.9
 * and scrolls a little. Frank ruled it stays scrolling rather than the type
 * shrinking for one screen, and accepted the sideways scroll in the same
 * breath: "the phone screen is going to be tight."
 *
 * harness/test-swipe-reader.sh holds that reading as a scan over the payload
 * rather than as a sentence here, and it keeps BOTH heights, because the pair
 * is what makes the scan discriminate.
 *
 * THE COLLAPSE CONTROL WENT WITH IT, and it was a leftover rather than a
 * second decision. The head was a button toggling v.collapsed[key] and
 * printing "hide" or "show". That earned its place while the model shared the
 * resting view with the card. The step IS the model since D1, so collapsing it
 * leaves the step with a head and nothing under it, which is very likely what
 * Frank was looking at when he reported that the model was not showing. The
 * head is a label now and the model's NAME stays on it, since that is the one
 * thing on screen saying which model is being read.
 *
 * ========================================================================
 * THE STEP HINT GOES, AND AN i CARRIES THE GESTURE TABLE
 * ========================================================================
 *
 * Bead tla-7xql.20, the evening of the two above. The step view ended with
 * "up for the model, tap to come back", or "tap to come back" at the top, and
 * the second half of that line promised something most of the view cannot
 * keep. scrollerDeclining() refuses a touch that starts over a model
 * scrolling sideways, and central read 22 of the 24 published screens in
 * Chrome as wider than the 29 characters the body fits. With the claim gone
 * that body is 613.9 of 844, so about three quarters of the step will not
 * take the tap the hint was offering.
 *
 * Both lines go and nothing replaces them. The head reads "THE MODEL, 2 OF 3"
 * and the back button says "back", which is what the hint was restating.
 *
 *   D1  THE CARD HINT STAYS, and the pair was decided together rather than as
 *       one deletion. cardHint() is the only thing on screen saying the
 *       premise exists at all, and the resting view has had room since the
 *       menu became one control. Hiding it would buy space that is not scarce
 *       with discoverability that is.
 *
 *   D2  THE i CONTROL CARRIES THE FIVE GESTURES. Nothing on screen has ever
 *       said what down means, and "it says nothing" is the one meaning a
 *       reader cannot reconstruct from what is in front of them. The panel's
 *       wording moved with bead tla-7xql.23 and its reason did not. The
 *       control sits in the step head beside the back button and in the
 *       counts row at rest, which is the same corner of the page in both.
 *       Those two slots are never drawn together, so there is exactly one of
 *       it on screen.
 *
 *       The panel's words are the contract page's own, down to the sentence
 *       about what down covers. Two readings of one gesture is worse than
 *       none, and the reader reaches that page from the menu.
 *
 *   D3  THE HELP IS v.panel's FOURTH VALUE AND NOT AN OVERLAY, and this is
 *       the load-bearing part. gesture() returns early while a panel is open,
 *       and that guard is what stands between an open help screen and an
 *       accidental verdict. Frank reported those on 2026-10-19: "I've now
 *       accidentally sent multiple responses." An overlay would leave the
 *       step rendered underneath and would need a second guard written from
 *       scratch, so a panel is both the cheaper route and the safer one.
 *
 *       chromeAt() NEEDED NO CHANGE FOR IT, which reads like an omission and
 *       is not one. The function never asks which panel is open, only whether
 *       one is, so the fourth value was answered the day the third landed.
 *       render()'s dispatch is the half that does need its own branch, and
 *       WITHOUT ONE IT FALLS THROUGH to chrome.card, which is false at depth,
 *       and draws the step instead of the help. The gate holds render() to
 *       having a branch for every value the code can set, rather than to
 *       having one for this value, because a fifth would arrive the same way.
 *
 *   D4  THE ICON IS TRANSLUCENT AND THE PANEL IS NOT. Frank offered the
 *       translucency and it is right for a control that sits in a corner over
 *       content and costs no layout. It is wrong for the panel: a translucent
 *       panel over a model is monospace over monospace, and a reader
 *       comparing a step against a claim is who can least afford it. You are
 *       reading one or the other and never both.
 *
 * ========================================================================
 * THE DECLINE IS PER AXIS, AND THE WHOLE BOX IS DEAD
 * ========================================================================
 *
 * Bead tla-7xql.21, and it is the third wrong-verdict defect in this rung.
 * Frank, on his own phone on 2026-10-19: "Scrolling up and down in the model
 * is being read as a navigation swipe." Down files "not a claim", so the
 * reader was writing answers he never gave.
 *
 * Two things were wrong and both had to go.
 *
 *   P1  THE PARTS THAT LOOK LIKE THE MODEL ARE NOT THE SCROLLER. The model's
 *       name row, the gaps inside its box and its bottom padding all sit
 *       outside .swipe-screen-body, so a region test on the body could never
 *       reach them. Central read 220 of 730 pixels taking a gesture with the
 *       model step open, and 143 of those sat on or around the model box. The
 *       whole box is dead now, whatever the thumb does.
 *
 *   P2  THE CAPACITY TEST WAS WHOLE-BOX, so either axis overflowing killed
 *       both. The flaw was never that it used capacity. It was that it asked
 *       the question of the box instead of the axis, which both takes
 *       gestures that were safe and misses the case Frank hit: a body that
 *       scrolls down while it fits sideways. 2:Contention is that model, and
 *       at 730 a vertical drag in it scrolled the premise and answered the
 *       item in one stroke.
 *
 * So a SWIPE is judged by capacity on the one axis it travelled. That keeps
 * what made the original safe and drops what made it wrong.
 *
 * AND A TAP IS JUDGED BY WHETHER THE SCROLLER MOVED, which is the other half
 * and took two wrong turns to find. The split is the point rather than a
 * hedge: each rule is right for the stroke it judges and wrong for the other.
 *
 * A swipe cannot use the position, because the browser may legitimately have
 * hit a limit. At the bottom of 1:Shelves a further drag down moves nothing,
 * so a delta reads zero and files "not a claim", which is the reported defect
 * by another route.
 *
 * A tap cannot use the capacity, because a tap is spelled "both deltas under
 * SWIPE_THRESHOLD" and that is 55 pixels, while a deliberate small scroll of
 * the model is 30 or 40. So a short flick reads as a tap. Judge it by capacity
 * and it files, and the reader scrolls two lines and is thrown out of the
 * model. A tap has no limit case to worry about: if it moved the box it was a
 * drag, and if it did not it was a tap.
 *
 * ONE VIEWPORT HEIGHT WAS NEVER A MEASUREMENT OF A PHONE, and that is the
 * part worth carrying past this bead. Every figure in the three beads above
 * was read at an innerHeight of 844. A phone showing its URL bar gives 730,
 * which is what Frank was holding. At 844 one model screen scrolls vertically
 * and nothing conflicts. At 730 four do.
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

  /* THE CLASS THAT GIVES THE READER THE VIEWPORT, bead tla-7xql.16. The
     stylesheet hangs the whole no-scroll layout off it: the document stops
     scrolling and stops overscrolling, the theme's chrome goes, and the reader
     is fixed to 100dvh. See applyViewport() for why it is applied from here
     rather than from a page template, and for why taking it off again is the
     half that matters. */
  var VIEWPORT_CLASS = "swipe-owns-viewport";

  /* What forget asks before it writes anything. The record is a file, so the
     question names the file: a reader whose browser is ahead of SWIPE.tsv
     should export first and there is no way for this page to know. */
  var FORGET_PROMPT =
    "Forget every answer this browser holds? The record is " +
    "~/tla-practice/swipe/SWIPE.tsv, so export first if this browser is " +
    "ahead of it. There is no undo here.";

  var SWIPES = ["right", "left", "down"];

  /* THE BUTTON TEXT, and the left column of the help panel's table. One word
     each, because that is what a third of the dock's width holds. */
  var LABELS = {
    right: "true",
    left: "false",
    down: "nothing"
  };

  /* THE SAME THREE ANSWERS AS CLAUSES, bead tla-7xql.23. A button is a noun
     and a verdict is a sentence, so one map cannot do both jobs: "It is "
     plus a down label that reads "says nothing" gives "It is says nothing".

     DOWN NOW SAYS WHAT IT ASSERTS INSTEAD OF NAMING A CATEGORY. It read "not
     a claim" until 2026-10-20. On L0-T1-14, whose claim is
     Cardinality({1, 2, 3}) = 4 => Cardinality({}) = 1, the frame then read
     "You said true. It is not a claim." over a correction arguing the line
     holds. Frank, from his phone: "this feels flawed, while it is vacuously
     true, it is still a true assertion. (and all the elephants in my pocket
     are pink)" He is right. A vacuously true line is true, and it still says
     nothing, so the second half is the part that holds for all four kinds
     under down. swipe/README.md carries the ruling and what it cost. */
  var VERDICT = {
    right: "it is true",
    left: "it is false",
    down: "it says nothing"
  };

  /* THE ENGLISH NAME OF EACH RUNG, which is TLA+'s own level calculus. A
     level 0 claim is constant, a level 1 claim is about a state and a level 2
     claim is about a step, so the tag teaches the vocabulary the project
     exists to make automatic rather than inventing a second one. "level 1"
     teaches nothing. Level 3 is temporal and this corpus has no rung for it,
     so a level with no name here shows as itself. */
  var TAGS = {
    0: "constant",
    1: "state",
    2: "action"
  };

  /* What each step of the stack is called where the reader can see it. The pin
     step takes its name from the item, since level 1 pins a state and level 2
     pins a step, so stepLabel() rather than a fourth entry here. */
  var STEP_NAMES = {
    screen: "the model",
    explain: "the last one you got wrong"
  };

  /* What the ask tag means, per rung. A tag with no entry is shown as itself,
     which is what a new question kind does until somebody writes its line.

     NOT ONE OF THEM IS YES/NO SHAPED, bead tla-7xql.23, and this is the half
     of the same defect a screenshot cannot show. Three answers sit under the
     ask and a yes/no question takes two, so "does this hold" is a question
     the honest answer may not fit. A noun phrase takes all three.

     THEY ARE ALSO SHORTER THAN THE QUESTION FORMS, which the dock cares
     about: the ask shares its line with the level tag, and every pixel here
     is a pixel of premise the reader does not get. */
  var PROMPTS = {
    holds: "what this line says",
    implies: "what this implication says",
    enabled: "what this says about firing here",
    terminal: "what this says about stopping here",
    step: "what this says across the step",
    always: "what this says all the way"
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

  /* Returns whether the key is gone, which is not the same as whether it was
     there. A browser that refuses to store also refuses to remove, and the
     caller has to say so on the page rather than claim a record was cleared
     when it was not. */
  function dropKey(key) {
    try {
      window.localStorage.removeItem(key);
      return true;
    } catch (e) {
      return false;
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

  /* THE STATE A FORGET LEAVES BEHIND, and it returns the state it was GIVEN
     when the reader declines. That identity is the contract rather than a
     shortcut: doForget() drops the keys only when it gets a different object
     back, so the decline path cannot reach a write at all. Frank asked for a
     forget that writes nothing if he says no, and this is what makes that
     checkable without a browser.

     storable carries over rather than being assumed true. A browser that will
     not store will not remove either, and the page has to be able to say the
     record is still there. */
  function forgetState(state, confirmed) {
    if (!confirmed) {
      return state;
    }
    return {
      version: STATE_VERSION,
      log: [],
      storable: state ? state.storable : true
    };
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
  /* The stack                                                           */
  /*                                                                     */
  /* These four are pure and they are the whole rule, so                  */
  /* harness/test-swipe-reader.sh drives them through module.exports      */
  /* rather than grepping the file for a shape. Depth 0 is the resting    */
  /* card and depth k is step k of stepsFor(), so a depth is only ever    */
  /* read against the step list it was produced from.                     */
  /* ------------------------------------------------------------------ */

  /* The pin, as the blocks a renderer draws, in reading order. The labels are
     the renderers' own, from swipe/level1/render.sh and swipe/level2/render.sh,
     so a reader who has seen a terminal render sees the same words here.

     A BLOCK WITH NO ROWS IS LEFT OUT, which is what lets stepsFor() ask
     whether an item has a pin at all without knowing its level. 18 of the 48
     level 2 items carry no bind list, so that case is live rather than
     theoretical. */
  function pinBlocks(item) {
    var out = [];
    if (!item) {
      return out;
    }
    if (item.pin && item.pin.length > 0) {
      out.push({ label: "pinned at", rows: item.pin });
      return out;
    }
    if (item.pre && item.pre.length > 0) {
      out.push({ label: "from", rows: item.pre });
    }
    if (item.post && item.post.length > 0) {
      out.push({ label: "steps to", rows: item.post });
    }
    if (item.binds && item.binds.length > 0) {
      out.push({ label: "where", rows: item.binds });
    }
    return out;
  }

  /* The steps above the resting card, nearest first.

     BUILT FROM WHAT THE ITEM CARRIES, not from its level. A level 0 item has
     neither a pin nor a model, so its stack is one step deep and the rung is
     unchanged by all of this. An item that named a model but shipped no pin
     would skip the pin step rather than draw an empty panel. That last case is
     defensive rather than observed: every one of the 192 shipped level 1 and
     level 2 items names a model and carries a pin, and SCREENS.tsv holds no
     EMPTY row, so nothing in the corpus today takes the short list.

     THE LAST STEP IS ALWAYS THE EXPLANATION, and it is the one step that is
     not about the current item. So the list has it even with no item in hand,
     which is what keeps the review reachable from the done screen. */
  function stepsFor(item) {
    var out = [];
    if (item) {
      if (pinBlocks(item).length > 0) {
        out.push("pin");
      }
      if (item.model) {
        out.push("screen");
      }
    }
    out.push("explain");
    return out;
  }

  /* Where one gesture leaves the stack. Up goes a step deeper and stops at the
     top, tap comes a step back and stops at rest, and the three answers never
     move it. A gesture that cannot move returns the depth it was given, so a
     caller compares rather than branching on the direction twice. */
  function depthAfter(dir, depth, steps) {
    var n = steps.length;
    if (dir === "up") {
      return depth >= n ? n : depth + 1;
    }
    if (dir === "tap") {
      return depth <= 0 ? 0 : depth - 1;
    }
    return depth;
  }

  /* Whether the three answers mean anything at this depth. They do wherever
     the reader is still looking at the item the dock is asking about, which is
     the resting card and every step but the last. */
  function answersLive(depth, steps) {
    if (depth <= 0) {
      return true;
    }
    if (depth > steps.length) {
      return false;
    }
    return steps[depth - 1] !== "explain";
  }

  /* What a step is called on screen. The pin step is named by the item,
     because level 1 pins a state and level 2 pins a step, and those are
     different things to go and read. */
  function stepLabel(kind, item) {
    if (STEP_NAMES[kind]) {
      return STEP_NAMES[kind];
    }
    return (item && item.pre) ? "the step" : "the pinned state";
  }

  /* The one line on the resting card that says the premise is up there. It
     names the FIRST step, read off the same list the gesture walks, so it
     cannot promise a step the item does not have. At level 0 that is today's
     line unchanged, which is the right answer rather than a coincidence: the
     explanation is still all that rung has above the card.

     IT IS THE RESTING VIEW'S LINE AND ONLY THE RESTING VIEW'S. At the model
     step it used to read "up for the pinned state" with the pinned state one
     step BELOW, which was the third defect bead tla-7xql.18 closed. The card
     is not drawn at depth now, so the line cannot be reached from a step, and
     renderStep() writes its own. */
  function cardHint(item) {
    return "up for " + stepLabel(stepsFor(item)[0], item);
  }

  /* WHICH CHROME A STATE DRAWS, bead tla-7xql.18. D1 of that bead is that a
     step is the whole page: at depth the counts, the card and the menu are not
     drawn and the step gets 824 of the 844 rather than 276.

     THIS IS A FUNCTION AND NOT THREE CONDITIONS INSIDE render(), because what
     has to be true is a table over every state the reader can be in and no
     pattern over render()'s source can see a table. The gate drives all 30
     combinations of depth, panel and flash through here.

     The three slots are the three things render() appends around whatever the
     middle of the view is: the counts row, the resting view's own box, and the
     menu. `card` is the resting box rather than the card element, since the
     done screen stands in the same slot when the pool is empty.

     Many of the 30 are unreachable through the reader today, and the reason
     is worth more than the count: answer() returns early on an open panel and
     closes the stack before it sets the flash, so no panel can be open with a
     flash up. The function is total anyway, so a later bead that makes one of
     them reachable finds it already answered.

     IT NEEDED NO CHANGE FOR THE FOURTH PANEL VALUE, bead tla-7xql.20. It
     never asks WHICH panel is open, only whether one is, so the help was
     answered the day the menu landed. render()'s dispatch is the half a new
     value does need work in. */
  function chromeAt(depth, panel, flash) {
    var open = Boolean(panel) || Boolean(flash);
    var stepped = !open && depth > 0;
    return {
      status: !stepped,
      card: !open && depth <= 0,
      /* The menu panel IS the menu, so drawing the resting control beside it
         would put two ways into one thing on one screen. Every other panel
         keeps the control, which is how a reader leaves stats for export. */
      controls: !stepped && panel !== "menu"
    };
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

  /* A VERDICT CLAUSE AT THE HEAD OF A SENTENCE. VERDICT holds clauses, so the
     sites that open a sentence with one have to raise the first letter. */
  function upperFirst(s) {
    return s.charAt(0).toUpperCase() + s.slice(1);
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

    var steps = stepsFor(v.current);
    if (v.depth > steps.length) {
      /* Reachable when the item changed under an open stack, which the menu
         and the import both do. Clamped rather than reset, so a reader deep
         in the explanation stays there. Clamped BEFORE the chrome is decided,
         because a depth past the top is not a step and must not take the
         card away. */
      v.depth = steps.length;
    }

    /* WHAT THIS STATE DRAWS AROUND THE MIDDLE OF THE VIEW. One call, so the
       rule is chromeAt()'s and the gate can drive it. See D1 in the header. */
    var chrome = chromeAt(v.depth, v.panel, v.flash);

    if (chrome.status) {
      v.root.appendChild(renderStatus());
    }

    if (v.panel === "stats") {
      v.root.appendChild(renderStats());
    } else if (v.panel === "message") {
      v.root.appendChild(renderMessage());
    } else if (v.panel === "menu") {
      v.root.appendChild(renderMenu());
    } else if (v.panel === "help") {
      /* A BRANCH OF ITS OWN, bead tla-7xql.20, and leaving it out is the
         defect rather than an omission: the chain would fall through to
         chrome.card, which is false at depth, and draw the step instead of
         the help. */
      v.root.appendChild(renderHelp());
    } else if (v.flash) {
      v.root.appendChild(renderFlash());
    } else if (chrome.card) {
      /* The resting view, which is the question or the done screen. They stand
         in one slot because they are the same slot: whichever is drawn, it is
         what the reader is looking at with no step open. */
      v.root.appendChild(v.current ? renderCard() : renderDone());
    } else {
      /* THE STEP IS THE WHOLE PAGE. Nothing else is appended in this branch,
         so the step is the only child of #swipe-app and the flex rule that
         made it the one shrinkable thing now hands it everything. */
      v.root.appendChild(renderStep(steps));
    }

    if (chrome.controls) {
      v.root.appendChild(renderControls());
    }
  }

  function renderStatus() {
    var v = view;
    var box = el("div", "swipe-status");
    var answered = Object.keys(answeredIds(v.state.log)).length;
    var remaining = v.items.length - answered;

    if (v.state.log.length === 0) {
      box.appendChild(el("p", "swipe-status-empty",
        "No record in this browser. The record lives in SWIPE.tsv, so import " +
        "one from the menu to pick up where you left off, or just start."));
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

    /* THE HELP CONTROL'S RESTING CORNER, bead tla-7xql.20. The counts row is
       drawn in every state that is not a step, so the control is here for all
       of them and in the step head for the rest. The row exists only to put
       the two at opposite ends of one line, which is why the counts keep their
       own element and their own type. */
    var row = el("div", "swipe-counts-row");
    row.appendChild(line);
    row.appendChild(helpControl());
    box.appendChild(row);
    return box;
  }

  /* ------------------------------------------------------------------ */
  /* The model screen                                                    */
  /*                                                                     */
  /* Returns null for a level 0 item, which has no model.                 */
  /*                                                                     */
  /* THE HEAD IS A LABEL AND NOT A CONTROL, since bead tla-7xql.19. It    */
  /* used to be a button that collapsed the body and remembered that per  */
  /* bucket for the visit, which earned its place while the model shared  */
  /* the resting view with the card and the reader wanted the viewport    */
  /* back for the stream. The step IS the model now, so collapsing it     */
  /* left the step with a head and nothing under it, and that is very     */
  /* likely what Frank was looking at when he reported that the model was */
  /* not showing.                                                        */
  /*                                                                     */
  /* THE NAME STAYS, because it is the only label on screen that says     */
  /* which model is being read. harness/swipe/stemblind.sh withholds the  */
  /* module name from a judge for exactly the reason a reader has to be   */
  /* shown it.                                                           */
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
    var box = el("div", "swipe-screen");
    box.setAttribute("data-swipe-screen", "1");

    var head = el("div", "swipe-screen-head");
    head.appendChild(el("span", "swipe-screen-name", item.model));
    box.appendChild(head);

    /* At renderScreen()'s own statement level, which is the point rather than
       the formatting. No state of the reader can withhold the model from a
       step whose whole subject is that model. */
    box.appendChild(el("pre", "swipe-screen-body", text));
    return box;
  }

  /* The pin, which is the question's subject. Level 1 pins one state and
     level 2 pins a step, so one rung draws one block and the other draws two
     or three. pinBlocks() decides which, and it is the same reading stepsFor()
     uses to know whether the item has a pin step at all. */
  function renderPin(item) {
    var box = el("div", "swipe-pin");
    var blocks = pinBlocks(item);
    for (var i = 0; i < blocks.length; i++) {
      box.appendChild(pinBlock(blocks[i].label, blocks[i].rows));
    }
    return box;
  }

  function pinBlock(label, rows) {
    var g = el("div", "swipe-pin-group");
    g.appendChild(el("p", "swipe-pin-label", label));
    g.appendChild(el("pre", "swipe-pin-body", (rows || []).join("\n")));
    return g;
  }

  /* ONE STEP OF THE STACK, WHICH SINCE BEAD tla-7xql.18 IS THE WHOLE PAGE.
     Nothing else is drawn at depth, so this is the only child of #swipe-app
     and it gets 824 of the 844 rather than the 276 it had while the counts,
     the card and the menu took their own height first.

     Every step carries its own back button and it is not decoration:
     touchstart declines a touch that starts inside a .swipe-screen-body that
     is scrolling sideways, so there is no tap surface over a wide model, and
     a wide model is most of the page now. Tap anywhere is the convenience and
     the button is the guarantee.

     THE BODY IS THE ONE THING HERE THAT GIVES UP ROOM. The head takes its own
     height and the body takes the rest, which is the same rule #swipe-app
     follows one level up and the reason that rule cost the model 66 pixels
     when the chrome was still in the way.

     THERE IS NO HINT UNDER THE BODY SINCE BEAD tla-7xql.20. It read "up for
     the model, tap to come back", and scrollerDeclining() refuses a touch
     over 22 of the 24 published screens, so most of the view would not take
     the tap it offered. The head's own "2 of 3" and the back button were
     already saying the rest of it. The gesture table moved to the i control
     beside the back button, which is where down finally gets explained.

     THE CLAIM IS NOT HERE, AND IT WAS FOR ONE AFTERNOON. Decision D2 of bead
     tla-7xql.18 put one line of it at the foot, so that a reader checking a
     claim against a step in front of them was not holding it in their head.
     Frank reversed that the same day, bead tla-7xql.19, after reading a model
     on his phone: "I think we will be better off having to flick back and
     forth for the problem." To re-read the claim you tap back to the question
     and swipe up again.

     The argument for keeping it was never refuted. It lost to a measurement
     nobody had taken yet. The claim cost the model body 133.9 of its 613.9
     pixels, and four of the 24 published screens went from overflowing to
     fitting the moment it left. answersLive() is untouched by this: it still
     governs the answer buttons, and it had three other callers all along. */
  function renderStep(steps) {
    var v = view;
    var kind = steps[v.depth - 1];
    var box = el("div", "swipe-step swipe-step-" + kind);
    box.setAttribute("data-swipe-step", kind);

    /* The head says which step this is and how many there are, so the reader
       knows there is more above without having to swipe and find out. */
    var head = el("div", "swipe-step-head");
    head.appendChild(el("span", "swipe-step-where",
      stepLabel(kind, v.current) + ", " + v.depth + " of " + steps.length));
    var back = el("button", "swipe-btn swipe-step-back", "back");
    back.type = "button";
    back.addEventListener("click", function () {
      v.depth = v.depth - 1;
      render();
    });
    head.appendChild(back);
    /* THE SAME CORNER AS THE COUNTS ROW, which is the one the counts row is
       not drawn in. See D2 of bead tla-7xql.20. */
    head.appendChild(helpControl());
    box.appendChild(head);

    var body = el("div", "swipe-step-body");
    body.setAttribute("data-swipe-step-body", "1");
    if (kind === "pin") {
      body.appendChild(renderPin(v.current));
    } else if (kind === "screen") {
      var screen = renderScreen(v.current);
      if (screen) {
        body.appendChild(screen);
      }
    } else {
      body.appendChild(renderExplain());
    }
    box.appendChild(body);
    return box;
  }

  /* THE CARD IS THE DOCK, and it writes the level tag, the ask, the claim and
     the three answer buttons and nothing else. No item id, for the reason in
     this file's header, and no template name either: the claim already says
     what family it is in and the tag is the only label decision D5 asks for.

     NEITHER THE PIN NOR THE MODEL IS IN HERE, and since tla-7xql.15 neither
     is anywhere else in the resting view. They are premise and they are steps
     of the stack. That is what makes the resting view fit at every level by
     construction rather than by arithmetic. */
  function renderCard() {
    var v = view;
    var item = v.current;
    var card = el("div", "swipe-card");
    card.setAttribute("data-swipe-card", "1");

    /* THE TAG SITS BESIDE THE ASK rather than on a line of its own, so the
       rung is on screen before the reader answers and the dock is no taller
       for it. Every pixel here is a pixel of premise the reader does not get. */
    var ask = el("p", "swipe-ask");
    ask.appendChild(el("span", "swipe-tag", TAGS[item.level] || ("level " + item.level)));
    ask.appendChild(el("span", "swipe-ask-text", PROMPTS[item.ask] || item.ask));
    card.appendChild(ask);

    card.appendChild(el("pre", "swipe-claim", item.claim));

    var answers = el("div", "swipe-answers");
    for (var i = 0; i < SWIPES.length; i++) {
      answers.appendChild(answerButton(SWIPES[i]));
    }
    card.appendChild(answers);

    /* One line, and short. It names the first step of this item's own stack,
       so it stops saying "the last one you got wrong" at a rung where up 1 is
       the state. The hint is how a reader learns the premise is up there at
       all, which makes it the opposite of decoration here. */
    card.appendChild(el("p", "swipe-hint", cardHint(item)));
    return card;
  }

  function renderFlash() {
    var v = view;
    var box = el("div", "swipe-flash swipe-flash-" + v.flash.verdict);
    box.setAttribute("data-swipe-flash", "1");

    /* THE BUTTON WORD FOR WHAT THE READER DID AND THE CLAUSE FOR WHAT THE
       ITEM IS, bead tla-7xql.23. "You said true" names the button they
       pressed, and the half after it has to assert rather than label, or a
       vacuous item gets told it is not a claim while its own correction
       argues that it holds. */
    box.appendChild(el("p", "swipe-verdict",
      v.flash.verdict === "hit"
        ? "Right. " + upperFirst(VERDICT[v.flash.item.swipe]) + "."
        : "No. You said " + LABELS[v.flash.given] + " and " +
          VERDICT[v.flash.item.swipe] + "."));
    /* THE PIN GOES WITH THE CORRECTION at the pinned rungs. A level 1
       correction reads "the open count is 1, so Pop's first conjunct holds",
       and that sentence is unreadable without the state it is about. The
       model screen does NOT come along: it is 29 lines at worst and the
       flash is the feedback L2 measured, so it gets the screen to itself. */
    if (pinBlocks(v.flash.item).length > 0) {
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

  /* Decision D4: the top of the stack carries the explanation of the last
     WRONG answer, held until the next wrong one. The explanation a wrong
     answer has is its flash, which is field 11. At the pinned rungs the pin
     goes with it, since a claim without its pin says nothing.

     THE CONTENT IS WHAT THE REVIEW PANEL ALWAYS SHOWED. Only its frame moved:
     renderStep() owns the head and the back button now, because every step
     carries one and a step that brought its own would carry two. */
  function renderExplain() {
    var v = view;
    var box = el("div", "swipe-review");
    if (!v.lastMiss) {
      box.appendChild(el("p", "swipe-hint",
        "Nothing to review yet. This holds the last answer you got wrong."));
      return box;
    }
    var item = v.lastMiss.item;
    /* THE LINE FRANK PHOTOGRAPHED, and the reason bead tla-7xql.23 exists.
       Same split as the flash: the button word for the answer given, the
       VERDICT clause for the item. */
    box.appendChild(el("p", "swipe-verdict",
      "You said " + LABELS[v.lastMiss.given] + ". " +
      upperFirst(VERDICT[item.swipe]) + "."));
    if (pinBlocks(item).length > 0) {
      box.appendChild(el("p", "swipe-hint", item.model));
      box.appendChild(renderPin(item));
    }
    box.appendChild(el("pre", "swipe-claim", item.claim));
    box.appendChild(el("p", "swipe-correction", item.flash));
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
        "The review queue is empty. Switch back to the main stream from the menu."));
    } else if (v.level !== null) {
      box.appendChild(el("p", "swipe-verdict", "Level " + v.level + " is done."));
      box.appendChild(el("p", null,
        "Switch to all levels from the menu, or export the record."));
    } else {
      box.appendChild(el("p", "swipe-verdict", "That is all " + v.items.length + "."));
      box.appendChild(el("p", null,
        "Export the record, then run the review queue over whatever is still " +
        "standing wrong."));
    }
    return box;
  }

  /* THE RESTING VIEW GETS ONE CONTROL, bead tla-7xql.18. Eight of them were
     three rows of buttons at 390 pixels wide, measured at 172 of the 844, and
     every one is touched once a session against the stream the reader touches
     on every item. So the eight go behind this one and the resting view gets
     120 pixels back.

     IT IS v.panel's THIRD VALUE rather than a new mechanism. That is what
     makes a swipe with the menu open get declined and a tap close it: both
     rules are already written for stats and the messages, and gesture() reads
     v.panel rather than naming a panel.

     The three answer buttons are not in here. They live in the dock with the
     claim, so they cannot be scrolled away from the question they answer. */
  function renderControls() {
    var v = view;
    var box = el("div", "swipe-controls");
    var bar = el("div", "swipe-menu");
    bar.appendChild(menuButton("menu", function () {
      v.panel = "menu";
      render();
    }));
    box.appendChild(bar);
    return box;
  }

  /* THE MENU ITSELF, which is everything that is not an answer. A panel like
     stats and the messages, with its own back button, because that is the
     pattern this reader already has and a second one would be a second set of
     rules about what a swipe means while it is open. */
  function renderMenu() {
    var v = view;
    var box = el("div", "swipe-menu-panel");

    var menu = el("div", "swipe-menu");

    /* STRAIGHT TO THE TOP OF THE STACK, which is where the explanation lives.
       It is the same step a reader reaches by swiping up through the premise,
       so the button is a shortcut rather than a second route. */
    menu.appendChild(menuButton("review", function () {
      v.panel = null;
      v.message = null;
      v.depth = stepsFor(v.current).length;
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
        v.depth = 0;
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
        v.depth = 0;
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

    /* THE CONTRACT IS A PAGE OF ITS OWN SINCE tla-7xql.16, so the menu is the
       route to it. With no Material header on this page there is no nav, which
       makes this link the only one. The URL comes off the root element the way
       data-items already does, so scripts/build-docs.sh owns where the page
       lives and this file does not write a path. No attribute, no button. */
    if (v.contract) {
      menu.appendChild(menuLink("the contract", v.contract));
    }

    /* LAST, BECAUSE IT IS THE ONE THAT DESTROYS SOMETHING. */
    menu.appendChild(menuButton("forget", doForget));

    box.appendChild(menu);

    /* The way out, the same one stats and the messages draw. Tap anywhere also
       closes a panel, through gesture(), and the button is the guarantee for
       the same reason every step carries one. */
    var back = el("button", "swipe-btn", "back");
    back.type = "button";
    back.addEventListener("click", function () {
      v.panel = null;
      render();
    });
    box.appendChild(back);
    return box;
  }

  /* THE GESTURE TABLE AS A PANEL, bead tla-7xql.20. Five gestures, and before
     this the reader was told what down means on the contract page and nowhere
     the thumb could reach.

     THE THREE ANSWERS COME OFF SWIPES AND LABELS rather than being written out
     again. Those two are what gesture() dispatches on and what the dock prints,
     so a table typed a second time here would be a second account of one
     gesture, and the account that goes stale is the one nobody runs.

     THE WORDS FOR DOWN ARE THE CONTRACT PAGE'S, in scripts/build-docs.sh. A
     reader who meets two accounts of a gesture has to work out which one is
     current, so there is one account standing in two places.

     A PANEL AND NOT AN OVERLAY. See D3 in this file's header: gesture()
     declines everything but tap while v.panel is set, so this screen cannot
     be swiped through into a verdict. The last paragraph says so out loud,
     because a reader who has already filed verdicts by accident has no reason
     to believe a help screen is safe to read. */
  function renderHelp() {
    var v = view;
    var box = el("div", "swipe-help-panel");
    box.appendChild(el("p", "swipe-verdict", "What the gestures do"));

    var rows = el("div", "swipe-help-rows");
    var i;
    /* THE ROWS READ VERDICT RATHER THAN LABELS, bead tla-7xql.23. This table
       says what each gesture asserts, and a one-word button label beside
       "one step deeper into the premise" was naming the answer instead. */
    for (i = 0; i < SWIPES.length; i++) {
      helpRow(rows, "swipe " + SWIPES[i], VERDICT[SWIPES[i]]);
    }
    helpRow(rows, "swipe up", "one step deeper into the premise");
    helpRow(rows, "tap", "one step back out");
    box.appendChild(rows);

    box.appendChild(el("p", null,
      "Down covers four shapes of line. It can fail to parse, it can fail " +
      "to mean anything, it can be about the wrong rung for the question, " +
      "or it can hold for a reason that leaves it empty. A vacuously true " +
      "line is true and it still says nothing. That is why the ask is what " +
      "the line says rather than whether it holds."));

    box.appendChild(el("p", null,
      "Nothing in here answers an item. A swipe does nothing while a panel is " +
      "open, so this is a safe place to stop and read. Tap anywhere, or use " +
      "the button, and you are back on the step you were on."));

    var back = el("button", "swipe-btn", "back");
    back.type = "button";
    back.addEventListener("click", function () {
      v.panel = null;
      render();
    });
    box.appendChild(back);
    return box;
  }

  /* ONE ROW OF THE TABLE, APPENDED RATHER THAN RETURNED. The table is a
     two-column grid and the two cells are its direct children, so there is no
     row element to hand back. That is the whole reason for the grid: the
     meanings line up down the panel without this file guessing how wide
     "SWIPE RIGHT" renders, and a width guessed in a stylesheet is what cost
     the model 66 pixels two beads ago. */
  function helpRow(rows, move, means) {
    rows.appendChild(el("span", "swipe-help-move", move));
    rows.appendChild(el("span", "swipe-help-means", means));
  }

  /* THE DOCK GOES DEAD AT THE LAST STEP AND NOWHERE ELSE. stats and the
     message panels change the subject, and so does the explanation step,
     which is about the last item answered wrong rather than the one in the
     dock. Steps 1 and 2 are the SAME item, so an answer there is an answer to
     the question on screen and the buttons stay live. Before tla-7xql.15 this
     read `view.panel !== null`, which was right for the panels and had no
     opinion about a stack that did not exist yet. */
  function answerButton(swipe) {
    var b = el("button", "swipe-btn swipe-answer swipe-answer-" + swipe, LABELS[swipe]);
    b.type = "button";
    b.disabled = !view.current || view.panel !== null ||
      !answersLive(view.depth, stepsFor(view.current));
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

  /* THE WAY INTO THE GESTURE TABLE, bead tla-7xql.20. One control, drawn in
     the counts row at rest and in the step head at depth, which is the same
     corner of the page in both.

     IT OPENS A PANEL AND NOT AN OVERLAY. gesture() returns early while
     v.panel is set, so this inherits the decline that stands between an open
     help screen and an accidental verdict. It touches v.depth nowhere, which
     is what leaves the reader on the step they were reading.

     A BUTTON, SO isControl() DECLINES THE TAP. Without that a tap here would
     open the help and step the stack back in one motion. The label is a
     letter rather than a glyph, because the type here is the theme's and a
     glyph font is one more thing that can fail to load. */
  function helpControl() {
    var v = view;
    var b = el("button", "swipe-help", "i");
    b.type = "button";
    b.setAttribute("aria-label", "what the gestures do");
    b.addEventListener("click", function () {
      v.panel = "help";
      render();
    });
    return b;
  }

  /* An anchor rather than a button that navigates, because leaving the page is
     what a link is for and the browser's own affordances come free with it.
     isControl() names the anchor for that reason: a tap on it must not step
     the stack back on the way out. */
  function menuLink(text, href) {
    var a = el("a", "swipe-btn swipe-link", text);
    a.href = href;
    return a;
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
    /* The same rule the buttons are disabled by, enforced again here because a
       keyboard reaches answer() without passing a button. */
    if (!answersLive(v.depth, stepsFor(v.current))) {
      return;
    }
    var item = v.current;
    var verdict = swipe === item.swipe ? "hit" : "miss";
    v.state.log.push({ i: item.id, t: nowStamp(), s: swipe, v: verdict });
    saveState(v.state);
    if (verdict === "miss") {
      v.lastMiss = { item: item, given: swipe };
    }
    /* The flash owns the screen, so the stack closes under it rather than
       being held open over a different item. */
    v.depth = 0;
    v.flash = { item: item, given: swipe, verdict: verdict };
    render();
  }

  function advance() {
    view.flash = null;
    view.depth = 0;
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
      v.depth = 0;
      rebuildLastMiss();
      nextItem();
      render();
    };
    reader.readAsText(file);
  }

  /* ------------------------------------------------------------------ */
  /* Forget                                                             */
  /*                                                                    */
  /* Decision D5 of bead tla-7xql.16. There was no reset path at all:    */
  /* the record lives under one localStorage key and clearing site data   */
  /* was the only route, which takes the theme preference with it. Frank  */
  /* needed one on 2026-10-19 and had to clear the lot.                  */
  /* ------------------------------------------------------------------ */

  function doForget() {
    var v = view;

    /* THE QUESTION COMES FIRST AND NOTHING IS WRITTEN BEFORE IT ANSWERS. A
       browser with no confirm at all counts as a decline, which is the safe
       direction: the alternative is clearing a record nobody agreed to
       clear. */
    var confirmed = typeof window.confirm === "function" &&
      window.confirm(FORGET_PROMPT) === true;
    var next = forgetState(v.state, confirmed);
    if (next === v.state) {
      return;
    }

    /* BOTH KEYS, because loadState() still reads the level 0 one and migrates
       it. Leaving that behind would have the next visit resume from a record
       the reader just asked to be rid of. */
    var dropped = dropKey(STORAGE_KEY);
    var droppedLegacy = dropKey(LEGACY_STORAGE_KEY);
    next.storable = next.storable && dropped && droppedLegacy;
    v.state = next;

    v.flash = null;
    v.bucket = null;
    v.depth = 0;
    rebuildLastMiss();
    nextItem();
    v.panel = "message";
    v.message = {
      kind: "info",
      title: "Forgotten.",
      body: [
        next.storable
          ? "This browser holds no answers now. Import your SWIPE.tsv to come back."
          : "This browser would not let the page remove its record, so it may " +
            "still be there after a reload."
      ]
    };
    render();
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

  /* A tap on one of these is the control's own business and must not also move
     the stack. Without it a tap on "true" at depth 1 would answer the item and
     step back out of the premise in the same motion, which is one touch doing
     two unrelated things. */
  function isControl(node) {
    return Boolean(node && node.closest && node.closest("a, button, label, input"));
  }

  /* THE TAIL OF A GESTURE RATHER THAN A PRESS, bead tla-7xql.22.

     One touch produces a touchend AND a synthesized click. The tap is handled
     at touchend, render() runs inside that handler, clear() removes every
     child the touch began on, and the card comes back with .swipe-answers near
     the bottom edge because .swipe-card carries margin-top: auto. Only THEN
     does the browser dispatch the click. It hit-tests the page as it stands
     now and lands on a button that did not exist when the thumb went down.
     SWIPES reads ["right", "left", "down"] over a 3-column grid, so false is
     the middle column, which is where a thumb tapping the lower middle of a
     model screen comes down. Frank filed several of those by hand.

     isControl() cannot catch it, and that is worth saying because it looks
     like the guard for this. It reads the touch's own target, which is the
     model and not a button. A touch sequence keeps one target throughout and
     the synthesized click does not.

     `arm` is the element the touch began on, held only when that touch filed a
     gesture. isConnected IS THE WHOLE TEST, and it buys a rule with no window,
     no timer and no timestamp in it. If the element the thumb came down on is
     still in the page then nothing moved under it and the click is honest,
     whatever else happened. A tap that changes no depth renders nothing, so it
     has to let the click through. */
  function clickIsTail(arm) {
    return Boolean(arm) && arm.isConnected === false;
  }

  /* WHICH SCROLLERS A TOUCH SITS INSIDE, TAKEN WHEN THE TOUCH BEGINS.

     This is the half of the decline that is about WHERE, and bead tla-7xql.21
     split it from the half that is about WHETHER so the pair can be driven
     with no browser. The mark is taken at touchstart because a touch belongs
     to where it began. Whether any of those scrollers takes the stroke is
     asked at touchend, once the gesture has an axis.

     Returns { dead, chain } or null. `dead` names a region that declines
     whatever the thumb does, and `chain` holds one scroller per box the touch
     sits inside, innermost first. The name a scroller answers with is what the
     gate reads, because a table answering only yes or no could not tell a
     decline on the right scroller from one on the wrong scroller.

     EACH ENTRY CARRIES AN ELEMENT AND A POSITION, AND THE POSITION IS NOT
     DEAD WEIGHT. Do not delete it as unused. The two kinds of stroke ask
     different questions of the same scroller, and only one of them is
     answerable from the element alone. A swipe asks what the box CAN scroll,
     which is a size and readable at any time. A tap asks whether the box DID
     scroll, which is a comparison and needs a value from before the stroke.
     scrollerDeclining() picks between them and says why. */
  function scrollerMark(target) {
    if (!target || !target.closest) {
      return null;
    }

    var mark = { dead: null, chain: [] };
    var screenBody = target.closest(".swipe-screen-body");

    /* P1 OF BEAD tla-7xql.21. THE PARTS THAT LOOK LIKE THE MODEL ARE NOT THE
       SCROLLER. The model's own name row, the two gaps inside its box and its
       bottom padding all sit outside .swipe-screen-body, so no region test on
       the body ever reached them. A thumb landing on the name and dragging
       down filed "not a claim".

       Central read the step view in Chrome at 390 wide with an innerHeight of
       730, model step open on 1:Fences. The box runs 93 to 669 and its body
       153 to 653, which leaves the name row, the gap under it and the bottom
       padding live. 220 of those 730 pixels took a gesture and 143 of them sat
       on or around the model box.

       THE DECLINE HERE IS A REGION RULE AND NOT A CAPACITY ONE, which is the
       part worth reading twice. The name row fits its own content, so asking
       it what it can scroll answers "nothing" and files a verdict. It has to
       be dead because of what it LOOKS like, which is the one thing no
       measurement of it can report.

       THE NEGATION IS THE OTHER HALF. Declining .swipe-screen with no
       exception for the part of it that scrolls would go the other way and
       take every gesture over the model away, which is what tla-7xql.15 did
       and what made the back button the only way out. */
    if (!screenBody && target.closest(".swipe-screen")) {
      mark.dead = "screen";
      return mark;
    }

    /* THE MODEL BODY, WHICH IS THE ONE PART OF THE BOX THE BROWSER SCROLLS.
       The widest screen line is 73 characters, which does not fit 390 CSS
       pixels at any readable size, so a wide model scrolls sideways and that
       scroll and a left swipe would be one gesture on one pixel.

       EACH AXIS ON ITS OWN NOW, which supersedes tla-7xql.18's sideways-only
       ruling. That ruling was right about the axis it named and silent about
       the other one, and the other one is what Frank hit. Asking per axis
       needs no ruling at all: the body takes the stroke when it can scroll the
       way the thumb went, and keeps the other axis for the reader. That is
       what D4 of that bead asks for and what a whole-box reading cannot give.

       WHAT THE CORPUS DOES ON EACH AXIS, measured in the same browser pass.
       The body's client width is 318 pixels and the type is 10.825 pixels a
       character, so 29 characters fit across and 22 of the 24 published
       screens are wider than that. Only 2:Contention at 25 and 1:Contention at
       23 fit. On the vertical axis the body is 613.9 at an innerHeight of 844
       and 500 at 730, so one screen runs past it at 844 and four do at 730.

       SO THE THREE CASES A READER MEETS, and the gate drives all three. A body
       that overflows sideways only, which is 22 of 24: a vertical swipe fires
       and a horizontal one is declined. A body that overflows both, which is
       1:Shelves at 730: nothing fires in here and the back button is the way
       out. A body that overflows neither: everything fires.

       THE HORIZONTAL DECLINE IS UNAVOIDABLE RATHER THAN CHOSEN. A left swipe
       and a sideways scroll are one gesture on one pixel, so on a model wider
       than its body the reader would answer "false" every time they read along
       a line. That was tla-7xql.18's ruling and it was right. */
    if (screenBody) {
      mark.chain.push(scrollerAt("screen", screenBody));
    }

    /* R1 OF THE STACK DESIGN, bead tla-7xql.15. A step taller than the room
       scrolls inside itself, and a drag in there has to scroll rather than
       move the stack.

       IT STAYS IN THE CHAIN BEHIND THE MODEL BODY, which is the fall-through
       the rewrite could have lost. The model body can sit still while the step
       under it scrolls, and that stroke is the step's. Stopping at the
       innermost scroller found would let it move the stack as well. */
    var body = target.closest(".swipe-step-body");
    if (body) {
      mark.chain.push(scrollerAt("step", body));
    }

    /* R1 AGAIN, ON THE FLASH, since bead tla-7xql.16. The page no longer
       scrolls, so a correction taller than the flash has nowhere else to be
       read. Measured at 390x844 on 2026-10-19 over EVERY item of each pinned
       rung: 39 of the 48 level 2 corrections run past the flash, by up to 111
       pixels, against 0 of 144 at level 1.

       So the flash allows pan-y and a vertical drag in one tall enough to
       scroll files nothing. Without this the stroke would scroll the correction
       and advance off it at once. A horizontal drag in a flash still fires,
       since the flash has no sideways scroll to take it.

       TAP STILL ADVANCES EVERYWHERE IN HERE, which is what makes declining
       safe: renderFlash() owns a click handler on the box, and the browser
       raises a click after a tap and suppresses it after a scroll. */
    var flash = target.closest(".swipe-flash");
    if (flash) {
      mark.chain.push(scrollerAt("flash", flash));
    }

    return mark;
  }

  /* ONE SCROLLER THE TOUCH SITS INSIDE, WITH WHERE IT STOOD WHEN THE TOUCH
     BEGAN. Both facts are consumed, by different strokes. See the note in
     scrollerMark() and the split in scrollerDeclining(). */
  function scrollerAt(name, el) {
    return { name: name, el: el, top: el.scrollTop, left: el.scrollLeft };
  }

  /* CAN THIS BOX SCROLL ON THIS AXIS. "x" is the sideways axis and anything
     else is read as the vertical one, which keeps the caller honest: an axis
     the caller never set cannot silently mean "neither".

     NO ROUNDING TOLERANCE, AND THE +1 THAT USED TO BE HERE IS GONE. tla-7xql.18
     allowed a box one pixel over its client size, on the grounds that it is a
     subpixel layout artifact rather than a scroll. The two failure directions
     are not symmetric, so the tolerance was buying the wrong one. A box that
     is one pixel over and declined costs the reader a gesture they can see
     fail and repeat. A box that is one pixel over and NOT declined scrolls
     under the thumb while a verdict is filed, which is the silent wrong answer
     this bead exists to close. */
  function overflowsOn(el, axis) {
    if (axis === "x") {
      return el.scrollWidth > el.clientWidth;
    }
    return el.scrollHeight > el.clientHeight;
  }

  /* DID THIS BOX ACTUALLY SCROLL SINCE THE TOUCH BEGAN. Read against the
     position the mark took at touchstart, and used for a TAP and nothing else.
     Why only a tap is the paragraph below. */
  function movedFrom(at) {
    return at.el.scrollTop !== at.top || at.el.scrollLeft !== at.left;
  }

  /* WHETHER THAT TOUCH WAS THE SCROLLER'S RATHER THAN A GESTURE.

     TWO RULES, AND THE STROKE DECIDES WHICH ONE ANSWERS. That is a split
     rather than indecision, so here is the split written down:

       a swipe, which has an axis   CAPACITY on that one axis
       a tap, which has none        whether the position MOVED

     Each rule is right for the stroke it judges and wrong for the other, and
     both halves of that were learned the hard way in this one bead.

     WHY A SWIPE CANNOT USE THE DELTA. The honest question for a directional
     stroke is "could this have been a scroll", because the browser may
     legitimately have hit a limit. At the bottom of 1:Shelves a further drag
     down moves nothing, so a delta reads zero and files "not a claim", which
     is the defect Frank reported reached by another route. Capacity never asks
     whether the browser moved, so it has no limit case.

     WHY A TAP CANNOT USE THE CAPACITY. A tap is spelled "both deltas under
     SWIPE_THRESHOLD", which is 55 pixels, and a deliberate small scroll of the
     model is 30 or 40. So a short flick reads as a tap. Judging it by capacity
     means filing it, and the reader scrolls two lines and gets thrown out of
     the model. Judging it by the delta is exact: a tap has no limit case,
     because if it moved the box it was a drag and if it did not it was a tap.

     A TAP THAT REALLY WAS A TAP STILL FILES, on all 24 screens. tla-7xql.18
     declined every touch over a model that could scroll sideways, which left
     the back button as the only way out of 22 of them. That change stands and
     this only narrows it to taps that moved nothing.

     THE CHAIN IS WALKED INNERMOST FIRST, under either rule. The model body can
     fit on the axis while the step body under it overflows on the same axis,
     and that stroke is the step's. Stopping at the innermost scroller found
     would let it move the stack as well. */
  function scrollerDeclining(mark, axis) {
    if (!mark) {
      return null;
    }
    if (mark.dead) {
      return mark.dead;
    }
    if (!mark.chain) {
      return null;
    }
    var i;
    for (i = 0; i < mark.chain.length; i += 1) {
      var at = mark.chain[i];
      var takesIt = axis ? overflowsOn(at.el, axis) : movedFrom(at);
      if (takesIt) {
        return at.name;
      }
    }
    return null;
  }

  function bindGestures(root) {
    var startX = 0;
    var startY = 0;
    var tracking = false;
    var mark = null;
    /* The element the last gesture-filing touch began on. clickIsTail() reads
       it, and the comment there is the whole of the rule. */
    var arm = null;

    /* THE DECLINE IS NOT DECIDED HERE. touchstart records which scrollers the
       thumb landed in, and touchend asks whether any of them can scroll on the
       axis the gesture turned out to be on. The listeners hold no reading of
       their own, so the table in harness/test-swipe-reader.sh is the whole of
       the rule.

       THE ORDER IS FORCED: the axis has to exist before the decline can be
       asked, so the decline sits AFTER dx and dy are read and before anything
       is filed. A tap reaches scrollerDeclining() with a null axis rather than
       skipping the call, and that null is load-bearing twice over. It is how
       the dead region still declines a tap, and it is how the decline knows to
       judge this stroke by what the scroller DID rather than by what it
       could.

       { passive: true } ON BOTH LISTENERS. Passive means this file cannot
       cancel the browser's scroll, which is correct: the browser should scroll.
       All that is decided here is whether to ALSO fire a gesture. */
    root.addEventListener("touchstart", function (ev) {
      if (ev.touches.length !== 1) {
        tracking = false;
        return;
      }
      mark = scrollerMark(ev.target);
      /* A DELIBERATE PRESS BEGINS WITH A TOUCHSTART, which is what makes the
         ghost-click rule need no timing constant. Clearing the arm here means
         the swallow can only ever reach a click with no touchstart of its own
         between it and the gesture that moved the page. */
      arm = null;
      tracking = true;
      startX = ev.touches[0].clientX;
      startY = ev.touches[0].clientY;
    }, { passive: true });

    root.addEventListener("touchend", function (ev) {
      if (!tracking) {
        return;
      }
      tracking = false;
      var at = mark;
      mark = null;
      var t = ev.changedTouches[0];
      var dx = t.clientX - startX;
      var dy = t.clientY - startY;
      var tap = Math.abs(dx) < SWIPE_THRESHOLD && Math.abs(dy) < SWIPE_THRESHOLD;
      var axis = null;
      if (!tap) {
        axis = Math.abs(dx) > Math.abs(dy) ? "x" : "y";
      }
      if (scrollerDeclining(at, axis)) {
        return;
      }
      if (tap) {
        /* A TAP, WHICH MEANS ONE STEP BACK. It is handled here and nowhere
           else: a touch produces a touchend AND a synthesized click, and some
           browsers synthesize the click after a drag, so a second listener on
           click would double-fire and a swipe would also step back.

           THE FLASH IS LEFT ALONE. renderFlash() has owned a click handler
           since tla-7xql.12 and prints "Tap anywhere here for the next one",
           which is where the reader learns the gesture. Handling a tap here as
           well would advance twice on one touch. */
        if (view && view.flash) {
          return;
        }
        if (isControl(ev.target)) {
          return;
        }
        /* THE ARM IS TAKEN HERE AND NOT HIGHER UP, and both guards above it
           are the reason. The flash owns a click handler of its own, which is
           how a reader advances to the next item, so arming before that guard
           would swallow the advance. A press that starts on a button is the
           control's own business, so arming before that guard would swallow
           the press. */
        arm = ev.target;
        gesture("tap");
        return;
      }
      /* A swipe arms too. Some browsers synthesize a click after a drag, and
         an answer re-renders the page the same way a step back does. */
      arm = ev.target;
      if (axis === "x") {
        gesture(dx > 0 ? "right" : "left");
      } else {
        gesture(dy > 0 ? "down" : "up");
      }
    }, { passive: true });

    /* THE SWALLOW, IN THE CAPTURE PHASE, which is what stops the button's own
       handler running at all. A bubbling listener would arrive after the
       verdict was already filed.

       preventDefault() AS WELL AS stopPropagation(), because menuLink() draws
       an <a>: a ghost click on that navigates to the contract page, and
       stopping propagation says nothing about the browser's own default.

       The arm is cleared on every click this sees, whether it swallowed or
       not, so one gesture can only ever eat one click. The touch listeners
       stay passive: canceling the click here rests on nothing the browser has
       to honor, where preventDefault() on the touch would. */
    root.addEventListener("click", function (ev) {
      var tail = clickIsTail(arm);
      arm = null;
      if (tail) {
        ev.preventDefault();
        ev.stopPropagation();
      }
    }, true);
  }

  /* THE FIVE GESTURES, EACH WITH ONE MEANING IN EVERY STATE. right, left and
     down are the three answers, up is one step deeper and tap is one step
     back. Nothing here reads a mode to decide what a direction means, which is
     the property the whole design turns on: a reader wrong about which mode
     they are in would otherwise file a vacuity verdict on a real claim. */
  function gesture(dir) {
    var v = view;
    if (v.panel !== null) {
      /* stats and the message panels are not steps of the stack, so no answer
         and no stack move reaches them. Tap still means one step back, which
         from a panel is out of it. */
      if (dir === "tap") {
        v.panel = null;
        v.message = null;
        render();
      }
      return;
    }
    if (v.flash) {
      advance();
      return;
    }
    var steps = stepsFor(v.current);
    if (dir === "up" || dir === "tap") {
      var d = depthAfter(dir, v.depth, steps);
      if (d !== v.depth) {
        v.depth = d;
        render();
      }
      return;
    }
    if (!answersLive(v.depth, steps)) {
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
      /* Escape is tap, because a desktop has no tap and the stack still has to
         be walkable both ways from a keyboard. The four arrows are unchanged. */
      var map = {
        ArrowRight: "right",
        ArrowLeft: "left",
        ArrowDown: "down",
        ArrowUp: "up",
        Escape: "tap"
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

  /* THE READER OWNS THE VIEWPORT ON ITS PAGE, AND ONLY ON ITS PAGE.
     Bead tla-7xql.16.

     Before this, the reader was a widget in a scrolling page: 387 pixels of
     theme above it, 1944 pixels of contract prose below it, 3266 pixels of
     document on an 844 pixel viewport. The touch listeners are
     { passive: true } and so cannot cancel a scroll, which means a vertical
     drag inside the reader scrolled the page AND fired gesture(). Down is
     "not a claim", so a scroll filed a vacuity verdict on a real claim. Frank
     found answers in his own record that he never gave.

     THE CLASS GOES ON FROM HERE RATHER THAN FROM A PAGE TEMPLATE, because
     mkdocs.yml runs navigation.instant: the document's content is replaced
     without a reload, so a per-page template is not known to apply when the
     reader is reached from the nav. This file already boots off
     window.document$ for that reason, so the class rides the same observable.

     AND IT HAS TO COME OFF AGAIN. The html element SURVIVES an instant
     navigation, so a class left on it follows the reader to every other page
     of the site and takes the Material header with it. That removal is the one
     thing in this bead that breaks the whole site if it is wrong, which is why
     the rule is one function with one caller: the class is on exactly when
     this document carries the reader's root.

     Takes the document rather than reaching for a global, so
     harness/test-swipe-reader.sh drives both directions against one stub whose
     root comes and goes, which is what an instant navigation does. Returns
     whether the class is on afterwards. */
  function applyViewport(doc) {
    var html = doc && doc.documentElement;
    if (!html || !html.classList) {
      return false;
    }
    var present = Boolean(doc.getElementById && doc.getElementById("swipe-app"));
    if (present) {
      html.classList.add(VIEWPORT_CLASS);
    } else {
      html.classList.remove(VIEWPORT_CLASS);
    }
    return present;
  }

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
      /* Where the contract prose went, read off the page rather than written
         here. Absent is a legitimate answer: a page that publishes no
         contract draws no link to one. */
      contract: root.getAttribute ? root.getAttribute("data-contract") : null,
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
      flash: null,
      lastMiss: null,
      /* How deep the premise stack is open. 0 is the resting card and k is
         step k of stepsFor(v.current). Separate from panel on purpose: a panel
         changes the subject and a step does not. */
      depth: 0,
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

    /* FIRST, AND ON BOTH BRANCHES. Every return below it is a page that has
       already been given or taken back the viewport, including the one where
       the payload failed to load: that failure message is the reader's page
       too, and a half-dressed layout is worse than either state. */
    applyViewport(d);

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

  /* THE PARSE, EXPORT, BUCKET AND STACK HALVES ARE PURE, SO A GATE CAN
     EXERCISE THEM WITH NO BROWSER. harness/test-swipe-reader.sh requires this
     file through a script runtime and drives the refusal paths, the bucket
     split and every depth transition directly rather than grepping for a
     shape. These lines are the only place in this file that knows a module
     system exists, and a browser takes neither branch.

     The stack five are exported for that reason and not as an afterthought:
     the step list and the depth transitions are the whole of tla-7xql.15's
     rule, and a rule asserted by grep is a rule nobody ran. */
  if (typeof module === "object" && module && module.exports) {
    module.exports = {
      parseLog: parseLog,
      mergeLog: mergeLog,
      exportText: exportText,
      bucketsOf: bucketsOf,
      bucketKey: bucketKey,
      pinBlocks: pinBlocks,
      stepsFor: stepsFor,
      depthAfter: depthAfter,
      answersLive: answersLive,
      cardHint: cardHint,
      /* tla-7xql.18's two, and both are here because a text gate cannot see a
         table. chromeAt answers what a state draws, over 30 combinations, and
         the decline pair answers which scroller eats a touch, in BOTH
         directions: a decline that always fires and a decline that never fires
         both pass a one-sided check, and the first of those is the defect that
         bead removed.

         THE DECLINE IS TWO EXPORTS SINCE tla-7xql.21, because it is two
         questions. scrollerMark answers WHICH scrollers the thumb landed in,
         at touchstart. scrollerDeclining answers WHETHER one of them takes the
         stroke, at touchend, once the gesture has an axis. The gate drives the
         pair in that order over a table of (start element, per-axis overflow,
         gesture axis), which is the real sequence rather than a stand-in. */
      chromeAt: chromeAt,
      scrollerMark: scrollerMark,
      scrollerDeclining: scrollerDeclining,
      /* tla-7xql.22's one, and a text gate cannot see the thing that matters
         about it: which way it answers. A guard that always swallows and one
         that never swallows both pass a one-sided check, and the first of
         those eats every real press. So the gate drives it over all three
         arms, no arm at all and an element on either side of isConnected. */
      clickIsTail: clickIsTail,
      /* tla-7xql.16's two. applyViewport takes the document rather than
         reaching for a global precisely so it can be driven here, and the
         removal direction is the assertion worth having: a class left on the
         html element follows the reader to every other page of the site. */
      applyViewport: applyViewport,
      forgetState: forgetState,
      VIEWPORT_CLASS: VIEWPORT_CLASS,
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
