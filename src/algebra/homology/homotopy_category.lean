/-
Copyright (c) 2021 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import algebra.homology.homotopy
import category_theory.quotient

/-!
# The homotopy category

`homotopy_category V c` gives the category of chain complexes of shape `c` in `V`,
with chain maps identified when they are homotopic.
-/

universes v u

open_locale classical
noncomputable theory

open category_theory category_theory.limits homological_complex

variables {ι : Type*}
variables (V : Type u) [category.{v} V] [has_zero_object V] [preadditive V]
variables (c : complex_shape ι)

/--
`homotopy_category V c` is the category of chain complexes of shape `c` in `V`,
with chain maps identified when they are homotopic.
-/
@[derive category]
def homotopy_category :=
category_theory.quotient (λ (C D : homological_complex V c) (f g : C ⟶ D), nonempty (homotopy f g))

namespace homotopy_category

/-- The quotient functor from complexes to the homotopy category. -/
def quotient : homological_complex V c ⥤ homotopy_category V c :=
category_theory.quotient.functor _

variables {V c}

@[simp] lemma quotient_obj_as (C : homological_complex V c) :
  ((quotient V c).obj C).as = C := rfl

lemma quotient_map_out {C D : homotopy_category V c} (f : C ⟶ D) :
  (quotient V c).map f.out = f :=
quot.out_eq _

lemma eq_of_homotopy {C D : homological_complex V c} (f g : C ⟶ D) (h : homotopy f g) :
  (quotient V c).map f = (quotient V c).map g :=
category_theory.quotient.sound _ ⟨h⟩

-- This may take some work,
-- because `category_theory.quotient` doesn't assume an equivalence relation.
def homotopy_of_eq {C D : homological_complex V c} (f g : C ⟶ D)
  (w : (quotient V c).map f = (quotient V c).map g) : homotopy f g :=
begin
  have := quot.eq.mp w,
  sorry,
end

@[simp] lemma quotient_map_out_comp_out {C D E : homotopy_category V c} (f : C ⟶ D) (g : D ⟶ E) :
  (quotient V c).map (quot.out f ≫ quot.out g) = f ≫ g :=
by conv_rhs { erw [←quotient_map_out f, ←quotient_map_out g, ←(quotient V c).map_comp], }

/-- Homotopy equivalent complexes become isomorphic in the homotopy category. -/
def iso_of_homotopy_equiv {C D : homological_complex V c} (f : homotopy_equiv C D) :
  (quotient V c).obj C ≅ (quotient V c).obj D :=
{ hom := (quotient V c).map f.hom,
  inv := (quotient V c).map f.inv,
  hom_inv_id' := begin
    rw [←(quotient V c).map_comp, ←(quotient V c).map_id],
    exact eq_of_homotopy _ _ f.homotopy_hom_inv_id,
  end,
  inv_hom_id' := begin
    rw [←(quotient V c).map_comp, ←(quotient V c).map_id],
    exact eq_of_homotopy _ _ f.homotopy_inv_hom_id,
  end }

/-- If two complexes become isomorphic in the homotopy category,
  then they were homotopy equivalent. -/
def homotopy_equiv_of_iso {C D : homological_complex V c} (i : (quotient V c).obj C ≅ (quotient V c).obj D) :
  homotopy_equiv C D :=
{ hom := quot.out i.hom,
  inv := quot.out i.inv,
  homotopy_hom_inv_id := homotopy_of_eq _ _ (by { simp, refl, }),
  homotopy_inv_hom_id := homotopy_of_eq _ _ (by { simp, refl, }), }

variables (V c) [has_equalizers V] [has_images V] [has_image_maps V] [has_cokernels V]

/-- The `i`-th homology, as a functor from the homotopy category. -/
def homology_functor (i : ι) : homotopy_category V c ⥤ V :=
category_theory.quotient.lift _ (homology_functor V c i)
  (λ C D f g ⟨h⟩, homology_map_eq_of_homotopy h i)

/-- The homology functor on the homotopy category is just the usual homology functor. -/
def homology_factors (i : ι) :
  quotient V c ⋙ homology_functor V c i ≅ _root_.homology_functor V c i :=
category_theory.quotient.lift.is_lift _ _ _

@[simp] lemma homology_factors_hom_app (i : ι) (C : homological_complex V c) :
  (homology_factors V c i).hom.app C = 𝟙 _ :=
rfl

@[simp] lemma homology_factors_inv_app (i : ι) (C : homological_complex V c) :
  (homology_factors V c i).inv.app C = 𝟙 _ :=
rfl

end homotopy_category

namespace category_theory

variables {W : Type*} [category W] [preadditive W] [has_zero_object W]

/-- An additive functor induces a functor between homotopy categories. -/
@[simps]
def functor.map_homotopy_category (c : complex_shape ι) (F : V ⥤ W) [F.additive] :
  homotopy_category V c ⥤ homotopy_category W c :=
{ obj := λ C, (homotopy_category.quotient W c).obj ((F.map_homological_complex c).obj C.as),
  map := λ C D f,
    (homotopy_category.quotient W c).map ((F.map_homological_complex c).map (quot.out f)),
  map_id' := λ C, begin
    rw ←(homotopy_category.quotient W c).map_id,
    apply homotopy_category.eq_of_homotopy,
    rw ←(F.map_homological_complex c).map_id,
    apply F.map_homotopy,
    apply homotopy_category.homotopy_of_eq,
    exact quot.out_eq _,
  end,
  map_comp' := λ C D E f g, begin
    rw ←(homotopy_category.quotient W c).map_comp,
    apply homotopy_category.eq_of_homotopy,
    rw ←(F.map_homological_complex c).map_comp,
    apply F.map_homotopy,
    apply homotopy_category.homotopy_of_eq,
    convert quot.out_eq _,
    exact homotopy_category.quotient_map_out_comp_out,
  end }.

end category_theory
