# Code Generation and Backends

During code generation, the following steps are performed (more or less in this
order):

* A `ClosedTerm` (alias for `Core.TT.Term.Term []`) together with all
  declarations it invokes is converted to a `Core.CompileExpr.CExp []`
  in function `Compiler.CompileExpr.compileExpr`. This involves many
  steps and quite a bit of analysis, so it will be discussed in more
  detail below.
* All functions called from the main expression will be compiled and
  optimized via `Compiler.Inline.compileAndInlineAll` (see below
  for the optimizations that Idris performs).
* Optimized compiled expressions will be converted into the intermediate
  representation (see below) required by the code generator.
* Code generators interpret the intermediate representation and generate
  the backend's code in text form.

Modules:

* `Core.CompileExpr`: TODO
* `Core.CompileExpr.Pretty`: Pretty printer for `CDef` (using `NamedCExp` internally)
* `Core.Ord`: `Ord` implementation for `CExp`

* `Compiler.Common`: Provides the following data types and utilities
  * `Codegen`: a record type, which describes
      * how to compile a `ClosedTerm` and write the generated code to a file
      * how to compile and execute a `ClosedTerm` directly
      * how to incrementally compile source files (not all code generators support
        this)
    Functions `compile`, `execute`, and `incCompile` are utilities that setup
    the necessary files and directories before invoking the corresponding 
    `Codegen` fields.
  * `UsePhase`: Enum type describing the IRs (intermediate representations) currently
    available for code generation.
  * `CompileData`: Record containing compiled expressions in different IRs.
    If we are not interested in one of the lower level IRs, the corresponding
    lists will be empty.
  * `getCompileDataWith` is the compilation unit used for compiling a closed
    term and related expressions to `CExp`, and process them further into
    one of the intermediate representations. The resulting list of
    compiled data is the returned to the caller.
* `Compiler.CompileExpr`: TODO
* `Compiler.Inline`: TODO
* `Compiler.Generated`: Just a function for generating a string explaing
  that it was Idris who generated the code. Yay.
* `Compiler.NoMangle`: Some backends (currently only the JavaScript backends)
  support annotating functions with an `%export` pragma. Such functions should
  not be skipped and their names not be adjusted during code generation. This
  module analyzes and lists all function names that must not be modified.
* `Compiler.Separate`: Groups definitions into compilation unites for
  separate code generation. This is currently only used by the `ChezSep`
  backend.
* `Compiler.CaseOpts`: This provides two optimizations for typical patterns
  found in case trees.
* `Compiler.Interpreter.VMCode`: A simple "backend" for the `VMCode` IR that
  interprets `VMCode` declarations and converts them to human readable
  form.

## Compiling Expressions

TODO

## Optimization

Idris performs a couple of optimizations before code generation, which help
with reducing generated code size and avoiding computations the results
of which are already known at compile time.

TODO:

* `inlineDef`
* `mergeLambdaDef`
* `caseLamDef`
* `fixArityDef`

### Optimizing Identity Functions

It is not uncommon to have utilities for converting values of
one type into values of another type of the same structure, the sole
purpose of which is to satisfy or support the elaborator. One
such function is, for instance, `finToNat`, which converts a natural
number of type `Fin n` to a natural number of type `Nat` of the same
value. But also `Prelude.id`, `believe_me`, or conversions from enum
types to the corresponding `Bits8` values come to mind.

If such conversions can still be perceived as the identity when
in `CExp` form, the function is flagged during code generation and
optimized away.

Modules:

* `Compiler.Opts.Identity` (TODO: I'd like to have a pragma to annotate
  functions with, to make sure they are recognized as the identity during
  code generation)

### Constant Folding

There are several constructs that can be at least partially evaluated
into a simpler form before code generation. Applications of constants
to primitive operations come to mind, but also rewriting certain
forms of `let` expressions to get nicer lists of imperative statements
in the produced code. This is handled by the constant folding optimizer.

Modules:

* `Compiler.Opts.ConstantFold`

### Common Subexpression Elimination (CSE)

Certain expressions - especially ones that have been inserted by the compiler
when filling in (auto-)implicits - keep coming up in many places in the
generated code. This can lead to a considerable blow up in the size
of the generated code (an order of magnitude in pathological cases)
and drop down in performance when complex and nested record types (interface
implementations!) are rebuilt time again.

CSE recognizes such reoccuring expressions, extracts them from
definitions and moves them to the top-level, giving them a new,
machine-generated name. This is somewhat the opposite of what
inlining does (see below), so we have to take some care not to move
very small and trivial expressions to the top-level, which might
be bad for performance and (to a lesser degree) generated code
size. Since CSE can considerably alter and obfuscate the generated
code, it can be turned off with a command-line flag.

Module:

* `Compiler.Opts.CSE`

### Lazily Evaluated Top-Level Constants

Interface implementations but also potentially large
and complex user-defined constants at the top-level might
be expensive to recompute every time they are required.

At the same time, top-level constants might require functionality
that is defined later in the list of definitions to be processed.
Definitions are therefore split into constants and functions
and sorted by their call graph, to make sure constants depending
on other functions are introduced later in the generated code.

Module:

* `Compiler.Opts.ToplevelConstants`

### Inlining

Inlining is the process of copying the definition of a top-level
function or constant into the call-site. This is typically feasible
for very simple expressions such as mere function applications
or top-level primitive constants. For these, inlining can reduce
(but sometimes also increase) the size of the generated code, while
at the same time improving performance, because it reduces the
number of function calls. Depending on the use case, this can or
cannot help de-obfuscating the generated code.

Module:

* `Compiler.Opts.InlineHeuristics`


## Intermediate Representations

TODO

Modules:

* `Compiler.ANF`
* `Compiler.LambdaLift`
* `Compiler.VMCode`

## Code Generators

### Scheme Generators

TODO

Modules:

* `Compiler.Scheme.Chez`
* `Compiler.Scheme.ChezSep`
* `Compiler.Scheme.Common`
* `Compiler.Scheme.Gambit`
* `Compiler.Scheme.Racket`

### JavaScript Generators

TODO

* `Compiler.ES.Ast`
* `Compiler.ES.Codegen`
* `Compiler.ES.Doc`
* `Compiler.ES.Javascript`
* `Compiler.ES.Node`
* `Compiler.ES.State`
* `Compiler.ES.TailRec`
* `Compiler.ES.ToAst`

### Reference Counting C Backend

TODO

* `Compiler.RefC`
* `Compiler.RefC.CC`
* `Compiler.RefC.RefC`
