# Code Generation and Backends

During code generation, the following steps are performed (more or less in this
order):

Modules:

* `Core.CompileExpr`: TODO
* `Core.CompileExpr.Pretty`: Pretty printer for `CDef` (using `NamedCExp` internally)
* `Core.Ord`: `Ord` implementation for `CExp`

* `Compiler.Common`: Provides the following data types and utilities
  * `Codegen`: a record type, which describes
      * how to compile a `ClosedTerm` and write the generated code to a file
      * how to compile and execute a `ClosedTerm` directly
      * how to incrementally compile source files (not all code generators support
        this)
  * `UsePhase`: Enum type describing the IRs (intermediate representations) currently
    available for code generation.
  * `CompileData`: Record containing compiled expressions in different IRs.
    If we are not interested in one of the lower level IRs, the corresponding
    lists will be empty.

  
