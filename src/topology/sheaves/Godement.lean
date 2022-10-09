/-
Copyright (c) 2022 Jujian Zhang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jujian Zhang
-/

import topology.sheaves.sheaf
import topology.sheaves.limits
import topology.sheaves.skyscraper
import topology.sheaves.stalks
import category_theory.preadditive.injective

/-!
# Godement resolution

For a presheaf `𝓕 : (opens X)ᵒᵖ ⥤ C`, we can embedded `𝓕` into a sheaf `∏ₓ skyscraper(𝓕ₓ)` where
`x` ranges over `X` and `𝓕 ⟶ ∏ₓ skyscraper(𝓕ₓ)` is mono.

## Main definition
* `godement_presheaf`: for a presheaf `𝓕`, its Godement presheaf is `∏ₓ skyscraper(𝓕ₓ)`
* `to_godement_presheaf`: the canonical map `𝓕 ⟶ godement_presheaf 𝓕` sending `s : 𝓕(U)` to a
  bundle of stalks `x ↦ sₓ`.
-/

noncomputable theory

section presheaf

open Top
open topological_space
open category_theory
open category_theory.limits

universes u v

variables {X : Top.{u}} {C : Type u} [category.{u} C]
variables [has_limits C] [has_terminal C] [has_colimits C]
variables [Π (x : X) (U : opens X), decidable (x ∈ U)]
variables (𝓕 : presheaf C X)

/--
The `godement_presheaf` for a presheaf `𝓕` is defined as a product presheaf `∏ₓ skyscraper(𝓕ₓ)`
-/
def godement_presheaf : presheaf C X :=
∏ (λ x, skyscraper_presheaf x (𝓕.stalk x) : X → presheaf C X)

/--
The sections of `godement_presheaf` on opens `U` is isomorphic to `∏ₓ skyscraper(x, 𝓕ₓ)(U)`, i.e.
the categorical definition and the concrete definition agree.
-/
@[simps] def godement_presheaf_obj (U : (opens X)ᵒᵖ) :
  (godement_presheaf 𝓕).obj U ≅ ∏ (λ x, (skyscraper_presheaf x (𝓕.stalk x)).obj U) :=
limit_obj_iso_limit_comp_evaluation _ _ ≪≫
{ hom := lim_map { app := λ _, 𝟙 _, naturality' := by { rintros ⟨x⟩ ⟨y⟩ ⟨⟨(rfl : x = y)⟩⟩, refl } },
  inv := lim_map { app := λ _, 𝟙 _, naturality' := by { rintros ⟨x⟩ ⟨y⟩ ⟨⟨(rfl : x = y)⟩⟩, refl } },
  hom_inv_id' :=
  begin
    ext,
    erw [category.assoc, lim_map_π, ←category.assoc, lim_map_π, category.id_comp, category.comp_id,
      category.comp_id],
  end,
  inv_hom_id' :=
  begin
    dsimp,
    ext,
    erw [category.assoc, lim_map_π, ←category.assoc, lim_map_π, category.comp_id, category.id_comp,
      category.comp_id],
  end }

/--
Under the isomorphism `godement_presheaf(𝓕, U) ≅ ∏ₓ skyscraper(x, 𝓕ₓ)(U)`, there is a morphism
`𝓕 ⟶ ∏ₓ skyscraper(x, 𝓕ₓ) ≅ godement_presheaf(𝓕)`
-/
def to_godement_presheaf : 𝓕 ⟶ godement_presheaf 𝓕 :=
pi.lift $ λ p₀, (skyscraper_presheaf_stalk_adjunction p₀).unit.app 𝓕

end presheaf
