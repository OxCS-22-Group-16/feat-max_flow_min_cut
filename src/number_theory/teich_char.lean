/-
Copyright (c) 2021 Ashvni Narayanan. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ashvni Narayanan
-/
import number_theory.weight_space
import number_theory.dirichlet_character
import number_theory.general_bernoullli_number
import ring_theory.roots_of_unity

/-!
# Special values of the p-adic L-function

This file determines the special values the p-adic L-function takes at negative integers, in terms
of generalized Bernoulli numbers. We first define Dirichlet characters over ℤ and then relate them
to multiplicative homomorphisms over ℤ/nℤ for any n divisible by the conductor. We then define the
generalized Bernoulli numbers related to Dirichlet characters.

## Main definitions
 * `p_adic_L_function'`

## Implementation notes
TODO (optional)

## References
Introduction to Cyclotomic Fields, Washington (Chapter 12, Section 2)

## Tags
p-adic, L-function, Bernoulli measure, Dirichlet character
-/

/-- The Teichmuller character defined on 𝔽ₚ*. -/
noncomputable abbreviation teichmuller_character_mod_p (p : ℕ) [fact (nat.prime p)] :
  dirichlet_character ℤ_[p] p :=
units.map (((witt_vector.equiv p).to_monoid_hom).comp (witt_vector.teichmuller p))

lemma units.map_injective {M N : Type*} [monoid M] [monoid N] (f : M →* N)
  (hf : function.injective f) : function.injective (units.map f) :=
λ a b h, begin
  rw ←units.eq_iff at *, rw [units.coe_map, units.coe_map] at h,
  apply hf h,
end

lemma teichmuller_character_mod_p_injective (p : ℕ) [fact (nat.prime p)] :
  function.injective (teichmuller_character_mod_p p) :=
begin
  delta teichmuller_character_mod_p,
  rw units.map_comp,
  change function.injective (function.comp (units.map (witt_vector.equiv p).to_monoid_hom)
    (units.map (@witt_vector.teichmuller p (zmod p) _ _))),
  apply function.injective.comp,
  { apply units.map_injective _ _,
    apply (equiv.injective (witt_vector.equiv p).to_equiv), },
  { apply units.map_injective _ _,
    intros a b h,
    rw witt_vector.ext_iff at h,
    specialize h 0,
    repeat { rw witt_vector.teichmuller_coeff_zero p at h, },
    assumption, },
end

lemma teichmuller_character_mod_p_ne_one (p : ℕ) [fact (nat.prime p)] (hp : 2 < p) :
  teichmuller_character_mod_p p ≠ 1 :=
λ h, begin
  have := teichmuller_character_mod_p_injective p,
  rw h at this,
  haveI : nontrivial (units (zmod p)),
  { refine fintype.one_lt_card_iff_nontrivial.mp _,
    rw zmod.card_units p,
    exact lt_tsub_iff_right.mpr hp, },
  have h' := function.injective.exists_ne this 1,
  simp only [eq_self_iff_true, exists_false, monoid_hom.one_apply, not_true, ne.def] at h',
  assumption,
end

instance : fact (nat.prime 2) := by { apply fact_iff.2 nat.prime_two, }

lemma teichmuller_character_mod_p_two : teichmuller_character_mod_p 2 = 1 :=
begin
  rw monoid_hom.ext_iff,
  intro x,
  simp only [units.coe_map, units.coe_one, function.comp_app, monoid_hom.one_apply,
    padic_int.coe_one, monoid_hom.coe_comp],
  convert (teichmuller_character_mod_p 2).map_one,
end

lemma is_primitive_teichmuller_character_zmod_p (p : ℕ) [fact (nat.prime p)] (hp : 2 < p) :
  (teichmuller_character_mod_p p).is_primitive :=
begin
  have dvd := dirichlet_character.conductor_dvd (teichmuller_character_mod_p p),
  rw nat.dvd_prime _ at dvd,
  { cases dvd,
    { exfalso, apply teichmuller_character_mod_p_ne_one p hp
      (dirichlet_character.conductor_eq_one _ dvd), },
    { exact dvd, }, },
  { apply fact.out, },
end

/-lemma is_primitive_teichmuller_character_mod_p_pow (p : ℕ) [fact (nat.prime p)] (m : ℕ) :
  (teichmuller_character_mod_p p^m).is_primitive :=
begin
  have f1 := (teichmuller_character_mod_p p ^ m).conductor_dvd,
  rw nat.dvd_prime _ at f1,
  { cases f1,
    { have f2 := dirichlet_character.conductor_eq_one _ f1,
      exfalso, apply zero_ne_one f2, },
    { exact f1, }, },
  { apply fact.out, },
end-/

/-lemma is_primitive_teich_char_comp (p : ℕ) [fact (nat.prime p)] (m : ℕ)
  {S : Type*} [comm_monoid_with_zero S] [nontrivial S] (f : units ℤ_[p] →* units S) :
  (dirichlet_character.comp (teichmuller_character_mod_p p^m) f).is_primitive :=
begin
  rw dirichlet_character.is_primitive_def,
  obtain ⟨h1, ψ, h2⟩ :=
    (dirichlet_character.comp (teichmuller_character_mod_p p^m) f).factors_through_conductor,
  rw nat.dvd_prime _ at h1,
  { cases h1,
    { rw h1_1,
      have := dirichlet_character.conductor_eq_one _ h1,
      exfalso,
      apply zero_ne_one this, },
    { assumption, }, },
  { apply fact.out, },
end-/

open_locale big_operators
local attribute [instance] zmod.topological_space

variables (p : ℕ) [fact (nat.prime p)] (d : ℕ) (R : Type*) [normed_comm_ring R] (m : ℕ)
(hd : d.gcd p = 1) (χ : dirichlet_character R (d*(p^m))) {c : ℕ} (hc : c.gcd p = 1)
(hc' : c.gcd d = 1) (na : ∀ (n : ℕ) (f : ℕ → R),
  ∥ ∑ (i : ℕ) in finset.range n, f i∥ ≤ ⨆ (i : zmod n), ∥f i.val∥)
(w : weight_space (units (zmod d) × units ℤ_[p]) R)

/-- Similar to `pri_dir_char_extend`, except it takes as input a monoid_hom and returns a
  monoid_hom. -/
noncomputable abbreviation pri_dir_char_extend' : ((units (zmod d)) × (units ℤ_[p])) →* units R :=
monoid_hom.comp χ (monoid_hom.comp (monoid_hom.comp (units.map (zmod.chinese_remainder
(nat.coprime_pow_spl p d m hd)).symm.to_monoid_hom)
(mul_equiv.to_monoid_hom (mul_equiv.symm mul_equiv.prod_units)) ) -- units (zmod d) × units (zmod p^m) →* units (zmod d × zmod p^m) →* units zmod (d * p^m)
 (monoid_hom.prod_map (monoid_hom.id (units (zmod d))) (units.map (padic_int.to_zmod_pow m).to_monoid_hom ) ) ) -- units (zmod d) × units ℤ_[p] →* units (zmod d) × units (zmod p^m)

lemma pri_dir_char_extend'_continuous [fact (0 < d)] : continuous (pri_dir_char_extend' p d R m hd χ) :=
begin
  refine continuous.comp _ (continuous.comp (continuous.comp (continuous.comp _ _) _)
    (continuous_id)),
  { convert continuous_of_discrete_topology, exact disc_top_units (d * p ^ m), },
  { convert continuous_of_discrete_topology, exact units_prod_disc, },
  { convert continuous_of_discrete_topology,
    convert prod.discrete_topology,
    { exact disc_top_units _, },
    { convert disc_top_units _, apply fact_iff.2 _,
      convert mul_prime_pow_pos p 1 m, rw one_mul, }, },
  { simp only [monoid_hom.id_apply, ring_hom.to_monoid_hom_eq_coe, monoid_hom.coe_prod_map,
      prod_map],
    refine continuous_fst.prod_mk (continuous.comp _ continuous_snd),
    refine cont_units_map (cont_inv p) _ (padic_int.continuous_to_zmod_pow p m),
    convert continuous_of_discrete_topology,
    refine discrete_topology_induced (λ a b h, units.eq_iff.1 h), },
end

variables [normed_algebra ℚ_[p] R] [fact (0 < m)] -- [norm_one_class R]

/-- Returns ω⁻¹ = ω^(p - 2) : ℤ/(d * p^m)ℤ* →* R*. -/
noncomputable abbreviation teichmuller_character_mod_p_change_level [algebra ℚ_[p] R] : dirichlet_character R (d * p^m) :=
  dirichlet_character.change_level (((units.map ((algebra_map ℚ_[p] R).comp
  (padic_int.coe.ring_hom)).to_monoid_hom).comp (teichmuller_character_mod_p p) : dirichlet_character R p)⁻¹ )
  (begin apply dvd_mul_of_dvd_right (dvd_pow_self p (ne_of_gt (fact.out _))), apply_instance, end)
--replace ^(p - 2) with ⁻¹

/-noncomputable abbreviation weight_space_extend :=
  monoid_hom.comp (units.map w.to_monoid_hom)
    (mul_equiv.to_monoid_hom (mul_equiv.symm mul_equiv.prod_units))-/

lemma inv_prod_eq_prod_inv : (units.inv : units (zmod d × ℤ_[p]) → zmod d × ℤ_[p]) =
      (prod.map (units.inv : units (zmod d) → zmod d) (units.inv : units ℤ_[p] → ℤ_[p])) ∘
      mul_equiv.prod_units.to_fun :=
begin
  ext,
  { rw mul_equiv.prod_units,
    simp only [monoid_hom.coe_fst, monoid_hom.prod_apply, units.coe_map_inv,
      function.comp_app, units.inv_eq_coe_inv, prod.map_mk], },
  { rw mul_equiv.prod_units,
    simp only [monoid_hom.prod_apply, units.coe_map_inv, monoid_hom.coe_snd,
      function.comp_app, units.inv_eq_coe_inv, prod.map_mk], },
end

/-- Defines a homeomorphism between (α × β) × (γ × δ) and (α × γ) × (β × δ). -/
def homeomorph.prod_prod_comm (α β γ δ : Type*) [topological_space α] [topological_space β]
  [topological_space γ] [topological_space δ] : (α × β) × (γ × δ) ≃ₜ (α × γ) × (β × δ) :=
homeomorph.trans (homeomorph.prod_assoc _ _ _)
  (homeomorph.symm (homeomorph.trans (homeomorph.prod_assoc _ _ _)
  (homeomorph.prod_congr (homeomorph.refl α)
  (homeomorph.trans (homeomorph.prod_assoc _ _ _).symm (homeomorph.symm (homeomorph.trans
  (homeomorph.prod_assoc _ _ _).symm (homeomorph.trans (homeomorph.prod_comm _ _)
  (homeomorph.symm (homeomorph.trans (homeomorph.prod_comm _ _)
  (homeomorph.prod_congr (homeomorph.refl δ) (homeomorph.prod_comm _ _)))))))))))

/-/-- Defines a homeomorphism between α and αᵒᵖ. -/
def homeomorph.op {α : Type*} [topological_space α] : α ≃ₜ αᵐᵒᵖ :=
begin
  refine homeomorph.homeomorph_of_continuous_open opposite.equiv_to_opposite mul_opposite.continuous_op _,
  { change is_open_map opposite.op,
    apply is_open_map.of_inverse,
    { apply continuous_unop, },
    { tauto, },
    { tauto, }, },
end

/-- Defines a homeomorphism between (α × β) × (α × β)ᵒᵖ and (α × αᵒᵖ) × (β × βᵒᵖ). -/
def homeomorph.prod_op_comm {α β : Type*} [topological_space α] [topological_space β] :
 ((α × β) × (α × β)ᵒᵖ) ≃ₜ ((α × αᵒᵖ) × (β × βᵒᵖ)) :=
homeomorph.symm (homeomorph.trans (homeomorph.prod_prod_comm α β (αᵒᵖ) (βᵒᵖ)).symm
  (homeomorph.prod_congr (homeomorph.refl _) (homeomorph.symm
  (homeomorph.trans homeomorph.op.symm (homeomorph.prod_congr homeomorph.op homeomorph.op))))) -/

/- lemma mul_equiv.prod_units_is_open_map : is_open_map (@mul_equiv.prod_units (zmod d) ℤ_[p] _ _) :=
begin
  rintros s hs,
  rw is_open_induced_iff at hs,
  rcases hs with ⟨t, h1, h2⟩,
  set t' : set ((zmod d × (zmod d)ᵒᵖ) × (ℤ_[p] × ℤ_[p]ᵒᵖ)) := (homeomorph.prod_op_comm)'' t
    with ht',
  rw is_open_prod_iff, rintros a b h,
  rw ←(set.preimage_eq_iff_eq_image _) at ht',
  { rw ←ht' at h2,
/-    have image_s : (@mul_equiv.prod_units (zmod d) ℤ_[p] _ _)'' s =
      prod ((embed_product (zmod d))⁻¹' ((prod.fst)'' t')) ((embed_product (ℤ_[p]))⁻¹' ((prod.snd)'' t')),-/
    refine ⟨({a} : set (units (zmod d))), (embed_product (ℤ_[p]))⁻¹' ((prod.snd)'' t'),
      _, _, set.mem_singleton a, _, λ y hy, _⟩,
    { convert is_open_discrete _, exact disc_top_units d, },
    { refine is_open_induced_iff.mpr ⟨(prod.snd '' t'), _, rfl⟩,
      apply is_open_map_snd, exact homeomorph.prod_op_comm.is_open_image.mpr h1, },
    { rw ←h2 at h, rw set.mem_preimage, sorry, },
    { --simp at hy,
      simp only [set.mem_image],
      refine ⟨mul_equiv.prod_units.symm y, _, _⟩,
      { rw ←set.mem_preimage, rw mul_equiv.inv_fun_eq_symm,
        simp only [set.mem_preimage, set.mem_image, set.mem_singleton_iff, set.mem_prod,
          prod.exists] at hy, sorry, },
      { rw mul_equiv.apply_symm_apply, }, }, },
  { exact homeomorph.prod_op_comm.bijective, },
end

lemma mul_equiv.prod_units_embedding : embedding (@mul_equiv.prod_units (zmod d) ℤ_[p] _ _) :=
begin
  fconstructor,
  { fconstructor, ext,
    refine ⟨λ hx, _, λ hx, _⟩,
    { rw is_open_induced_iff',
      refine ⟨(@mul_equiv.prod_units (zmod d) ℤ_[p] _ _)'' x, _, _⟩,
      { apply mul_equiv.prod_units_is_open_map, exact hx, },
      { convert equiv.preimage_image (@mul_equiv.prod_units (zmod d) ℤ_[p] _ _).to_equiv _, }, },
    { rw is_open_induced_iff' at hx,
      refine is_open_implies_is_open_iff.mpr _ x _,

      sorry, }, },
  { exact mul_equiv.prod_units.injective, },
end

lemma continuous_prod_units : continuous (@mul_equiv.prod_units (zmod d) ℤ_[p] _ _) :=
begin
/-  rw mul_equiv.prod_units, simp,
  refine continuous_iff_le_induced.mpr _,
  intros s hs, rcases hs with ⟨t, h1, h2⟩,
  rw set.preimage_eq_iff_eq_image _ at h2,
  rw h2 at h1,
  rw is_open_prod_iff at h1,

  refine ⟨_, _⟩,-/
  rw mul_equiv.prod_units,
  simp only [mul_equiv.coe_mk],

  apply continuous.prod_mk,
  { simp only,
    fconstructor, rintros s hs,
    rw units.map, simp,
    apply cont_units_map,
    { fconstructor,
        rintros s hs, rw is_open_iff_forall_mem_open,
  rintros x hx,rw set.mem_preimage at hx,
  rw metric.is_open_iff at hs,

      rintros s hs,
      rw is_open_prod_iff at hs,
      refine is_open_induced_eq.mpr _, simp,
      refine ⟨_, _, _⟩,
      sorry,
      sorry,
      {  }, },
    { apply discrete_topology_induced, },
    sorry, },
end

lemma continuous_weight_space_extend : continuous (weight_space_extend p d R w) :=
begin
  refine continuous.comp (cont_units_map _ _ w.continuous_to_fun) _,
  { rw inv_prod_eq_prod_inv,
    apply continuous.comp _ _,
    swap, { continuity, },
    sorry, },
  { sorry, },
  { simp only [mul_equiv.coe_to_monoid_hom],
    sorry, },
end -/

/-noncomputable instance peace (p : ℕ) [fact (nat.prime p)] {R : Type*} [semi_normed_comm_ring R]
  [semi_normed_algebra ℚ_[p] R] [has_scalar ℚ R] [is_scalar_tower ℚ ℚ_[p] R] :
  semi_normed_algebra ℚ R :=
begin
  haveI : semi_normed_algebra ℚ ℚ_[p], sorry,
  haveI : algebra ℚ R,
  {
    refine ring_hom.to_algebra' (ring_hom.comp (algebra_map ℚ_[p] R) (algebra_map ℚ ℚ_[p]))
      (λ c x, _),
    simp only [function.comp_app, ring_hom.coe_comp], rw mul_comm, },
  fconstructor, intro x,
  rw ←norm_algebra_map_eq ℚ_[p] x,
  have := norm_algebra_map_eq R ((algebra_map ℚ ℚ_[p]) x),
  symmetry, convert this.symm,
  rw algebra_map,
  change ∥(algebra_map ℚ_[p] R) ((algebra_map ℚ ℚ_[p]) x)∥ = ∥x∥,
  sorry
end -/


/-- Given a natural number s, defines the monoid homomorphism <a>^s taking a ∈ ℤ/dℤ* × ℤₚ* to
  (a * ω⁻¹ (a.2 (mod p)))^s in R. -/
noncomputable abbreviation neg_pow'_to_hom (s : ℕ) :
  monoid_hom (units (zmod d) × units ℤ_[p]) R :=
  ((algebra_map ℚ_[p] R).to_monoid_hom).comp ((
    (@padic_int.coe.ring_hom p _).to_monoid_hom).comp ((units.coe_hom ℤ_[p]).comp
    (((monoid_hom.snd (units (zmod d)) (units ℤ_[p])) * (monoid_hom.comp
    (monoid_hom.comp ((teichmuller_character_mod_p p)⁻¹)
    (units.map padic_int.to_zmod.to_monoid_hom))
    (monoid_hom.snd (units (zmod d)) (units ℤ_[p]))) )^s )) )
-- noncomputable abbreviation neg_pow'_to_hom (s : ℕ) :
--   monoid_hom (units (zmod d) × units ℤ_[p]) R :=
--   ((algebra_map ℚ_[p] R).to_monoid_hom).comp ((
--     (@padic_int.coe.ring_hom p _).to_monoid_hom).comp ((units.coe_hom ℤ_[p]).comp
--     (zpow_group_hom (-s) ((monoid_hom.snd (units (zmod d)) (units ℤ_[p])) * (monoid_hom.comp
--     (monoid_hom.comp ((teichmuller_character_mod_p p)^(p - 2))
--     (units.map padic_int.to_zmod.to_monoid_hom))
--     (monoid_hom.snd (units (zmod d)) (units ℤ_[p]))) ))) )
/-{
  to_fun := λ x, (units.map (algebra_map ℚ_[p] R).to_monoid_hom) (units.map
    (@padic_int.coe.ring_hom p _).to_monoid_hom (gpow_group_hom (-s) (monoid_hom.snd (units (zmod d)) (units ℤ_[p]) x))),
    --(units.map ((@padic_int.coe.ring_hom p _).to_monoid_hom _)),
  map_one' := by simp only [one_inv, one_gpow, prod.snd_one, monoid_hom.map_one],
  map_mul' := begin rw pow_monoid_hom, end,
}-/
-- to figure out : is ℤ/dℤ* × ℤ_[p] → ℤ_[p] with projection onto the 2nd coord the same as
-- going down to ℤ/dp^n ℤ and using CRT and then going mod p^n?

--instance : topological_group (units R) := units.topological_group

--instance : metric_space (units ℤ_[p]) := infer_instance

--noncomputable instance : has_pow (units ℤ_[p]) ℤ := div_inv_monoid.has_pow

lemma padic_int.continuous_units_zpow (s : ℤ) : continuous (λ (x : units ℤ_[p]), x^s : units ℤ_[p] → units ℤ_[p]) := --continuous (pow s : units ℤ_[p] → units ℤ_[p]) :=
begin
  exact continuous_zpow s,
/-  suffices : continuous ((units.coe_hom ℤ_[p]) ∘ (zpow s)),
  { fconstructor, rintros t ht,
    rw continuous_def at this,
    specialize this ((units.coe_hom ℤ_[p])'' t) (is_open_coe p t ht),
    rw [set.preimage_comp, set.preimage_image_eq _] at this,
    { assumption, },
    { convert units.ext, }, }, -- if composition of a map with an open inj map is cont, then map is cont
  { cases s,
    { change continuous (λ x, ((x^s : units ℤ_[p]) : ℤ_[p])),
      simp only [units.coe_pow],
      continuity, apply units.continuous_coe, },
    { change continuous (λ x, ((x^(-[1+ s]) : units ℤ_[p]) : ℤ_[p])),
      simp only [gpow_neg_succ_of_nat],
      conv { congr, funext, rw ←units.inv_eq_coe_inv, },
      refine continuous.comp _ (continuous_pow s.succ),
      change continuous (units.val ∘ units.has_inv.inv),
      refine continuous.comp _ continuous_id'.inv, change continuous coe,
      apply units.continuous_coe, }, }, -/
end
-- this can be generalized to whenever inv is continuous? -/

lemma neg_pow'_continuous (s : ℕ) : continuous (neg_pow'_to_hom p d R s) :=
begin
  refine continuous.comp _ _,
  { simp only [ring_hom.coe_monoid_hom, ring_hom.to_monoid_hom_eq_coe],
    rw algebra.algebra_map_eq_smul_one',
    exact continuous_id'.smul continuous_const, },
  { refine continuous.comp (continuous_induced_dom.comp (continuous.comp
      (units.continuous_coe.comp (continuous.comp ((continuous_pow s).comp
      (continuous.comp (continuous.mul continuous_snd (continuous.comp
      (continuous.comp (continuous.comp _ (continuous.comp (cont_units_map (cont_inv p) _ _)
      continuous_id)) continuous_snd) continuous_id)) continuous_id)) continuous_id))
      continuous_id)) continuous_id,
    { convert continuous_of_discrete_topology, exact disc_top_units _, },
    { convert continuous_of_discrete_topology,
      refine discrete_topology_induced units.ext, },
    { rw [ring_hom.to_monoid_hom_eq_coe, ring_hom.coe_monoid_hom],
      apply continuous_to_zmod p, }, },
end
-- why can't i use the dot notation?
-- maybe make a separate lemma saying any Dir char is cont?

/-- The element of weight space corresponding to neg_pow'_to_hom. -/
noncomputable abbreviation neg_pow' (s : ℕ) :
  weight_space (units (zmod d) × units ℤ_[p]) R :=
⟨(neg_pow'_to_hom p d R s).to_fun, (neg_pow'_to_hom p d R s).map_one', (neg_pow'_to_hom p d R s).map_mul',
  neg_pow'_continuous p d R s⟩

variable [fact (0 < d)]

theorem cont_paLf' : continuous
((units.coe_hom R).comp (pri_dir_char_extend' p d R m hd (χ *
  (teichmuller_character_mod_p_change_level p d R m))) * w.to_monoid_hom) :=
  continuous.mul (units.continuous_coe.comp (pri_dir_char_extend'_continuous p d R m hd _))
  w.continuous_to_fun
  /- continuous.comp units.continuous_coe (continuous.mul
    (pri_dir_char_extend'_continuous p d R m hd _)
    w.continuous_to_fun) -/
--why is this taking so long / not anymore haha
-- we chose target as R instead of units R so did we did not have to show continuity of
-- units.map _ (recall that showing inv is continuous is hard for R without extra assumptions)

/-continuous ((pri_dir_char_extend' p d R m hd
    (χ * (dirichlet_character.change_level
      ( ( (units.map ((algebra_map ℚ_[p] R).comp
      (padic_int.coe.ring_hom)).to_monoid_hom).comp (teichmuller_character_mod_p p) )^(p - 2))
      (begin sorry end) )) ) * w).to_fun := sorry -/

/- theorem cont_paLf' (p : ℕ) [fact (nat.prime p)] (d : ℕ) [fact (0 < d)] (hd : d.gcd p = 1)
(R : Type*) [normed_comm_ring R] [complete_space R] [char_zero R] [semi_normed_algebra ℚ_[p] R]
(m : ℕ) [fact (0 < m)]
(χ : dirichlet_character R (d * p ^ m)) --(hcond : χ.is_primitive)
(w : weight_space (units (zmod d) × units ℤ_[p]) R) :
continuous ((pri_dir_char_extend' p d R m hd
    (χ * (dirichlet_character.change_level
      ( ( (units.map ((algebra_map ℚ_[p] R).comp
      (padic_int.coe.ring_hom)).to_monoid_hom).comp (teichmuller_character_mod_p p) )^(p - 2))
      (begin sorry end) )) ) * w).to_fun := sorry -/

variables [complete_space R] [char_zero R]

/-- The p-adic L- function, as defined in Thm 12.2, absorbing the (1 - χ(c)<c>^(-n)) term
  (since it appears as it is in the Iwasawa Main Conjecture). -/
noncomputable def p_adic_L_function' [normed_algebra ℚ R] [norm_one_class R] : R :=
    (@measure.integral _ _ _ _ (is_this_even_true p d) _ _ _ (bernoulli_measure' p d R hc hc' hd na)
      ⟨(units.coe_hom R).comp (pri_dir_char_extend' p d R m hd (χ *
  (teichmuller_character_mod_p_change_level p d R m))) * w.to_monoid_hom,
       cont_paLf' p d R m hd χ w⟩)
-- technically bernoulli_measure lands in units R, you should not have to use (units.coe_hom R),
-- unless (units R) is not a complete space?

lemma is_unit_iff_not_dvd (z : ℕ) (h : ¬ p ∣ z) : is_unit (z : ℤ_[p]) :=
begin
  contrapose h, rw not_not,
  have := padic_int.mem_nonunits.1 h,
  rw ←int.coe_nat_dvd,
  rw ←padic_int.norm_int_lt_one_iff_dvd,
  convert this using 1,
end

noncomputable instance zmod.pow_fintype (n : ℕ) : fintype (zmod (p^n))ˣ :=
begin
  apply @units.fintype _ _ _ _,
  { convert zmod.fintype _, apply fact_iff.2, apply pow_pos _, apply nat.prime.pos (fact.out _),
    assumption, },
  { exact classical.dec_eq (zmod (p ^ n)), },
end

--noncomputable example (n : ℕ) (a : (zmod (p^n))ˣ) : ℤ_[p]ˣ := units.map (zmod. : zmod (p^n) →* ℤ_[p])

abbreviation units_clopen_from (n : ℕ) (a : (zmod d)ˣ × (zmod (p^n))ˣ) : set ((zmod d)ˣ × ℤ_[p]ˣ) :=
  ({a.1} : set (zmod d)ˣ) ×ˢ ((units.map (@padic_int.to_zmod_pow p _ n).to_monoid_hom)⁻¹' {a.2})

lemma disc_top_pow (n : ℕ) : discrete_topology (zmod (p^n))ˣ :=
by {convert disc_top_units _, apply fact_iff.2, apply pow_pos (nat.prime.pos _),
  apply fact.out _, assumption, }

instance : ∀ n, discrete_topology (zmod n)ˣ :=
λ n, begin
  by_cases 0 < n,
  { apply @disc_top_units n (fact_iff.2 h), },
  { have : n = 0,
    { contrapose h, push_neg, exact zero_lt_iff.mpr h, },
    rw this, change discrete_topology ℤˣ,
    constructor,
    delta units.topological_space,
    convert_to topological_space.induced ⇑(units.embed_product ℤ) ⊥ = ⊥,
    congr,
    { suffices dt : discrete_topology (ℤ × ℤᵐᵒᵖ),
      apply dt.eq_bot,
      convert prod.discrete_topology,
      apply_instance,
      constructor, --delta mul_opposite.topological_space,
      change topological_space.induced mul_opposite.unop ⊥ = ⊥,
      rw induced_bot,
      exact mul_opposite.unop_injective, },
    rw induced_bot _,
    exact units.embed_product_injective ℤ, },
end

lemma continuous_units (n : ℕ) :
  continuous (units.map (@padic_int.to_zmod_pow p _ n).to_monoid_hom) :=
begin
  apply cont_units_map (cont_inv p),
  { have := @induced_bot _ _ _ _,
    swap 4, exact units.coe_hom (zmod (p^n)),
    swap, exact units.ext,
    apply @continuous_of_discrete_topology _ _ _ _ _ _,
    constructor,
    rw ← this,
    congr, },
  { rw [ring_hom.to_monoid_hom_eq_coe, ring_hom.coe_monoid_hom],
    apply padic_int.continuous_to_zmod_pow p n, },
end

lemma proj_lim_preimage_units_clopen (n : ℕ) (a : (zmod (p^n))ˣ) :
  is_clopen ((units.map (@padic_int.to_zmod_pow p _ n).to_monoid_hom) ⁻¹' {a}) :=
  ⟨continuous_def.mp (continuous_units p n) {a} (@is_open_discrete _ _ (disc_top_pow p n) _),
    continuous_iff_is_closed.mp (continuous_units p n) {a}
      (@is_closed_discrete _ _ (disc_top_pow p n) {a})⟩

lemma is_clopen_units_clopen_from (n : ℕ) (a : (zmod d)ˣ × (zmod (p^n))ˣ) :
  is_clopen (units_clopen_from p d n a) :=
  is_clopen_prod (is_clopen_singleton (a.1)) (proj_lim_preimage_units_clopen p n a.2)

noncomputable def ind_fn' (f : (units (zmod d) × units ℤ_[p]) → R) :=
  λ x : (zmod d × ℤ_[p]), @dite _ (is_unit x.1 ∧ is_unit x.2)
    (classical.dec (is_unit x.fst ∧ is_unit x.snd)) (λ h, f (is_unit.unit h.1, is_unit.unit h.2)) (λ h, 0)

lemma ind_fn_eq_fun' (f : (units (zmod d) × units ℤ_[p]) → R) :
  f = (ind_fn' p d R f) ∘ (prod.map (coe : units (zmod d) → zmod d) (coe : units ℤ_[p] → ℤ_[p])) :=
begin
  ext x, rw function.comp, simp only, rw ind_fn', simp only,
  symmetry, convert dif_pos _,
  { rw prod.ext_iff, simp only [prod_map], split,
    all_goals { rw units.ext_iff,
      rw is_unit.unit_spec (units.is_unit _), }, },
  { simp only [units.is_unit, prod_map, and_self], },
end

/-lemma is_unit_padic_of_is_unit_zmod_pow {n x : ℕ} (hn : n ≠ 0) (hx : is_unit (x : zmod (p^n))) :
  is_unit (x : ℤ_[p]) :=
begin
  have h : x.coprime p, sorry,
  apply is_unit_padic_of_is_unit_zmod _ _ h,
  have c := units.map (zmod.cast_hom (dvd_pow (dvd_refl p) hn) (zmod p)).to_monoid_hom,
  contrapose h,
  rw padic_int.is_unit_iff at h,
  have hx' := lt_of_le_of_ne (padic_int.norm_le_one _) h,
  change ∥((x : ℤ) : ℤ_[p])∥ < 1 at hx',
  rw padic_int.norm_int_lt_one_iff_dvd at hx',
  norm_cast at hx',
  rw nat.coprime_comm,
  rw nat.prime.coprime_iff_not_dvd _,
  { rw not_not, assumption, },
  { apply fact.out, },
end-/


/-abbreviation rev_coe' {n : ℕ} (a : (zmod (p^n))ˣ) : ℤ_[p]ˣ :=
begin
  set f := λ k : ℕ, dite (k ≤ n) (λ h, zmod.cast_hom (pow_dvd_pow p h) (zmod (p^k))) (λ h, ring_hom.),
  convert (@units.map _ _ _ _ (@padic_int.lift p _ _ _ _ _).to_monoid_hom) a,
  apply @padic_int.lift p _ _ _ _ _ _,
end
-- this map cannot exist because for K →+*L, char_p K ↔ char_p L!
-/

/-example (f : C((zmod d)ˣ × ℤ_[p]ˣ, R)) : continuous (ind_fn' p d R f) :=
begin
  delta ind_fn',
  rw continuous_iff_continuous_at,
  intro x,
  by_cases is_unit x.fst ∧ is_unit x.snd,
  {sorry, },
  rw metric.continuous_iff,
  refine inducing.continuous _,
end-/

/-example : pseudo_metric_space ((zmod d)ˣ × ℤ_[p]ˣ) :=
begin
  refine pseudo_metric_space.induced _ _,
  { exact (zmod d) × ℤ_[p], },
  { apply prod.map (units.coe_hom _) (units.coe_hom _), },
  {
    refine pseudo_metric_space.of_metrizable _ _ _ _ _,
     },
end

example (f : C((zmod d)ˣ × ℤ_[p]ˣ, R))
  (this : ∀ (x : (zmod d)ˣ × ℤ_[p]ˣ) (n : ℕ),
            ∑ (a : (zmod d)ˣ × (zmod (p ^ n))ˣ),
                ⇑f (a.fst, rev_coe p a.snd) •
                  ⇑(locally_constant.char_fn R _) x =
              ⇑f
                (x.fst,
                 rev_coe p
                   (⇑(units.map (padic_int.to_zmod_pow n).to_monoid_hom)
                      x.snd)))
  (f2 : ∀ (n : ℕ),
          ∑ (a : (zmod d)ˣ × (zmod (p ^ n))ˣ),
              ⇑f (a.fst, rev_coe p a.snd) •
                ↑(locally_constant.char_fn R _) =
            {to_fun := ⇑f ∘
                         prod.map id
                           (rev_coe p ∘
                              ⇑(units.map
                                   (padic_int.to_zmod_pow n).to_monoid_hom)),
             continuous_to_fun := _}) :
  filter.tendsto
    (λ (n : ℕ),
       {to_fun := prod.map id
                    (rev_coe p ∘
                       ⇑(units.map (padic_int.to_zmod_pow n).to_monoid_hom)),
        continuous_to_fun := _})
    filter.at_top
    (nhds {to_fun := prod.map id id, continuous_to_fun := _}) :=
begin
  admit,
end

example (n : ℕ) : filter.tendsto (λ n : ℕ, @rev_coe p _ n ∘
  (units.map (@padic_int.to_zmod_pow p _ n).to_monoid_hom)) filter.at_top (nhds (id)) :=
begin
--  convert filter.tendsto.comp _ _,
  simp,
--  unfold filter.at_top,
  rw filter.tendsto_at_top',
  rintros s hs,
  obtain ⟨t, ht, ht1, ht2⟩ := mem_nhds_iff.1 hs,

  rw metric.tendsto_at_top,
end
-- can we use cont_ind_fn in any way?
-/
