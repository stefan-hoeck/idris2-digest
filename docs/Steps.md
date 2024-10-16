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

You can start your own experiments by compiling `Digest.Elab` and invoke
it with your own module and declaration name. Like so:

```sh
pack -o elab exec src/Digest/Elab.idr
build/exec/elab path/to/MyModule.idr funName
```

Likewise, modules `Digest.Parse` and `Digest.Desugar` can be run
against custom modules to check the output of the corresponding
compilation steps.

## Parsing into a high-level syntax Tree

First, the module is [parsed](Text.md) into a record type called `Module` from
[`Idris.Syntax`](Syntax.md#high-level-language). It contains the
fully qualified module name, a list of module imports, the module
documentation, plus a list
of top-level declarations in a [tree representation](Tree.md)
of the high-level syntax. Here's how this information looks in
pretty printed form:

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
we get when looking for "test" after processing it looks as follows:

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
is not correct, because I did not bother to adjust it in the global
context before invoking `processDecl`. (This has been fixed in the code
but I leave the output as it is to demonstrate the effect of `setNS`,
which is used for setting the namespace.)

Next, we see that we got some ominous number: `2648`. In fact, we see several
additional numbers, typically wrapped in a `Resolved` constructor. These are
resolved names of the global definitions, which are stored in a mutable array
to get fast lookup times. Resolved names contain the indices pointing to
the corresponding array entries.

That's all well and good, but how are we supposed to make sense of things
if all the names are encoded as meaningless integers? Fortunately, there
is interface `Core.Context.HasNames`, that allows us to convert values
with `Name`s from and to the resolved versions. With this, the output
above gets more readable.
This time, I print only the global definition, but in its full glory:

```repl
MkGlobalDef
  { location = fc
  , fullname = NS (MkNamespace [Module, My]) (UN (Basic "test"))
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

Let us now look at what happened behind the scenes. I do this
by listing the different steps taken, glossing over some details.
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
* It then checks the type of the declaration's term itself by
  introducing a dummy definition at the top-level. We will talk
  about this in more detail [below](#checking-a-term-in-a-type).
* The type term is next converted to a `ClosedTerm` by applying
  the environment. Since the environment is currently empty,
  nothing has to be done here.
* The fully applied type is then inspected to determine erased arguments.
  (TODO)
* Next, inferrable argument types are determined in a clear context. (TODO)
* Create a new declaration with all the info assembled and add it to
  the global context.
* Flag the declaration to have been linearity checked.
* Process the declaration's function opts (such as `%inline` or `%foreign`).
* Set the function's expected totality (either the currently set default one,
  or the one given explicitly with the function).
* Make the type available for interactive editing. (TODO)
* Add the declaration's name and type to the global context.
* Process the type's metadata. (TODO)
* Add the name's and type's hashes if the function is not private.
  This determines, if a module's visible API has changed and
  whether downstream modules should be rechecked.
* Warn if names are shadowing other names. (TODO)

### Checking a Term in a Type

We glossed over the details of checking the type's term in the discussion
above. Let's have a closer look at how this goes now. The entry point for this
is `TTImp.Elab.checkTerm` and it takes several additional arguments.
Here's the meaning and value of each explicit argument in our current
function call:

* `defining`: Index of definition declaration. In our case, this is the
  index of `My.Module.test` that has already been resolved.
* `mode`    : Mode of elaboration. Currently, this is set to `InType`
* `opts`    : Elaboration options. Currently, this is `[HolesOkay]`.
* `nest`    : Nested names (TODO). This is currently empty.
* `env`     : Defined variables in scope. This is currently empty.
* `tm`      : The term we are about to check. This is currently
  `IBindHere _ (PI erased) (IVar _ (UN (Basic "Nat")))`. (I omitted
  the file contexts because we are currently not interested in those.)
* `ty`      : The type this should elaborate to. Now, this calls for
  some explanation. This is of type `Glued vars`, which pairs a term
  with its [normal form](Elab.md#normalization).
  For reasons of efficiency, glued normal forms
  are lazily evaluated and cached in the current context. In our case,
  this is the result of invoking `Core.Normalise.Eval.gType`, which
  corresponds to `TType` as the term and `NType` as its normal form.

Function `checkTerm` immediately invokes `checkTermSub`, which
takes an additional inner environment with a proof that it is a
[thinning](Tree.md#operations-on-scoped-terms) of the outer
environment. Here's the steps it goes through:

* First, since we are in a type (`mode` is `InType`), we branch off
  the current context (this will later be committed back once we
  were successful) because we might need to backtrack.
* We then store the current state of other mutable variables in
  case we need to retry with implicits.
* Next, `elabTermSub` is invoked and we inspect the error we get
  (if any). In case this is a `TryWithImplicits`, mutable variables
  are restored, implicits are bound to the current term and
  elaboration is retried.

Now, the big one: `elabTermSub`.

* We first determine from the list of elab options, if we are in
  a case block, a partial evaluation, or a transform rule.
* We then save some state (`saveHoles` and `delayedElab`).

To be continued...
