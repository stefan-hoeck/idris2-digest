# Utility Modules in `Libraries`

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

