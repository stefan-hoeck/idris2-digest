# Elaboration

At the heart (or core) of Idris lies the elaborator. In this section, I'm going
to look at different aspects of elaboration. I'm by no means an expert in these
things, so there might be some gaping holes and wrong assumptions.

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

## Elaboration

Modules:

* `TTImp.Elab.Check`: Interface for main checker function plus additional
  functionality. Also defines `EState ns`, the state type used during
  elaboration.
* `TTImp.ProcessDecls`: Implements `TTImp.Elab.Check.processDecl`. This is
  the starting point for elaborating top-level declarations. Several utility
  top-level constructs such as `namespace`s or pragmas are not very hard
  to understand. For `failing` blocks, it is interesting to see that the
  global state is stored before and reset after elaborating the block
  to make sure the declarations in the `failing` block do not pollute
  the outer namespace.
* `TTImp.ProcessFnOpt`: Processes function options such as `%inline`
  or `%foreign`.
