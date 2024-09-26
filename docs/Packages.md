# Packages

Idris packages are defined in `.ipkg` files, which list a package's
dependencies, the modules it exports, additional fields for building
and installing, plus information about the author(s) and
licensing. The following modules are relevant:

* `Idris.Package.Types`: Defines the `PkgDesc` type, a record type
  listing all the fields that can be specified in an `.ipkg` file.
  This module also defines data types `PkgVersion` and `VersionBounds`
  plus utilities for comparing package version bounds.
  Finally, it contains a pretty printer for `PkgDesc`, which can be
  used to generate `.ipkg` files from the Idris type.
* `Idris.Package.Init`: Utilities for (interactively) setup a new
  Idris project plus corresponding `.ipkg` file.
* `Idris.Package.ToJson`: Utilities for exporting `.ipkg` files to
  the JSON format.
* `Idris.Package`: Parser for `.ipkg` files plus utilities used during
  (transitive) dependency resolution. Finally, this module also contains
  the runner for processing packaging commands such as `--build`,
  `--install`, or `--mkdorcs`.
* `Parser.Lexer.Package`: Provides the token type and lexing rules used
  for tokenizing `.ipkg` files.
* `Parser.Rule.Package`: Basic rules for parsing `.ipkg` files.
* `Parser.Package`: Re-exports `Parser.Rule.Package` and `Parser.Lexer.Package`
  and provides two utilities for parsing `.ipkg` files.

## Package Processing

TODO (`Idris.Package.processPackageOpts`)

### Finding and processing `.ipkg` Files

This tries do find an `.ipkg` file and - if successful - changes
the working directory to the file's root directory and adjusts
the path of the main source file (if any) accordingly.

In addition, all dependencies of the `.ipkg` file are resolved transitively
(function `addDeps`), and their root directories added to the
`package_dirs` field in `Directories`.
