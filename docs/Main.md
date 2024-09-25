# Main: Point of Entry

In this section, we are going to have a look at the first couple
of steps taken when invoking the `main` function, and provide links
to where additional information can be found.

## The `main` Function

The `main` function is located at `Idris.Main.main`, this just
invokes `Idris.Driver.mainWithCodegens`, which
then reads [command-line options](Core.md) and either runs a single print-only
command, or moves on and runs `stMain` in the `Core` effect
[see `Core.Core`](Core.md).

* `Idris.Main`: Main program entry point. Immediately invokes
  `Idris.Diver.mainWithCodegens`.
* `Idris.Driver`: Assembles all the pieces required for running `idris2`
