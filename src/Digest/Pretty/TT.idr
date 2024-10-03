||| This modules contains `PrettyVal` implementations for most
||| data types from the Idris core language. They can be used to
||| create nicely formatted, human readable output of Idris values.
|||
||| This is useful when experimenting with what the compiler does
||| at different levels.
|||
||| Most implementations can be derived automatically using elaborator
||| reflections but a few need to be written manually due to limitations
||| in the elaborator scripts.
module Digest.Pretty.TT

import Data.List.Quantifiers.Extra
import Derive.Prelude
import public Core.Core
import public Core.Context
import public Core.Name.Namespace
import public Core.Options.Log
import public Core.TT
import public Libraries.Data.WithDefault
import public TTImp.TTImp
import public Text.Show.Pretty

%language ElabReflection
%hide Language.Reflection.TT.BuiltinType
%hide Language.Reflection.TT.Constant
%hide Language.Reflection.TT.FC
%hide Language.Reflection.TT.LazyReason
%hide Language.Reflection.TT.ModuleIdent
%hide Language.Reflection.TT.Name
%hide Language.Reflection.TT.NameType
%hide Language.Reflection.TT.Namespace
%hide Language.Reflection.TT.OriginDesc
%hide Language.Reflection.TT.PiInfo
%hide Language.Reflection.TT.PrimType
%hide Language.Reflection.TT.TotalReq
%hide Language.Reflection.TT.VirtualIdent
%hide Language.Reflection.TT.Visibility
%hide Language.Reflection.TTImp.DataOpt
%hide Language.Reflection.TTImp.UseSide
%hide Language.Reflection.TTImp.BindMode
%hide Language.Reflection.TTImp.WithDefault
%hide Language.Reflection.TTImp.DotReason
%hide Language.Reflection.TTImp.WithFlag

||| Render a value with a `PrettyVal` instance and
||| print it to standard output.
export
putPretty : PrettyVal a => a -> IO ()
putPretty v = putStrLn (valToStr $ prettyVal v)

||| Utility for pretty printing a constructor of a sum type.
export
con : (ps : All PrettyVal ts) => VName -> HList ts -> Value
con s vs = Con s $ forget $ hzipWith (\_ => prettyVal) ps vs

||| TODO: This should go to the pretty-show library itself.
export
PrettyVal t => PrettyVal (SnocList t) where
  prettyVal vs = prettyVal (vs <>> [])

export
PrettyVal ZeroOneOmega where
  prettyVal v = Con (MkName $ show v) []

export
PrettyVal Namespace where
  prettyVal ns =
    Con "MkNamespace" [Lst $ Str <$> unsafeUnfoldNamespace ns]

export
PrettyVal ModuleIdent where
  prettyVal ns = 
    Con "MkModuleIdent" [Lst $ Str <$> unsafeUnfoldModuleIdent ns]

export
PrettyVal LogLevel where
  prettyVal l = Str (show l)

export
PrettyVal (Var n) where
  prettyVal (MkVar {varIdx} _) = Con "MkVar" [Natural $ show varIdx]

%runElab derive "VirtualIdent" [PrettyVal]
%runElab derive "OriginDesc" [PrettyVal]
%runElab derive "FC" [PrettyVal]
%runElab derive "Core.Name.UserName" [PrettyVal]
%runElab derive "Core.Name.Name" [PrettyVal]
%runElab derive "Fixity" [PrettyVal]
%runElab derive "NameType" [PrettyVal]
%runElab derive "PrimType" [PrettyVal]
%runElab derive "Constant" [PrettyVal]
%runElab derive "PiInfo" [PrettyVal]
%runElab derive "Precision" [PrettyVal]
%runElab derive "IntKind" [PrettyVal]
%runElab derive "LazyReason" [PrettyVal]
%runElab derive "UseSide" [PrettyVal]
%runElab derive "Binder" [PrettyVal]
%runElab derive "WhyErased" [PrettyVal]
%runElab derive "BindMode" [PrettyVal]
%runElab derive "DataOpt" [PrettyVal]
%runElab derive "WithFlag" [PrettyVal]
%runElab derive "DotReason" [PrettyVal]
%runElab derive "TotalReq" [PrettyVal]
%runElab derive "Visibility" [PrettyVal]
%runElab derive "BindingModifier" [PrettyVal]
%runElab derive "BuiltinType" [PrettyVal]
%runElab deriveIndexed "PrimFn" [PrettyVal]

export
{v : _} -> PrettyVal (WithDefault Visibility v) where
  prettyVal x = prettyVal $ collapseDefault x

export
PrettyVal (Term n) where
  prettyVal (Local _ x y _)  = con "Local" [x, y]
  prettyVal (Ref _ x y)      = con "Ref" [x, y]
  prettyVal (Meta _ x y z)   = con "Meta" [x, y, z]
  prettyVal (Bind _ x y z)   = con "Bind" [x, y, z]
  prettyVal (App _ x y)      = con "App" [x, y]
  prettyVal (As _ x y z)     = con "As" [x, y, z]
  prettyVal (TDelayed _ x y) = con "TDelayed" [x, y]
  prettyVal (TDelay _ x y z) = con "TDelay" [x, y, z]
  prettyVal (TForce _ x y)   = con "TForce" [x, y]
  prettyVal (PrimVal _ x)    = con "PrimVal" [x]
  prettyVal (Erased _ x)     = con "Erased" [x]
  prettyVal (TType _ x)      = con "TType" [x]
