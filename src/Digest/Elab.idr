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
  -- set the current namespace in the global context to the name
  -- of the module we are processing
  setNS (miAsNamespace m.moduleNS)

  -- desugar to TTImp
  ds <- desugarModule m

  -- process all module declarations
  traverse_ (Check.processDecl [] (MkNested []) []) ds

prog : Module -> Name -> Core ()
prog m n = do
  refs <- initRefs
  elabModule m
  defs      <- get Ctxt
  [(_,_,v)] <- lookupCtxtName n defs.gamma | _ => pure ()
  vr        <- full defs.gamma v
  dump vr

declName : List String -> Name
declName (h::_) = fromString h
declName _      = "test"

main : IO ()
main = run $ do
  (mod,ts) <- readModule
  m        <- parseModule mod
  prog m (declName ts)
