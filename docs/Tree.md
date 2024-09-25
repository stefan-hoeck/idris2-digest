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
