||| Keeping track of mutable references
module Digest.Context

import Compiler.Common
import Core.InitPrimitives
import Core.Directory
import Idris.Package.Types
import Idris.SetOptions
import IdrisPaths
import Libraries.Utils.Path

import Digest.Pretty.Context
import Digest.Util

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
|||
||| This is a minimal setup: You can load modules from the Prelude
||| and base, but not from other libraries. It is for testing only.
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

  -- Update the environment so that the key directories where we
  -- are looking for installed packages will be set up.
  setPrefix yprefix
  addPackageSearchPath !pkgGlobalDirectory
  addPkgDir "prelude" anyBounds
  addPkgDir "base" anyBounds
  pure (R ds syn opts ust meta)

||| Pretty prints a value to standard output
export %inline
dump : PrettyVal a => a -> Core ()
dump =  coreLift . putPretty

||| Dumps all definitions.
|||
||| Caution: This will generate a lot of output and typically last several
||| seconds up to several minutes depending on how many modules (and imports!)
||| have been loaded.
|||
||| However, it can be highly illuminating to inspect what's going on in here.
export %inline
dumpDefs : Refs => Core ()
dumpDefs = get Ctxt >>= dump
