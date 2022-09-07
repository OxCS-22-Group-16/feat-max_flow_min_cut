/-
Copyright (c) 2022 Joël Riou. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Joël Riou
-/

import algebraic_topology.alternating_face_map_complex
import algebraic_topology.cech_nerve
import algebra.homology.homotopy
import algebraic_topology.simplicial_set
import tactic.equiv_rw
import tactic.fin_cases

/-!

# Augmented simplicial objects with an extra degeneracy

In simplicial homotopy theory, in order to prove that the connected components
of a simplicial set `X` are contractible, it suffices to construct an extra
degeneracy as it is defined in *Simplicial Homotopy Theory* by Goerrs-Jardine p. 190.
It consists of a series of maps `π₀ X → X _[0]` and `X _[n] → X _[n+1]` which
behaves formally like an extra degeneracy `σ (-1)`. It can be thought as a datum
associated to the augmented simplicial set `X → π₀ X`.

In this file, we adapt this definition to the case of augmented
simplicial objects in any category.

## Main definitions

- the structure `extra_degeneracy X` for any `X : simplicial_object.augmented C`
- `extra_degeneracy.map`: extra degeneracies are preserved by the application of any
functor `C ⥤ D`
- `extra_degeneracy.for_cech_nerve_of_split_epi`: the augmented Čech nerve of a split
epimorphism has an extra degeneracy
- `sSet.augmented_cech.extra_degeneracy`...
- `extra_degeneracy.preadditive.homotopy_equivalence`: when the category `C` is
preadditive and has a zero object, and `X : simplicial_object.augmented C` has an extra
degeneracy, then the augmentation `alternating_face_map_complex.ε.app X` is a homotopy
equivalence of chain complexes

## References
* [Paul G. Goerss, John F. Jardine, *Simplical Homotopy Theory*][goerss-jardine-2009]

-/

noncomputable theory


open category_theory category_theory.category category_theory.limits
open category_theory.simplicial_object.augmented
open opposite simplex_category
open_locale simplicial

universes u

lemma fin.eq_succ_of_ne_zero {n : ℕ} {x : fin (n+1)} (hx : x ≠ 0) : ∃ (y : fin n), x = y.succ :=
⟨x.pred hx, by simp only [fin.succ_pred]⟩

@[simp]
lemma fin.succ_pred_above_succ {n : ℕ} (x : fin n) (y : fin (n+1)) :
  x.succ.pred_above y.succ = (x.pred_above y).succ :=
sorry

namespace algebraic_topology

variables {C : Type*} [category C]

/-- The datum of an extra degeneracy is a technical condition on
augmented simplicial objects. The morphisms `s'` and `s n` of the
structure formally behave like extra degeneracies `σ (-1)`. In
the case of augmented simplicial sets, the existence of an extra
degeneray implies the augmentation is an homotopy equivalence. -/
@[ext]
structure extra_degeneracy (X : simplicial_object.augmented C) :=
(s' : point.obj X ⟶ (drop.obj X) _[0])
(s : Π (n : ℕ), (drop.obj X) _[n] ⟶ (drop.obj X) _[n+1])
(s'_comp_ε' : s' ≫ X.hom.app (op [0]) = 𝟙 _)
(s₀_comp_δ₁' : s 0 ≫ (drop.obj X).δ 1 = X.hom.app (op [0]) ≫ s')
(s_comp_δ₀' : Π (n : ℕ), s n ≫ (drop.obj X).δ 0 = 𝟙 _)
(s_comp_δ' : Π (n : ℕ) (i : fin (n+2)), s (n+1) ≫ (drop.obj X).δ i.succ =
  (drop.obj X).δ i ≫ s n)
(s_comp_σ' : Π (n : ℕ) (i : fin (n+1)), s n ≫ (drop.obj X).σ i.succ =
  (drop.obj X).σ i ≫ s (n+1))

namespace extra_degeneracy

restate_axiom s'_comp_ε'
restate_axiom s₀_comp_δ₁'
restate_axiom s_comp_δ₀'
restate_axiom s_comp_δ'
restate_axiom s_comp_σ'
attribute [reassoc] s'_comp_ε s₀_comp_δ₁ s_comp_δ₀ s_comp_δ s_comp_σ
attribute [simp] s'_comp_ε s_comp_δ₀

/-- If `ed` is an extra degeneracy for `X : simplicial_object.augmented C` and
`F : C ⥤ D` is a functor, then `ed.map F` is an extra degeneracy for the
augmented simplical object in `D` obtained by applying `F` to `X`. -/
def map {D : Type*} [category D]
  {X : simplicial_object.augmented C} (ed : extra_degeneracy X) (F : C ⥤ D) :
  extra_degeneracy (((whiskering _ _).obj F).obj X) :=
{ s' := F.map ed.s',
  s := λ n, F.map (ed.s n),
  s'_comp_ε' := by { dsimp, erw [comp_id, ← F.map_comp, ed.s'_comp_ε, F.map_id], },
  s₀_comp_δ₁' := by { dsimp, erw [comp_id, ← F.map_comp, ← F.map_comp, ed.s₀_comp_δ₁], },
  s_comp_δ₀' := λ n, by { dsimp, erw [← F.map_comp, ed.s_comp_δ₀, F.map_id], },
  s_comp_δ' := λ n i, by { dsimp, erw [← F.map_comp, ← F.map_comp, ed.s_comp_δ], refl, },
  s_comp_σ' := λ n i, by { dsimp, erw [← F.map_comp, ← F.map_comp, ed.s_comp_σ], refl, }, }

end extra_degeneracy

end algebraic_topology

namespace sSet

open algebraic_topology

/-- The category of augmented simplicial sets, as a particular case of
augmented simplicial objects. -/
abbreviation augmented := simplicial_object.augmented (Type u)

namespace augmented

/-- The functor which sends `[n]` to the simplicial set `Δ[n]` equipped by
the obvious augmentation towards the terminal object of the category of sets. -/
@[simps]
def standard_simplex : simplex_category ⥤ sSet.augmented :=
{ obj := λ Δ,
  { left := sSet.standard_simplex.obj Δ,
    right := terminal _,
    hom := { app := λ Δ', terminal.from _, }, },
  map := λ Δ₁ Δ₂ θ,
  { left := sSet.standard_simplex.map θ,
    right := terminal.from _, }, }

namespace standard_simplex

/-- When `[has_zero X]`, the shift of a map `f : fin (n+1) → X`
is a map `fin (n+2) → X` which sends `0` to `0` and `i.succ` to `f i`. -/
def shift_fn {n : ℕ} {X : Type*} [has_zero X] (f : fin (n+1) → X) (i : fin (n+2)) : X :=
dite (i = 0) (λ h, 0) (λ h, f (i.pred h))

@[simp]
lemma shift_fn_0 {n : ℕ} {X : Type*} [has_zero X] (f : fin (n+1) → X) : shift_fn f 0 = 0 := rfl

@[simp]
lemma shift_fn_succ {n : ℕ} {X : Type*} [has_zero X] (f : fin (n+1) → X)
  (i : fin (n+1)) : shift_fn f i.succ = f i :=
begin
  dsimp [shift_fn],
  split_ifs,
  { exfalso,
    simpa only [fin.ext_iff, fin.coe_succ] using h, },
  { simp only [fin.pred_succ], },
end

/-- The shift of a morphism `f : [n] → Δ` in `simplex_category` corresponds to
the monotone map which sends `0` to `0` and `i.succ` to `f.to_order_hom i`. -/
@[simp]
def shift {n : ℕ} {Δ : simplex_category} (f : [n] ⟶ Δ) : [n+1] ⟶ Δ := simplex_category.hom.mk
{ to_fun := shift_fn f.to_order_hom,
  monotone' := λ i₁ i₂ hi, begin
    by_cases h₁ : i₁ = 0,
    { subst h₁,
      simp only [shift_fn_0, fin.zero_le], },
    { have h₂ : i₂ ≠ 0 := by { intro h₂, subst h₂, exact h₁ (le_antisymm hi (fin.zero_le _)), },
      cases fin.eq_succ_of_ne_zero h₁ with j₁ hj₁,
      cases fin.eq_succ_of_ne_zero h₂ with j₂ hj₂,
      substs hj₁ hj₂,
      simpa only [shift_fn_succ] using f.to_order_hom.monotone (fin.succ_le_succ_iff.mp hi), },
  end, }

/-- The obvious extra degeneracy on the standard simplex. -/
@[protected]
def extra_degeneracy (Δ : simplex_category) : extra_degeneracy (standard_simplex.obj Δ) :=
{ s' := λ x, simplex_category.hom.mk (order_hom.const _ 0),
  s := λ n f, shift f,
  s'_comp_ε' := by { ext1 j, fin_cases j, },
  s₀_comp_δ₁' := by { ext x j, fin_cases j, refl, },
  s_comp_δ₀' := λ n, begin
    ext φ i : 4,
    dsimp [simplicial_object.δ, simplex_category.δ, sSet.standard_simplex],
    simp only [shift_fn_succ],
  end,
  s_comp_δ' := λ n i, begin
    ext φ j : 4,
    dsimp [simplicial_object.δ, simplex_category.δ, sSet.standard_simplex],
    by_cases j = 0,
    { subst h,
      simp only [fin.succ_succ_above_zero, shift_fn_0], },
    { cases fin.eq_succ_of_ne_zero h with k hk,
      subst hk,
      simp only [fin.succ_succ_above_succ, shift_fn_succ], },
  end,
  s_comp_σ' := λ n i, begin
    ext φ j : 4,
    dsimp [simplicial_object.σ, simplex_category.σ, sSet.standard_simplex],
    by_cases j = 0,
    { subst h,
      simpa only [shift_fn_0] using shift_fn_0 φ.to_order_hom, },
    { cases fin.eq_succ_of_ne_zero h with k hk,
      subst hk,
      simp only [fin.succ_pred_above_succ, shift_fn_succ], },
  end, }

instance nonempty_extra_degeneracy_standard_simplex (Δ : simplex_category) :
  nonempty (extra_degeneracy (standard_simplex.obj Δ)) :=
⟨standard_simplex.extra_degeneracy Δ⟩

end standard_simplex

end augmented

end sSet
