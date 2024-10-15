# Packages and Modules

Idris packages are defined in `.ipkg` files, which list a package's
dependencies, the modules it exports, additional fields for building
and installing, plus information about the author(s) and
licensing. The following modules are relevant:

* `Idris.Package.Types`: Defines the `PkgDesc` type, a record type
  listing all the fields that can be specified in an `.ipkg` file.
  This module also defines data types `PkgVersion` and `VersionBounds`
  plus utilities for comparing package version bounds.
  Finally, it contains a pretty printer for `PkgDesc`, which can be
  used to generate `.ipkg` files from values of the Idris type.
* `Idris.Package.Init`: Utilities for (interactively) setting up a new
  Idris project plus corresponding `.ipkg` file.
* `Idris.Package.ToJson`: Utilities for exporting `.ipkg` files to
  the JSON format.
* `Idris.Package`: Parser for `.ipkg` files plus utilities used during
  (transitive) dependency resolution. Finally, this module also contains
  the runner for processing packaging commands such as `--build`,
  `--install`, or `--mkdorcs`. It is described in more detail below.
* `Parser.Lexer.Package`: Provides the token type and lexing rules used
  for tokenizing `.ipkg` files.
* `Parser.Rule.Package`: Basic rules for parsing `.ipkg` files.
* `Parser.Package`: Re-exports `Parser.Rule.Package` and `Parser.Lexer.Package`
  and provides two utilities for parsing `.ipkg` files.

## Package Processing

All functions described in this section are in module `Idris.Package`
unless a different namespace is specified explicitly.

From point of view of the Idris driver, the main entry point into package
processing is function `processPackageOpts`, which partitions
command line options into one or more packaging commands plus their
settings. The commands found are then passed on to `processPackage`.

Function `processPackage` runs a pattern match on the commands it got,
but before doing so, it safes the current state of
the definitions, syntax info, and REPL options, restoring all three
once it is done.

In case of the `--init` command, `processPackage` will just run
`Idris.Package.Init.interactive` and create a new Idris
project from the information it got.

In all other cases, the command requires an `.ipkg` file, which has either
been given explicitly at the command-line or is now being searched in
the current working director (function `localPackageFile`). The working
dir is then adjusted to where the `.ipkg` file was found, the `.ipkg`
file is parsed and the `build_dir` and `output_dir` adjusted in the
current context.

Finally, a pattern match on the current command decides, which of the
packaging actions to run. Several of these check, if the current Idris
version is compatible with the one specified in the `.ipkg` file in
function `assertIdrisCompatibility`.

### Preparing Compilation

Function `prepareCompilation` processes some options and adds all
dependencies (transitively) of an `.ipkg` file via `addDeps`.
Then it runs the `prebuild` hooks, before finally building all
modules listed in the `.ipkg` file via `Idris.ModTree.buildAll`,
which is described further below.

### The `--build` and `--check` Commands

Function `build` verifies Idris compatibility and prepares for compilation.
It then checks if the `.ipkg` file describes an executable. If yes,
it compiles it using `compileMain`. Either way, the `postbuild` hooks
are run afterwards.

Function `check` is like `build`, but does not compile `main`.

Function `compileMain` initializes metadata and unification state,
then loads the main file (via `Idris.REPL.loadMainFile`), and finally
initializes [code generation](Codegen.md) by invoking
`Idris.REPL.compileExp`.

### The `--mkdoc` Command

This is run via `mkDoc`, which is quite a beast, so I'll come back later.
TODO.

### The `--install` and `--install-with-src` Commands

Runs `build` first, followed by `install`, signalling via a flag if sources
should be installed or not.

Function `install` first figures out (by inspecting the context), in what
directories stuff should be installed, before running the `preinstall` hook.
After collecting all the exported modules from the package description,
each is installed via a call to `installFrom`. Optionally, sources are installed
via `installSrcFrom`. Finally, a string representation of the package description
is generated and installed as well before running the `postinstall` hooks.

Function `installFrom`: TODO
Function `installSrcFrom`: TODO

### The `--repl` Command

Runs `build` and starts a REPL session via `runRepl`, which sets up
a new unification state and metadata context, loads the main module (if any)
via `Idris.REPL.loadMainFile`
before starting a REPL session via `Idris.REPL.repl`
(see also [The Idris REPL](REPL.idr)).

### The `--clean` Command

This iterates over all exported modules in an `.ipkg` (plus the main
module, if specified), and deletes the corresponding build artifacts
files and directories as well as generated source docs.

### Finding and processing `.ipkg` Files

Function `findIpkg` tries do find an `.ipkg` file
and - if successful - changes
the working directory to the file's root directory and adjusts
the path of the main source file (if any) accordingly.

In addition, options set in the `.ipkg` file will be set via
`Idris.SetOptions.preOptions`, and all dependencies of the `.ipkg`
file are resolved transitively
(function `addDeps`), and their root directories added to the
`package_dirs` field in `Directories` (see the section about directories
in [Core](Core.md#directories)).

## Module Trees

Modules:
* `Idris.ModTree`: This module provides the `ModTree` data type for
  describing modules and their dependencies. Function `mkModTree` is
  used to recursively assemble a `ModTree` from a starting module plus
  list of already processed modules (for cycle detection). It uses
  a mutable cache of already processed module and tries to load
  a module and its imports from a source file if it is not yet
  in the cache.

  Function `mkBuildMods` generates a sequence describing the order
  in which the modules in a `ModTree` should be built.
  Exported function `getBuildMods` unifies the functionality of
  `mkModTree` and `mkBuildMods`.

  Exported function `needsBuilding` checks, if for a given module
  there is already an up to date (by hash or by modification time)
  `.ttc` file and if all dependencies are up to date as well.

TODO: Building modules clears the context. The whole context? If yes,
doesn't this slow stuff down? I should check this out.

### Processing Modules

Modules:

* `Idris.ProcessIdr`: Reads and processes modules from source files.
  Provides functionality for checking if `.ttc` files are up to date,
  for loading imported modules, and processing whole source files.
  When a module is being processed (in `processMod`), the metadata
  of its imports is loaded (`readImportMeta`) and (after checking
  if the module is up-to-date), imports are processed in full before
  elaborating all top-level declarations via `TTImp.Elab.Check.processDecl`,
  which is the entry point into [elaboration](Elab.md).

  Note, that `processMod` expects the imported modules to have already
  been processed (transitively) (see the section about module trees
  above).


## Creating Documentation

* `Idris.Doc.Annotations`: `IdrisDocAnn`, a data type used as annotation during
  pretty printing. Includes a conversion to ANSI styles and another one to
  `Protocol.IDE.Decoration.Decoration`.
* `Idris.Doc.Brackets`: Documentation for idiom brackets and declaration quotes.
* `Idris.Doc.Display`: Utilities for displaying types and terms found in the
  current context.
* `Idris.Doc.HTML`: Utilities for generating HTML documents from module and
  declaration doc strings.
* `Idris.Doc.Keywords`: Doc strings for keywords and other language constructs.
  These are displayed in the REPL, for instance when typing `:doc case`.
* `Idris.Doc.String`: Utilities for printing documentation of names in
  the current namespace. This contains utilities for pretting printing
  types, looking up known interface implementations of a type, and printing
  documentation and implementations for built-in primitives.
  For user-defined type, `getDocsForName` prints information about a declaration's
  or constructors type, fixity, totality, and so on.
  This also prints documentation for certain syntactic forms such as literals
  (string, integer, but also list and snoclist, pairs and quotes).
* `Idris.Syntax.Views`: Some utilities used during doc generations. Haven't looked
  at them in detail yet.

## Additional Utilities and Information

We store additional information about packages such as module metadata
and source hashes. These are summarized here.

### Metadata

Modules not only provide top-level declarations that can be used in
other modules, but come with additional metadata needed elsewhere.

* `Core.Metadata`: Provides record type `Metadata` plus utilities for
  storing and retrieving information from such records. Metadata contains
  information about holes, declared types, source locations and semantic
  decorations. Metadata is stored in binary form in `.ttm` files.

### Hashes

* `Core.Hash`: Utilities for hashing module interfaces to figure out if
  a module has to be reloaded or not.
