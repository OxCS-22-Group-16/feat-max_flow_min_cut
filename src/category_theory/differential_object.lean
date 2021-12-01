/-
Copyright (c) 2020 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import category_theory.shift

/-!
# Differential objects in a category.

A differential object in a category with zero morphisms and a shift is
an object `X` equipped with
a morphism `d : X ⟶ X⟦1⟧`, such that `d^2 = 0`.

We build the category of differential objects, and some basic constructions
such as the forgetful functor, zero morphisms and zero objects, and the shift functor
on differential objects.
-/

open category_theory.limits

universes v u

namespace category_theory

variables (C : Type u) [category.{v} C]

variables [has_zero_morphisms C] [has_shift C ℤ]

/--
A differential object in a category with zero morphisms and a shift is
an object `X` equipped with
a morphism `d : X ⟶ X⟦1⟧`, such that `d^2 = 0`.
-/
@[nolint has_inhabited_instance]
structure differential_object :=
(X : C)
(d : X ⟶ X⟦1⟧)
(d_squared' : d ≫ d⟦(1:ℤ)⟧' = 0 . obviously)

restate_axiom differential_object.d_squared'
attribute [simp] differential_object.d_squared

variables {C}

namespace differential_object

/--
A morphism of differential objects is a morphism commuting with the differentials.
-/
@[ext, nolint has_inhabited_instance]
structure hom (X Y : differential_object C) :=
(f : X.X ⟶ Y.X)
(comm' : X.d ≫ f⟦1⟧' = f ≫ Y.d . obviously)

restate_axiom hom.comm'
attribute [simp, reassoc] hom.comm

namespace hom

/-- The identity morphism of a differential object. -/
@[simps]
def id (X : differential_object C) : hom X X :=
{ f := 𝟙 X.X }

/-- The composition of morphisms of differential objects. -/
@[simps]
def comp {X Y Z : differential_object C} (f : hom X Y) (g : hom Y Z) : hom X Z :=
{ f := f.f ≫ g.f, }

end hom

instance category_of_differential_objects : category (differential_object C) :=
{ hom := hom,
  id := hom.id,
  comp := λ X Y Z f g, hom.comp f g, }

@[simp]
lemma id_f (X : differential_object C) : ((𝟙 X) : X ⟶ X).f = 𝟙 (X.X) := rfl

@[simp]
lemma comp_f {X Y Z : differential_object C} (f : X ⟶ Y) (g : Y ⟶ Z) :
  (f ≫ g).f = f.f ≫ g.f :=
rfl

@[simp]
lemma eq_to_hom_f {X Y : differential_object C} (h : X = Y) :
  hom.f (eq_to_hom h) = eq_to_hom (congr_arg _ h) :=
by { subst h, rw [eq_to_hom_refl, eq_to_hom_refl], refl }

variables (C)

/-- The forgetful functor taking a differential object to its underlying object. -/
def forget : (differential_object C) ⥤ C :=
{ obj := λ X, X.X,
  map := λ X Y f, f.f, }

instance forget_faithful : faithful (forget C) :=
{ }

instance has_zero_morphisms [is_equivalence (shift_functor C (0:ℤ))] :
  has_zero_morphisms (differential_object C) :=
{ has_zero := λ X Y,
  ⟨{ f := 0 }⟩}

variables {C}

@[simp]
lemma zero_f [is_equivalence (shift_functor C (0:ℤ))] (P Q : differential_object C) :
  (0 : P ⟶ Q).f = 0 := rfl

/--
An isomorphism of differential objects gives an isomorphism of the underlying objects.
-/
@[simps] def iso_app {X Y : differential_object C} (f : X ≅ Y) : X.X ≅ Y.X :=
⟨f.hom.f, f.inv.f, by { dsimp, rw [← comp_f, iso.hom_inv_id, id_f] },
  by { dsimp, rw [← comp_f, iso.inv_hom_id, id_f] }⟩

@[simp] lemma iso_app_refl (X : differential_object C) : iso_app (iso.refl X) = iso.refl X.X := rfl
@[simp] lemma iso_app_symm {X Y : differential_object C} (f : X ≅ Y) :
  iso_app f.symm = (iso_app f).symm := rfl
@[simp] lemma iso_app_trans {X Y Z : differential_object C} (f : X ≅ Y) (g : Y ≅ Z) :
  iso_app (f ≪≫ g) = iso_app f ≪≫ iso_app g := rfl

/-- An isomorphism of differential objects can be constructed
from an isomorphism of the underlying objects that commutes with the differentials. -/
@[simps] def mk_iso {X Y : differential_object C}
  (f : X.X ≅ Y.X) (hf : X.d ≫ f.hom⟦1⟧' = f.hom ≫ Y.d) : X ≅ Y :=
{ hom := ⟨f.hom, hf⟩,
  inv := ⟨f.inv, by { dsimp, rw [← functor.map_iso_inv, iso.comp_inv_eq, category.assoc,
    iso.eq_inv_comp, functor.map_iso_hom, hf] }⟩,
  hom_inv_id' := by { ext1, dsimp, exact f.hom_inv_id },
  inv_hom_id' := by { ext1, dsimp, exact f.inv_hom_id } }

end differential_object

namespace functor

universes v' u'
variables (D : Type u') [category.{v'} D]
variables [has_zero_morphisms D] [has_shift D ℤ]

/--
A functor `F : C ⥤ D` which commutes with shift functors on `C` and `D` and preserves zero morphisms
can be lifted to a functor `differential_object C ⥤ differential_object D`.
-/
@[simps]
def map_differential_object (F : C ⥤ D)
  (η : (shift_functor C (1:ℤ)).comp F ⟶ F.comp (shift_functor D (1:ℤ)))
  (hF : ∀ c c', F.map (0 : c ⟶ c') = 0) :
  differential_object C ⥤ differential_object D :=
{ obj := λ X, { X := F.obj X.X,
    d := F.map X.d ≫ η.app X.X,
    d_squared' := begin
      rw [functor.map_comp, ← functor.comp_map F (shift_functor D (1:ℤ))],
      slice_lhs 2 3 { rw [← η.naturality X.d] },
      rw [functor.comp_map],
      slice_lhs 1 2 { rw [← F.map_comp, X.d_squared, hF] },
      rw [zero_comp, zero_comp],
    end },
  map := λ X Y f, { f := F.map f.f,
    comm' := begin
      dsimp,
      slice_lhs 2 3 { rw [← functor.comp_map F (shift_functor D (1:ℤ)), ← η.naturality f.f] },
      slice_lhs 1 2 { rw [functor.comp_map, ← F.map_comp, f.comm, F.map_comp] },
      rw [category.assoc]
    end },
  map_id' := by { intros, ext, simp },
  map_comp' := by { intros, ext, simp }, }

end functor

end category_theory

namespace category_theory

namespace differential_object

variables (C : Type u) [category.{v} C]

variables [has_zero_object C] [has_zero_morphisms C] [has_shift C ℤ]

open_locale zero_object

instance has_zero_object [is_equivalence (shift_functor C (0:ℤ))] :
  has_zero_object (differential_object C) :=
{ zero :=
  { X := (0 : C),
    d := 0, },
  unique_to := λ X, ⟨⟨{ f := 0 }⟩, λ f, (by ext)⟩,
  unique_from := λ X, ⟨⟨{ f := 0 }⟩, λ f, (by ext)⟩, }

end differential_object

namespace differential_object

variables (C : Type (u+1)) [large_category C] [concrete_category C]
  [has_zero_morphisms C] [has_shift C ℤ]

instance concrete_category_of_differential_objects :
  concrete_category (differential_object C) :=
{ forget := forget C ⋙ category_theory.forget C }

instance : has_forget₂ (differential_object C) C :=
{ forget₂ := forget C }

end differential_object

/-! The category of differential objects itself has a shift functor. -/
namespace differential_object

variables (C : Type u) [category.{v} C]
variables [has_zero_morphisms C] [has_shift C ℤ] [∀ n:ℤ, is_equivalence (shift_functor C n)]

/-- The shift functor on `differential_object C`. -/
@[simps]
def shift_functor (n : ℤ) : differential_object C ⥤ differential_object C :=
{ obj := λ X,
  { X := X.X⟦n⟧,
    d := X.d⟦n⟧' ≫ (shift_comm _ _ _).hom,
    d_squared' := by rw [functor.map_comp, category.assoc, shift_comm_hom_comp_assoc,
        ←functor.map_comp_assoc, X.d_squared, is_equivalence_preserves_zero_morphisms, zero_comp] },
  map := λ X Y f,
  { f := f.f⟦n⟧',
    comm' := by { dsimp, rw [category.assoc, shift_comm_hom_comp, ← functor.map_comp_assoc,
      f.comm, functor.map_comp_assoc], }, },
  map_id' := by { intros X, ext1, dsimp, rw functor.map_id },
  map_comp' := by { intros X Y Z f g, ext1, dsimp, rw functor.map_comp } }

/-- The shift functor on `differential_object C` is additive. -/
@[simps] def shift_functor_add (m n : ℤ) :
  shift_functor C (m + n) ≅ shift_functor C m ⋙ shift_functor C n :=
begin
  refine nat_iso.of_components (λ X, mk_iso (shift_add X.X _ _) _) _,
  { dsimp, rw [category.assoc, functor.map_comp_assoc, shift_add_hom_comp_assoc],
    congr' 1, sorry },
  { intros X Y f, ext1, dsimp, rw [shift_add_hom_comp] }
end
.

instance : has_shift (differential_object C) ℤ :=
{ shift := shift_functor C,
  shift_add := shift_functor_add C,
  iso_whisker_right_shift_add := λ i j k, by
  { ext X, dsimp, rw [shift_shift_add_hom', category.comp_id, eq_to_hom_app, eq_to_hom_f], refl } }

end differential_object

end category_theory
