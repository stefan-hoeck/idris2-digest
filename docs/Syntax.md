# Syntax

Idris source code gets parsed into `PDecl`s and `PTerm`s, syntax trees
for the high-level source language. This then gets simplified (desugared)
into `TTImp` (type theory with implicits), a simplified syntax tree without
syntactic sugar. 

## High-level Language

* `Idris.Syntax`: Defines a syntax tree `PTerm` for the high-level source
  language. This is what Idris source code gets parsed into.
* `Idris.Syntax.Pragmas`: Defines data type `KwPragma`, language pragmas
  and compiler instructions not associated with functions or data types.
  Its `Show` implementation shows the name of each pragma as it is used
  in source files. This module also defines the language extensions
  (currently, only `ElabReflection` is implemented).
* `Idris.Parser`: Parser of the high-level source language as well as
  REPL commands, their parsers, and help text.
* `Idris.Parser.Let`: Utility parser for `let` expressions and
  definitions (also, `let` in `do` notation).
* `Idris.Syntax.Builtin`: Contains a couple of `Name` constants with
  special syntactic meaning such as `MkPair`, `DPair`, or `Nil`.
* `Idris.Syntax.Traversals`: Provides utilities for pure and effectful
  traversals of `PTerm`s. A direct application can be found in `substFC`,
  where the file contexts in a term are replaced with a new one.

## Desugaring

Desugaring allows us to use convenient syntactic constructs such as `do`
notation, idiom brackets, infix operators, or list notation, without
complicating the underlying core language and type theory. As a first step,
typically right after parsing, the high-level syntax tree is therefore
desugared into the core language (here: `TTImp`).

* `Idris.Desugar.Mutual`: Desugars a `mutual` block into two lists
  of `PDecl`s (source language declarations): The first consisting of
  the definitions, the second of the implementations. This shows, that
  `mutual` blocks are not necessarily needed: We can just first write
  add all definitions in a source file and write the implementations
  later.
* `Idris.Desugar`: This converts high-level syntax trees to `TTImp`.
  According to the source comment at the beginning of the file, this
  includes the following:

  * Shunting infix operators into function applications according to precedence
  * Replacing 'do' notating with applications of (>>=)
  * Replacing string interpolation with concatenation by (++)
  * Replacing pattern matching binds with 'case'
  * Changing tuples to 'Pair/MkPair'
  * List notation
  * Replacing !-notation
  * Dependent pair notation
  * Idiom brackets

## Resugaring

While desugaring keeps the core language simpler, it reduces readability. Resugaring
is the process of converting core language terms back to nice high-level syntax.

* `Idris.Resugar`: Exports utilities for resugaring `RawTerm`s (`TTImp`) as well as
  `Term`s (`TT`; after unelaboration).
