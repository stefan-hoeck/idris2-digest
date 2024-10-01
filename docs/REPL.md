# The Idris REPL

* `Idris.REPL`: The REPL driver. Contains the relevant calls into
  code generation plus lots of functionality for managing the REPL
  state.
* `Idris.REPL.Common`: Additional functionality to be used in a REPL
  session, such as resetting the context. TODO
* `Idris.REPL.FuzzySearch`: Implements fuzzy expression/type search that
  is available at the REPL via the `:fs` command.
* `Idris.REPL.Opts`: Provides record type `REPLOpts` containing all
  the settings relevant when running the REPL. In addition, this comes
  with the usual setters and getters for manipulating these options
  in presence of an appropriate mutable reference.

Function `loadMainFile`: Reads the main file and builds it
together with its dependencies (via `Idris.ModTree.buildDeps`, TODO)
in a clean context.

Function `prepareExp`: Prepares an `Idris.Syntax.PTerm` for
code generation. It
desugars the term to `TTImp.TTImp.RawImp`, generates a pair of
local declarations (type plus definition) for the `it` variable,
which is assigned the expression and elaborated via `elabTerm`.
(I don't understand everything of this, yet. TODO). This returns
a pair (a `Term` and its type) and runs a linearity check on the
term. It then runs `Compiler.Inline.compileAndInlineAll`,
which takes no explicit argument, so I guess it's reading stuff from the
context, and finally returns the `ClosedTerm` it got
from linearity checking. Honestly, this is quite a mess.

Function `compileExp`: Compiles a `Idris.Syntax.PTerm` in the current
context (from loading the main file at the REPL or the main module
of an `.ipkg` file). This invokes `prepareExp`, followed by running
`Compiler.Common.compileExpr` on the selected code generator.

## IDE Mode

In IDE mode, Idris is run as a server that can take requests from and
send responses to - for instance - an editor editing `.idr` files.
It provides interactive editing features about which a regular editor
or IDE can know nothing, such as case splitting or semantic highlighting.

Modules

* `Protocol.Hex`: Converting integers from and to hexadecimal format.
* `Protocol.IDE`: TODO
* `Protocol.IDE.Command`: A data type for known IDE commands plus
  their conversions from and to S-expressions.
* `Protocol.IDE.Decoration`: Decorations used (I assume) in semantic
  highlighting plus their conversions from and to S-expressions.
* `Protocol.IDE.FileContext`: The file context used (file name plus bounds).
* `Protocol.IDE.Formatting`: Record `Properties` at most one `Decoration`
  plus one `Formatting` (currently: bold, italic, or underline).
* `Protocol.IDE.Highlight`: TODO
* `Protocol.IDE.Holes`: TODO
* `Protocol.IDE.Result`: TODO
* `Protocol.SExp`: A data type for S-expressions plus marshalling interfaces
  with implementations for the usual Idris types.
* `Protocol.SExp.Parser`: Lexer and parser for S-expressions.
* `Idris.IDEMode.CaseSplit`: Implements case splitting: The ability expand
  a variable in a pattern match into a list of applied data constructors.
* `Idris.IDEMode.Commands`: Some small utilities for reading and sending
  commands.
* `Idris.IDEMode.Holes`: TODO
* `Idris.IDEMode.MakeClause`: Utilities for generating `case` and `with` clauses.
* `Idris.IDEMode.Parser`: A parser for S-expressions. Makes use of stuff from
  `Protocol.SExp` and `Protocol.SExp.Parser
* `Idris.IDEMode.Pretty`: TODO
* `Idris.IDEMode.REPL`: Provides `replIDE` for running Idris as a server
  taking requests and sending responses via a socket.
* `Idris.IDEMode.SyntaxHighlight`: Provides semantic highlighting via IDE mode.
* `Idris.IDEMode.TokenLine`: A simple tokenizer for source lines.

## Yaffle

A simplified REPL that runs only on `TTImp`, and I currently have no idea
what that means. It can be started with `idris2 --yaffle --repl` or,
alternatively, `idris2 --ttimp --repl`. (TODO)

Modules:

* `Yaffle.Main`
* `Yaffle.REPL`

## Interactive Editing

Idris provides different utilities for interactive editing that can simplify
many programming tasks. These are implemented in submodules of
`TTImp.Interactive` and are available at the REPL as well as in IDE mode.

Modules:

* `TTImp.Interactive.CaseSplit`: Implements case-splitting functionality.
  Generates clauses for each of the data constructors of the type we split on.
* `TTImp.Interactive.Completion`: Provides auto completion for names, pragmas,
  and commands.
* `TTImp.Interactive.ExprSearch`: Expression search tries to replace a hole
  with a value of the desired type. This uses proof search internally but
  allows for the search result to be non-unique.
* `TTImp.Interactive.GenerateDef`: Utilities for generating skeletton
  definitions.
* `TTImp.Interactive.Intro`: Don't know yet what this does (TODO).
* `TTImp.Interactive.MakeLemma`: Utilities for lifting a hole into a
  new top-level function (a "lemma").
