module Digest.Pretty.Context

import Derive.Prelude
import Data.Buffer
import public Core.Context
import public Digest.Pretty.TTImp
import public Idris.Syntax
import Libraries.Data.IOArray
import Libraries.Data.IntMap
import Libraries.Data.NameMap
import Libraries.Data.UserNameMap
import Libraries.Utils.Binary
import Libraries.Utils.Scheme
import Core.CompileExpr
import Core.Env

%language ElabReflection

export
PrettyVal v => PrettyVal (NameMap v) where
  prettyVal = prettyVal . NameMap.toList

export
PrettyVal v => PrettyVal (IntMap v) where
  prettyVal = prettyVal . IntMap.toList

export
PrettyVal v => PrettyVal (UserNameMap v) where
  prettyVal = prettyVal . UserNameMap.toList

export
PrettyVal (Ref x y) where prettyVal _ = Con "ref" []

export
PrettyVal Buffer where prettyVal _ = Con "buf" []

%runElab deriveIndexed "PrimFn" [PrettyVal]

-- %runElab deriveMutual
--   [ "NamedDef"
--   , "NamedCExp"
--   , "CFType"
--   , "ConInfo"
--   , "NamedConAlt"
--   , "NamedConstAlt"
--   ] [PrettyVal]
-- 
-- export
-- PrettyVal ForeignObj where prettyVal _ = Con "fgnObj" []
-- 
-- %runElab deriveIndexed "SchemeObj" [PrettyVal]
-- %runElab derive "SchemeMode" [PrettyVal]
-- %runElab derive "SizeChange" [PrettyVal]
-- 
-- export
-- PrettyVal SCCall where
--   prettyVal v = ?foo
-- 
-- export
-- PrettyVal (CExp n) where
--   prettyVal v = ?bar
-- 
-- %runElab derive "Core.TT.Covering" [PrettyVal]
-- %runElab derive "Core.TT.Terminating" [PrettyVal]
-- %runElab derive "Core.TT.Totality" [PrettyVal]
-- %runElab derive "DefFlag" [PrettyVal]
-- %runElab derive "Def" [PrettyVal]
-- %runElab derive "CDef" [PrettyVal]
-- %runElab derive "GlobalDef" [PrettyVal]
-- %runElab derive "Binary" [PrettyVal]
-- %runElab derive "UConstraint" [PrettyVal]
-- %runElab derive "PossibleName" [PrettyVal]
-- %runElab derive "ContextEntry" [PrettyVal]
-- %runElab derive "Context" [PrettyVal]
