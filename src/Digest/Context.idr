||| Keeping track of mutable references
module Digest.Context

import Compiler.Common
import Core.InitPrimitives
import public Core.Context
import public Core.Core
import public Core.Metadata
import public Core.UnifyState
import public Idris.REPL.Opts
import public Idris.Syntax

%default covering

||| Mutable references typically used in stateful computations
public export
record Refs where
  [noHints]
  constructor R
  defs : Ref Ctxt Defs
  syn  : Ref Syn SyntaxInfo
  opts : Ref ROpts REPLOpts
  ust  : Ref UST UState
  meta : Ref MD Metadata

--------------------------------------------------------------------------------
-- Hints
--------------------------------------------------------------------------------

export %inline %hint
toDefs : Refs => Ref Ctxt Defs
toDefs @{r} = r.defs

export %inline %hint
toSyn : Refs => Ref Syn SyntaxInfo
toSyn @{r} = r.syn

export %inline %hint
toOpts : Refs => Ref ROpts REPLOpts
toOpts @{r} = r.opts

export %inline %hint
toUst : Refs => Ref UST UState
toUst @{r} = r.ust

export %inline %hint
toMeta : Refs => Ref MD Metadata
toMeta @{r} = r.meta

--------------------------------------------------------------------------------
-- Initializes
--------------------------------------------------------------------------------

||| Initialized the mutable global state to reasonable defaults
export
initRefs : Core Refs
initRefs = do
  -- initialize definitions...
  defs <- initDefs
  -- ... and write them to a mutable reference
  ds   <- newRef Ctxt defs
  -- add primitive functions known to Idris
  addPrimitives @{ds}

  -- initialize syntax options and write them to a mutable reference
  syn  <- newRef Syn initSyntax

  -- initialize REPL options and write them to a mutable reference
  opts <- newRef ROpts (defaultOpts Nothing (REPL NoneLvl) [])

  -- initialize unification state and write it to a mutable reference
  ust  <- newRef UST initUState

  -- initialize meta data and write it to a mutable reference
  meta <- newRef MD (initMetadata $ Virtual Interactive)
  pure (R ds syn opts ust meta)
