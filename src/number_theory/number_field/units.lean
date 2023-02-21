/-
Copyright (c) 2023 Xavier Roblot. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Xavier Roblot
-/
import group_theory.torsion
import number_theory.number_field.norm
import number_theory.number_field.embeddings

/-!
 # Units of a number field
 This file defines and proves results about the group `𝓤 K` of units of the ring of integers of a
 number field `K`.

 ## Tags
 number field, units
 -/

open_locale classical number_field

noncomputable theory

variables (K : Type*) [field K]

localized "notation `𝓤`K := (number_field.ring_of_integers K)ˣ" in number_field.units

namespace number_field

open number_field units

/-- The `monoid_hom` from the group of units to the field. -/
def units_to_field : (𝓤 K) →* K := monoid_hom.comp (coe_hom K) (map (algebra_map (𝓞 K) K))

lemma units_to_field_injective : function.injective (units_to_field K) :=
begin
  have t1 : function.injective (coe_hom K) := by ext,
  have t2 : function.injective (units.map (algebra_map (𝓞 K) K).to_monoid_hom) :=
  begin
    intros x y hxy,
    rw units.ext_iff,
    have t1 := congr_arg (coe : Kˣ → K) hxy,
    simp_rw [units.coe_map] at t1,
    exact (no_zero_smul_divisors.algebra_map_injective (𝓞 K) K) t1,
  end,
  rw [units_to_field, monoid_hom.coe_comp],
  exact function.injective.comp t1 t2,
end

instance ring_of_integers.units.has_coe : has_coe (𝓤 K) K := ⟨units_to_field K⟩

section coe

namespace number_field.unit

variable {K}

@[simp]
lemma coe_ext {x y : 𝓤 K} : (x : K) = (y : K) ↔ x = y := (units_to_field_injective K).eq_iff

@[simp]
lemma coe_inv {x : 𝓤 K} : ((x⁻¹ : 𝓤 K) : K) = (x : K)⁻¹ := map_inv (units_to_field K) x

@[simp]
lemma coe_pow {x : 𝓤 K} {n : ℕ} : ((x ^ n : 𝓤 K) : K) = (x : K) ^ n :=
  map_pow (units_to_field K) x n

@[simp]
lemma coe_zpow {x : 𝓤 K} {n : ℤ} : ((x ^ n : 𝓤 K) : K) = (x : K) ^ n :=
  map_zpow (units_to_field K) x n

@[simp]
lemma coe_mul {x y : 𝓤 K} : ((x * y : 𝓤 K) : K) = (x : K) * (y : K) := rfl

@[simp]
lemma coe_coe {x : 𝓤 K} : ((x : 𝓞 K) : K) = (x : K) := rfl

@[simp]
lemma coe_one : ((1 : 𝓤 K) : K) = (1 : K) := rfl

@[simp]
lemma coe_ne_zero {x : 𝓤 K} : (x : K) ≠ 0 :=
subtype.coe_injective.ne_iff.2 (units.ne_zero x)

end number_field.unit

end coe

-- TODO. That should be tautological
lemma is_unit_iff (x : 𝓞 K) (hx : x ≠ 0):
  is_unit x ↔ is_integral ℤ (x⁻¹ : K) :=
begin
  split,
  { rintros ⟨u, rfl⟩,
    convert ring_of_integers.is_integral_coe u.inv,
    simp only [number_field.unit.coe_coe, inv_eq_coe_inv, number_field.unit.coe_inv], },
  { intro h,
    rw is_unit_iff_exists_inv,
    use ⟨x⁻¹, h⟩,
    apply @subtype.coe_injective K (λ x, x ∈ 𝓞 K),
    simp only [mul_mem_class.coe_mul, subtype.coe_mk, algebra_map.coe_one],
    refine mul_inv_cancel _,
    exact (@subtype.coe_injective K (λ x, x ∈ 𝓞 K)).ne hx, },
end

-- TODO. Make that an iff and simplify the proof
lemma unit.abs_norm [number_field K] (u : 𝓤 K) :
  abs (ring_of_integers.norm ℚ (u : 𝓞 K) : ℚ) = 1 :=
begin
  have t1 := congr_arg (λ x, (ring_of_integers.norm ℚ) x) u.val_inv,
  have t2 := congr_arg rat.ring_of_integers_equiv t1,
  have t3 := congr_arg abs t2,
  simp_rw [map_mul, abs_mul, map_one, abs_one] at t3,
  have t4 := dvd.intro _ t3,
  have t5 :=  int.eq_one_of_dvd_one (abs_nonneg _) t4,
  rw ← abs_one at t5 ⊢,
  rw abs_eq_abs at t5 ⊢,
  cases t5,
  { left,
    have := congr_arg rat.ring_of_integers_equiv.symm t5,
    rw ring_equiv.symm_apply_apply _ _ at this,
    rw map_one at this,
    exact congr_arg (coe : (𝓞 ℚ) → ℚ) this, },
  { right,
    have := congr_arg rat.ring_of_integers_equiv.symm t5,
    rw ring_equiv.symm_apply_apply _ _ at this,
    rw ring_equiv.map_neg_one at this,
    exact congr_arg (coe : (𝓞 ℚ) → ℚ) this, }
end

section roots_of_unity

open number_field number_field.infinite_place

/-- The subgroup of roots of unity. -/
def roots_of_unity : subgroup 𝓤 K := comm_group.torsion (𝓤 K)

lemma mem_roots_of_unity [number_field K] (x : (𝓤 K)) :
  x ∈ roots_of_unity K ↔ ∀ w : infinite_place K, w x = 1 :=
begin
  rw (eq_iff_eq x 1 : (∀ w : infinite_place K, w x = 1) ↔ ∀ (φ : K →+* ℂ), ‖φ (x : K)‖ = 1),
  rw [roots_of_unity, comm_group.mem_torsion, is_of_fin_order_iff_pow_eq_one],
  split,
  { rintros ⟨n, ⟨hn1, hn2⟩⟩ φ,
    lift n to ℕ+ using hn1,
    rw [ ← number_field.unit.coe_ext, number_field.unit.coe_pow] at hn2,
    exact norm_map_one_of_pow_eq_one φ.to_monoid_hom hn2, },
  { intro h,
    obtain ⟨n , ⟨hn, hx⟩⟩ := embeddings.pow_eq_one_of_norm_eq_one K ℂ x.1.2 h,
    exact ⟨n, ⟨hn, by { rwa [← number_field.unit.coe_ext, number_field.unit.coe_pow], }⟩⟩, },
end

lemma finite_roots_of_unity [number_field K]: finite (roots_of_unity K) :=
begin
  suffices : ((coe : (𝓤 K) → K) '' { x : (𝓤 K) | x ∈ (roots_of_unity K )}).finite,
  { exact set.finite_coe_iff.mpr (set.finite.of_finite_image this
      ((units_to_field_injective K).inj_on _)), },
  refine (embeddings.finite_of_norm_le K ℂ 1).subset _,
  rintros a ⟨⟨u, _, _, _⟩, ⟨hu, rfl⟩⟩,
  split,
  { exact u.2, },
  { rw ← le_iff_le,
    convert λ w, le_of_eq (((mem_roots_of_unity K _).mp hu) w) using 1, },
end

lemma roots_of_unity_cyclic [number_field K]: is_cyclic (roots_of_unity K) :=
begin
  haveI := finite_roots_of_unity K,
  exact subgroup_units_cyclic _,
end

end roots_of_unity

namespace dirichlet

open number_field.canonical_embedding

@[reducible]
def log_embedding : (𝓤 K) → (number_field.infinite_place K → ℝ) := λ x w, real.log (w x)

open units number_field number_field.infinite_place number_field.dirichlet finite_dimensional

lemma log_embedding.map_one : log_embedding K 1 = 0 :=
by simpa only [log_embedding, number_field.unit.coe_one, map_one, real.log_one]

lemma log_embedding.map_mul (x y : 𝓤 K) :
  log_embedding K (x * y) = log_embedding K x + log_embedding K y :=
by simpa only [log_embedding, real.log_mul, number_field.unit.coe_mul, map_mul, ne.def,
  map_eq_zero, number_field.unit.coe_ne_zero, not_false_iff]

lemma log_embedding.map_inv (x : 𝓤 K) : log_embedding K x⁻¹ = - log_embedding K x :=
by simpa only [log_embedding, real.log_inv, number_field.unit.coe_inv, map_inv₀]

lemma log_embedding.map_pow (x : 𝓤 K) (n : ℤ) : log_embedding K (x ^ n) = n * log_embedding K x :=
by simpa only [log_embedding, map_zpow₀, real.log_zpow, number_field.unit.coe_zpow]

lemma log_embedding.eq_zero_iff (x : 𝓤 K) :
  log_embedding K x = 0 ↔ (∀ w : infinite_place K, w x = 1) :=
begin
  dsimp only [log_embedding],
  rw function.funext_iff,
  simp_rw pi.zero_apply,
  split,
  { exact λ h w, real.eq_one_of_pos_of_log_eq_zero (pos_iff.mpr
      number_field.unit.coe_ne_zero) (h w), },
  { intros h w,
    simp only [h w, real.log_one], },
end

@[simp]
lemma log_embedding.component (w : infinite_place K) (x : 𝓤 K) :
  (log_embedding K x) w = real.log (w x) := rfl

lemma log_embedding.nnnorm_eq [number_field K] (x : 𝓤 K) :
  ‖log_embedding K x‖₊ = finset.univ.sup (λ w : infinite_place K, ‖real.log (w x)‖₊ ) :=
by simp only [pi.nnnorm_def, log_embedding]

lemma log_embedding.le_of_le [number_field K] (x : 𝓤 K) (r : ℝ) :
  ‖log_embedding K x‖ ≤ r ↔ ∀ w : infinite_place K, real.exp (- r) ≤ w x ∧ w x ≤ real.exp r :=
begin
   obtain hr | hr := lt_or_le r 0,
  { split,
    { intro h, exfalso,
      exact (not_le.mpr (lt_of_le_of_lt h hr)) (norm_nonneg _), },
    { intro h, exfalso,
      obtain ⟨w⟩ := infinite_place.nonempty K,
      have := real.exp_le_exp.mp (le_trans (h w).1 (h w).2),
      linarith, }},
  { lift r to nnreal using hr,
    simp_rw [← coe_nnnorm, log_embedding.nnnorm_eq, nnreal.coe_le_coe, finset.sup_le_iff,
      finset.mem_univ, forall_true_left, ← nnreal.coe_le_coe, coe_nnnorm, real.norm_eq_abs, abs_le],
    split,
    { intros h w,
      specialize h w,
      rwa [← real.log_le_iff_le_exp, ← real.le_log_iff_exp_le],
      all_goals { exact infinite_place.pos_iff.mpr number_field.unit.coe_ne_zero, }},
    { intros h w,
      specialize h w,
      rwa [real.log_le_iff_le_exp, real.le_log_iff_exp_le],
      all_goals { exact infinite_place.pos_iff.mpr number_field.unit.coe_ne_zero, }}}
end

def unit_lattice : submodule ℤ (number_field.infinite_place K → ℝ) :=
{ carrier := set.range (log_embedding K),
  add_mem' :=
  begin
    rintros _ _ ⟨u, ⟨hu, rfl⟩⟩ ⟨v, ⟨hv, rfl⟩⟩,
    exact ⟨u * v, log_embedding.map_mul K u v⟩,
  end,
  zero_mem' := ⟨1, log_embedding.map_one K⟩,
  smul_mem' :=
  begin
    rintros r w ⟨x, ⟨hx, rfl⟩⟩,
    refine ⟨x ^ r, by simpa only [zsmul_eq_mul] using log_embedding.map_pow K x r⟩,
  end }

variable [number_field K]

lemma unit_lattice_kernel (x : 𝓤 K) :
  log_embedding K x = 0 ↔ x ∈ roots_of_unity K :=
by rw [log_embedding.eq_zero_iff, mem_roots_of_unity K x]

lemma unit_lattice_discrete (r : ℝ) :
  ((unit_lattice K : set (number_field.infinite_place K → ℝ)) ∩ (metric.closed_ball 0 r)).finite :=
begin
  obtain hr | hr := lt_or_le r 0,
  { convert set.finite_empty,
    rw metric.closed_ball_eq_empty.mpr hr,
    exact set.inter_empty _, },
  { let A := {x : 𝓤 K  | is_integral ℤ (x : K) ∧ ∀ φ : (K →+* ℂ), ‖φ x‖ ≤ real.exp r},
    have t1 : A.finite,
    { suffices : ((coe : (𝓤 K) → K) '' A).finite,
      { refine this.of_finite_image (set.inj_on_of_injective (units_to_field_injective K) _), },
      refine set.finite.subset (embeddings.finite_of_norm_le K ℂ (real.exp r)) _,
      rintros _ ⟨x, ⟨hx, rfl ⟩⟩,
      exact hx, },
    have t2 : ((log_embedding K) '' A).finite := set.finite.image _ t1,
    refine t2.subset _,
    rintros _ ⟨⟨x, ⟨hx1, rfl⟩⟩, hx2⟩,
    use x,
    split,
    { split,
      { exact ring_of_integers.is_integral_coe x, },
      { rw ← le_iff_le,
        rw mem_closed_ball_zero_iff at hx2,
        rw log_embedding.le_of_le at hx2,
        intro w,
        exact (hx2 w).2, }},
    { refl, }},
end

lemma unit_lattice_countable : countable (unit_lattice K) :=
begin
  suffices : (⋃ n : ℕ,
    ((unit_lattice K : set (number_field.infinite_place K → ℝ)) ∩
      (metric.closed_ball 0 n))).countable,
  { refine set.countable.to_subtype (set.countable.mono _ this),
    rintros _ ⟨x, ⟨hx, rfl⟩⟩,
    rw set.mem_Union,
    use nat.ceil (‖log_embedding K x‖),
    exact ⟨⟨x, rfl⟩, mem_closed_ball_zero_iff.mpr (nat.le_ceil _)⟩, },
  { exact set.countable_Union (λ n, (unit_lattice_discrete K n).countable), },
end

def lognorm : (number_field.infinite_place K → ℝ) →ₗ[ℝ] ℝ :=
{ to_fun := λ x, finset.univ.sum (λ w : infinite_place K, ite (w.is_real) (x w) (2*(x w))),
  map_add' :=
  begin
    intros x y,
    simp_rw [← finset.sum_add_distrib, pi.add_apply, mul_add],
    congr,
    ext,
    split_ifs ; refl
  end,
  map_smul' :=
  begin
    intros r x,
    simp_rw [finset.smul_sum, ring_hom.id_apply, pi.smul_apply, algebra.id.smul_eq_mul],
    congr,
    ext,
    split_ifs,
    refl,
    ring,
  end }

lemma lognorm_unit (x : 𝓤 K) :
  lognorm K (log_embedding K x) = 0 :=
begin
  convert congr_arg real.log (prod_eq_abs_norm K x),
  { rw [lognorm, linear_map.coe_mk, real.log_prod],
    { congr,
      simp_rw [log_embedding.component, apply_ite real.log, real.log_pow, nat.cast_two], },
    { intros x _,
      split_ifs;
      simp only [ne.def, map_eq_zero, number_field.unit.coe_ne_zero, not_false_iff, pow_eq_zero_iff,
        nat.succ_pos'], }},
  rw ← number_field.unit.coe_coe,
  rw ← ring_of_integers.norm_apply_coe ℚ (x : 𝓞 K),
  rw ← rat.cast_abs,
  rw unit.abs_norm K x,
  simp only [algebra_map.coe_one, real.log_one],
end

lemma lognorm_surjective : function.surjective (lognorm K) :=
begin
  cases linear_map.surjective_or_eq_zero (lognorm K),
  { exact h, },
  { exfalso,
    suffices : finset.univ.sum (λ w : infinite_place K, ite (w.is_real) 1 2) ≠ 0,
    { have t1 : lognorm K 1 ≠ 0,
      { convert nat.cast_ne_zero.2 this,
        simp only [lognorm, linear_map.coe_mk, pi.one_apply, mul_one, nat.cast_sum, nat.cast_ite,
          algebra_map.coe_one, nat.cast_bit0],
        apply_instance, },
      have t2 := linear_map.congr_fun h 1,
      exact t1 t2, },
    by_contra,
    rw finset.sum_eq_zero_iff at h,
    obtain ⟨w⟩ := infinite_place.nonempty K,
    have := h w (finset.mem_univ w),
    split_ifs at this ;
    norm_num at h, },
end

def unit_rank : ℕ := fintype.card (infinite_place K) - 1

lemma rank_ker : finrank ℝ (linear_map.ker (lognorm K)) = unit_rank K :=
begin
  have t1 : finrank ℝ (number_field.infinite_place K → ℝ) = fintype.card (infinite_place K) :=
    module.free.finrank_pi ℝ,
  have t2 : 0 < fintype.card (infinite_place K) := fintype.card_pos,
  rw [unit_rank, ← t1],
  have t3 := (lognorm K).finrank_range_add_finrank_ker,
  suffices : finrank ℝ (linear_map.range (lognorm K)) = 1,
  { rw this at t3,
    zify at ⊢ t3,
    have := eq_sub_of_add_eq' t3,
    convert this,
    simp only [*, nat.cast_pred], },
  have : linear_map.range (lognorm K) = ⊤ :=
  begin
    have z1 := lognorm_surjective K,
    exact (ideal.eq_top_iff_one (linear_map.range (lognorm K))).mpr (z1 1),
  end,
  have t4 := congr_arg (λ M : submodule ℝ ℝ, finrank ℝ M) this,
  have t5 := finrank_self ℝ,
  rw ← finrank_top at t5,
  dsimp at t4,
  rwa ← t4 at t5,
end

lemma unit_lattice_le : unit_lattice K ≤ submodule.restrict_scalars ℤ (linear_map.ker (lognorm K))
:=
begin
  rintros _ ⟨u, rfl⟩,
  rw submodule.restrict_scalars_mem,
  rw linear_map.mem_ker,
  exact lognorm_unit K u,
end

def unit_lattice_le_map := submodule.of_le (unit_lattice_le K)

def unit_lattice_submodule : submodule ℤ (linear_map.ker (lognorm K)) :=
(unit_lattice_le_map K).range

def unit_lattice_equiv : unit_lattice K ≃ₗ[ℤ] (unit_lattice_submodule K) :=
begin
  refine linear_equiv.of_bijective (unit_lattice_le_map K).range_restrict _,
  split,
  { intros _ _ h,
    apply submodule.of_le_injective (unit_lattice_le K),
    have := congr_arg (submodule.subtype _ ) h,
    exact this,  },
  { rintros ⟨_, ⟨u, rfl⟩⟩,
    use u, refl, },
end

lemma unit_lattice_submodule_discrete (r : ℝ) :
  ((unit_lattice_submodule K : set (linear_map.ker (lognorm K))) ∩ (metric.closed_ball 0 r)).finite
  :=
begin
  refine set.finite.of_finite_image _ (set.inj_on_of_injective (submodule.injective_subtype _) _),
  refine set.finite.subset (unit_lattice_discrete K r) _,
  rintros _ ⟨⟨x, _⟩, ⟨⟨⟨u, hu⟩, hx2⟩, rfl⟩⟩,
  split,
  { rw ← hu,
    exact set_like.coe_mem u, },
  { exact hx2, },
end

variable {K}

def w₀ : infinite_place K := (infinite_place.nonempty K).some

lemma _root_.number_field.norm_cast (a : 𝓞 K) :
  algebra.norm ℚ (algebra_map (𝓞 K) K a) = algebra_map ℤ ℚ (algebra.norm ℤ a) :=
algebra.norm_localization ℤ (non_zero_divisors ℤ) a

variable (K)

def unit_lattice_span_map :
  submodule.span ℝ (unit_lattice_submodule K : set (linear_map.ker (lognorm K)))
    →ₗ[ℝ] ({w : infinite_place K // w ≠ w₀} → ℝ) :=
{ to_fun := λ v w, ite ((w : infinite_place K).is_real)
    ((v : number_field.infinite_place K → ℝ) w) (2 * ((v : number_field.infinite_place K → ℝ) w)),
  map_add' :=
  begin
    intros _ _,
    ext,
    split_ifs,
    { simp only [coe_coe, submodule.coe_add, pi.add_apply, if_pos h], },
    { simp only [coe_coe, submodule.coe_add, pi.add_apply, if_neg h, mul_add], },
  end,
  map_smul' :=
  begin
    intros s x,
    ext,
    split_ifs,
    { simp only [if_pos h, coe_coe, submodule.coe_smul_of_tower, pi.smul_apply,
        ring_hom.id_apply], },
    { simp only [if_neg h, coe_coe, submodule.coe_smul_of_tower, pi.smul_apply,
        algebra.id.smul_eq_mul, ring_hom.id_apply],
      ring, },
  end, }

  lemma seq.exists (w : infinite_place K) {f : infinite_place K → nnreal} (hf : ∀ z, z ≠ w → f z ≠ 0)
  (B : ℕ) : ∃ C : nnreal,
    finset.univ.prod (λ v : infinite_place K, ite (v.is_real) (f.update w C v)
    ((f.update w C v) ^ 2)) = B :=
begin
  let S := (finset.univ.erase w).prod (λ v : infinite_place K, ite (v.is_real) (f v) (f v ^ 2)),
  have hS : S ≠ 0,
  { refine finset.prod_ne_zero_iff.mpr _,
    intros z hz,
    split_ifs,
    exacts [hf z (finset.mem_erase.mp hz).1, pow_ne_zero 2 (hf z (finset.mem_erase.mp hz).1)], },
  have Hsub : ∀ C : nnreal, ∀ x : infinite_place K, x ∈ finset.univ.erase w →
    ite x.is_real (ite (x = w) C (f x)) (ite (x = w) C (f x) ^ 2) = ite x.is_real (f x) (f x ^ 2),
  { intros _ x hx,
    simp_rw if_neg (finset.mem_erase.mp hx).1, },
  by_cases hw : w.is_real,
  { use B * S⁻¹,
    rw ← finset.mul_prod_erase finset.univ _ (finset.mem_univ w),
    rw if_pos hw,
    rw function.update_same,
    simp_rw function.update_apply,
    rw finset.prod_congr rfl (Hsub _),
    exact inv_mul_cancel_right₀ hS _, },
  { use nnreal.sqrt (B * S⁻¹),
    rw ← finset.mul_prod_erase finset.univ _ (finset.mem_univ w),
    rw if_neg hw,
    rw function.update_same,
    rw nnreal.sq_sqrt,
    simp_rw function.update_apply,
    rw finset.prod_congr rfl (Hsub _),
    exact inv_mul_cancel_right₀ hS _, },
end

lemma seq.volume (w : infinite_place K) {f : infinite_place K → nnreal} (hf : ∀ z, z ≠ w → f z ≠ 0)
  (B : ℕ) :
  (unit_measure K) (convex_body K (λ v : infinite_place K,
    (f.update w (seq.exists K w hf B).some v))) = (constant_volume K) * B :=
begin
  rw convex_body.volume,
  rw_mod_cast (seq.exists K w hf B).some_spec,
  refl,
end

def seq.next {B : ℕ} (w : infinite_place K) (hB : minkowski_bound K < (constant_volume K) * B)
  {x : 𝓞 K} (hx : x ≠ 0) :
  ∃ a : (𝓞 K), a ≠ 0 ∧ (∀ z, z ≠ w → z a < (z x) / 2) ∧ abs (algebra.norm ℚ (a : K)) ≤ B :=
begin
  let f : infinite_place K → nnreal := λ v, ⟨(v x) / 2, div_nonneg (map_nonneg _ _) (by norm_num)⟩,
  have hf : ∀ z, z ≠ w → f z ≠ 0,
  { intros z hz,
    apply (nonneg.mk_eq_zero _).not.mpr,
    simp only [hx, div_eq_zero_iff, map_eq_zero, zero_mem_class.coe_eq_zero, bit0_eq_zero,
      one_ne_zero, or_self, not_false_iff, coe_coe], },
  rw ← (seq.volume K w hf B) at hB,
  have t2 := exists_ne_zero_mem_ring_of_integers_le K hB,
  use t2.some,
  split,
  { exact t2.some_spec.1, },
  { split,
    { intros z hz,
      simp only [*, coe_coe, ne.def, subtype.coe_mk],
      convert t2.some_spec.2 z,
      simp [function.update_apply f _ _ _, hz, if_false, subtype.coe_mk], },
    { rw ← @rat.cast_le ℝ _ _ _,
      rw rat.cast_abs,
      have := prod_eq_abs_norm K (t2.some : K),
      rw ← prod_eq_abs_norm K (t2.some : K),
      have t5 := congr_arg nnreal.to_real_hom (seq.exists K w hf B).some_spec,
      rw map_prod nnreal.to_real_hom _ _ at t5,
      simp_rw apply_ite nnreal.to_real_hom _ _ _ at t5,
      simp_rw map_pow at t5,
      rw nnreal.coe_to_real_hom at t5,
      rw nnreal.coe_nat_cast at t5,
      rw rat.cast_coe_nat,
      refine le_of_le_of_eq (finset.prod_le_prod _ _) t5,
      { intros _ _,
        split_ifs; simp only [pow_nonneg, map_nonneg], },
      { intros z _,
        split_ifs,
        { exact le_of_lt (t2.some_spec.2 z), },
        { refine pow_le_pow_of_le_left (map_nonneg _ _) (le_of_lt (t2.some_spec.2 z)) _, }}}},
end

def seq {B : ℕ} (w : infinite_place K) (hB : minkowski_bound K < (constant_volume K) * B) (n : ℕ) :
  { x : 𝓞 K // x ≠ 0 } :=
begin
  refine nat.rec_on n _ _,
  use ⟨(1 : 𝓞 K), (by norm_num)⟩,
  intros _ a,
  use (seq.next K w hB a.prop).some,
  exact (seq.next K w hB a.prop).some_spec.1,
end

lemma seq.ne_zero {B : ℕ} (w : infinite_place K) (hB : minkowski_bound K < (constant_volume K) * B)
  (n : ℕ) : (seq K w hB n : K) ≠ 0 :=
(map_ne_zero_iff (algebra_map (𝓞 K) K) subtype.val_injective).mpr (seq K w hB n).prop

lemma seq.antitone {B : ℕ} (w : infinite_place K) (hB : minkowski_bound K < (constant_volume K) * B)
  (n m : ℕ) (h : n < m) :
  ∀ v : infinite_place K, v ≠ w → v (seq K w hB m) < v (seq K w hB n) :=
begin
  induction m with m hm,
  { exfalso,
    exact nat.not_lt_zero _ h, },
  { intros v hv,
    have hs : v (seq K w hB m.succ) < v (seq K w hB m),
    { have t1 := (seq.next K w hB (seq K w hB m).prop).some_spec.2.1 v hv,
      have t2 : v (seq K w hB m) / 2 < v (seq K w hB m),
      { exact half_lt_self (pos_iff.mpr (seq.ne_zero K w hB m)), },
      exact t1.trans t2, },
    cases nat.eq_or_lt_of_le (nat.le_of_succ_le_succ h) with h1 h2,
    { rwa h1, },
    { exact hs.trans (hm h2 v hv), }},
end

lemma seq.norm_bdd {B : ℕ} (w : infinite_place K) (hB : minkowski_bound K < (constant_volume K) * B)
  (n : ℕ) :
   1 ≤ (algebra.norm ℤ (seq K w hB n : 𝓞 K)).nat_abs ∧
    (algebra.norm ℤ (seq K w hB n : 𝓞 K)).nat_abs ≤ B :=
begin
  cases n,
  { have : algebra.norm ℤ (1 : 𝓞 K) = 1 := map_one (algebra.norm ℤ),
    simp only [seq, this, subtype.coe_mk, int.nat_abs_one, le_refl, true_and],
    contrapose! hB,
    simp only [nat.lt_one_iff.mp hB, algebra_map.coe_zero, mul_zero, zero_le'], },
  { split,
    { refine nat.succ_le_iff.mpr _,
      refine int.nat_abs_pos_of_ne_zero _,
      rw algebra.norm_ne_zero_iff,
      exact (seq K w hB _).prop, },
    { rw ← @nat.cast_le ℚ _ _ _ _,
      rw int.cast_nat_abs,
      change |algebra_map ℤ ℚ ((algebra.norm ℤ) (seq K w hB n.succ : 𝓞 K))| ≤ B,
      rw ← number_field.norm_cast (seq K w hB n.succ : 𝓞 K),
      exact (seq.next K w hB (seq K w hB n).prop).some_spec.2.2, }},
end

-- TODO. move to the right place
lemma _root_.ideal.comap_map_quo {R : Type*} [comm_ring R] {S T : ideal R} (h : S ≤ T) :
  ideal.comap (ideal.quotient.mk S) (ideal.map (ideal.quotient.mk S) T) = T :=
begin
  convert ideal.comap_map_of_surjective _ (ideal.quotient.mk S).is_surjective _,
  have : ideal.comap (ideal.quotient.mk S) ⊥ = S := ideal.mk_ker,
  rw this,
  refine left_eq_sup.mpr h,
end

lemma ideal.norm_bdd.finite (B : ℕ) :
  { I : ideal (𝓞 K) | 1 ≤ ideal.abs_norm I ∧ ideal.abs_norm I ≤ B }.finite :=
begin
  suffices : ∀ n : ℕ, 1 ≤ n → { I : ideal (𝓞 K) | ideal.abs_norm I = n }.finite,
  { rw (_ : { I : ideal (𝓞 K) | 1 ≤ ideal.abs_norm I ∧ ideal.abs_norm I ≤ B } =
      (⋃ n ∈ set.Icc 1 B, { I : ideal (𝓞 K) | ideal.abs_norm I = n })),
    { refine set.finite.bUnion (set.Icc 1 B).to_finite _,
      intros n hn,
      exact this n hn.1, },
    { ext x,
      simp only [set.mem_set_of_eq, set.mem_Icc, set.mem_Union, exists_prop, exists_eq_right'], }},
  intros n hn,
  let a := (n : (𝓞 K)),
  let A : ideal (𝓞 K) := ideal.span { a },
  let Q := (𝓞 K) ⧸ A,
  have t1 : ∀ I : ideal (𝓞 K), ideal.abs_norm I = n → A ≤ I,
  { intros I hI,
    rw ideal.span_le,
    simp only [a, set.singleton_subset_iff, set_like.mem_coe],
    convert ideal.abs_norm_mem I,
    exact hI.symm, },
  let f : ideal (𝓞 K) → ideal Q := λ I, ideal.map (ideal.quotient.mk A) I,
  have t2 : set.inj_on f { I : ideal (𝓞 K) | ideal.abs_norm I = n }:=
  begin
    intros I hI J hJ h,
    have := congr_arg (ideal.comap (ideal.quotient.mk A)) h,
    dsimp [f] at this,
    rw ideal.comap_map_quo (t1 I hI) at this,
    rwa ideal.comap_map_quo (t1 J hJ) at this,
  end,
  refine set.finite.of_finite_image _ t2,
  suffices : finite (set Q),
  { let g := (coe : ideal Q → set Q),
    have t3 : function.injective g := set_like.coe_injective,
    refine set.finite.of_finite_image _ (t3.inj_on _),
    refine set.finite.subset (@set.finite_univ _ this) _,
    exact set.subset_univ _, },
  haveI : finite Q,
  { convert add_subgroup.finite_quotient_of_finite_index _,
    refine ⟨_⟩,
    have : ideal.abs_norm A ≠ 0,
    { rw ideal.abs_norm_span_singleton,
      simp only [ne.def, int.nat_abs_eq_zero, algebra.norm_eq_zero_iff, nat.cast_eq_zero],
      exact ne_of_gt hn, },
    exact this, },
  exact set.finite',
end

lemma exists_unit (w : infinite_place K ) : ∃ u : 𝓤 K, (∀ z : infinite_place K, z ≠ w → z u < 1) :=
begin
  rsuffices ⟨B, hB⟩ : ∃ B: ℕ, minkowski_bound K < (constant_volume K) * B,
  { have : ∃ n m, n < m ∧
      ideal.span { (seq K w hB n : 𝓞 K) } = ideal.span { (seq K w hB m : 𝓞 K) },
    { obtain ⟨n, -, m, -, hnm, h⟩ :=
        @set.infinite.exists_ne_map_eq_of_maps_to ℕ (ideal (𝓞 K)) _ _
          (λ n, ideal.span { seq K w hB n}) set.infinite_univ _ (ideal.norm_bdd.finite K B),
      { by_cases hlt : n < m,
        { exact ⟨n, m, ⟨hlt, h⟩⟩, },
        { refine ⟨m, n, ⟨hnm.lt_or_lt.resolve_left hlt, h.symm⟩⟩, }},
      { intros n _,
        have := seq.norm_bdd K w hB n,
        simp only [this, set.mem_set_of_eq, ideal.abs_norm_span_singleton, and_self], }},
    obtain ⟨n, m, hnm, hid⟩ := this,
    rw ideal.span_singleton_eq_span_singleton at hid,
    obtain ⟨u, hu⟩ := hid,
    use u,
    intros z hz,
    have t1 := congr_arg z (congr_arg (coe : (𝓞 K) → K) hu),
    have t2 := seq.antitone K w hB n m hnm z hz,
    simp only [coe_coe, mul_mem_class.coe_mul, number_field.unit.coe_coe, map_mul] at t1 t2,
    rw ← t1 at t2,
    refine (mul_lt_iff_lt_one_right _).mp t2,
    exact pos_iff.mpr (seq.ne_zero K w hB n), },
  { have t2 : 0 < (constant_volume K).to_nnreal,
    { refine ennreal.to_nnreal_pos_iff.mpr ⟨_, _⟩,
      exact constant_volume_pos K,
      exact constant_volume_lt_top K, },
    have A := nnreal.archimedean.arch (minkowski_bound K).to_nnreal t2,
    use A.some + 1,
    suffices : minkowski_bound K ≤ constant_volume K * A.some,
    { refine lt_of_le_of_lt this _,
      simp only [nsmul_eq_mul, nat.cast_add, algebra_map.coe_one, mul_add, mul_one],
      refine ennreal.lt_add_right _ _,
      { refine ennreal.mul_ne_top _ _,
        exact ne_of_lt (constant_volume_lt_top K),
        exact ennreal.nat_ne_top _, },
      { exact (ne_of_lt (constant_volume_pos K)).symm, }},
    have h := A.some_spec,
    simp only [nsmul_eq_mul] at h,
    rw mul_comm,
    rw ← ennreal.coe_le_coe at h,
    simp [ne_of_lt (minkowski_bound_lt_top K), ne_of_lt (constant_volume_lt_top K)] at h,
    convert h,
    ext,
    simp only [nsmul_eq_mul], },
end

lemma exists_elem (w : infinite_place K) :
  ∃ v : (number_field.infinite_place K → ℝ), v ∈ (unit_lattice K) ∧
    (∀ z : infinite_place K, z ≠ w → v z < 0) :=
begin
  obtain ⟨u, hu⟩ := exists_unit K w,
  use log_embedding K u,
  split,
  { use u, },
  { intros z hz,
    specialize hu z hz,
    refine real.log_neg _ _,
    { rw pos_iff,
    exact number_field.unit.coe_ne_zero, },
    { exact hu, }},
end

-- TODO. move to the right place
lemma _root_.mat.det_ne_zero_of_neg {ι : Type*} [decidable_eq ι] [fintype ι] {M : matrix ι ι ℝ}
  (h1 : ∀ i j, i ≠ j → M i j < 0) (h2 : ∀ j, 0 < finset.univ.sum (λ i, M i j)) :
  M.det ≠ 0 :=
begin
  by_cases h : nonempty ι,
  { haveI : nonempty ι := h,
    contrapose! h2,
    have : ∃ g : ι → ℝ, 0 < finset.sup' finset.univ finset.univ_nonempty g ∧ matrix.vec_mul g M = 0,
    { rw ← matrix.exists_vec_mul_eq_zero_iff at h2,
      obtain ⟨v, ⟨hv1, hv2⟩⟩ := h2,
      by_cases  h : 0 < finset.sup' finset.univ finset.univ_nonempty v,
      { use v,
        exact ⟨h, hv2⟩, },
      { use -v,
        split,
        { rw function.ne_iff at hv1,
          obtain ⟨i, hi⟩ := hv1,
          simp only [pi.neg_apply, finset.lt_sup'_iff, finset.mem_univ, right.neg_pos_iff,
            exists_true_left],
          use i,
          push_neg at h,
          have := finset.le_sup' (λ j, v j) (finset.mem_univ i),
          have := this.trans h,
          refine ne.lt_of_le hi this, },
        { rw matrix.neg_vec_mul,
          exact neg_eq_zero.mpr hv2, }}},
    obtain ⟨g, ⟨hg1, hg2⟩⟩ := this,
    let A := finset.sup' finset.univ finset.univ_nonempty g,
    obtain ⟨a, ha1, ha2⟩ := finset.exists_mem_eq_sup' finset.univ_nonempty g,
    have t1 : matrix.vec_mul g M a = 0,
    { simp only [*, pi.zero_apply], },
    dsimp [matrix.vec_mul, matrix.dot_product] at t1,
    have t3 : ∀ i, i ∈ @finset.univ ι _  →  A * M i a ≤ g i * M i a,
    { intros i _,
      by_cases h : i = a,
      { rw h,
        rw ← ha2, },
      { simp only [*, mul_le_mul_right_of_neg, ne.def, not_false_iff],
        rw ← ha2,
        refine finset.le_sup' _ (finset.mem_univ i),}},
    have t4 := finset.sum_le_sum t3,
    use a,
    rw t1 at t4,
    rw ← finset.mul_sum at t4,
    exact nonpos_of_mul_nonpos_right t4 hg1, },
  { haveI : is_empty ι := (is_empty_or_nonempty ι).resolve_right h,
    simp only [ne.def, one_ne_zero, not_false_iff, matrix.det_is_empty], },
end

lemma unit_lattice.full_lattice :
  ∃ v : {w : infinite_place K // w ≠ w₀} →
    submodule.span ℝ (unit_lattice_submodule K : set (linear_map.ker (lognorm K))),
    linear_independent ℝ (unit_lattice_span_map K ∘ v) :=
begin
  let z : {w : infinite_place K // w ≠ w₀} →
    submodule.span ℝ (unit_lattice_submodule K : set (linear_map.ker (lognorm K))) :=
  begin
    intro w,
    let x := (exists_elem K ↑w).some,
    let p := (exists_elem K ↑w).some_spec,
    let y := (unit_lattice_le_map K) ⟨x, p.1⟩,
    use y,
    refine submodule.subset_span _,
    use x,
    exact p.1,
  end,
  use z,
  let B := pi.basis_fun ℝ {w : infinite_place K // w ≠ w₀},
  let M := B.to_matrix ((unit_lattice_span_map K) ∘ z),
  suffices : M.det ≠ 0,
  { dsimp only [M] at this,
    rw ← basis.det_apply at this,
    exact ((is_basis_iff_det B).mpr (ne.is_unit this)).1, },
  refine mat.det_ne_zero_of_neg _ _,
  { intros i j hij,
    dsimp only [M, B, unit_lattice_span_map, z, unit_lattice_le_map],
    rw basis.coe_pi_basis_fun.to_matrix_eq_transpose,
    simp only [ne.def, coe_coe, linear_map.coe_mk, matrix.transpose_apply, function.comp_app,
      submodule.coe_mk, submodule.coe_of_le],
    have p := (exists_elem K ↑j).some_spec,
    have := p.2 ↑i (subtype.ext_iff.not.mp hij),
    split_ifs,
    { exact this, },
    { exact mul_neg_of_pos_of_neg (by norm_num) this, }},
  { intro i,
    dsimp only [M, B, unit_lattice_le_map],
    rw basis.coe_pi_basis_fun.to_matrix_eq_transpose,
    simp only [ne.def, coe_coe, linear_map.coe_mk, matrix.transpose_apply, submodule.coe_mk,
      submodule.coe_of_le, function.comp_app],
    have t1 : finset.univ.sum (λ (w : infinite_place K), ite(w.is_real)
      ((exists_elem K ↑i).some w) (2*(exists_elem K ↑i).some w)) = 0,
    { have t10 := (exists_elem K ↑i).some_spec.1,
      obtain ⟨u, hu⟩ := t10,
      simp_rw ← hu,
      exact lognorm_unit K u, },
    have t2 : (w₀ : infinite_place K) ∈ finset.univ := finset.mem_univ w₀,
    rw ← finset.sum_erase_add finset.univ _ t2 at t1,
    dsimp at t1,
    have t3 : (finset.univ.erase w₀).sum (λ (w : infinite_place K), ite w.is_real
      ((exists_elem K ↑i).some w) (2 * (exists_elem K ↑i).some w)) =
      finset.univ.sum (λ (j : {w // w ≠ w₀}), ((unit_lattice_span_map K) (z i)) j),
    { refine finset.sum_subtype _ _ _,
      simp only [finset.mem_erase, finset.mem_univ, and_true, iff_self, forall_const], },
    rw ← t3,
    rw add_eq_zero_iff_eq_neg.mp t1,
    have t4 := (exists_elem K ↑i).some_spec.2 w₀ i.prop.symm,
    simp only [right.neg_pos_iff],
    split_ifs,
    { exact t4, },
    { exact mul_neg_of_pos_of_neg (by norm_num) t4, }}
end

lemma unit_lattice.full_lattice' :
  submodule.span ℝ (unit_lattice_submodule K : set (linear_map.ker (lognorm K))) = ⊤ :=
begin
  refine eq_of_le_of_finrank_le (le_top) _,
  rw finrank_top,
  rw rank_ker,
  obtain ⟨v, hv⟩ := unit_lattice.full_lattice K,
  have t1 := linear_independent.of_comp _ hv,
  have t2 := finrank_span_eq_card t1,
  have t3 := submodule.finrank_le (submodule.span ℝ (set.range v)),
  rw t2 at t3,
  convert t3,
  simpa only [fintype.card_subtype_compl, fintype.card_subtype_eq],
end

def unit_lattice.basis :  basis (fin (unit_rank K)) ℤ (unit_lattice K) :=
begin
  haveI : no_zero_smul_divisors ℤ (number_field.infinite_place K → ℝ) :=
    function.no_zero_smul_divisors,
  haveI : no_zero_smul_divisors ℤ (linear_map.ker (lognorm K)) := submodule.no_zero_smul_divisors
    (submodule.restrict_scalars ℤ (linear_map.ker (lognorm K))),
  let b := zlattice.basis (unit_lattice_submodule_discrete K) (unit_lattice.full_lattice' K),
  let c := basis.map b.2 (unit_lattice_equiv K).symm,
  have := zlattice.dim (unit_lattice_submodule_discrete K) (unit_lattice.full_lattice' K),
  rw rank_ker K at this,
  let d := basis.reindex c (fin_congr this),
  exact d,
end

end dirichlet

end number_field
