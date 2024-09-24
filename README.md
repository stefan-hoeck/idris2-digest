# Digesting Idris2

A walk-through through the Idris2 compiler source code with notes
about what happens where.

Before we begin looking at the compiler sources, a quick note about
backwards compatibility. The current HEAD of the Idris projects is
supposed to be buildable both from the bootstrap compiler attached
to the project (a pre-build of the latest release version) as well
as the current release version of the project. While the bootstrap
compiler first compiles and then uses the standard libraries in their
latest form, the release compiler makes use of the release version
of the standard libraries. This has a couple of implications of what
can and what cannot be added to the project between two releases.

* New syntactic forms such as new primitives, syntactic sugar, or
  pragmas can be added to the compiler, but they cannot be use
  in the standard libraries right away because the
  bootstrap compiler knows nothing about these new
  forms while requiring the current standard libs to build the
  rest of the project. Such new forms can therefore only be used in the
  standard libraries after the next release.
* New additions to the standard libraries cannot be used in the
  compiler sources until after the next release, because the
  release compiler uses its own version of the standard libraries.
  Since the new additions are missing in older versions, the release
  compiler will not be able to build the current HEAD.
  In case some functionality is needed in the compiler but is general
  enough that it should go to the standard libraries, it is common practice
  to add the functions and types in question twice: Once to the
  standard libraries (*base*, usually) and a second time to a submodule
  of `Libraries` in the compiler sources. The version in the compiler
  is typically annotated with a comment that it can be removed after
  the next release.

  While this works reasonably well, care must still be taken to
  distinguish between the two versions of new functionality,
  because the current compiler must also be able to build itself (self-hosting)
  in the presence of the current standard libraries. It is therefore
  advisable to use partially qualified names to resolve
  potential ambiguities in these cases.

## Basic Concepts

### The `main` Function

The `main` function is located at `Idris.Main.main`, this just
invokes `Idris.Driver.mainWithCodegens`, which
then reads command-line options and either runs a single print-only
command, or moves on and runs `stMain` in the `Core` effect (see `Core.Core`).

* `Idris.Main`: Main program entry point. Immediately invokes
  `Idris.Diver.mainWithCodegens`.
* `Idris.Driver`: Assembles all the pieces required for running `idris2`

### Command-Line Options

These are handled in module `Idris.CommandLine`
where also auto-completion functionality and scripts are defined as
well as parsers for command-line options plus help texts.

* `Idris.CommandLine`: Command-line options, their parser, and help text.
* `Idris.SetOptions`: Auto-completion script, setting of session options
  (see also `Core.Options.Session`). It also contains utilities for resolving
  package directories based on package name and version number.

### Environment

Environment variables are defined in `Idris.Env`. A list of them plus
explanation is printed when running `idris2 --help`. However, some of
them require further explanation, especially since they are related
to where Idris is looking for stuff.

* `IDRIS2_PREFIX`: This is the root directory of the Idris installation.
  It is added, for instance, to the package search path (see the description
  of `Core.Options.Dirs.prefix_dir`). If not set explicitly, this defaults
  to `IdrisPaths.yprefix`.
* `IDRIS2_PACKAGE_PATH`: Colon-separated list of absolute paths where Idris
  should look for installed packages (see also the description of
  `Core.Options.Dirs.package_search_paths`).
* `IDRIS2_PATH`: Colon-separated list of absolute paths where Idris
  will look for installed build artifacts for loading modules as well as
  some other utilities such as `.so` files for linking (see also the description of
  `Core.Options.Dirs.extra_dirs`).
* `IDRIS2_DATA`: Colon-separated list of absolute paths where Idris
  will look for additional support files written in the target language
  (see also the description of `Core.Options.Dirs.data_dirs`).
* `IDRIS2_LIBS`: Colon-separated list of absolute paths where Idris
  will look for additional `.so` for linking. 
  (see also the description of `Core.Options.Dirs.lib_dirs`).

Modules dealing with environment variables:

* `Idris.Env`: Environment variables used by Idris
* `IdrisPaths`: Auto-generated via `make src/IdrisPaths.idr`,
  this contains string constants for the current compiler version plus Git hash,
  as well as the prefix (installation directory).
* `Idris.Version`: Wraps the version from `IdrisPaths` in a semantic version
  (see `Libraries.Data.Version`)
* `Core.Directory`: Provides utilities for finding source and data files based
  on the environment variables. Utility `findIpkgFile` is used to recursively
  look for the first `.ipkg` file in the current directory or one of its parents.

### The `Core` Effect

Data type `Core.Core.Core` (lol) is a wrapper around `IO (Either Error t)`,
where `Error` is the compiler's error type (also defined in `Core.Core`).
It is the main effect type used in most parts of the compiler sources
and comes with custom implementations for typical combinators such as
`(>>=)`, `(<*>)`, and `traverse` for reasons of efficiency.
The content of `Core.Core` consists mostly of utilities for working with and
printing `Error`s plus the aforementioned combinators for working with
the `Core` effect type.

* `Core.Core`: The `Core` effect type and `Error` (Idris erros)
* `Idris.Error`: Pretty printing of errors and warnings

## Dealing with Text: Lexing, Parsing, and Pretty Printing

The core functionality for dealing with text can be found in the
submodules of `Libraries.Text`, which is documented here. Code for
lexing and parsing different formats is spread across several parts
of the code base and will be discussed together with the corresponding
data types.

### Lexing

A lexer cuts a piece of text into lexicographic tokens or *lexemes*
and usually annotates them with the location (file context) in the
source code where they were found.

The most basic lexers are context-free, that is, they cut text into
lexemes based on syntactic rules only, ignoring the surrounding context.
Here is a description of the three core modules plus some utilities
used for lexing:

* `Libraries.Text.Bounded`: This defines the `Bounds` data type, a
  region in a piece of text given as the start and end row (line) and
  column. It also defines `WithBounds` a wrapper for pairing a value
  with its `Bounds` in the source text. Some basic combinators and
  utilities are also provided.
* `Libraries.Text.Lexer.Core`: This defines the `Recognise` data type,
  an algebraic data type used to define context-free lexers. It is
  indexed over a boolean to indicate if it is *productive* (always
  consumes some input) or not. The idea is that only productive
  lexers can be freely used in recursive functions because they
  are guaranteed to reduce the size of the consumed text with each
  iteration.

  Groups of lexers are described as `TokenMap`s: Lists of lexers,
  each paired with a function from `String` to a token type `a`.
  Token maps are used in functions `lex` and `lexTo` to cut
  a piece of text into lists of bounded tokens. In addition, `lexTo`
  allows us to drop unneeded tokens (whitespace, for instance).
* `Libraries.Text.Quantity`: This defines a `Quantity` data type used
  to describe regions of natural numbers (minimum plus optional maximum
  count) that are used as a means of repeating tasks in lexing
  and parsing.
* `Libraries.Text.Token`: This provides an interface `TokenKind`
  that allows us to describe a lexeme as a dependent pair of
  a "kind" data type plus a token value of a type matching the
  token's kind. A `Token` is then a kind of token plus a string
  that was recognized as a token of this kind.
* `Libraries.Text.Lexer`: This provides additional utilities for
  defining all kinds of common lexers.
* `Libraries.Text.Lexer.Tokenizer`: This adds some context to the
  basic lexers we looked at so far: Data type `Tokenizer` allows us
  to tokenize text based on the current context. A starting lexer
  is used to identify certain regions in the text that must then
  begin and end with an opening and closing lexeme (for instance,
  pairs of parentheses or quotes). This muddles the boundaries
  between lexing and parsing but can sometimes be useful to
  tokenize complex language mixes such as interpolated string
  literals.
* `Libraries.Text.Literate`: Lexing utilities for embedding source
  code in other file formats (also called *literate* source documents).
  This allows us to, for instance, embed Idris source code in markdown and LaTeX files
  and use these files both for generating nicely formatted text documents
  and at the same time treat them as valid Idris source files that
  can be type-checked and used as regular modules in larger Idris
  projects.
* `Parser.Lexer.Common`: Lexers for single-line comments, identifiers
  and namespaces.
* `Parser.Lexer.Source`: A data type and lexer for Idris source file tokens.
  Most of these are simple and easy to understand: Literals, identifiers
  and namespaces, pragmas, and so on. The real complexity comes fro
  tokenizing interpolated strings and the resulting mutual relation
  between the string tokenizer and the one used for everything else.

### Parsing

While a lexer typically generates lexicographic tokens independent of
the current context, a parser typically puts the *lexemes* into context.
Parsing consists of basic tasks such as matching opening and closing
parentheses, but also identifying groups of tokens that are part of
a larger syntactic construct such as a function definitions and
implementations. In case of source code, the result of parsing is
typically a syntax tree: A heterogeneous tree type describing the
structure of an Idris program. Parsers are also used for reading
`.ipkg` files and command-line options (the latter is not based on
`Libraries.Text.Parser`).

One of the most important tasks of a parser for programming languages is
to generate coherent error messages in case of invalid syntax or type
errors. This can be very hard to achieve and leads to a considerable
increase in complexity in even the most basic parsers.

* `Libraries.Text.Parser.Core`: Defines the `Grammar` algebraic data type
  used to describe the grammars of different types of languages. Conceptually,
  a grammar is a monad, but since `Grammar` is also indexed by a boolean
  indicating if it is productive or not, this module provides custom
  implementations for the usual monadic and applicative operators.
  Besides a couple of well documented utilities, this provides functions
  `parse` and `parseWith` for converting lists of lexemes with bounds
  to Idris values. This also shows that in general parsing comes after
  lexing.
* `Libraries.Text.Parser`: This provides some additional grammar rules
  that are often used in parsers.
* `Libraries.Utils.Path`: A data type (`Path`) for working with relative
  and absolute file paths as well as a lexer and parser for reading
  `Path`s from strings. In addition, this contains utility functions
  for dealing with paths in `String` form (making use of `Path`
  and its parser internally).

### Pretty Printing

Pretty printing is all about presenting information in a clean, human
readable and nicely formatted form. This is used for generating all kinds
of output that is supposed to be read by humans instead of by machines.
Module `Libraries.PrettyPrint.Prettyprinter` and its submodules provide
an extensive and powerful pretty printer that is - unfortunately - a bit
too slow for code generation, so there is another much more basic pretty
printer currently in use in the JavaScript backends.

* `Libraries.Text.PrettyPrint.Prettyprinter`: Just re-exports the `Doc` and
  `Symbols` submodules.
* `Libraries.Text.PrettyPrint.Prettyprinter.Doc`: Defines the `Doc` data type
  (plus related types) used to define a syntax tree of pretty printed text that
  can be converted to a `SimpleDocStream` by means of several `layout*` functions
  adhering to different layout rules. Simple doc streams can be converted to
  strings or printed directly to an output stream or open file.

  Note that both `Doc`s and `SimpleDocStream`s are parameterized and can be
  annotated with additional instructions such as text styling rules that can
  be used (or ignored) by rendering functions.
* `Libraries.Text.PrettyPrint.Prettyprinter.Render.HTML`: Provides only `htmlEscape`
  for correctly escaping text in HTML documents.
* `Libraries.Text.PrettyPrint.Prettyprinter.Render.String`: Functionality for
  converting `SimpleDocStream`s to strings or printing them directly to
  standard output.
* `Libraries.Text.PrettyPrint.Prettyprinter.Render.Terminal`: Rendering function
  with support for ANSI terminal colors and text styles.
* `Libraries.Text.PrettyPrint.Prettyprinter.SimpleDocTree`: Another syntax tree
  more suitable for rendering structured text such as HTML documents. Comes with
  `fromStream` for converting `SimpleDocStream`s.
* `Libraries.Text.PrettyPrint.Prettyprinter.Symbols`: List of single character
  symbols as `Doc ann` values plus utilities for putting documents in different
  types of quotes and parentheses.
* `Libraries.Text.PrettyPrint.Prettyprinter.Util`: A few more utilities for
  working with pretty printers.

## Context

Many if not most functions in the compiler make use of the application
`Context` defined in `Core.Context`.

* `Core.Options`: Data types storing compiler options that have been read from
  command-line arguments and environment variables. The following data types
  are defined and used:
  * `Dirs`: Different directories where Idris looks for stuff
    (see also the *Directories* section below).
  * `CG`: Known code generators.
  * `PrimNames`: Names of functions used for conversion of literals.
    These are specified in the Prelude using the pragmas
    `%charLit`, `%doubleLit`, `%integerLit`, and `%stringLit`.
    Those dealing with elaborator reflection are specified in base.
  * `ElabDirective` hold settings and limits used during elaboration.
  * `Session` holds session options set via command-line arguments.
    These are processed in `Idris.SetOptions` and include settings about
    logging and timing amongst many others.
  * `PPrint` defines settings to be used when pretty printing stuff,
    especially related to names.
  * `PairNames`: TODO (don't know yet what they are used for)
  * `RewriteNames`: TODO (don't know yet what they are used for)
  * `Options` is a record type used for grouping the above mentioned
    options plus some additional ones such as currently active language
    extensions.

### Directories

It is illuminating to know in which directories Idris will look for information.
Record type `Core.Options.Dirs` lists most of these. Here's a list of
its fields:

* `working_dir`: The current working directory. Relative paths are relative
  to this directory.
* `source_dir`: Optional relative path where Idris will look for source files.
  Can be set in `.ipkg` files or via a command-line option. Defaults to the
  current working directory.
* `build_dir` : Relative path where build artifacts will be written to.
  Can be set in `.ipkg` files or via a command-line option and defaults to `build`.
* `depends_dir` : Relative path for local dependencies. Cannot currently be
  changed and defaults to `depends`. This is where Idris will first look for
  installed packages.
* `output_dir`: Relative path where executable programs will be written to.
  Can be set in `.ipkg` files or via a command-line option and defaults
  to `build_dir/exec`.
* `prefix_dir`: Root directory of the Idris installation. This defaults to
  `IdrisPaths.yprefix` but can be overwritten by setting the `IDRIS2_PREFIX`
  environment variable. It is added to the package search paths, but Idris
  looks also in some of its subdirectories for `.so` and support files.
* `extra_dirs`: These are the directories listed in the `IDRIS2_PATH` environment
  variable.
* `package_search_paths`: A list of paths where Idris will look for installed packages.
  Idris will look in all of these for matching packages (name plus version number)
  if it cannot find anything in the `depends_dir`.
  This includes the `pkgGlobalDirectory` (`prefix_dir/idris2-0.7.0`) plus all
  directories listed in environment variable `IDRIS2_PACKAGE_PATH`.
* `package_dirs`: This, together with `extra_dirs` is where Idris will look for
  installed build artifact. This is populated with the directories listed
  in the `IDRIS2_PATH` environment variable as well as the package installation
  directories found during package resolution.
* `lib_dirs` : These are the directories listed in the `IDRIS2_LIBS` environment
  variable. In addition, `prefix_dir/idris2-0.7.0/lib` and the current working
  directory end up in this list.
  This is where Idris will look for pre-built `.so` files to be used during
  linking.
* `data_dirs` : These are the directories listed in the `IDRIS2_DATA` environment
  variable, but also `prefix_dir/idris2-0.7.0/support` ends up in here.
  This is where Idris will look for installed support files (predefined source
  code written in the target programming language). Currently, only the JavaScript
  backends support additional support files besides the hard-coded ones.
  In addition, the `data` subdirectories in all resolved package directories
  will be added to this list (see `Idris.Package.addDeps`).

## Packages

Idris packages are defined in `.ipkg` files, which list a package's
dependencies, the modules it export, additional fields for building
and installing a package, plus information about the author(s) and
licensing. The following modules are relevant:

* `Idris.Package.Types`: Defines the `PkgDesc` type, a record type
  listing all the fields that can be specified in an `.ipkg` file.
  This module also defines data types `PkgVersion` and `VersionBounds`
  plus utilities for comparing package version bounds.
  Finally, it contains a pretty printer for `PkgDesc`, which can be
  used to generate `.ipkg` files from the Idris type.
* `Idris.Package.Init`: Utilities for (interactively) setup a new
  Idris project plus corresponding `.ipkg` file.
* `Idris.Package.ToJson`: Utilities for exporting `.ipkg` files to
  the JSON format.
* `Idris.Package`: Parser for `.ipkg` files plus utilities used during
  (transitive) dependency resolution. Finally, this module also contains
  the runner for processing packaging commands such as `--build`,
  `--install`, or `--mkdorcs`.
* `Parser.Lexer.Package`: Provides the token type and lexing rules used
  for tokenizing `.ipkg` files.
* `Parser.Rule.Package`: Basic rules for parsing `.ipkg` files.
* `Parser.Package`: Re-exports `Parser.Rule.Package` and `Parser.Lexer.Package`
  and provides two utilities for parsing `.ipkg` files.


## Syntax

* `Idris.Syntax.Pragmas` defines data type `KwPragma`, language pragmas
  and compiler instructions not associated with functions or data types.
  Its `Show` implementation shows the name of each pragma as it is used
  in source files. This module also defines the language extensions
  (currently, only `ElabReflection` is implemented).

## Utility Modules in `Libraries`

These contain all kinds of additional functionality required by the
compiler but - currently - not available from the standard libraries.
Some functions live in the standard libraries as well as in the compiler
libraries, because otherwise the compiler cannot be built from
the previous release version. These duplicate functions are typically
removed with the next release when they become redundant.

Below is the list of submodules currently not discussed elsewhere
plus a short description of each module's content:

* `Libraries.Control.ANSI`: ANSI terminal re-exports and decorated strings
* `Libraries.Control.ANSI.CSI`: ANSI terminal cursor position and movement
* `Libraries.Control.ANSI.SGR`: ANSI terminal colors and decorations
* `Libraries.Control.Delayed`: Type-level functions for conditional `inf` and `lazy` types
* `Libraries.Data.ANameMap`: Combination of `NameMap` and `UserNameMap`
  that allows the looking up of fully and partially qualified names such as `Fin.finToNat`.
* `Libraries.Data.DList`: A simple implementation of difference lists
  (as a function of type `List a -> Lista `)
* `Libraries.Data.Erased`: A wrapper for an erased value (quantity zero)
* `Libraries.Data.Fin`: `strengthen` from `Data.Fin` in base (has been added later)
* `Libraries.Data.Graph`: Tarjan's algorithm for finding the strongly
  connected components in a graph. This is used for identifying and possibly
  optimizing groups of mutually recursive functions.
* `Libraries.Data.IMaybe`: A boolean-indexed version of `Maybe`
* `Libraries.Data.IOArray`: Basic mutable arrays
* `Libraries.Data.IOMatrix`: Basic mutable 2D arrays
  (implemented as a single array of size `rows * columns`)
* `Libraries.Data.IntMap`: Like `Data.SortedMap` but specialized for `Int` keys (for efficiency)
* `Libraries.Data.List.Extra`: Additional utilities for `Data.List`
* `Libraries.Data.List.HasLength`: Additional utilities for `Data.List.HasLength`
* `Libraries.Data.List.Lazy`: A lazy list implementation (lazy in the spine)
* `Libraries.Data.List.LengthMatch`: A predicate witnessing that two lists have the same length
* `Libraries.Data.List.Quantifiers.Extra`: Additional utilities for `Data.List.Quantifiers`
* `Libraries.Data.List.SizeOf`: Wrapper around a `Nat` plus a proof that it is
  the length of the list in the index.
* `Libraries.Data.List1`: just `unsnoc` from `Data.List1` in base
* `Libraries.Data.NameMap`: Like `Data.SortedMap` but specialized for `Name` keys (for efficiency)
* `Libraries.Data.NameMap.Traversable`: Effectful tree traversals in the `Core` effect
* `Libraries.Data.Ordering.Extra`: Utility `thenComp` for lazily combining comparisons
* `Libraries.Data.PosMap`: An interval map used to retrieve data with a corresponding
  non-empty file context.
* `Libraries.Data.SnocList.HasLength`: Like `Data.List.HasLength` but for `SnocList`s
* `Libraries.Data.SnocList.LengthMatch`: Like `Data.List.LengthMatch` but for `SnocList`s
* `Libraries.Data.SnocList.SizeOf`: Like `Data.List.SizeOf` but for `SnocList`s
* `Libraries.Data.SortedMap`: Like `Data.SortedMap` in base (obsolete with the next release)
* `Libraries.Data.SortedSet`: Like `Data.SortedSet` in base (obsolete with the next release)
* `Libraries.Data.Span`: A value paired with a start position and
  length (two natural numbers).
* `Libraries.Data.SparseMatrix`: A sparse matrix implemented as a sparse vector
  of non-empty sparse vectors, where a "sparse vector" is a list of values paired
  with and sorted by their index in the vector.
* `Libraries.Data.String.Builder`: Another difference list implementation used for
  fast string concatenation.
* `Libraries.Data.String.Extra`: Additional utilities for working with `String`s.
* `Libraries.Data.String.Iterator`: Linear utilities for fast iteration over the
  characters in a string.
* `Libraries.Data.StringMap`: Like `Data.SortedMap` but specialized
  for `String` keys (for efficiency)
* `Libraries.Data.StringTrie`: TODO.
* `Libraries.Data.Tap`: A list monad transformer that wraps the spine in an effect
* `Libraries.Data.UserNameMap`: Like `SortedMap` specialized for `UserName`s
* `Libraries.Data.Version`: Provides a type plus parser for semantic versions
  (major, minor, path, plus an optional tag (for instance, for Git hashes))
* `Libraries.Data.WithDefault`: An indexed type pairing a type with a default value
  of this type. Functions relying on this can either use an specified value
  (wrapped in the `Specified` data constructor) or resort to the default value.
* `Libraries.System.Directory.Tree`: Utilities for traversing, sorting, printing,
  and copying directory trees
* `Libraries.Utils.Scheme`: Core functionality plus foreign function calls required
  to convert an Idris syntax tree (type `SchemeObj`, defined in this module) to
  a string of Scheme code and send this to a Scheme backend where the code should be
  parsed and evaluated, sending the result back to Idris.
  This seems to be considerably faster than evaluating the same syntax tree in
  Idris itself.
* `Libraries.Utils.String`: Some more utilities for working with strings.
* `Libraries.Utils.Octal`: Converting integers from and to octal literals.
* `Libraries.Utils.Binary`: Utilities for converting data from and to binary from.
* `Libraries.Text.Distance.Levenshtein`: The [Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance)
  is a string metric used to for measuring the distance between two
  sequences. It is used in Idris to make suggestions to programmers about
  potentially suitable names in scope in case of simple typos during input.
* `Libraries.Utils.Shunting`: From the source comments:
  "The shunting yard algorithm turns a list of tokens with operators into
  a parse tree expressing the precedence and associativity correctly."

## Module List

- [x] Algebra: `RigCount` alias and reexport of submodules
- [x] Algebra.Preorder: An interface for preorders
- [x] Algebra.Semiring: An interface for semirings
- [x] Algebra.SizeChange: The `SizeChange` semiring
- [x] Algebra.ZeroOneOmega: The `ZeroOneOmega` (or `RigCount`) semiring
- [ ] Compiler.ANF
- [ ] Compiler.CaseOpts
- [ ] Compiler.Common
- [ ] Compiler.CompileExpr
- [ ] Compiler.ES.Ast
- [ ] Compiler.ES.Codegen
- [ ] Compiler.ES.Doc
- [ ] Compiler.ES.Javascript
- [ ] Compiler.ES.Node
- [ ] Compiler.ES.State
- [ ] Compiler.ES.TailRec
- [ ] Compiler.ES.ToAst
- [ ] Compiler.Generated
- [ ] Compiler.Inline
- [ ] Compiler.Interpreter.VMCode
- [ ] Compiler.LambdaLift
- [ ] Compiler.NoMangle
- [ ] Compiler.Opts.CSE
- [ ] Compiler.Opts.ConstantFold
- [ ] Compiler.Opts.Identity
- [ ] Compiler.Opts.InlineHeuristics
- [ ] Compiler.Opts.ToplevelConstants
- [ ] Compiler.RefC
- [ ] Compiler.RefC.CC
- [ ] Compiler.RefC.RefC
- [ ] Compiler.Scheme.Chez
- [ ] Compiler.Scheme.ChezSep
- [ ] Compiler.Scheme.Common
- [ ] Compiler.Scheme.Gambit
- [ ] Compiler.Scheme.Racket
- [ ] Compiler.Separate
- [ ] Compiler.VMCode
- [ ] Core.AutoSearch
- [ ] Core.Binary
- [ ] Core.Binary.Prims
- [ ] Core.Case.CaseBuilder
- [ ] Core.Case.CaseTree
- [ ] Core.Case.CaseTree.Pretty
- [ ] Core.Case.Util
- [ ] Core.CompileExpr
- [ ] Core.CompileExpr.Pretty
- [ ] Core.Context
- [ ] Core.Context.Context
- [ ] Core.Context.Data
- [ ] Core.Context.Log
- [ ] Core.Context.Pretty
- [ ] Core.Context.TTC
- [ ] Core.Coverage
- [ ] Core.Env
- [ ] Core.FC
- [ ] Core.GetType
- [ ] Core.Hash
- [ ] Core.InitPrimitives
- [ ] Core.LinearCheck
- [ ] Core.Metadata
- [ ] Core.Name
- [x] Core.Name.Namespace: Data types and utilities for working with namespaces and module identifiers
- [ ] Core.Name.Scoped
- [ ] Core.Normalise
- [ ] Core.Normalise.Convert
- [ ] Core.Normalise.Eval
- [ ] Core.Normalise.Quote
- [ ] Core.Options.Log
- [x] Core.Ord: `Ord` implementation for `CExp`
- [ ] Core.Primitives
- [ ] Core.Reflect
- [ ] Core.SchemeEval
- [ ] Core.SchemeEval.Builtins
- [ ] Core.SchemeEval.Compile
- [ ] Core.SchemeEval.Evaluate
- [ ] Core.SchemeEval.Quote
- [ ] Core.SchemeEval.ToScheme
- [ ] Core.TT
- [ ] Core.TT.Binder
- [ ] Core.TT.Primitive
- [ ] Core.TT.Subst
- [ ] Core.TT.Term
- [ ] Core.TT.Term.Subst
- [ ] Core.TT.Traversals
- [ ] Core.TT.Var
- [ ] Core.TT.Views
- [ ] Core.TTC
- [ ] Core.Termination
- [ ] Core.Termination.CallGraph
- [ ] Core.Termination.Positivity
- [ ] Core.Termination.References
- [ ] Core.Termination.SizeChange
- [ ] Core.Transform
- [ ] Core.Unify
- [ ] Core.UnifyState
- [ ] Core.Value
- [ ] Idris.Desugar
- [ ] Idris.Desugar.Mutual
- [ ] Idris.Doc.Annotations
- [ ] Idris.Doc.Brackets
- [ ] Idris.Doc.Display
- [ ] Idris.Doc.HTML
- [ ] Idris.Doc.Keywords
- [ ] Idris.Doc.String
- [ ] Idris.Elab.Implementation
- [ ] Idris.Elab.Interface
- [ ] Idris.IDEMode.CaseSplit
- [ ] Idris.IDEMode.Commands
- [ ] Idris.IDEMode.Holes
- [ ] Idris.IDEMode.MakeClause
- [ ] Idris.IDEMode.Parser
- [ ] Idris.IDEMode.Pretty
- [ ] Idris.IDEMode.REPL
- [ ] Idris.IDEMode.SyntaxHighlight
- [ ] Idris.IDEMode.TokenLine
- [ ] Idris.ModTree
- [ ] Idris.Parser
- [ ] Idris.Parser.Let
- [ ] Idris.Pretty
- [ ] Idris.Pretty.Annotations
- [ ] Idris.Pretty.Render
- [ ] Idris.ProcessIdr
- [ ] Idris.REPL
- [ ] Idris.REPL.Common
- [ ] Idris.REPL.FuzzySearch
- [ ] Idris.REPL.Opts
- [ ] Idris.Resugar
- [ ] Idris.Syntax
- [ ] Idris.Syntax.Builtin
- [ ] Idris.Syntax.TTC
- [ ] Idris.Syntax.Traversals
- [ ] Idris.Syntax.Views
- [ ] Parser.Rule.Source
- [ ] Parser.Source
- [ ] Parser.Support
- [ ] Parser.Support.Escaping
- [ ] Parser.Unlit
- [ ] Protocol.Hex
- [ ] Protocol.IDE
- [ ] Protocol.IDE.Command
- [ ] Protocol.IDE.Decoration
- [ ] Protocol.IDE.FileContext
- [ ] Protocol.IDE.Formatting
- [ ] Protocol.IDE.Highlight
- [ ] Protocol.IDE.Holes
- [ ] Protocol.IDE.Result
- [ ] Protocol.SExp
- [ ] Protocol.SExp.Parser
- [ ] TTImp.BindImplicits
- [ ] TTImp.Elab
- [ ] TTImp.Elab.Ambiguity
- [ ] TTImp.Elab.App
- [ ] TTImp.Elab.As
- [ ] TTImp.Elab.Binders
- [ ] TTImp.Elab.Case
- [ ] TTImp.Elab.Check
- [ ] TTImp.Elab.Delayed
- [ ] TTImp.Elab.Dot
- [ ] TTImp.Elab.Hole
- [ ] TTImp.Elab.ImplicitBind
- [ ] TTImp.Elab.Lazy
- [ ] TTImp.Elab.Local
- [ ] TTImp.Elab.Prim
- [ ] TTImp.Elab.Quote
- [ ] TTImp.Elab.Record
- [ ] TTImp.Elab.Rewrite
- [ ] TTImp.Elab.RunElab
- [ ] TTImp.Elab.Term
- [ ] TTImp.Elab.Utils
- [ ] TTImp.Impossible
- [ ] TTImp.Interactive.CaseSplit
- [ ] TTImp.Interactive.Completion
- [ ] TTImp.Interactive.ExprSearch
- [ ] TTImp.Interactive.GenerateDef
- [ ] TTImp.Interactive.Intro
- [ ] TTImp.Interactive.MakeLemma
- [ ] TTImp.Parser
- [ ] TTImp.PartialEval
- [ ] TTImp.ProcessBuiltin
- [ ] TTImp.ProcessData
- [ ] TTImp.ProcessDecls
- [ ] TTImp.ProcessDecls.Totality
- [ ] TTImp.ProcessDef
- [ ] TTImp.ProcessFnOpt
- [ ] TTImp.ProcessParams
- [ ] TTImp.ProcessRecord
- [ ] TTImp.ProcessRunElab
- [ ] TTImp.ProcessTransform
- [ ] TTImp.ProcessType
- [ ] TTImp.Reflect
- [ ] TTImp.TTImp
- [ ] TTImp.TTImp.Functor
- [ ] TTImp.TTImp.TTC
- [ ] TTImp.TTImp.Traversals
- [ ] TTImp.Unelab
- [ ] TTImp.Utils
- [ ] TTImp.WithClause
- [ ] Yaffle.Main
- [ ] Yaffle.REPL
