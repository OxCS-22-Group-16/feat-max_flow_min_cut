/-
Copyright (c) 2023 Monica Omar. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Monica Omar
-/
import linear_algebra.basic
import linear_algebra.projection

/-!
# Invariant submodules

In this file, we define and prove some basic results on invariant submodules.
-/

namespace submodule

variables {E R : Type*} [ring R] [add_comm_group E] [module R E]

/-- `U` is `T` invariant : `U ≤ U.comap` -/
def invariant_under (U : submodule R E) (T : E →ₗ[R] E) : Prop := U ≤ U.comap T

/-- `U` is `T` invariant if and only if `U.map T ≤ U` -/
lemma invariant_under_iff_map (U : submodule R E) (T : E →ₗ[R] E) :
  U.invariant_under T ↔ U.map T ≤ U := submodule.map_le_iff_le_comap.symm

/-- `U` is `T` invariant if and only if `set.maps_to T U U` -/
lemma invariant_under_iff_maps_to (U : submodule R E) (T : E →ₗ[R] E) :
  U.invariant_under T ↔ set.maps_to T U U := iff.rfl

/-- `U` is `T` invariant is equivalent to saying `T(U) ⊆ U` -/
lemma invariant_under_iff (U : submodule R E) (T : E →ₗ[R] E) :
  U.invariant_under T ↔ T '' U ⊆ U := by rw [← set.maps_to', U.invariant_under_iff_maps_to]

variables (U V : submodule R E) (hUV : is_compl U V) (T : E →ₗ[R] E)

local notation `pᵤ` := submodule.linear_proj_of_is_compl U V hUV
local notation `pᵥ` := submodule.linear_proj_of_is_compl V U hUV.symm

lemma proj_comp_self_comp_proj_eq_of_invariant_under
  (h : U.invariant_under T) (x : E) : ↑(pᵤ (T ↑(pᵤ x))) = T ↑(pᵤ x) :=
begin
  rw submodule.linear_proj_of_is_compl_eq_self_iff,
  exact h (submodule.coe_mem _),
end

lemma invariant_under_of_proj_comp_self_comp_proj_eq
  (h : ∀ x : E, ↑(pᵤ (T ↑(pᵤ x))) = T ↑(pᵤ x)) : U.invariant_under T :=
begin
  intros u hu,
  rw [submodule.mem_comap, ← submodule.linear_proj_of_is_compl_eq_self_iff hUV _,
      ← (submodule.linear_proj_of_is_compl_eq_self_iff hUV u).mpr hu, h],
end

lemma proj_comp_self_comp_proj_eq_iff_invariant_under :
  U.invariant_under T ↔ (∀ x : E, ↑(pᵤ (T ↑(pᵤ x))) = T ↑(pᵤ x)) :=
⟨U.proj_comp_self_comp_proj_eq_of_invariant_under V hUV T,
 U.invariant_under_of_proj_comp_self_comp_proj_eq V hUV T⟩

lemma proj_comp_self_comp_proj_eq_iff_invariant_under' :
  V.invariant_under T ↔ (∀ x : E, (pᵤ (T ↑(pᵤ x)) : E) = pᵤ (T x)) :=
by simp_rw [submodule.proj_comp_self_comp_proj_eq_iff_invariant_under _ _ hUV.symm,
            linear_proj_of_is_compl_eq_self_sub_linear_proj, map_sub, sub_eq_self,
            submodule.coe_sub, sub_eq_zero, eq_comm]

lemma compl_invariant_under_iff_linear_proj_and_T_commute :
  (U.invariant_under T ∧ V.invariant_under T) ↔ commute (U.subtype.comp (pᵤ)) T :=
begin
  simp_rw [commute, semiconj_by, linear_map.ext_iff, linear_map.mul_apply,
           linear_map.comp_apply, U.subtype_apply],
  split,
  { rintros ⟨h1, h2⟩ x,
    rw [← (U.proj_comp_self_comp_proj_eq_iff_invariant_under' V _ _).mp h2 x],
    exact (submodule.linear_proj_of_is_compl_eq_self_iff hUV _).mpr
      (h1 (set_like.coe_mem (pᵤ x))) },
  { intros h,
    split,
    { simp_rw [U.proj_comp_self_comp_proj_eq_iff_invariant_under _ hUV, h,
               submodule.linear_proj_of_is_compl_idempotent hUV],
      exact λ x, rfl },
    { simp_rw [U.proj_comp_self_comp_proj_eq_iff_invariant_under' _ hUV, h,
               submodule.linear_proj_of_is_compl_idempotent hUV],
      exact λ x, rfl } }
end

lemma commutes_with_linear_proj_iff_linear_proj_eq [invertible T] :
  commute (U.subtype.comp pᵤ) T ↔
    (⅟ T).comp ((U.subtype.comp pᵤ).comp T) = U.subtype.comp pᵤ :=
begin
  simp_rw [← linear_equiv.coe_of_invertible T, T.to_equiv_symm_eq_inv_of, commute, semiconj_by],
  simp_rw [← linear_equiv.to_linear_map_eq_coe, linear_map.mul_eq_comp],
  rw [eq_comm, ← linear_equiv.eq_to_linear_map_symm_comp, eq_comm],
end

lemma invariant_under_inv_iff_U_subset_image [invertible T] :
  U.invariant_under (⅟ T) ↔ ↑U ⊆ T '' U :=
begin
  simp_rw [← linear_equiv.coe_of_invertible T, T.to_equiv_symm_eq_inv_of],
  exact (U.invariant_under_iff (linear_equiv.of_invertible T).symm).trans
    ((linear_equiv.of_invertible T).to_equiv.symm.subset_image' _ _).symm,
end

theorem inv_linear_proj_comp_map_eq_linear_proj_iff_images_eq [invertible T] :
  (⅟ T).comp ((U.subtype.comp pᵤ).comp T) = U.subtype.comp pᵤ ↔ T '' U = U ∧ T '' V = V :=
begin
  simp_rw [← submodule.commutes_with_linear_proj_iff_linear_proj_eq,
           ← submodule.compl_invariant_under_iff_linear_proj_and_T_commute,
           set.subset.antisymm_iff],
  have Hu : ∀ p q r s, ((p ∧ q) ∧ r ∧ s) = ((p ∧ r) ∧ (q ∧ s)) := λ _ _ _ _, by
    { simp only [ and.assoc, eq_iff_iff, and.congr_right_iff],
      simp only [← and.assoc, and.congr_left_iff],
      simp only [and.comm], simp only [iff_self, implies_true_iff], },
  rw Hu,
  clear Hu,
  simp_rw [← submodule.invariant_under_iff _ _, iff_self_and,
           ← submodule.invariant_under_inv_iff_U_subset_image,
           submodule.compl_invariant_under_iff_linear_proj_and_T_commute U V hUV],
  rw [submodule.commutes_with_linear_proj_iff_linear_proj_eq, commute, semiconj_by],
  simp_rw [← linear_map.mul_eq_comp],
  intros h,
  rw ← h,
  simp_rw [mul_assoc _ _ (⅟ T), mul_inv_of_self, h],
  refl,
end

end submodule
