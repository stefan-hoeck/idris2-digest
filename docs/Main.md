# Main: Point of Entry

In this section we are going to have a look at the first couple
of steps taken when invoking the `main` function, and provide links
to where additional information can be found.

## The `main` Function

The `main` function is located at `Idris.Main.main`. This just
invokes `Idris.Driver.mainWithCodegens`, which
then reads [command-line options](Core.md#command-line-options)
and either runs a single print-only
command, or moves on and runs `stMain` in the `Core` effect
[see `Core.Core`](Core.md#the-core-effect).

Modules:

* `Idris.Main`: Main program entry point. Immediately invokes
  `Idris.Diver.mainWithCodegens`.
* `Idris.Driver`: Assembles all the pieces required for running `idris2`

### `stMain`: The main Driver

In this section we are going to have a closer look at the steps
taken in the main driver based on command-line options and the
environment. Here's a simplified list of steps taken:

* Check if Yaffle should be run. Run and abort if yes. (TODO)
* Check if meta data should be dumped. Dump and abort if yes. (TODO)
* Initialize the [global context](Core.md#context) (of type `Core.Context.Defs`)
* Add custom code generators to list of code generators
* Initialize syntax info
* Set the default code generator (Chez, unless custom CGs are defined)
* Add [primitive operations](Tree.md#primitives) to the global context
* Set the current working directory to `.`
* Check if a missing `.ipkg` file should be ignored (from command-line options)
* Setup the output mode (IDE-mode or REPL) and initialize the REPL options
* Load settings from [environment variables](Core.md#environment)
* Run `showInfo`, which does exactly nothing and proudly returns `False` at the end
* Preprocess command-line options and continue if this returns `True`
* Invoke [`processPackageOpts`](Packages.md#package-processing)
  (such as `--build` or `--install`) and quit if done.
  This is the entry point into loading and building packages. It will be
  discussed in greater detail in [Packages and Modules](Packages.md).
* If we are still here, start a REPL session or IDE mode:
  * Set verbosity based on command-line options
  * Initialize unification state
  * Determine the origin based on whether we have a source file to load or not
  * Initialize meta data
  * Update REPL options by setting the preferred editor to use
  * Unless set otherwise, print the Idris banner and
    info about additional code generators (if any)
  * Find and process an `.ipkg` file if required (see [Packages and Modules](Packages.md))
  * Depending on whether a source file was specified or not, the Prelude or
    the source file is loaded (see [REPL](REPL.md)).
  * Process command-line options again to see whether a proper REPL session should
    be started or we only wanted to check one source file.
  * If we should continue, check if we should do so in IDE mode or as a REPL and
    do that by running either `Idris.REPL.repl` or `Idris.IDEMode.Repl` continuously.
