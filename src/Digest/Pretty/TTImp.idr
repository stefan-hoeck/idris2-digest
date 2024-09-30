||| `PrettyVal` implementations for `TTImp` terms and declarations.
module Digest.Pretty.TTImp

import Data.List.Quantifiers.Extra
import Derive.Prelude
import public Digest.Pretty.TT

%language ElabReflection

export
PrettyVal (NestedNames n) where
  prettyVal v = Con "nested_names" []

declImpl : PrettyVal n => ImpDecl' n -> Value

export
PrettyVal n => PrettyVal (ImpDecl' n) where
  prettyVal = declImpl

%runElab deriveMutual
  [ "RawImp'"
  , "IFieldUpdate'"
  , "AltType'"
  , "FnOpt'"
  , "ImpTy'"
  , "ImpData'"
  , "IField'"
  , "ImpRecord'"
  , "ImpClause'"
  ] [PrettyVal]

declImpl (IClaim _ x y z u)   = con "IClaim" [x, y, z, u]
declImpl (IData _ x y z)      = con "IData" [x, y, z]
declImpl (IDef _ x y)         = con "IDef" [x, y]
declImpl (IParameters _ x y)  = con "IParameters" [x, y]
declImpl (IRecord _ x y z u)  = con "IRecord" [x, y, z, u]
declImpl (IFail _ x y)        = con "IFail" [x, y]
declImpl (INamespace _ x y)   = con "INamespace" [x, y]
declImpl (ITransform _ x y z) = con "ITransform" [x, y, z]
declImpl (IRunElabDecl _ x)   = con "IRunElabDecl" [x]
declImpl (IPragma _ x y)      = con "IPragma" [x]
declImpl (ILog x)             = con "ILog" [x]
declImpl (IBuiltin _ x y)     = con "IBuiltin" [x, y]
