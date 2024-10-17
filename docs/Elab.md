# Elaboration

At the heart (or core) of Idris lies the elaborator. In this section, I'm going
to look at different aspects of elaboration. I'm by no means an expert in these
things, so there might be some gaping holes and wrong assumptions.

## Point of Entry: `TTImp.Elab.Check.processDecl`

From a module processing point of view, the main entry point into elaboration
is function `TTImp.Elab.Check.processDecl`. This takes a top-level declaration
(of type `TTImp.TTImp.ImpDecl`) and processes it via a pattern match and calls
to the necessary subroutines.

Function `processDecl` takes several additional arguments, the meaning of
which are described below:

* `List ElapOpt`: Optional flags used during elaboration. Here are the
  available flags and their meaning:
  * `HolesOkay`: This is set in `TTImp.ProcessType.processType` when invoking
    `checkTerm` but seems not to be used there.
  * `InCase`: This is set in `TTImp.Elab.Case.caseBlock` to inform that we
    are currently in a case block. It affects the behavior of several parts
    of the elaborator.
  * `InTrans`: Informs that we are elaborating a `%transform` declaration.
    It is set in `TTImp.ProcessTransform.processTransform` and affects
    unification of holes (see `Core.UnifyState.checkUserHolesAfter`).
  * `InPartialEval`: Informs that we are elaborating a specialised version
    of a function (TODO).
* `NestedNames`: Defined in module `TTImp.TTImp`.

## Case Trees

Case expressions and pattern matches are converted to *case trees* during
elaboration, which are then used for coverage and termination checking, and
finally code generation. It can be illuminating to inspect the generated
case tree of a top-level function at the REPL using the `:di` command.

Case trees offer several utilities for working with data types and their
constructors.

Modules:

* `Core.Case.CaseTree`: Case tree data definitions.
  * `CaseTree`: A case tree in A-normal form, that is, it matches on
    variables only, not on expressions. Constructors:
    * `Case`: A `case` expression matching on a variable and listing
      the possible alternatives (see `CaseAlt`). The type of the
      scrutinee is also given.
    * `Term`: Right hand side term that needs no further inspection.
    * `Unmatched`: An error message for a missing case in a partial match.
    * `Impossible`: An impossible case.
  * `CaseAlt`: A type for the alternatives in a case tree. Constructors:
    * `ConCase`: Pattern match on a data constructor.
    * `DelayCase`: Lazy match used for codata.
    * `ConstMatch`: Pattern match on a literal.
    * `DefaultCase`: Catch-all pattern.
  * `Pat`: While case trees are flat (no nested patterns on the left-hand side),
    general Idris pattern matches are not. A nested pattern on the LHS
    is represented by data type `Pat`. Constructors:
    * `PAs`: As *as pattern* (`x@(S k)`)
    * `PCon`: Pattern match on a data constructor with a list of nested patterns
    * `PTyCon`: Pattern match on a type constructor
    * `PConst`: Pattern match on a literal
    * `PArrow`: No idea (TODO)
    * `PLazy`: Something to do with lazyness (doh!) (TODO)
    * `PLoc`: A local variable
    * `PUnmatchable`: No idea (TODO)
* `Core.Case.CaseBuilder`: Core machinery for building case trees from definitions.
* `Core.Case.CaseTree.Pretty`: Pretty printers for case trees
* `Core.Case.Util`: Some utilities for working with case trees and
  data constructors:
  * `getCons` returns all data constructors for a type that is in normalized form

## Coverage Checking

Modules:

* `TTImp.Impossible`: Function `getImpossibleTerm` converts a
  `RawImp` to a `ClosedTerm` to be used during coverage checking.
* `Core.Coverage`: Implements coverage checks. Provides functionality
  for traversing a case tree and ticking of matched data constructors.

## Termination Checking

Modules (TODO):

* `Core.Termination`
* `Core.Termination.CallGraph`
* `Core.Termination.Positivity`
* `Core.Termination.References`
* `Core.Termination.SizeChange`

## Normalization

Modules (TODO):

* `Core.Normalise`
* `Core.Normalise.Convert`
* `Core.Normalise.Eval`
* `Core.Normalise.Quote`
* `Core.Value`

## Unification

Modules (TODO):

* `Core.UnifyState`
* `Core.Unify`
* `Core.AutoSearch`: Implements `Core.Unify.search`

## Elaboration

Modules:

* `TTImp.Utils`: Lots of utilities used during elaboration (TODO)
* `TTImp.BindImplicits`: Utilities for generating bindings for parameters.
* `TTImp.Elab.Check`: Interface for main checker function plus additional
  functionality. Also defines `EState ns`, the state type used during
  elaboration.
* `Core.GetType`: Provides utility `getType` for (re)computing the type of an
  already elaborated thing.
* `Core.LinearCheck`: Implements linearity check (TODO)
* `Core.Transform`: Provides function `applyTransforms`, which is used
  for applying `%transform` rules when compiling runtime case trees
  (see `TTImp.ProcessDef.mkRunTime`).
* `TTImp.Elab.Ambiguity`: Implements ambiguity resolution.
* `TTImp.Elab.App`: Elaboration of function application (explicit, named,
  and auto implicit)
* `TTImp.Elab.As`: Provides `checkAs` for checking *as-patterns*
  (such as `x` in `x@(...)`).
* `TTImp.Elab.Binders`: Elaboration of binders (pi types, `let`, and lambdas)
* `TTImp.Elab.Case`: Elaboration of case blocks
* `TTImp.Elab.Delayed`: Not sure yet when this is used (TODO)
* `TTImp.Elab.Dot`: Checking dot patterns (TODO)
* `TTImp.Elab.Hole`: Elaboration of holes (TODO)
* `TTImp.Elab.ImplicitBind`: This is used for checking implicit name bindings.
  These are introduce during pattern matches and via unbound implicits as
  type variables.
* `TTImp.Elab.Lazy`: Machinery for checking delayed and forced computations.
* `TTImp.Elab.Local`: Elaboration of local definitions (in `where` blocks, I think?),
  and `ICaseLocal` things (don't know yet where this comes from: TODO)
* `TTImp.Elab.Prim`: Elaboration of primitives (of type `Constant`) converting
  them to the corresponding type and value.
* `TTImp.Elab.Quote`: Elaboration of quoted names, terms, and declarations. (TODO)
* `TTImp.Elab.Record`: Elaboration of (possibly nested) record updates
* `TTImp.Elab.Rewrite`: Elaboration of `rewrite` rules
* `TTImp.Elab.Term`: Elaboration of terms (of type `TTImp.TTImp.RawImp`). This
  is mainly a large pattern match that delegates to other modules.
* `TTImp.Elab.Utils`: Some utilities used during elaboration. I'm going to describe
  these once I understand stuff better.
* `TTImp.Elab`: Additional functions for elaborating terms. (TODO)
* `TTImp.Unelab`: This goes in the opposite direction of elaboration:
  It allows us to convert TT terms back to terms with implicits (TTImp).
  It seems to be used all over the place, so I probably should dig a bit
  deeper (TODO).

### Ambiguity Resolution

This is the process of fully qualifying partially qualified names based on
their expected types. Module `TTImp.Elab.Ambiguity` exports two major functions
that are used externally:

* `expandAmbigName`: This is invoked from `TTImp.Elab.Term.check` to resolve
  partially qualified names before checking terms. It operates on variables
  and on all kinds of function applications. Other terms are ignored.
  `IBindVar`s on the left hand side get special treatment, but I haven't looked
  at the details yet.
* `checkAlternative` (TODO)

## Processing Top-Level Declarations

In these modules, top-level (and, sometimes, nested) declarations are processed
and elaborated. All of these update the current context instead of returning
some elaborated result, because the effect of different top-level constructs
(data definitions, pragmas, transform rules, declarations and definitions)
vary a lot.

Modules:
* `TTImp.ProcessDecls`: Implements `TTImp.Elab.Check.processDecl`. This is
  the entry point into elaborating top-level declarations. Several utility
  top-level constructs such as `namespace`s or pragmas are not very hard
  to understand. For `failing` blocks, it is interesting to see that the
  global state is stored before and reset after elaborating the block
  to make sure the declarations in the `failing` block do not pollute
  the outer namespace.
* `TTImp.ProcessFnOpt`: Processes function options such as `%inline`
  or `%foreign`.
* `TTImp.ProcessBuiltin`: Utility for verifying a `%builtin` pragma.
* `TTImp.ProcessData`: Processes data definitions.
* `TTImp.ProcessDecls.Totality`: Checks totality of a group of definitions
  (for instance, of a whole source file) by invoking `Core.Termination.checkTotal`).
  Note: This is just invoke if termination info is actually required.
* `TTImp.ProcessDef`: Elaboration of function definitions. Probably the most
  complex of the `ProcessXY` source files. Definitely worth a closer look.
  TODO.
* `TTImp.ProcessParams`: Processing of `parameters` blocks. The list of
  parameters is converted to a function type, which is elaborated with
  its environment being prepended to the current environment. This way,
  all parameters can be read from the environment when elaborating
  the declarations in the block.
* `TTImp.ProcessRecord`: Processing record types, which includes adding getters
  for the record's fields.
* `TTImp.ProcessRunElab`: Processes a `%runElab` directive.
* `TTImp.ProcessTransform`: Processing of `%transform` rules.
* `TTImp.ProcessType`: Processes a function declaration. This includes
  verifying that the function name has not already been defined in the
  current namespace, finding inferrable argument types, and checking its type
  and converting it to closed term.
* `TTImp.WithClause`: Utilities for processing `with` clauses (TODO)
* `TTImp.PartialEval`: Exports `applySpecialise`, which implements
  function specialisation (via `%spec` pragmas) (TODO)

## Elaborator Reflection

TODO

Modules:
* `Core.Reflect`: Some utilities plus two interfaces (`Reflect` and `Reify`) used
  during elaborator reflection. Plus lots of implementations for these interfaces.
* `TTImp.Reflect`: Additional implementations of `Reflect` and `Reify` interfaces.
* `TTImp.Elab.RunElab`: Main driver for elaborator reflection. TODO
