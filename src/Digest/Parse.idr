module Digest.Parse

import Digest.Pretty.Syntax
import Digest.Util
import Idris.Parser
import System

covering
mod : EmptyRule Module
mod = prog virt

export covering
parseModule : String -> Core Module
parseModule s =
  case runParser virt Nothing s mod of
    Right (_,_,m) => pure m
    Left err      => coreFail err

-- reads the file given as the command-line argument (or loads `mod1` instead)
-- parses it into a `Idris.Syntax.Module` record and pretty-prints the result.
main : IO ()
main = run $ do
  mod <- readModule
  m   <- parseModule mod
  coreLift $ putPretty m
