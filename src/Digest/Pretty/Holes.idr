module Digest.Pretty.Holes

import Derive.Prelude
import Data.List.Quantifiers
import public Digest.Pretty.Context
import public Digest.Pretty.Syntax
import public Digest.Pretty.TT
import public Idris.IDEMode.Holes

%default total
%language ElabReflection

%runElab derive "KindedName" [PrettyVal]
%runElab derive "Premise" [PrettyVal]
%runElab derive "Holes.Data" [PrettyVal]
