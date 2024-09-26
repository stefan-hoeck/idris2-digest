# Syntax Tree and Intermediary Representations

In this section we are going to look at the different tree
representations of programs during compilation. Some data types
show up in almost all of these, so we are going to look at those
as well.

## Names and Namespaces

`Name`s and `Namespace`s represent not only user-defined identifiers
but also machine generated names used during compilation, for instance,
when case trees or `where` blocks are moved to the top level.

* `Core.Name.Namespace`: Data types and utilities for working
  with namespaces and module identifiers
* `Core.Name`: Data type `UserName` defines user-defined names:
  regular identifiers, record field projections, and placeholders
  (underscores: '_'). Data type `Name` adds support for names in a
  namespace as well as machine generated names, names from `case`
  and `with` blocks, and some others.
* `Core.Name.Scoped`: While names are useful for human readability, they
  can be cumbersome when working with syntax trees. There are many
  tree conversions used throughout the compiler sources and for these
  it can be more convenient to use
  [de Bruijn indices](https://en.wikipedia.org/wiki/De_Bruijn_index). However,
  keeping track of de Bruijn indices can be error prone and cumbersome.
  Therefore, some program trees in Idris are indexed over a list
  of `Name`s: The context (or scope) of currently defined variables.
  For these terms, local variables are described as well-typed indices
  into the scope.
  This gives us lots of help from the compiler when performing
  common transformations such as substitution, where it is a type
  error if variables are not adjusted correctly.

  This module introduces aliases `Scope` (`List Name`) and
  `Scoped` (`Scope -> Type`) plus some interfaces and utilities
  for working with scoped terms (see below).

### Operations on `Scoped` Terms

I *think* I understood the ones below, but there might be others:

* *weakening*: Weakening a scope means prepending (since currently, scopes
  are lists instead of `SnocList`s) additional variables to it.
  A term can always be weakened, but the indices of all its
  bound variables must be adjusted (increased).
  Interface `Weaken` adds support for this transformation.
* *strengthening*: This removes one or more variable from the head of
  a scope. Only terms not consisting of any of the removed variables
  can be strengthened, so these functions return terms wrapped in a
  `Maybe`. Interface: `Strengthen`.
* *embedding*: A term can be *embedded* in a larger scope with additional
  variables *appended* to the list of names without further modification
  because all de Bruijn indices stay the same. Interface: `Embeddable`.
* *thinning*: A term can be added to a wider scope having additional
  variables at various indices. For instance:
  ```
  thin : Term ["x", "y", "z"] -> Term ["a", "x", "y", "b", "z"]
  ```
  This will always work but some de Bruijn indices will have to be
  adjusted, so we need to know about the exact scopes at runtime.
  Interface: `Scoped`.
* *shrinking*: This opposite of *thinning* is *shrinking* and like
  *strengthening*, this is an operation that might fail.
  Interface: `Scoped`.
* *renaming*: The variables in a term can be renamed if two scopes have
  the same number of entries. This is typically a no-op, since internally,
  variables are represented as de Bruijn indices. Interface: `Scoped`.

### Variables

As explained above, variables are represented as de Bruijn indices into
the current scope.

* `Core.TT.Var`: Defines indexed record type `Var vars`, a variable in scope
  `vars`. This wraps an erased proof of type `IsVar` plus a natural number
  corresponding to the variable's de Bruijn index. The module also
  provides implementations for the transformations described above
  (interface `Scoped`).
* `Core.TT.Subst`: I think this is about
  [substitution](https://en.wikipedia.org/wiki/Lambda_calculus), but I haven't
  figured out the details yet. It's a smallish module, so I should be able to
  eventually understand this. TODO.
* `Core.TT.Term.Subst`: Like `Core.TT.Subst` but implements substitution
  for `Term`s.
* `Core.Env`: Provides data type `Env tm vars` for listing the types and
  values of local variables in a term. An environment of type `Env Term vars`
  allows us to convert a `Term vars` into a closed term (`Term []`).
  Several more utilities for working with and adjusting the environments
  of terms are provided.

## Primitives

Primitive types and functions are built into the compiler. They can be
used in all Idris programs but cannot be defined in Idris itself.
Currently, Idris comes with the following primitive types:

* `Int`
* `Int8`
* `Int16`
* `Int32`
* `Int64`
* `Integer`
* `Bits8`
* `Bits16`
* `Bits32`
* `Bits64`
* `String`
* `Char`
* `Double`
* `%World`

We can only operate on primitive values via the built-in primitive functions or
via foreign function calls. Idris can normalize closed terms involving primitives
during unification, but it knows nothing about their internal structures. Therefore,
it is for instance impossible to proof the following without resorting to
`believe_me`:

```haskell
claim : (s : String) -> length s === length (prim__strReverse s)
```

Modules:

* `Core.TT.Primitive`: Defines data types for primitive types and their values
  (`Constant`) as well as the primitive operations (`PrimFn`) operating on the primitives.
  In addition, integer types are categorized by their signdness (signed or unsigned)
  and precision (number of bits) via data types `Precision` and `IntKind`.
* `Core.Primitives`: While `Core.TT.Primitive` defines data types for describing
  primitive types, values, and their operations, `Core.Pritimtives` explicitly
  states, which primitive operation can be used with what primitive types.
  Function `allPrimitives` lists all the combinations of primitive operations
  with primitive types Idris can deal with. For instance, primitive operation
  `GTE` can be used to compare primitive values of the same type. It is
  available for all primitives except `%World`. On the other hand, primitive
  operation `BAnd` allows us to bitwise AND-ing two numbers. It is only available
  for the integral primitives.

  Exported function `getOp` is used to normalize primitive operations applied
  to constants during unification and constant folding (an optimization
  run before code generation).

  Finally, function `opName` defines the name of every specific primitive
  operation. For instance, `prim__add_Bits8` is the name of the function used
  to add two numbers of type `Bits8`. It is available to all Idris programs
  and is used in the implementation of `Num Bits8`. You can checkout its type
  and try it out in a REPL session or as part of some Idris source code.
* `Core.InitPrimitives`: This module only exports function `addPrimitives`, which
  adds all primitive operations returned by `Core.Primitives.allPrimitives` to
  the compiler's context.

## Binders

A *binder* is a syntactic construct that adds new variables to the
current context. Examples include `let` expressions and lambdas,
but also new variables introduced from pattern matches and function
signatures.

* `Core.TT.Binder`: Defines data types `PiInfo` and `Binder` plus some
  utilities and interfaces.

### Quantities

In Idris, every bound variable is annotated with a quantity (data type
`RigCount`, which is an alias for `Algebra.ZeroOneOmega.ZeroOneOmega`.
Relevant modules:

* `Algebra`: `RigCount` alias and reexport of submodules
* `Algebra.Preorder`: An interface for preorders
* `Algebra.Semiring`: An interface for semirings
* `Algebra.SizeChange`: The `SizeChange` semiring
* `Algebra.ZeroOneOmega`: The `ZeroOneOmega` (or `RigCount`) semiring

### Data type `PiInfo`

This describes the *implicitness* of a bound variable: implicit, explicit,
auto-implicit, or implicit with default. These correspond to the different
ways variables can be introduced in Idris code. Explicit variables are
manually (explicitly) passed to function, while implicit variables are usually
solved by unification or - in the case of auto-implicit variables - proof search.
Default implicit variables are assigned the default value unless given
explicitly.

`PiInfo` is parameterized, because the default-implicit data constructor has
a field for the default value.

### Data type `Binder`

This provides data constructors for the different kinds of binders Idris
knows about. They are listed and explained below. Every binder is annotated
with a file context (`FC`; see the [section about parsers](Text.md)), the
quantity (`RigCount`) and implicitness (`PiInfo`).

## Type Theory: `TT`

Below is a list of the remaining submodules of `Core.TT` and their content:

* `Core.TT.Traversals`: Contains functionality to extract all names and
  constants from a `Term` as well as (effectful) traversals and mappings of
  `Term`s.
* `Core.TT.Views`: Provides utility `underPis`. TODO: I think I understand the
  type of this but don't know what it's being used for.
* `Core.TT.Term`: Defines a data tree for elaborated terms (`Term vars`, where
  `vars` is the scope of the term) plus several utilities:
  * `NameType`: Describes where a `Name` (in a `Ref` constructor) comes from.
    `Bound` names come from binders and can be resolved to `Local` variables
    in presence of a suitable scope (`resolveNames`).
  * `LazyReason`: Reason, why the evaluation of a term should be delayed.
  * `WhyErased`: Describes why a term should be erased.
  * `Term`: An elaborated term indexed by its scope. A `ClosedTerm` is a
    term with an empty scope, and therefore, `ClosedTerm` is an alias for
    `Term []`. Here is a list of the data constructors and their meaning:
    * `Local`: Bound variable as a De Bruijn index into the current scope
    * `Ref`  : Other variable (free, function name, or data or type constructor)
    * `Meta` : TODO
    * `Bind` : Declares (binds) a new variable given as a `Name` and `Binder`.
      Contains an inner term: The scope of the freshly bound variable.
    * `App`  : Function application.
    * `As`   : Not sure about this one. Is this `x@(Foo y z)`? TODO
    * `TDelayed` : Delayed evaluation of a term.
    * `TDelay` : Again delayed evaluation, this time with an attached type (?).
      Not sure, when each of the two delayed forms is used. TODO
    * `TForce` : Forces evaluation of a delayed term.
    * `PrimVal` : Primitive values (constants) and types.
    * `Erased` : An erased term wrapped in the reason why it is erased.
    * `TType`: `Type` with potential support (?) for universe levels. TODO
* `Core.TT`: More data types and utilities:
  * `KindedName`: Adds additional information to a `Name`.
  * `CList`: Don's know. Seems to be dead code.
  * `Visibility`: Enum type corresponding to `private`, `export`, and `public export`.
  * `Fixity`: Enum type corresponding to different types
     of fixity declarations (`infixl`, `infir`, `infix`, and `prefix`).
  * `BindingModifier`: This seems to be related to issue #3113, which has been
    implemented in #3120.
  * `FixityInfo`: This seems to be related to issue #3113, which has been
    implemented in #3120.
  * `FixityDeclaration`: This seems to be related to issue #3113, which has been
    implemented in #3120.
  * `OperatorLHSInfo`: This seems to be related to issue #3113, which has been
    implemented in #3120.
  * `TotalReq`: Enum type corresponding to `%total`, `%covering`, and `%partial`.
  * `PartialReason`: Data type encapsulating the different reasons why Idris
    might consider a function as being non-total.
  * `Terminating`: Data type describing if a function is total (terminating) or not.
    I assume (haven't checked yet, TODO) that this is the outcome of totality checking.
  * `Covering`: Data type describing if a function is covering or not.
    I assume (haven't checked yet, TODO) that this is the outcome of coverage checking.
  * `Totality`: Record pairing `Terminating` and `Covering`.
  * `Bounds`: TODO
  * `addVars`: TODO
  * `resolveRef`: TODO
  * `refsToLocal`: TODO
  * `refToLocal`: TODO
  * `substName`: TODO
  * `addRefs`: TODO
