# Elaboration

At the heart (or core) of Idris lies the elaborator. In this section, I'm going
to look at different aspects of elaboration. I'm by no means an expert in these
things, so there might be some gaping holes and wrong assumptions.

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
