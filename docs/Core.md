# Core Functionality

In this section, I'm going to describe key functionality that is used
in most parts of the compiler code base: Options, the `Core` effect,
logging, and the main context containing all settings and definitions.

## Command-Line Options

These are handled in module `Idris.CommandLine`
where also auto-completion functionality and scripts are defined as
well as parsers for command-line options plus help texts.

* `Idris.CommandLine`: Command-line options, their parser, and help text.
* `Idris.SetOptions`: Auto-completion script, setting of session options
  (see also `Core.Options.Session`). It also contains utilities for resolving
  package directories based on package name and version number.

## Environment

Environment variables are defined in `Idris.Env`. A list of them plus
explanation is printed when running `idris2 --help`. However, some of
them require further explanation, especially since they are related
to where Idris is looking for stuff.

* `IDRIS2_PREFIX`: This is the root directory of the Idris installation.
  It is added, for instance, to the package search path (see the description
  of `Core.Options.Dirs.prefix_dir`). If not set explicitly, this defaults
  to `IdrisPaths.yprefix`.
* `IDRIS2_PACKAGE_PATH`: Colon-separated list of absolute paths where Idris
  should look for installed packages (see also the description of
  `Core.Options.Dirs.package_search_paths`).
* `IDRIS2_PATH`: Colon-separated list of absolute paths where Idris
  will look for, for instance, for `.so` files as well as installed
  build artifacts for loading modules (see also the description of
  `Core.Options.Dirs.extra_fields`).
* `IDRIS2_DATA`: Colon-separated list of absolute paths where Idris
  will look for additional support files written in the target language
  (see also the description of `Core.Options.Dirs.data_dirs`).
* `IDRIS2_LIBS`: Colon-separated list of absolute paths where Idris
  will look for additional `.so` for linking. 
  (see also the description of `Core.Options.Dirs.lib_dirs`).

Modules dealing with environment variables:

* `Idris.Env`: Environment variables used by Idris
* `IdrisPaths`: Auto-generated via `make src/IdrisPaths.idr`,
  this contains string constants for the current compiler version plus Git hash,
  as well as the prefix (installation directory).
* `Idris.Version`: Wraps the version from `IdrisPaths` in a semantic version
  (see `Libraries.Data.Version`)
* `Core.Directory`: Provides utilities for finding source and data files based
  on the environment variables. Utility `findIpkgFile` is used to recursively
  look for the first `.ipkg` file in the current directory or one of its parents.

## The `Core` Effect

Data type `Core.Core.Core` (lol) is a wrapper around `IO (Either Error t)`,
where `Error` is the compiler's error type (also defined in `Core.Core`).
It is the main effect type used in most parts of the compiler sources
and comes with custom implementations for typical combinators such as
`(>>=)`, `(<*>)`, and `traverse` for reasons of efficiency.
The content of `Core.Core` consists mostly of utilities for working with and
printing `Error`s plus the aforementioned combinators for working with
the `Core` effect type.

* `Core.Core`: The `Core` effect type and `Error` (Idris erros)
* `Idris.Error`: Pretty printing of errors and warnings

## Logging

TODO

## Mutable State

TODO

## Context

Many if not most functions in the compiler make use of the application
`Context` defined in `Core.Context`. This is actually a composed record
type holding all kinds of contextual information. Below is a description
of the pieces it contains.

* `Core.Options`: Data types storing compiler options that have been read from
  command-line arguments and environment variables. The following data types
  are defined and used:
  * `Dirs`: Different directories where Idris looks for stuff
    (see also the *Directories* section below).
  * `CG`: Known code generators.
  * `PrimNames`: Names of functions used for conversion of literals.
    These are specified in the Prelude using the pragmas
    `%charLit`, `%doubleLit`, `%integerLit`, and `%stringLit`.
    Those dealing with elaborator reflection are specified in base.
  * `ElabDirective` hold settings and limits used during elaboration.
  * `Session` holds session options set via command-line arguments.
    These are processed in `Idris.SetOptions` and include settings about
    logging and timing amongst many others.
  * `PPrint` defines settings to be used when pretty printing stuff,
    especially related to names.
  * `PairNames`: TODO (don't know yet what they are used for)
  * `RewriteNames`: TODO (don't know yet what they are used for)
  * `Options` is a record type used for grouping the above mentioned
    options plus some additional ones such as currently active language
    extensions.

### Directories

It is illuminating to know in which directories Idris will look for information.
Record type `Core.Options.Dirs` lists most of these. Here's a list of
its fields:

* `working_dir`: The current working directory. Relative paths are relative
  to this directory.
* `source_dir`: Optional relative path where Idris will look for source files.
  Can be set in `.ipkg` files or via a command-line option. Defaults to the
  current working directory.
* `build_dir` : Relative path where build artifacts will be written to.
  Can be set in `.ipkg` files or via a command-line option and defaults to `build`.
* `depends_dir` : Relative path for local dependencies. Cannot currently be
  changed and defaults to `depends`. This is where Idris will first look for
  installed packages.
* `output_dir`: Relative path where executable programs will be written to.
  Can be set in `.ipkg` files or via a command-line option and defaults
  to `build_dir/exec`.
* `prefix_dir`: Root directory of the Idris installation. This defaults to
  `IdrisPaths.yprefix` but can be overwritten by setting the `IDRIS2_PREFIX`
  environment variable. It is added to the package search paths, but Idris
  looks also in some of its subdirectories for `.so` and support files.
* `extra_dirs`: These are the directories listed in the `IDRIS2_PATH` environment
  variable.
* `package_search_paths`: A list of paths where Idris will look for installed packages.
  Idris will look in all of these for matching packages (name plus version number)
  if it cannot find anything in the `depends_dir`.
  This includes the `pkgGlobalDirectory` (`prefix_dir/idris2-0.7.0`) plus all
  directories listed in environment variable `IDRIS2_PACKAGE_PATH`.
* `package_dirs`: This, together with `extra_dirs` is where Idris will look for
  installed build artifact. This is populated with the directories listed
  in the `IDRIS2_PATH` environment variable as well as the package installation
  directories found during package resolution.
* `lib_dirs` : These are the directories listed in the `IDRIS2_LIBS` environment
  variable. In addition, `prefix_dir/idris2-0.7.0/lib` and the current working
  directory end up in this list.
  This is where Idris will look for pre-built `.so` files to be used during
  linking.
* `data_dirs` : These are the directories listed in the `IDRIS2_DATA` environment
  variable, but also `prefix_dir/idris2-0.7.0/support` ends up in here.
  This is where Idris will look for installed support files (predefined source
  code written in the target programming language). Currently, only the JavaScript
  backends support additional support files besides the hard-coded ones.
  In addition, the `data` subdirectories in all resolved package directories
  will be added to this list (see `Idris.Package.addDeps`).
