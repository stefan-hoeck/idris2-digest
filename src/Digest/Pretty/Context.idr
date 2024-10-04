module Digest.Pretty.Context

import Data.List.Quantifiers
import Derive.Prelude
import Data.Buffer
import public Core.Context
import public Digest.Pretty.TTImp
import public Idris.Syntax
import Libraries.Data.IOArray
import Libraries.Data.IntMap
import Libraries.Data.NameMap
import Libraries.Data.SparseMatrix
import Libraries.Data.UserNameMap
import Libraries.Data.StringMap
import Libraries.Data.StringTrie
import Libraries.Utils.Binary
import Libraries.Utils.Scheme
import Core.CompileExpr
import Core.Env
import Core.Case.CaseTree
import Core.Options.Log

%language ElabReflection
%hide Language.Reflection.TTImp.Clause

export
PrettyVal v => PrettyVal (NameMap v) where
  prettyVal = prettyVal . NameMap.toList

export
PrettyVal LogLevels where
  prettyVal _ = Con "loglevels" []

export
PrettyVal v => PrettyVal (IntMap v) where
  prettyVal = prettyVal . IntMap.toList

export
PrettyVal v => PrettyVal (StringMap v) where
  prettyVal = prettyVal . StringMap.toList

export
PrettyVal v => PrettyVal (UserNameMap v) where
  prettyVal = prettyVal . UserNameMap.toList

export
PrettyVal (Ref x y) where prettyVal _ = Con "ref" []

export
PrettyVal Buffer where prettyVal _ = Con "buf" []

%runElab derive "HoleInfo" [PrettyVal]
%runElab derive "PMDefInfo" [PrettyVal]
%runElab derive "TypeFlags" [PrettyVal]
%runElab derive "HoleFlags" [PrettyVal]

envToLst : Env Term ns -> List Value
envToLst []          = []
envToLst (bd :: rho) = prettyVal bd :: envToLst rho

export %inline
PrettyVal (Env Term ns) where
  prettyVal = Lst . envToLst

export
PrettyVal (ns ** (Env Term ns, Term ns, Term ns)) where
  prettyVal (ns ** (x,y,z)) =
    InfixCons (prettyVal ns) [("**",Tuple (prettyVal x) (prettyVal y) [prettyVal z])]

export
PrettyVal Def where
  prettyVal None = Con "None" []
  prettyVal (PMDef a b c d e) = con "PMDef" [a,b,c,d,e]
  prettyVal (ExternDef x) = con "ExternDef" [x]
  prettyVal (ForeignDef x y) = con "ForeignDef" [x,y]
  prettyVal (Builtin f) = con "Builtin" [f]
  prettyVal (DCon x y z) = con "DCon" [x,y,z]
  prettyVal (TCon x y a b c d e f) = con "TCon" [x,y,a,b,c,d,e,f]
  prettyVal (Hole x y) = con "Hole" [x,y]
  prettyVal (BySearch x y z) = con "BySearch" [x,y,z]
  prettyVal (Guess x y z) = con "Guess" [x,y,z]
  prettyVal ImpBind = Con "ImpBind" []
  prettyVal (UniverseLevel i) = con "UniverseLevel" [i]
  prettyVal Delayed = Con "Delayed" []

export
PrettyVal ForeignObj where prettyVal _ = Con "fgnObj" []

%runElab derive "Constructor" [PrettyVal]
%runElab derive "DataDef" [PrettyVal]
%runElab derive "Clause" [PrettyVal]
%runElab derive "ConInfo" [PrettyVal]
%runElab derive "DefFlag" [PrettyVal]
%runElab derive "InlineOk" [PrettyVal]
%runElab derive "SizeChange" [PrettyVal]
%runElab derive "SCCall" [PrettyVal]
%runElab derive "SchemeMode" [PrettyVal]
%runElab deriveIndexed "SchemeObj" [PrettyVal]

%runElab deriveParam
  [ PI "CExp" allIndices [PrettyVal]
  , PI "CConAlt" allIndices [PrettyVal]
  , PI "CConstAlt" allIndices [PrettyVal]
  ]

%runElab deriveMutual
  [ "NamedCExp"
  , "NamedConAlt"
  , "NamedConstAlt"
  ] [PrettyVal]

%runElab derive "CFType" [PrettyVal]
%runElab derive "CDef" [PrettyVal]
%runElab derive "NamedDef" [PrettyVal]
%runElab derive "PartialReason" [PrettyVal]
%runElab derive "Core.TT.Covering" [PrettyVal]
%runElab derive "Core.TT.Terminating" [PrettyVal]
%runElab derive "Core.TT.Totality" [PrettyVal]
%runElab derive "GlobalDef" [PrettyVal]
%runElab derive "Binary" [PrettyVal]
%runElab derive "UConstraint" [PrettyVal]
%runElab derive "PossibleName" [PrettyVal]
%runElab derive "ContextEntry" [PrettyVal]
%runElab derive "Context" [PrettyVal]
%runElab derive "Core.Options.CG" [PrettyVal]
%runElab derive "Core.Options.PairNames" [PrettyVal]
%runElab derive "Core.Options.RewriteNames" [PrettyVal]
%runElab derive "PrimNames" [PrettyVal]
%runElab derive "ElabDirectives" [PrettyVal]
%runElab derive "PPrinter" [PrettyVal]
%runElab derive "Dirs" [PrettyVal]
%runElab derive "Session" [PrettyVal]
%runElab derive "LangExt" [PrettyVal]
%runElab derive "Core.Options.Options" [PrettyVal]
%runElab derive "Transform" [PrettyVal]
%runElab derive "Warning" [PrettyVal]
%runElab derive "Defs" [PrettyVal]
