/-
Copyright (c) 2023 Monica Omar. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Monica Omar
-/
import linear_algebra.invariant_submodule
import analysis.inner_product_space.adjoint
import analysis.inner_product_space.spectrum
import linear_algebra.trace

/-!
# Finite-dimensional inner product spaces

In this file, we prove some results in finite-dimensional inner product spaces.

## Notation

This file uses the local notation `P _` for `orthogonal_projection _`
and `↥P _` for the extended orthogonal projection `orthogonal_projection' _`.

We let `V` be an inner product space over `𝕜`.
-/

variables {𝕜 V : Type*} [is_R_or_C 𝕜] [inner_product_space 𝕜 V]

local notation `P` := orthogonal_projection
local notation `↥P` := orthogonal_projection'

-- the extended orthogonal projection is an invariant subspace
lemma submodule.invariant_orthogonal_projection' (U : submodule 𝕜 V) [complete_space U] :
  U.invariant_under (↥P U) := λ x hx, set_like.coe_mem (P U x : U)

section
  --API from `https://github.com/leanprover-community/mathlib/pull/18243`
  lemma orthogonal_projection_eq_linear_proj (K : submodule 𝕜 V) [complete_space K] :
   (orthogonal_projection K : V →ₗ[𝕜] K) =
   submodule.linear_proj_of_is_compl K _ submodule.is_compl_orthogonal_of_complete_space :=
 begin
   have : is_compl K Kᗮ := submodule.is_compl_orthogonal_of_complete_space,
   ext x : 1,
   nth_rewrite 0 [← submodule.linear_proj_add_linear_proj_of_is_compl_eq_self this x],
   rw [continuous_linear_map.coe_coe, map_add, orthogonal_projection_mem_subspace_eq_self,
       orthogonal_projection_mem_subspace_orthogonal_complement_eq_zero (submodule.coe_mem _),
       add_zero]
 end

 lemma orthogonal_projection_eq_linear_proj' (K : submodule 𝕜 V) [complete_space K] (x : V) :
  orthogonal_projection K x =
  submodule.linear_proj_of_is_compl K _ submodule.is_compl_orthogonal_of_complete_space x :=
 by rw [← orthogonal_projection_eq_linear_proj]; refl
end

lemma orthogonal_projection'_eq_linear_proj (K : submodule 𝕜 V) [complete_space K] :
  (↥P K : V →ₗ[𝕜] V) = K.subtype.comp
  (submodule.linear_proj_of_is_compl K _ submodule.is_compl_orthogonal_of_complete_space) :=
begin
  ext x,
  simp_rw [continuous_linear_map.coe_coe, orthogonal_projection'_apply,
           orthogonal_projection_eq_linear_proj'],
  refl,
end

lemma orthogonal_projection'_eq_linear_proj' (K : submodule 𝕜 V) [complete_space K] (x : V) :
  (↥P K : V →ₗ[𝕜] V) x = K.subtype.comp
    (submodule.linear_proj_of_is_compl K _ submodule.is_compl_orthogonal_of_complete_space) x :=
by rw [← orthogonal_projection'_eq_linear_proj]

/-- if `U` is `T` invariant, then `(P U).comp T.comp (P U) = T.comp (P U)`
where `P U` is `orthogonal_projection U` -/
lemma submodule.invariant_under_imp_ortho_proj_comp_T_comp_ortho_proj_eq_T_comp_ortho_proj
  (U : submodule 𝕜 V) [complete_space U] (T : V →ₗ[𝕜] V)
  (h : U.invariant_under T) (x : V) : ↑(P U (T ↑(P U x))) = T ↑(P U x) :=
by simp_rw [orthogonal_projection_eq_linear_proj' U,
            U.proj_comp_self_comp_proj_eq_of_invariant_under _ _ _ h]

/-- if `(P U).comp T.comp (P U) = T.comp (P U)`, then `U` is `T` invariant,
where `P U` is `orthogonal_projection U` -/
lemma submodule.ortho_proj_comp_T_comp_ortho_proj_eq_T_comp_ortho_proj_imp_invariant
  (U : submodule 𝕜 V) [complete_space U] (T : V →ₗ[𝕜] V)
  (h : ∀ x : V, ↑(P U (T ↑(P U x))) = T ↑(P U x)) : U.invariant_under T :=
by { simp_rw [orthogonal_projection_eq_linear_proj'] at h,
     exact submodule.invariant_under_of_proj_comp_self_comp_proj_eq _ _ _ T h, }

lemma submodule.invariant_under_iff_ortho_proj_comp_T_comp_ortho_proj_eq_T_comp_ortho_proj
  (U : submodule 𝕜 V) [complete_space U] (T : V →ₗ[𝕜] V) :
  U.invariant_under T ↔ ∀ x : V, ↑(P U (T ↑(P U x))) = T ↑(P U x) :=
⟨λ h, submodule.invariant_under_imp_ortho_proj_comp_T_comp_ortho_proj_eq_T_comp_ortho_proj _ _ h,
 λ h, submodule.ortho_proj_comp_T_comp_ortho_proj_eq_T_comp_ortho_proj_imp_invariant _ _ h⟩

/-- `U,Uᗮ` are `T` invariant if and only if `commute (P U) T`,
where `P U` is `orthogonal_projection U` -/
lemma submodule.invariant_under_and_ortho_invariant_iff_ortho_proj_and_T_commute
  [complete_space V] (U : submodule 𝕜 V) [complete_space U] (T : V →ₗ[𝕜] V) :
  (U.invariant_under T ∧ Uᗮ.invariant_under T) ↔ commute ↑(↥P U) T :=
by rw [orthogonal_projection'_eq_linear_proj,
       U.compl_invariant_under_iff_linear_proj_and_T_commute]

/-- `commute (P U) T` if and only if `T⁻¹.comp (P U).comp T = P U`,
where `P U` is `orthogonal_projection U` -/
lemma ortho_proj_and_T_commute_iff_Tinv_comp_ortho_proj_comp_T_eq_ortho_proj
  (U : submodule 𝕜 V) [complete_space U] (T : V →L[𝕜] V) [invertible T] :
  commute (↥P U) T ↔ T.inverse.comp ((↥P U).comp T) = ↥P U :=
begin
  simp_rw [commute, semiconj_by, continuous_linear_map.ext_iff,
           continuous_linear_map.mul_apply, continuous_linear_map.comp_apply,
           ← continuous_linear_map.coe_coe,
           orthogonal_projection'_eq_linear_proj,
           ← linear_map.mul_apply, ← linear_map.ext_iff],
  rw [← semiconj_by, ← commute,
      submodule.commutes_with_linear_proj_iff_linear_proj_eq],
  refl,
end

/-- `T⁻¹ * (P U) * T = P U` if and only if `T(U) = U` and `T(Uᗮ) = Uᗮ`,
where `P U` is `orthogonal_projection U` -/
theorem T_inv_P_U_T_eq_P_U_iff_image_T_of_U_eq_U_and_image_T_of_U_ortho_eq_U_ortho
  [complete_space V] [finite_dimensional 𝕜 V] (U : submodule 𝕜 V) (T : V →L[𝕜] V) [invertible T] :
  T.inverse.comp ((↥P U).comp T) = ↥P U ↔ T '' U = U ∧ T '' Uᗮ = Uᗮ :=
by simp_rw [continuous_linear_map.ext_iff,
            continuous_linear_map.comp_apply,
            ← continuous_linear_map.coe_coe _,
            orthogonal_projection'_eq_linear_proj',
            ← linear_map.comp_apply,
            ← linear_map.ext_iff,
            continuous_linear_map.coe_coe,
            submodule.inv_linear_proj_comp_map_eq_linear_proj_iff_images_eq]

/-- `U` is `T` invariant if and only if `Uᗮ` is `T.adjoint` invariant -/
theorem submodule.invariant_under_iff_ortho_adjoint_invariant
  [finite_dimensional 𝕜 V] (U : submodule 𝕜 V) (T : V →ₗ[𝕜] V) :
  submodule.invariant_under U T ↔ submodule.invariant_under Uᗮ T.adjoint :=
begin
  suffices : ∀ U : submodule 𝕜 V, ∀ T : V →ₗ[𝕜] V,
   submodule.invariant_under U T → submodule.invariant_under Uᗮ T.adjoint,
     {  split,
        exact this U T,
        intro h,
        rw [← linear_map.adjoint_adjoint T,
            ← submodule.orthogonal_orthogonal U],
        apply this,
        exact h, },
  clear U T,
  simp only [ submodule.invariant_under_iff, set_like.mem_coe,
              set.image_subset_iff, set.subset_def, set.mem_image,
              forall_exists_index, and_imp, forall_apply_eq_imp_iff₂ ],
  intros U T h x hx y hy,
  rw linear_map.adjoint_inner_right,
  apply (submodule.mem_orthogonal U x).mp hx,
  apply h y hy,
end

/-- `T` is self adjoint implies
`U` is `T` invariant if and only if `Uᗮ` is `T` invariant -/
lemma is_self_adjoint.submodule_invariant_iff_ortho_submodule_invariant
  [finite_dimensional 𝕜 V] (U : submodule 𝕜 V) (T : V →ₗ[𝕜] V) (h : is_self_adjoint T) :
  submodule.invariant_under U T ↔ submodule.invariant_under Uᗮ T :=
by rw [ submodule.invariant_under_iff_ortho_adjoint_invariant,
        linear_map.is_self_adjoint_iff'.mp h ]

/-- `T.ker = (T.adjoint.range)ᗮ` -/
lemma ker_is_ortho_adjoint_range {W : Type*} [finite_dimensional 𝕜 V]
  [inner_product_space 𝕜 W] [finite_dimensional 𝕜 W] (T : V →ₗ[𝕜] W) :
  T.ker = (T.adjoint.range)ᗮ :=
begin
  ext,
  simp only [linear_map.mem_ker, submodule.mem_orthogonal,
             linear_map.mem_range, forall_exists_index,
             forall_apply_eq_imp_iff', linear_map.adjoint_inner_left],
  exact ⟨ λ h, by simp only [h, inner_zero_right, forall_const],
          λ h, inner_self_eq_zero.mp (h (T x))⟩,
end

/-- given any idempotent operator `T ∈ L(V)`, then `is_compl T.ker T.range`,
in other words, there exists unique `v ∈ T.ker` and `w ∈ T.range` such that `x = v + w` -/
lemma linear_map.is_idempotent.is_compl_range_ker {V R : Type*} [ring R] [add_comm_group V] [module R V] (T : V →ₗ[R] V) (h : is_idempotent_elem T) :
  is_compl T.ker T.range :=
begin
 split,
   { rw disjoint_iff,
     ext,
     simp only [submodule.mem_bot, submodule.mem_inf, linear_map.mem_ker,
                linear_map.mem_range, continuous_linear_map.to_linear_map_eq_coe,
                continuous_linear_map.coe_coe],
     split,
       { intro h',
         cases h'.2 with y hy,
         rw [← hy, ← is_idempotent_elem.eq h, linear_map.mul_apply, hy],
         exact h'.1, },
       { intro h',
         rw [h', map_zero],
         simp only [eq_self_iff_true, true_and],
         use x,
         simp only [h', map_zero, eq_self_iff_true], }, },
    { suffices : ∀ x : V, ∃ v : T.ker, ∃ w : T.range, x = v + w,
        { rw [codisjoint_iff, ← submodule.add_eq_sup],
          ext,
          rcases this x with ⟨v,w,hvw⟩,
          simp only [submodule.mem_top, iff_true, hvw],
          apply submodule.add_mem_sup (set_like.coe_mem v) (set_like.coe_mem w), },
      intro x,
      use (x-(T x)), rw [linear_map.mem_ker, map_sub,
                         ← linear_map.mul_apply, is_idempotent_elem.eq h, sub_self],
      use (T x), rw [linear_map.mem_range]; simp only [exists_apply_eq_apply],
      simp only [submodule.coe_mk, sub_add_cancel], }
end

/-- idempotent `T` is self-adjoint if and only if `(T.ker)ᗮ = T.range` -/
theorem linear_map.is_idempotent_is_self_adjoint_iff_ker_is_ortho_to_range
  [inner_product_space ℂ V] [finite_dimensional ℂ V] (T : V →ₗ[ℂ] V) (h : is_idempotent_elem T) :
  is_self_adjoint T ↔ (T.ker)ᗮ = T.range :=
begin
  rw linear_map.is_self_adjoint_iff',
  split,
    { intros l, rw [ker_is_ortho_adjoint_range, submodule.orthogonal_orthogonal],
      revert l, exact congr_arg linear_map.range, },
    { intro h1, apply eq_of_sub_eq_zero,
      simp only [← inner_map_self_eq_zero],
      intro x,
      obtain ⟨v, w, hvw, hunique⟩ :=
        submodule.exists_unique_add_of_is_compl
        (linear_map.is_idempotent.is_compl_range_ker T h) x,
      simp only [linear_map.sub_apply, inner_sub_left, linear_map.adjoint_inner_left],
      cases (set_like.coe_mem w) with y hy,
      rw [← hvw, map_add, linear_map.mem_ker.mp (set_like.coe_mem v),
          ← hy, ← linear_map.mul_apply, is_idempotent_elem.eq h, zero_add, hy, inner_add_left,
          inner_add_right, ← inner_conj_sym ↑w ↑v, (submodule.mem_orthogonal T.ker ↑w).mp
            (by { rw h1, exact set_like.coe_mem w }) v (set_like.coe_mem v),
          map_zero, zero_add, sub_self], },
end

/-- `U` and `W` are mutually orthogonal if and only if `(P U).comp (P W) = 0`,
where `P U` is `orthogonal_projection U` -/
lemma ortho_spaces_iff_ortho_proj_comp_ortho_proj_eq_0 [inner_product_space ℂ V]
  [finite_dimensional ℂ V] (U W : submodule ℂ V) :
  (∀ x y, x ∈ U ∧ y ∈ W → ⟪x,y⟫_ℂ = 0) ↔ (↥P U).comp (↥P W) = 0 :=
begin
  split,
  { intros h,
    ext v,
    rw [continuous_linear_map.comp_apply, continuous_linear_map.zero_apply,
        ← inner_self_eq_zero, orthogonal_projection'_apply, orthogonal_projection'_apply,
        ← inner_orthogonal_projection_left_eq_right,
        orthogonal_projection_mem_subspace_eq_self],
    apply h, simp only [submodule.coe_mem, and_self], },
  { intros h x y hxy,
    rw [← orthogonal_projection_eq_self_iff.mpr hxy.1,
        ← orthogonal_projection_eq_self_iff.mpr hxy.2,
        inner_orthogonal_projection_left_eq_right,
        ← orthogonal_projection'_apply, ← orthogonal_projection'_apply,
        ← continuous_linear_map.comp_apply, h,
        continuous_linear_map.zero_apply, inner_zero_right], }
end

section is_star_normal
open linear_map

/-- linear map `is_star_normal` if and only if it commutes with its adjoint -/
lemma linear_map.is_star_normal_iff_adjoint [finite_dimensional 𝕜 V] (T : V →ₗ[𝕜] V) :
  is_star_normal T ↔ commute T T.adjoint :=
by rw commute.symm_iff; exact ⟨λ hT, hT.star_comm_self, is_star_normal.mk⟩

/-- `T` is normal if and only if `∀ v, ‖T v‖ = ‖T.adjoint v‖` -/
lemma linear_map.is_star_normal.norm_eq_adjoint [inner_product_space ℂ V]
  [finite_dimensional ℂ V] (T : V →ₗ[ℂ] V) :
  is_star_normal T ↔ ∀ v : V, ‖T v‖ = ‖T.adjoint v‖ :=
begin
  rw [T.is_star_normal_iff_adjoint, commute, semiconj_by, ← sub_eq_zero],
  simp only [← inner_map_self_eq_zero, sub_apply, inner_sub_left, mul_apply,
             adjoint_inner_left, inner_self_eq_norm_sq_to_K],
  simp only [← adjoint_inner_right T, inner_self_eq_norm_sq_to_K, sub_eq_zero,
             ← sq_eq_sq (norm_nonneg _) (norm_nonneg _)],
  norm_cast,
  exact ⟨λ h x, (h x).symm, λ h x, (h x).symm⟩,
end

/-- if `T` is normal, then `T.ker = T.adjoint.ker` -/
lemma linear_map.is_star_normal.ker_eq_ker_adjoint [inner_product_space ℂ V]
  [finite_dimensional ℂ V] (T : V →ₗ[ℂ] V) (h : is_star_normal T) : T.ker = T.adjoint.ker :=
by ext; rw [mem_ker, mem_ker, ← norm_eq_zero, iff.comm,
            ← norm_eq_zero, ← (linear_map.is_star_normal.norm_eq_adjoint T).mp h]
/-- if `T` is normal, then `T.range = T.adjoint.range` -/
lemma linear_map.is_star_normal.range_eq_range_adjoint [inner_product_space ℂ V]
  [finite_dimensional ℂ V] (T : V →ₗ[ℂ] V) (h : is_star_normal T) : T.range = T.adjoint.range :=
by rw [← submodule.orthogonal_orthogonal T.adjoint.range, ← ker_is_ortho_adjoint_range,
       linear_map.is_star_normal.ker_eq_ker_adjoint T h,
       ker_is_ortho_adjoint_range, adjoint_adjoint,
       submodule.orthogonal_orthogonal]

open_locale complex_conjugate
open module.End
/-- if `T` is normal, then `∀ x : V, x ∈ eigenspace T μ ↔ x ∈ eigenspace T.adjoint (conj μ)` -/
lemma linear_map.is_star_normal.eigenvec_in_eigenspace_iff_eigenvec_in_adjoint_conj_eigenspace
  [inner_product_space ℂ V] [finite_dimensional ℂ V] (T : V →ₗ[ℂ] V) (h : is_star_normal T)
  (μ : ℂ) : ∀ x : V, x ∈ eigenspace T μ ↔ x ∈ eigenspace T.adjoint (conj μ) :=
begin
  suffices : ∀ T : V →ₗ[ℂ] V, is_star_normal T →
    ∀ μ : ℂ, ∀ v : V, v ∈ eigenspace T μ → v ∈ eigenspace T.adjoint (conj μ),
  { intro v, refine ⟨this T h μ v, _⟩,
    intro hv, rw [← adjoint_adjoint T, ← is_R_or_C.conj_conj μ],
    apply this _ _ _ _ hv, exact is_star_normal_star_self, },
  clear h μ T,
  intros T h μ v hv,
  have t1 : (T - μ•1) v = 0,
  { rw [sub_apply, smul_apply, one_apply, sub_eq_zero],
    exact mem_eigenspace_iff.mp hv, },
  suffices : (T.adjoint - (conj μ)•1) v = 0,
  { rw [mem_eigenspace_iff, ← sub_eq_zero],
    rw [sub_apply, smul_apply, one_apply] at this, exact this, },
  rw ← norm_eq_zero,
  have nh : is_star_normal (T-μ•1),
  { apply is_star_normal.mk,
    rw [star_sub, star_smul, is_R_or_C.star_def, star_one, commute, semiconj_by],
    simp only [sub_mul, mul_sub, commute.eq h.star_comm_self],
    simp only [smul_one_mul, smul_smul, mul_smul_comm, mul_one],
    rw [mul_comm, sub_sub_sub_comm], },
  have : (T-μ•1).adjoint = T.adjoint - (conj μ)•1 :=
  by simp only [← star_eq_adjoint, star_sub, star_smul, is_R_or_C.star_def, star_one],
  rw [← this, ← (linear_map.is_star_normal.norm_eq_adjoint (T-μ•1)).mp nh, t1, norm_zero],
end
end is_star_normal

/-- `T` is injective if and only if `T.adjoint` is surjective  -/
lemma linear_map.injective_iff_adjoint_surjective
  {W : Type*} [inner_product_space 𝕜 W] [finite_dimensional 𝕜 W]
  [finite_dimensional 𝕜 V] (T : V →ₗ[𝕜] W) :
  function.injective T ↔ function.surjective T.adjoint :=
by rw [ ← linear_map.ker_eq_bot, ← linear_map.range_eq_top,
        ker_is_ortho_adjoint_range, submodule.orthogonal_eq_bot_iff ]
