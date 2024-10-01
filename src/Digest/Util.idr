module Digest.Util

import Core.FC
import System
import System.File
import public Core.Core

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
readModule : Core String
readModule = do
  coreLift getArgs >>= \case
    [_,f] => Util.readFile f
    _     => pure mod1

mod1 =
  """
  module My.Module

  import Prelude
  import System.File
  import public Data.List.Quantifiers as Q

  %default total

  export covering %inline
  hello : IO ()
  hello = putStrLn "Hello World!"

  compute : Nat -> Nat -> Nat
  compute x y z = x + y * z
  """
