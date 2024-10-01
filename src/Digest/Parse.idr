module Digest.Parse

import Digest.Pretty.Syntax
import Idris.Parser
import System

virt : OriginDesc
virt = Virtual Interactive

export
mod1 : String
mod1 =
  """
  module My.Module

  import System.File
  import public Data.List.Quantifiers as Q

  %default total

  export covering %inline
  hello : IO ()
  hello = putStrLn "Hello World!"
  """

covering
mod : EmptyRule Module
mod = prog virt

export covering
parseModule : String -> Maybe Module
parseModule s =
  case runParser virt Nothing s mod of
    Right (_,_,m) => Just m
    _             => Nothing

main : IO ()
main =
  let Just m := parseModule mod1 | Nothing => die "invalid module"
   in putPretty m
