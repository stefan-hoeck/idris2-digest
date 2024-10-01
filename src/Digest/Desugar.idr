module Digest.Desugar

import Digest.Parse
import Digest.Context
import Digest.Pretty.TTImp

import Idris.Desugar
import System

||| Desugars the declarations in a module.
export
desugarModule : Refs => Module -> Core (List $ ImpDecl)
desugarModule m = join <$> traverse (desugarDecl []) m.decls

export
prog : Module -> Core ()
prog m = do
  refs <- initRefs
  ds   <- desugarModule m
  traverse_ (coreLift . putPretty) ds

main : IO ()
main =
  let Just m := parseModule mod1 | Nothing => die "invalid module"
   in coreRun (prog m) (\_ => pure ()) pure
