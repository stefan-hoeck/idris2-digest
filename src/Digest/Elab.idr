module Digest.Elab

import Digest.Context
import Digest.Desugar
import Digest.Parse
import Digest.Pretty.Context
import Digest.Pretty.Holes
import Digest.Pretty.TTImp
import Digest.Util

import TTImp.Elab.Check
import Core.Env

export
elabModule : Refs => Module -> Core ()
elabModule m = do
  ds <- desugarModule m
  traverse_ (Check.processDecl [] (MkNested []) []) ds

prog : Module -> Core ()
prog m = do
  refs <- initRefs
  elabModule m
  hs   <- getUserHolesData
  dump hs

main : IO ()
main = run $ do
  mod <- readModule
  m   <- parseModule mod
  prog m
