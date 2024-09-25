# Syntax

* `Idris.Syntax.Pragmas` defines data type `KwPragma`, language pragmas
  and compiler instructions not associated with functions or data types.
  Its `Show` implementation shows the name of each pragma as it is used
  in source files. This module also defines the language extensions
  (currently, only `ElabReflection` is implemented).
