/-
Copyright (c) 2022 Eric Wieser. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Eric Wieser
-/
import tactic.core

/-!
# Json serialization typeclass

This file provides helpers for serializing primitive types to json.

`@[derive non_null_json_serializable]` will make any structure json serializable.

## Main definitions

* `json_serializable`: a typeclass for objects which serialize to json
* `json_serializable.to_json x`: convert `x` to json
* `json_serializable.of_json α j`: read `j` in as an `α`

## TODO

It would be great if `auto_param`s and `opt_param`s could be supported for structures like
```lean
@[derive non_null_json_serializable]
structure foo :=
(x : ℕ := 2)
(y : fin x.succ := 0)
```
which would happily load from the json literal `{}`,

This ought to be possible by using a different invocation of `pexpr.mk_structure_instance` for every
field that is present.
-/


open exceptional

meta instance : has_orelse exceptional :=
{ orelse := λ α f g, match f with
  | success x := success x
  | exception msg := g
  end }

meta instance : decidable_eq json :=
begin
  intros j₁ j₂,
  letI := json.decidable_eq,
  cases j₁; cases j₂; simp; apply_instance,
end

/-- A class to indicate that a type is json serializable -/
meta class json_serializable (α : Type) :=
(to_json : α → json)
(of_json [] : json → exceptional α)

/-- A class for types which never serialize to null -/
meta class non_null_json_serializable (α : Type) extends json_serializable α

export json_serializable (to_json of_json)

/-- Describe the type of a json value -/
meta def json.typename : json → string
| (json.of_string _) := "string"
| (json.of_int _) := "number"
| (json.of_float _) := "number"
| (json.of_bool _) := "bool"
| json.null := "null"
| (json.object _) := "object"
| (json.array _) := "array"

/-! ### Primitive types -/

meta instance : non_null_json_serializable string :=
{ to_json := json.of_string,
  of_json := λ j, do
    json.of_string s ← success j | exception (λ _, format!"string expected, got {j.typename}"),
    pure s }

meta instance : non_null_json_serializable ℤ :=
{ to_json := λ z, json.of_int z,
  of_json := λ j, do
    json.of_int z ← success j | exception (λ _, format!"number expected, got {j.typename}"),
    pure z }

meta instance : non_null_json_serializable native.float :=
{ to_json := λ f, json.of_float f,
  of_json := λ j, do
    json.of_int z ← success j | do
    { json.of_float f ← success j | exception (λ _, format!"number expected, got {j.typename}"),
      pure f },
    pure z }

meta instance : non_null_json_serializable bool :=
{ to_json := λ b, json.of_bool b,
  of_json := λ j, do
    json.of_bool b ← success j | exception (λ _, format!"boolean expected, got {j.typename}"),
    pure b }

meta instance : json_serializable punit :=
{ to_json := λ u, json.null,
  of_json := λ j, do
    json.null ← success j | exception (λ _, format!"null expected, got {j.typename}"),
    pure () }

meta instance {α} [json_serializable α] : non_null_json_serializable (list α) :=
{ to_json := λ l, json.array (l.map to_json),
  of_json := λ j, do
    json.array l ← success j | exception (λ _, format!"array expected, got {j.typename}"),
    l.mmap (of_json α) }

meta instance {α} [json_serializable α] : json_serializable (rbmap string α) :=
{ to_json := λ m, json.object (m.to_list.map $ λ x, (x.1, to_json x.2)),
  of_json := λ j, do
    json.object l ← success j | exception (λ _, format!"object expected, got {j.typename}"),
    l ← l.mmap (λ x : string × json, do x2 ← of_json α x.2, pure (x.1, x2)),
    l.mfoldl (λ m x, do
      none ← pure (m.find x.1) | exception (λ _, format!"duplicate key {x.1}"),
      pure (m.insert x.1 x.2)) (mk_rbmap _ _) }

/-! ### Basic coercions -/

meta instance : non_null_json_serializable ℕ :=
{ to_json := λ n, to_json (n : ℤ),
  of_json := λ j, do
    int.of_nat n ← of_json ℤ j | exception (λ _, format!"must be non-negative"),
    pure n }

meta instance {n : ℕ} : non_null_json_serializable (fin n) :=
{ to_json := λ i, to_json i.val,
  of_json := λ j, do
    i ← of_json ℕ j,
    if h : i < n then
      pure ⟨i, h⟩
    else
      exception (λ _, format!"must be less than {n}") }

meta instance {α : Type} [json_serializable α] (p : α → Prop) [decidable_pred p] :
  json_serializable (subtype p) :=
{ to_json := λ x, to_json (x : α),
  of_json := λ j, do
    i ← of_json α j,
    if h : p i then
      pure (subtype.mk i h)
    else
      exception (λ _, format!"condition does not hold") }

/-- Note this only makes sense on types which do not themselves serialize to `null` -/
meta instance {α} [non_null_json_serializable α] : json_serializable (option α) :=
{ to_json := option.elim json.null to_json,
  of_json := λ j, do (of_json punit j >> pure none) <|> (some <$> of_json α j)}

open tactic expr

/-- Flatten a list of (p)exprs into a (p)expr forming a list of type `list t`. -/
meta def list.to_expr {elab : bool} (t : expr elab) (l : level) : list (expr elab) → expr elab
| [] := expr.app (expr.const `list.nil [l]) t
| (x :: xs) := (((expr.const `list.cons [l]).app t).app x).app xs.to_expr

/-- Begin parsing fields -/
meta def json_serializable.field_starter (j : json) : exceptional (list (string × json)) :=
do
  json.object p ← pure j | exception (λ _, format!"object expected, got {j.typename}"),
  pure p

/-- Check a field exists and is unique -/
meta def json_serializable.field_get (l : list (string × json)) (s : string) :
  exceptional (option json × list (string × json)) :=
let (p, n) := l.partition (λ x, prod.fst x = s) in
match p with
| [] := pure (none, n)
| [x] := pure (some x.2, n)
| x :: xs := exception (λ _, format!"duplicate {s} field")
end

/-- Check no fields remain -/
meta def json_serializable.field_terminator (l : list (string × json)) : exceptional unit :=
do [] ← pure l | exception (λ _, format!"unexpected fields {l.map prod.fst}"), pure ()

/-- ``((c_name, c_fun), [(p_name, p_fun), ...]) ← get_constructor_and_projections `(struct n)``
gets the names and partial invocations of the constructor and projections of a structure -/
meta def get_constructor_and_projections (t : expr) :
  tactic (name × (name × expr) × list (name × expr)):=
do
  (const I ls, args) ← pure (get_app_fn_args t),
  env ← get_env,
  [ctor] ← pure (env.constructors_of I),
  ctor ← do
  { d ← get_decl ctor,
    let a := @expr.const tt ctor $ d.univ_params.map level.param,
    pure (ctor, a.mk_app args) },
  ctor_type ← infer_type ctor.2,
  tt ← pure ctor_type.is_pi | pure (I, ctor, []),
  some fields ← pure (env.structure_fields I) | fail!"Not a structure",
  projs ← fields.mmap $ λ f, do
  { d ← get_decl (I ++ f),
    let a := @expr.const tt (I ++ f) $ d.univ_params.map level.param,
    pure (f, a.mk_app args) },
  pure (I, ctor, projs)

/-- Make a structure of type `t` using a list of possibly absent fields -/
meta def mk_struct_opt (t : expr) : structure_instance_info → list (name × pexpr) → tactic pexpr
| struct [] := do
  -- allow this partial constructor if `to_expr` allows it
  let p := ``(pure %%(pexpr.mk_structure_instance struct) : exceptional %%t),
  to_expr p,
  pure p
| s ((name, val) :: xs) := do
  ft : expr ← mk_mvar,
  let vname := `mk ++ name,
  n_binder ← mk_local' vname binder_info.default ft,
  let with_field_info : structure_instance_info :=
    ⟨s.struct, name :: s.field_names, to_pexpr n_binder :: s.field_values, s.sources⟩,
  with_field ← mk_struct_opt with_field_info xs,
  let with_field : pexpr := expr.lam vname binder_info.default (to_pexpr ft) with_field,
  without_field ←
  (λ ts, match mk_struct_opt s xs ts with
  | r@(interaction_monad.result.success _ s) := r
  | (interaction_monad.result.exception _ p s) :=
    interaction_monad.result.success
      ``(exception $ λ o, let x := %%`(name) in format!"Field {x} is required" : exceptional %%t)
      ts
  end : tactic pexpr),
  pure ``(option.elim %%without_field %%with_field %%val)

structure has_def :=
(fst : nat)
(snd : nat := 2*fst)
(thd : fin snd.succ := 0 )

#check ({ fst := 1} : has_def)

run_cmd do
  to_expr ``({ fst := 1, thd := 0} : has_def),
  some o ← pure (pexpr.get_structure_instance_info ``({ fst := 1})) | tactic.trace "oh",
  tactic.trace o.sources

run_cmd do
  p ← mk_struct_opt `(has_def)
    {structure_instance_info . struct := some "has_def", sources:=[], field_names := [],
    field_values := []} [ (`thd, ``(some 1)), (`snd, ``(none)), (`fst, ``(some 1))],
  e ← to_expr p,
  tactic.trace e,
  pure ()

/-- A derive handler to serialize structures by their fields -/
@[derive_handler, priority 2000] meta def non_null_json_serializable_handler : derive_handler :=
instance_derive_handler ``non_null_json_serializable $ do
  intros,
  `(non_null_json_serializable %%e) ← target >>= whnf,
  (struct_name, (ctor_name, ctor), fields) ← get_constructor_and_projections e,
  refine ``(@non_null_json_serializable.mk %%e ⟨λ x, json.object _,
    λ j, json_serializable.field_starter j >>= _
  ⟩),
  -- the forward direction
  x ← get_local `x,
  (projs : list (option expr)) ← fields.mmap (λ ⟨f, a⟩, do
    let x_e := a.app x,
    t ← infer_type x_e,
    s ← infer_type t,
    expr.sort (level.succ u) ← pure s | pure (none : option expr),
    level.zero ← pure u | fail!"Only Type 0 is supported",
    j ← tactic.mk_app `json_serializable.to_json [x_e],
    pure (some `((%%`(f.to_string), %%j) : string × json))
  ),
  tactic.exact (projs.reduce_option.to_expr `(string × json) level.zero),

  -- the reverse direction
  get_local `j >>= tactic.clear,
  -- check fields are present
  json_fields ← fields.mmap (λ ⟨f, e⟩, do
    t ← infer_type e,
    s ← infer_type t,
    tactic.trace e,
    expr.sort (level.succ u) ← pure s | pure (f, none),  -- do nothing for prop fields
    refine ``(λ p, json_serializable.field_get p %%`(f.to_string) >>= _),
    tactic.applyc `prod.rec,
    get_local `p >>= tactic.clear,
    jf ← tactic.intro (`field ++ f),
    pure (f, some jf)),
  refine ``(λ p, json_serializable.field_terminator p >> _),
  get_local `p >>= tactic.clear,
  -- parse fields one by one
  (fields) ← json_fields.mfoldl (λ (fields : list (name × pexpr)) ⟨f, j⟩, do
    match j with
    | none := do
        focus1 (do
        {refine ``(dite _ _ (λ _, exception $ λ _, format!"condition does not hold")),
          rotate_right 1 }),
        v ← tactic.intro (`field ++ f),
        pure (
          (f, ``(some %%v)) :: fields)
    | some j := do
        focus1 (do
        { refine ``(option.mmap (of_json _) %%j >>= _), rotate_right 1 }),
        tactic.clear j,
        v ← tactic.intro (`field ++ f),
        pure (
          (f, to_pexpr v) :: fields)
    end) ([]),
  trace_state,
  p ← mk_struct_opt e (structure_instance_info.mk (some struct_name) [] [] []) fields,
  refine p
  -- exact `(pure %%val : exceptional %%e)


#check tactic.focus1
