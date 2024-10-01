module Digest.Desugar

import Digest.Parse
import Digest.Context
import Digest.Pretty.TTImp

import Idris.Desugar
import Idris.ProcessIdr
import System

||| Desugars the declarations in a module.
|||
||| Depending on the functions and operators used in the module,
||| this requires a properly set up context (the `Refs` argument),
||| which can be generated from `Digest.Context.initRefs`.
export
desugarModule : Refs => Module -> Core (List $ ImpDecl)
desugarModule m = do
  traverse_ addImport (imports m)
  join <$> traverse (desugarDecl []) m.decls

export
prog : Module -> Core ()
prog m = do
  refs <- initRefs
  ds   <- desugarModule m
  traverse_ (coreLift . putPretty) ds

run : Core () -> IO ()
run p = coreRun p (\x => printLn x) pure

main : IO ()
main =
  let Just m := parseModule mod1 | Nothing => die "invalid module"
   in run (prog m)
