# Dealing with Text: Lexing, Parsing, and Pretty Printing

The core functionality for dealing with text can be found in the
submodules of `Libraries.Text`, which is documented here. Code for
lexing and parsing different formats is spread across several parts
of the code base and will be discussed together with the corresponding
data types.

## Lexing

A lexer cuts a piece of text into lexicographic tokens or *lexemes*
and usually annotates them with the location (file context) in the
source code where they were found.

The most basic lexers are context-free, that is, they cut text into
lexemes based on syntactic rules only, ignoring the surrounding context.
Here is a description of the three core modules plus some utilities
used for lexing:

* `Libraries.Text.Bounded`: This defines the `Bounds` data type, a
  region in a piece of text given as the start and end row (line) and
  column. It also defines `WithBounds` a wrapper for pairing a value
  with its `Bounds` in the source text. Some basic combinators and
  utilities are also provided.
* `Libraries.Text.Lexer.Core`: This defines the `Recognise` data type,
  an algebraic data type used to define context-free lexers. It is
  indexed over a boolean to indicate if it is *productive* (always
  consumes some input) or not. The idea is that only productive
  lexers can be freely used in recursive functions because they
  are guaranteed to reduce the size of the consumed text with each
  iteration.

  Groups of lexers are described as `TokenMap`s: Lists of lexers,
  each paired with a function from `String` to a token type `a`.
  Token maps are used in functions `lex` and `lexTo` to cut
  a piece of text into lists of bounded tokens. In addition, `lexTo`
  allows us to drop unneeded tokens (whitespace, for instance).
* `Libraries.Text.Quantity`: This defines a `Quantity` data type used
  to describe regions of natural numbers (minimum plus optional maximum
  count) that are used as a means of repeating tasks in lexing
  and parsing.
* `Libraries.Text.Token`: This provides an interface `TokenKind`
  that allows us to describe a lexeme as a dependent pair of
  a "kind" data type plus a token value of a type matching the
  token's kind. A `Token` is then a kind of token plus a string
  that was recognized as a token of this kind.
* `Libraries.Text.Lexer`: This provides additional utilities for
  defining all kinds of common lexers.
* `Libraries.Text.Lexer.Tokenizer`: This adds some context to the
  basic lexers we looked at so far: Data type `Tokenizer` allows us
  to tokenize text based on the current context. A starting lexer
  is used to identify certain regions in the text that must then
  begin and end with an opening and closing lexeme (for instance,
  pairs of parentheses or quotes). This muddles the boundaries
  between lexing and parsing but can sometimes be useful to
  tokenize complex language mixes such as interpolated string
  literals.
* `Libraries.Text.Literate`: Lexing utilities for embedding source
  code in other file formats (also called *literate* source documents).
  This allows us to, for instance, embed Idris source code in markdown and LaTeX files
  and use these files both for generating nicely formatted text documents
  and at the same time treat them as valid Idris source files that
  can be type-checked and used as regular modules in larger Idris
  projects.
* `Parser.Lexer.Common`: Lexers for single-line comments, identifiers
  and namespaces.
* `Parser.Lexer.Source`: A data type and lexer for Idris source file tokens.
  Most of these are simple and easy to understand: Literals, identifiers
  and namespaces, pragmas, and so on. The real complexity comes fro
  tokenizing interpolated strings and the resulting mutual relation
  between the string tokenizer and the one used for everything else.

## Parsing

While a lexer typically generates lexicographic tokens independent of
the current context, a parser typically puts the *lexemes* into context.
Parsing consists of basic tasks such as matching opening and closing
parentheses, but also identifying groups of tokens that are part of
a larger syntactic construct such as a function definitions and
implementations. In case of source code, the result of parsing is
typically a syntax tree: A heterogeneous tree type describing the
structure of an Idris program. Parsers are also used for reading
`.ipkg` files and command-line options (the latter is not based on
`Libraries.Text.Parser`).

One of the most important tasks of a parser for programming languages is
to generate coherent error messages in case of invalid syntax or type
errors. This can be very hard to achieve and leads to a considerable
increase in complexity in even the most basic parsers.

* `Libraries.Text.Parser.Core`: Defines the `Grammar` algebraic data type
  used to describe the grammars of different types of languages. Conceptually,
  a grammar is a monad, but since `Grammar` is also indexed by a boolean
  indicating if it is productive or not, this module provides custom
  implementations for the usual monadic and applicative operators.
  Besides a couple of well documented utilities, this provides functions
  `parse` and `parseWith` for converting lists of lexemes with bounds
  to Idris values. This also shows that in general parsing comes after
  lexing.
* `Libraries.Text.Parser`: This provides some additional grammar rules
  that are often used in parsers.
* `Libraries.Utils.Path`: A data type (`Path`) for working with relative
  and absolute file paths as well as a lexer and parser for reading
  `Path`s from strings. In addition, this contains utility functions
  for dealing with paths in `String` form (making use of `Path`
  and its parser internally).
* `Core.FC`: Provides data type `FC` for describing *file contexts*.
  Every piece of information in a syntax or program tree is usually annotated
  with the corresponding file context, because this will be used for
  generating error messages that point to the right location in the code
  as well as when defining semantic tokens (for semantic highlighting).
  Module `Core.FC` provides quite a few utilities for creating, inspecting,
  and manipulating (for instance, merging) file contexts. 
* `Parser.Rule.Source`: Additional utilities for parsing Idris source code
  with support for semantic decorations.
* `Parser.Support.Escaping`: Unescaping string literals.
* `Parser.Support`: Some utilities for working with errors and unescaping
  `Char` literals.
* `Parser.Source`: Utilities for parsing source files over a
  `Parser.Rule.Source.ParsingState`.
* `Parser.Unlit`: Extracting and embedding Idris code in literate text
  (from literate source files).
* `Idris.Parser`: Parser of the high-level source language as well as
  REPL commands, their parsers, and help text.
* `Idris.Parser.Let`: Utility parser for `let` expressions and
  definitions (also, `let` in `do` notation).

## Pretty Printing

Pretty printing is all about presenting information in a clean, human
readable and nicely formatted form. This is used for generating all kinds
of output that is supposed to be read by humans instead of by machines.
Module `Libraries.PrettyPrint.Prettyprinter` and its submodules provide
an extensive and powerful pretty printer that is - unfortunately - a bit
too slow for code generation, so there is another much more basic pretty
printer currently in use in the JavaScript backends.

* `Libraries.Text.PrettyPrint.Prettyprinter`: Just re-exports the `Doc` and
  `Symbols` submodules.
* `Libraries.Text.PrettyPrint.Prettyprinter.Doc`: Defines the `Doc` data type
  (plus related types) used to define a syntax tree of pretty printed text that
  can be converted to a `SimpleDocStream` by means of several `layout*` functions
  adhering to different layout rules. Simple doc streams can be converted to
  strings or printed directly to an output stream or open file.

  Note that both `Doc`s and `SimpleDocStream`s are parameterized and can be
  annotated with additional instructions such as text styling rules that can
  be used (or ignored) by rendering functions.
* `Libraries.Text.PrettyPrint.Prettyprinter.Render.HTML`: Provides only `htmlEscape`
  for correctly escaping text in HTML documents.
* `Libraries.Text.PrettyPrint.Prettyprinter.Render.String`: Functionality for
  converting `SimpleDocStream`s to strings or printing them directly to
  standard output.
* `Libraries.Text.PrettyPrint.Prettyprinter.Render.Terminal`: Rendering function
  with support for ANSI terminal colors and text styles.
* `Libraries.Text.PrettyPrint.Prettyprinter.SimpleDocTree`: Another syntax tree
  more suitable for rendering structured text such as HTML documents. Comes with
  `fromStream` for converting `SimpleDocStream`s.
* `Libraries.Text.PrettyPrint.Prettyprinter.Symbols`: List of single character
  symbols as `Doc ann` values plus utilities for putting documents in different
  types of quotes and parentheses.
* `Libraries.Text.PrettyPrint.Prettyprinter.Util`: A few more utilities for
  working with pretty printers.
* `Idris.Pretty.Annotations`: A data type (`IdrisSyntax`) for semantic
  tokens used as annotations in pretty printing.
* `Idris.Pretty.Render`: Utilities for pretty rendering at the REPL
  based on REPL options (with and without ANSI colors, for instance).
* `Idris.Pretty`: Additional types and utilities for pretty printing and
  annotating Idris tokens plus a corresponding ANSI coloring scheme. In
  addition, this provides a pretty printer for (unelaborated) `IPTerm`s
  and `Import` statements.
