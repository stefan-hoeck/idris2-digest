# Compilation Steps: A Walk-through

In this section we are going to have a closer look at the steps
involved when compiling a very simple module. Here's the source code:

```idris
module My.Module

%default total

export
test : Nat
test = 1
```

## Parsing into a high-level syntax Tree

First, the module is [parsed](Text.md) into a record type called `Module` from
[`Idris.Syntax`](Syntax.md#high-level-language). It contains the
fully qualified module name, a list of module imports, the module
documentation, plus a list
of top-level declarations in a tree representation of the high-level
syntax. Here's how this information looks in pretty printed form:

```repl
MkModule
  { headerLoc = fc
  , moduleNS = MkModuleIdent [Module, My]
  , imports =
      [ MkImport
          { loc = fc
          , reexport = False
          , path = MkModuleIdent [Prelude]
          , nameAs = MkNamespace [Prelude]
          }
      ]
  , documentation = ""
  , decls =
      [ PDirective fc (Defaulttotality Total)
      , PClaim
          fc
          RigW
          Export
          []
          (MkPTy fc fc (UN (Basic "test")) "" (PRef fc (UN (Basic "Nat"))))
      , PDef
          fc
          [MkPatClause fc (PRef fc (UN (Basic "test"))) (PPrimVal fc (BI 1)) []]
      ]
  }
```

As can be seen, the module name is given in reverse order
(for practical reasons: it facilitates resolving partially qualified
names), the list of imports has a single entry,
there is no documentation, and
the top-level declaration consist of the `%default total` directive,
plus the declaration (`PClaim`) and definition (`PDef`) of constant `test`.

We also see a couple of very basic expressions (`PRef` is a reference
to a named thing such as a variable or top-level function and
`PPrimVal` is a primitive literal).

Finally, there is a thing called a *pattern clause* (constructor
`MkPatClause`) used to specify the left- and right-hand side in
a function definition or case block.

## Desugaring to TTImp (Type Theory with Implicits)

Desugaring is the process of translating syntactic conveniences into
a syntax tree that is more basic than the high-level language. This
deals with `do` notation, idiom brackets, list syntax, and several
other things that are nice to have for us programmers but can be
expressed in more basic terms in the core language.

Now, desugaring already relies on many kinds of settings to be available
(for instance: operator precedence), so we need to properly setup an
environment for compilation. The necessary steps are taken and described
in function `Digest.Context.initRefs`.

Desugaring gives us again a list of declarations, this time in a
more basic form, which will be visible more clearly when we desugar
expressions containing lots of conveniences such as `do` blocks.

```repl
IClaim
  RigW
  Export
  []
  (MkImpTy fc fc (UN (Basic "test")) (IVar fc (UN (Basic "Nat"))))

IDef
  (UN (Basic "test"))
  [ PatClause
      fc
      (IVar fc (UN (Basic "test")))
      (IApp fc (IVar fc (UN (Basic "fromInteger"))) (IPrimVal fc (BI 1)))
  ]
```

In the code above, the `%default total` directive is omitted, but it
will also be processed as part of the top-level declarations.

The most interesting part is the `fromInteger ...` thing. In Idris,
literals are overloaded in general, that is, an integer literal such
as `1` needs to be put into context in order to figure out how it
should be processed. As can be see, the literal is interpreted as an
`Integer` that is passed to function `fromInteger`. This is because
the Prelude contains an `%integerLit` pragma, that tells Idris that
integer literals should be passed to function `fromInteger`.

## Elaborating to TT

We start the elaboration machinery by passing our desugared declarations
to `TTImp.Elab.Check.processDecls`, which will not return a result but
update the global context instead. The freshly generated declarations
can be retrieved with `Core.Context.lookupCtxtName`. The beginning of what
we get looks as follows:

```repl
[ ( NS (MkNamespace [Main]) (UN (Basic "test"))
  , 2648
  , MkGlobalDef
      { location = fc
      , fullname = NS (MkNamespace [Main]) (UN (Basic "test"))
      , type = Ref TyCon {tag = 100, arity = 0} (Resolved 1023)
...
]
```

We are going to take it slowly here. We first note that the `Namespace`
is not correct, because I did not bother to adjust it before
invoking `processDecl`.

Next, we see that we got some ominous number: `2648`. In fact, we see several
additional numbers, typically wrapped in a `Resolved` constructor. These are
resolved names of global definitions, which are stored in a mutable array
to get very fast lookup times. Resolved names contain the indices with which
to look up definitions in this array.

That's all well and good, but how are we supposed to make sense of things
if all the names are encoded as meaningless integers? Fortunately, there
is interface `Core.Context.HasNames`, that allows us to convert values
from and to resolved names. With this, the output above gets more readable.
This time, I print only the global definition, but in its full glory:

```repl
MkGlobalDef
  { location = fc
  , fullname = NS (MkNamespace [Main]) (UN (Basic "test"))
  , type =
      Ref
        TyCon {tag = 100, arity = 0}
        (NS (MkNamespace [Types, Prelude]) (UN (Basic "Nat")))
  , eraseArgs = []
  , safeErase = []
  , specArgs = []
  , inferrable = []
  , multiplicity = RigW
  , localVars = []
  , visibility = Export
  , totality = MkTotality {isTerminating = Unchecked, isCovering = IsCovering}
  , isEscapeHatch = False
  , flags = [AllGuarded, SetTotal Total]
  , refersToM =
      Just
        { x =
            [ (NS (MkNamespace [Types, Prelude]) (UN (Basic "S")), False)
            , (NS (MkNamespace [Types, Prelude]) (UN (Basic "Z")), False)
            ]
        }
  , refersToRuntimeM =
      Just
        { x =
            [ (NS (MkNamespace [Types, Prelude]) (UN (Basic "S")), False)
            , (NS (MkNamespace [Types, Prelude]) (UN (Basic "Z")), False)
            ]
        }
  , invertible = False
  , noCycles = False
  , linearChecked = True
  , definition =
      PMDef
        MkPMDefInfo
          {holeInfo = NotHole, alwaysReduce = False, externalDecl = False}
        []
        (STerm
           0
           (App
              (Ref
                 DataCon {tag = 1, arity = 1}
                 (NS (MkNamespace [Types, Prelude]) (UN (Basic "S"))))
              (Ref
                 DataCon {tag = 0, arity = 0}
                 (NS (MkNamespace [Types, Prelude]) (UN (Basic "Z"))))))
        (STerm
           0
           (App
              (Ref
                 DataCon {tag = 1, arity = 1}
                 (NS (MkNamespace [Types, Prelude]) (UN (Basic "S"))))
              (Ref
                 DataCon {tag = 0, arity = 0}
                 (NS (MkNamespace [Types, Prelude]) (UN (Basic "Z"))))))
        [ [] ** ( []
                , Ref Func (NS (MkNamespace [Main]) (UN (Basic "test")))
                , App
                    (Ref
                       DataCon {tag = 1, arity = 1}
                       (NS (MkNamespace [Types, Prelude]) (UN (Basic "S"))))
                    (Ref
                       DataCon {tag = 0, arity = 0}
                       (NS (MkNamespace [Types, Prelude]) (UN (Basic "Z"))))
                )
        ]
  , compexpr = Nothing
  , namedcompexpr = Nothing
  , sizeChange =
      [ MkSCCall
          { fnCall = NS (MkNamespace [Types, Prelude]) (UN (Basic "S"))
          , fnArgs = []
          , fnLoc = fc
          }
      , MkSCCall
          { fnCall = NS (MkNamespace [Types, Prelude]) (UN (Basic "Z"))
          , fnArgs = []
          , fnLoc = fc
          }
      ]
  , schemeExpr = Nothing
  }
```

That's obviously a lot of information, so I'll try and digest in in smaller pieces.
Let's first look at the elaborated declaration.

### Processing a Function Declaration

In order to focus on the most basic stuff, I removed the function definition
keeping only the declaration and reran the process. Here's the output:

```repl
MkGlobalDef
  { location = fc
  , fullname = NS (MkNamespace [Main]) (UN (Basic "test"))
  , type =
      Ref
        TyCon {tag = 100, arity = 0}
        (NS (MkNamespace [Types, Prelude]) (UN (Basic "Nat")))
  , eraseArgs = []
  , safeErase = []
  , specArgs = []
  , inferrable = []
  , multiplicity = RigW
  , localVars = []
  , visibility = Export
  , totality = MkTotality {isTerminating = Unchecked, isCovering = IsCovering}
  , isEscapeHatch = False
  , flags = [SetTotal Total]
  , refersToM = Nothing
  , refersToRuntimeM = Nothing
  , invertible = False
  , noCycles = False
  , linearChecked = True
  , definition = None
  , compexpr = Nothing
  , namedcompexpr = Nothing
  , sizeChange = []
  , schemeExpr = Nothing
  }
```

As you can see, most fields are at their empty default values, to we will
focus on the information that is already there. We see settings about the
function's quantity (`RigW` meaning unrestricted), visibility (`Export`),
and expected totality (`SetTotal Total`). We see also that the
function's type has been properly resolved to `Prelude.Types.Nat`,
and that this in fact corresponds to a type constructor of
arity zero.

Let us now look at what happened behind the scenes. I do this in
by listing different steps taken, glossing over some details.
It might be best to follow along with the source code open
at the same time:

* We manually invoked `TTImp.Elab.Check.processDecl`
  (implemented in `TTImp.ProcessDecls`) with default arguments
  (no flags and an empty environment).
* After a pattern match, this immediately passes all information to
 `TTImp.ProcessType.processType`.
* This first puts the function's name in the current namespace,
  resolves it, and checks, if a thing with that name is already
  defined.
*  
