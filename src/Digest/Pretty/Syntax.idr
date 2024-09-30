||| `PrettyVal` implementations for high-level syntax trees.
module Digest.Pretty.Syntax

import Data.List.Quantifiers.Extra
import Derive.Prelude
import public Digest.Pretty.TTImp
import public Idris.Syntax

import System

%language ElabReflection

%runElab derive "OpStr'" [PrettyVal]
%runElab derive "HidingDirective" [PrettyVal]
%runElab derive "LangExt" [PrettyVal]

prettyDir : Directive -> Value

prettyLHS : PrettyVal a => OperatorLHSInfo a -> Value

export
PrettyVal Directive where prettyVal = prettyDir

export
PrettyVal a => PrettyVal (OperatorLHSInfo a) where prettyVal = prettyLHS

%runElab deriveMutual
  [
    "PWithProblem'"
  , "Pass"
  , "PFnOpt'"
  , "PDecl'"
  , "PField'"
  , "PClause'"
  , "PTypeDecl'"
  , "PDataDecl'"
  , "PRecordDecl'"
  , "PFieldUpdate'"
  , "PDo'"
  , "PStr'"
  , "PTerm'"
  ] [PrettyVal]

prettyDir (Hide x)                    = con "Hide" [x]
prettyDir (Unhide x)                  = con "Unhide" [x]
prettyDir (Logging x)                 = con "Logging" [x]
prettyDir (LazyOn x)                  = con "LazyOn" [x]
prettyDir (UnboundImplicits x)        = con "UnboundImplicits" [x]
prettyDir (AmbigDepth x)              = con "AmbigDepth" [x]
prettyDir (PairNames x y z)           = con "PairNames" [x, y, z]
prettyDir (RewriteName x y)           = con "RewriteName" [x, y]
prettyDir (PrimInteger x)             = con "PrimInteger" [x]
prettyDir (PrimString x)              = con "PrimString" [x]
prettyDir (PrimChar x)                = con "PrimChar" [x]
prettyDir (PrimDouble x)              = con "PrimDouble" [x]
prettyDir (PrimTTImp x)               = con "PrimTTImp" [x]
prettyDir (PrimName x)                = con "PrimName" [x]
prettyDir (PrimDecls x)               = con "PrimDecls" [x]
prettyDir (CGAction x y)              = con "CGAction" [x, y]
prettyDir (Names x y)                 = con "Names" [x, y]
prettyDir (StartExpr x)               = con "StartExpr" []
prettyDir (Overloadable x)            = con "Overloadable" [x]
prettyDir (Extension x)               = con "Extension" [x]
prettyDir (DefaultTotality x)         = con "Defaulttotality" [x]
prettyDir (PrefixRecordProjections x) = con "PrefixRecordProjections" [x]
prettyDir (AutoImplicitDepth x)       = con "AutoImplicitDepth" [x]
prettyDir (NFMetavarThreshold x)      = con "NFMetavarThreshold" [x]
prettyDir (SearchTimeout x)           = con "SearchTimeout" [x]
prettyDir (ForeignImpl x y)           = con "ForeignImpl" [x, y]

prettyLHS (NoBinder x)             = con "NoBinder" [x]
prettyLHS (BindType x y)           = con "BindType" [x, y]
prettyLHS (BindExpr x y)           = con "BindExpr" [x, y]
prettyLHS (BindExplicitType x y z) = con "BindExplicitType" [x, y, z]

%runElab derive "Import" [PrettyVal]
%runElab derive "Module" [PrettyVal]
