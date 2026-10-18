// Levels.java — read the TLA+ level of every definition a module declares.
//
// TLA+'s level calculus has four values, and a swipe-item generator needs all
// four to dispatch on, because the level decides what the item pins:
//
//   0  constant expression   no variables, no primes, no temporal operators
//   1  state predicate       mentions variables, no primes, no temporal ops
//   2  action                mentions primes or UNCHANGED
//   3  temporal              mentions [] <> WF SF
//
// WHY THE SEMANTIC TREE AND NOT AN ERROR MESSAGE. SANY reports a level in its
// own refusal text when an ASSUME is not level 0, and that is how this route
// was validated. It is not a channel to build on, for a reason that is about
// correctness rather than cost: the level in that message belongs to the
// APPLICATION, not to the definition. Measured on reading/core/01-nim, where
// \oplus is a level 0 operator of two arguments:
//
//   ASSUME (a (+) b) = 0        level 1    the arguments are variables
//   ASSUME (Heap (+) Heap) = 1  level 0    SANY accepts it, no message at all
//
// Same definition, two answers, chosen by arguments a probe has to invent. 37
// of the level 2 definitions in reading/ take arguments, so the ASSUME channel
// cannot answer the question for them and would answer it wrongly in silence.
// getLevel() on the OpDefNode reads the level the definition has.
//
// WHY THERE IS NO BUILD STEP. This file runs under Java's single-file source
// launcher, so `java -cp tla2tools.jar Levels.java <modules>` compiles it in
// memory and runs it. No javac call, no .class file to gitignore, and nothing
// for scripts/setup to install beyond the JDK that CI already provisions.
// harness/levels/levels.sh is the wrapper and carries the full contract.
//
// ONE SANY PARSE PER MODULE, ONE JVM FOR THE WHOLE CORPUS. Every path on the
// command line is parsed in this one process. A JVM per definition, or per
// module, is the fork-pressure defect this project has shipped twice.

import java.io.ByteArrayOutputStream;
import java.io.PrintStream;
import java.io.UnsupportedEncodingException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

import tla2sany.drivers.SANY;
import tla2sany.drivers.SanyExitCode;
import tla2sany.drivers.SanySettings;
import tla2sany.modanalyzer.SpecObj;
import tla2sany.output.LogLevel;
import tla2sany.output.SimpleSanyOutput;
import tla2sany.semantic.ModuleNode;
import tla2sany.semantic.OpDefNode;
import util.SimpleFilenameToStream;

public final class Levels {

  private static final int RC_OK = 0;
  private static final int RC_MODULE_FAILED = 1;
  private static final int RC_USAGE = 2;
  // The project-wide reserved code for "the check could not be performed", so
  // a caller can tell a missing toolchain from a module that will not parse.
  private static final int RC_INDETERMINATE = 99;
  private static final String TOKEN_INDETERMINATE = "CHECK_DID_NOT_RUN";

  private static final int MIN_LEVEL = 0;
  private static final int MAX_LEVEL = 3;

  private Levels() {
  }

  public static void main(final String[] args) {
    boolean all = false;
    final List<String> paths = new ArrayList<>();

    for (final String arg : args) {
      if ("--all".equals(arg)) {
        all = true;
      } else if ("-h".equals(arg) || "--help".equals(arg)) {
        usage(System.out);
        System.exit(RC_OK);
      } else if (arg.startsWith("-")) {
        System.err.println("Levels: unknown option '" + arg + "' (try --help)");
        System.exit(RC_USAGE);
      } else {
        paths.add(arg);
      }
    }

    if (paths.isEmpty()) {
      usage(System.err);
      System.exit(RC_USAGE);
    }

    final StringBuilder out = new StringBuilder();
    int failed = 0;

    for (final String path : paths) {
      failed += readModule(path, all, out);
    }

    final PrintStream stdout = utf8(System.out);
    stdout.print(out);
    stdout.flush();
    System.exit(failed == 0 ? RC_OK : RC_MODULE_FAILED);
  }

  // Parses one module and appends its rows to `out`. Returns 1 if the module
  // could not be read, 0 otherwise.
  private static int readModule(final String path, final boolean all, final StringBuilder out) {
    final ByteArrayOutputStream diagnostics = new ByteArrayOutputStream();
    final SpecObj spec = new SpecObj(path, new SimpleFilenameToStream());

    int rc;
    try {
      // SANY.parse is frontEndMain's non-deprecated form on this build. Both
      // overloads of frontEndMain are deprecated, and the settings object is
      // what replaced their boolean arguments. doLevelChecking must be on or
      // getLevel() below reports nothing worth reading, and defaultSettings()
      // has it on — asserted by the 01-nim table in harness/test-levels.sh
      // rather than taken on trust.
      final SanyExitCode code = SANY.parse(spec, path,
          new SimpleSanyOutput(utf8(diagnostics), LogLevel.WARNING),
          SanySettings.defaultSettings());
      rc = code.code();
    } catch (final Throwable t) {
      // SANY throws for an unreadable file and for a few malformed inputs. A
      // thrown parse is still a parse failure, so it reports as one rather
      // than taking the whole run down and losing the modules after it.
      rc = -1;
      diagnostics.reset();
      final PrintStream sink = utf8(diagnostics);
      sink.println(t.getClass().getName() + ": " + t.getMessage());
      sink.flush();
    }

    final ModuleNode root = spec.getRootModule();
    if (root == null) {
      out.append("MOD\t").append(path).append("\t?\t").append(rc).append("\t0\n");
      report(path, "no root module", diagnostics);
      return 1;
    }

    final String rootName = root.getName().toString();

    // A LEVEL IS ONLY READABLE AFTER A SUCCESSFUL LEVEL CHECK. When semantic
    // analysis fails, SANY never reaches the level pass, and getLevel() then
    // throws `WrongInvocationException: getLevel called before levelCheck`.
    // That throw is outside the try above, so before this guard existed one
    // unparseable module took the whole run down and every module after it
    // went unreported. A module that did not pass semantic analysis has no
    // trustworthy level anyway, so it reports as one failed module and the
    // run carries on.
    if (rc != 0) {
      out.append("MOD\t").append(path).append('\t').append(rootName)
          .append('\t').append(rc).append("\t0\n");
      report(path, "SANY returned " + rc + ", so no level was read", diagnostics);
      return 1;
    }

    final List<String> rows = new ArrayList<>();
    boolean levelOutOfRange = false;

    // Contained for the same reason as the guard above: a throw from any one
    // definition reports as this module failing, never as the run ending.
    try {
      for (final OpDefNode def : root.getOpDefs()) {
        final ModuleNode origin = def.getOriginallyDefinedInModuleNode();
        final boolean fromRoot = origin == root;

        // THE EXTENDS FILTER. root.getOpDefs() carries every definition in
        // scope, so EXTENDS Naturals contributes +, -, %, \div and the rest.
        // Identity against the root ModuleNode is what separates what this
        // module declares from what it imported. An INSTANCE of an inner
        // module keeps the root's identity, so Abs!MFSpec in
        // reading/modules/01-bitcounter survives the filter with its own
        // level, which is the behavior the generator wants: the prefixed name
        // is what a learner reads.
        if (!all && !fromRoot) {
          continue;
        }

        final int level = def.getLevel();
        if (level < MIN_LEVEL || level > MAX_LEVEL) {
          levelOutOfRange = true;
          System.err.println("Levels: " + path + ": " + def.getName()
              + " reports level " + level + ", outside the level calculus "
              + MIN_LEVEL + ".." + MAX_LEVEL);
        }

        rows.add("DEF\t" + rootName
            + "\t" + def.getName().toString()
            + "\t" + level
            + "\t" + def.getArity()
            + "\t" + (origin == null ? "?" : origin.getName().toString())
            + "\t" + (def.isLocal() ? "local" : "exported"));
      }
    } catch (final Throwable t) {
      out.append("MOD\t").append(path).append('\t').append(rootName)
          .append("\t-1\t0\n");
      diagnostics.reset();
      final PrintStream sink = utf8(diagnostics);
      sink.println(t.getClass().getName() + ": " + t.getMessage());
      sink.flush();
      report(path, "reading its definitions threw", diagnostics);
      return 1;
    }

    out.append("MOD\t").append(path).append('\t').append(rootName)
        .append('\t').append(rc).append('\t').append(rows.size()).append('\n');
    for (final String row : rows) {
      out.append(row).append('\n');
    }

    if (levelOutOfRange) {
      return 1;
    }
    return 0;
  }

  private static void report(final String path, final String why,
      final ByteArrayOutputStream diagnostics) {
    System.err.println("Levels: " + path + ": " + why);
    final String text = new String(diagnostics.toByteArray(), StandardCharsets.UTF_8).trim();
    if (!text.isEmpty()) {
      System.err.println(text);
    }
  }

  private static PrintStream utf8(final java.io.OutputStream stream) {
    try {
      return new PrintStream(stream, true, "UTF-8");
    } catch (final UnsupportedEncodingException e) {
      // Every JVM is required to carry UTF-8, so this branch is unreachable.
      // It returns the indeterminate code rather than a guess, because a
      // charset fallback here would corrupt operator names such as \oplus.
      System.err.println("Levels: " + TOKEN_INDETERMINATE + ": no UTF-8 on this JVM");
      System.exit(RC_INDETERMINATE);
      throw new IllegalStateException(e);
    }
  }

  private static void usage(final PrintStream to) {
    to.println("usage: java -cp <tla2tools.jar> Levels.java [--all] <module.tla>...");
    to.println();
    to.println("Prints one tab-separated row per module and per definition:");
    to.println("  MOD  <path>  <module-name>  <sany-rc>  <definition-count>");
    to.println("  DEF  <module-name>  <name>  <level>  <arity>  <origin-module>  <local|exported>");
    to.println();
    to.println("Levels are TLA+'s own: 0 constant, 1 state, 2 action, 3 temporal.");
    to.println("Definitions an EXTENDS brought in are dropped unless --all is given.");
    to.println();
    to.println("exit: 0 every module read, 1 a module failed, 2 usage,");
    to.println("      " + RC_INDETERMINATE + " " + TOKEN_INDETERMINATE);
  }
}
