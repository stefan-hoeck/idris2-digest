module Digest.Util

import Core.FC
import Data.String
import Data.List1
import System
import System.File
import public Core.Core
import public Core.Name
import public Core.Name.Namespace

||| The default `OriginDesc` we use in our experiments.
export
virt : OriginDesc
virt = Virtual Interactive

||| Tries to read a file as single block of text.
export
readFile : String -> Core String
readFile s = do
  e <- coreLift (readFile s)
  either (coreFail . Fatal . FileErr s) pure e

||| Runs a `Core` program, printing any error to standard output.
export
run : Core () -> IO ()
run p = coreRun p (\x => printLn x) pure

||| A small example module.
export
mod1 : String

||| Reads the file given as the sole command-line argument. Otherwise
||| returns `mod1`.
export
readModule : Core (String, List String)
readModule = do
  coreLift getArgs >>= \case
    (_::f::t) => (,t) <$> Util.readFile f
    _         => pure (mod1, [])

export
FromString Name where
  fromString s =
    let (ns,n) := mkNamespacedIdent s
     in mkNamespacedName ns (Basic n)
      

mod1 =
  """
  module My.Module

  import Prelude

  %default total

  export
  test : Nat
  """
