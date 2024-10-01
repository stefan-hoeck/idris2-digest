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

## Overview

A general overview over the implementation of Idris on which parts of this
source map is built can be found in the
[Idris2 documentation](https://idris2.readthedocs.io/en/latest/implementation/overview.html).

A quick overview of how Idris code is processed: The core language is *TT*
(quantitative type theory), that is defined in `Core.TT` and some of its
submodules. A higher level language called *TTImp* (TT with implicits and other
additional utilities; found in submodules of `TTImp`) is *elaborated* to TT.
Elaboration relies on *unification* (in `Core.Unify`). The high level language 
(defined in `Idris.Syntax` as `PTerm'` (terms) and `PDecl` (declarations))
is parsed from Idris source code and *desugared* to `TTImp`.

During code generation, *TT* is compiled to `CExp` (expressions) and
`CDef` (top-level definitions) (both defined in `Core.CompileExpr`), run
through several optimizers and cleanup functions, and converted to
one of several intermediate representations (IRs), which are used by the
code generators to output code in the chosen backend's source language.
Everything related to code generation can be found in the submodules
of `Compiler`.

Throughout the compiler sources, Idris makes use of the `Core` effect type
(`IO` plus error handling), and keeps different types of mutable state
in mutable references. It can be quite confusing figuring out, which parts
of the code affect which parts of the threaded mutable state, especially
since there is often no distinction between references that are indeed
updated within a function and those that serve as a read-only context.
It is one of the goals of this source map to shed some light on where
the Idris context is updated how, but we are not there yet.

### Running Experiments

The more I dig into the compiler sources, the more it becomes clear that
the only way to make sense of this is to actually write and run some code
myself. This project therefore comes with a small library for experimenting
with the compiler pipelines (currently, only the parser).

The first thing required for this are proper pretty printers for most
data types in the *idris2* codebase. I use the
[*pretty-show*](https://github.com/stefan-hoeck/idris2-pretty-show) library, with
which most of these can be derived automatically using elaborator reflection.

As an example, we can use this to parse the source code of a small module
into the corresponding `Idris.Syntax.Module` data type and pretty print
the result to standard output (see `Digest.Parse` for an example, how this is
done). Likewise, in `Digest.Desugar` a module can be parsed and desugared.
Note, that for stuff like operators to behave correctly, you might have
to include the Prelude before running this.

## Table of Content

* [Main: Point of Entry](docs/Main.md)
* [Core Functionality](docs/Core.md)
* [Packages and Modules](docs/Packages.md)
* [The Idris REPL](docs/REPL.md)
* [Syntax](docs/Syntax.md)
* [Syntax Trees and Intermediary Representations](docs/Tree.md)
* [Code Generation and Backends](docs/Codegen.md)
* [Dealing with Text: Lexing, Parsing, and Pretty Printing](docs/Text.md)
* [Utility Modules in `Libraries`](docs/Libraries.md)

## TODO Module List

- [ ] Core.AutoSearch
- [ ] Core.Case.CaseBuilder
- [ ] Core.Case.CaseTree
- [ ] Core.Case.CaseTree.Pretty
- [ ] Core.Case.Util
- [ ] Core.Context.Data
- [ ] Core.Context.Pretty
- [ ] Core.Coverage
- [ ] Core.GetType
- [ ] Core.LinearCheck
- [ ] Core.Normalise
- [ ] Core.Normalise.Convert
- [ ] Core.Normalise.Eval
- [ ] Core.Normalise.Quote
- [ ] Core.Reflect
- [ ] Core.SchemeEval
- [ ] Core.SchemeEval.Builtins
- [ ] Core.SchemeEval.Compile
- [ ] Core.SchemeEval.Evaluate
- [ ] Core.SchemeEval.Quote
- [ ] Core.SchemeEval.ToScheme
- [ ] Core.Termination
- [ ] Core.Termination.CallGraph
- [ ] Core.Termination.Positivity
- [ ] Core.Termination.References
- [ ] Core.Termination.SizeChange
- [ ] Core.Transform
- [ ] Core.Unify
- [ ] Core.UnifyState
- [ ] Core.Value
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
- [ ] TTImp.TTImp.Traversals
- [ ] TTImp.Unelab
- [ ] TTImp.Utils
- [ ] TTImp.WithClause
