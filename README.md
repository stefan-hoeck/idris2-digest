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

## Table of Content

* [Main: Point of Entry](docs/Main.md)
* [Core Functionality](docs/Core.md)
* [Packages](docs/Packages.md)
* [Syntax](docs/Syntax.md)
* [Syntax Trees and Intermediary Representations](docs/Tree.md)
* [Code Generation and Backends](docs/Codegen.md)
* [Dealing with Text: Lexing, Parsing, and Pretty Printing](docs/Text.md)
* [Utility Modules in `Libraries`](docs/Libraries.md)

## TODO Module List

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
- [ ] Core.Coverage
- [ ] Core.Env
- [ ] Core.GetType
- [ ] Core.Hash
- [ ] Core.LinearCheck
- [ ] Core.Metadata
- [ ] Core.Normalise
- [ ] Core.Normalise.Convert
- [ ] Core.Normalise.Eval
- [ ] Core.Normalise.Quote
- [ ] Core.Options.Log
- [x] Core.Ord: `Ord` implementation for `CExp`
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
- [ ] Idris.Pretty
- [ ] Idris.Pretty.Annotations
- [ ] Idris.Pretty.Render
- [ ] Idris.ProcessIdr
- [ ] Idris.REPL
- [ ] Idris.REPL.Common
- [ ] Idris.REPL.FuzzySearch
- [ ] Idris.REPL.Opts
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
- [ ] TTImp.TTImp.Traversals
- [ ] TTImp.Unelab
- [ ] TTImp.Utils
- [ ] TTImp.WithClause
- [ ] Yaffle.Main
- [ ] Yaffle.REPL
