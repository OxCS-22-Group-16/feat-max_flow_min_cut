/-
Copyright (c) 2022 Thomas Browning. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Thomas Browning
-/

import group_theory.abelianization
import group_theory.transfer

/-!
# Schreier's Lemma

In this file we prove Schreier's lemma.

## Main results

- `closure_mul_image_eq` : **Schreier's Lemma**: If `R : set G` is a right_transversal
  of `H : subgroup G` with `1 ∈ R`, and if `G` is generated by `S : set G`,
  then `H` is generated by the `set` `(R * S).image (λ g, g * (to_fun hR g)⁻¹)`.
- `fg_of_index_ne_zero` : **Schreier's Lemma**: A finite index subgroup of a finitely generated
  group is finitely generated.
-/

open_locale pointwise

namespace subgroup

open mem_right_transversals

variables {G : Type*} [group G] {H : subgroup G} {R S : set G}

lemma closure_mul_image_mul_eq_top
  (hR : R ∈ right_transversals (H : set G)) (hR1 : (1 : G) ∈ R) (hS : closure S = ⊤) :
  (closure ((R * S).image (λ g, g * (to_fun hR g)⁻¹)) : set G) * R = ⊤ :=
begin
  let f : G → R := λ g, to_fun hR g,
  let U : set G := (R * S).image (λ g, g * (f g)⁻¹),
  change (closure U : set G) * R = ⊤,
  refine top_le_iff.mp (λ g hg, _),
  apply closure_induction_right (eq_top_iff.mp hS (mem_top g)),
  { exact ⟨1, 1, (closure U).one_mem, hR1, one_mul 1⟩ },
  { rintros - s hs ⟨u, r, hu, hr, rfl⟩,
    rw show u * r * s = u * ((r * s) * (f (r * s))⁻¹) * f (r * s), by group,
    refine set.mul_mem_mul ((closure U).mul_mem hu _) (f (r * s)).coe_prop,
    exact subset_closure ⟨r * s, set.mul_mem_mul hr hs, rfl⟩ },
  { rintros - s hs ⟨u, r, hu, hr, rfl⟩,
    rw show u * r * s⁻¹ = u * (f (r * s⁻¹) * s * r⁻¹)⁻¹ * f (r * s⁻¹), by group,
    refine set.mul_mem_mul ((closure U).mul_mem hu ((closure U).inv_mem _)) (f (r * s⁻¹)).2,
    refine subset_closure ⟨f (r * s⁻¹) * s, set.mul_mem_mul (f (r * s⁻¹)).2 hs, _⟩,
    rw [mul_right_inj, inv_inj, ←subtype.coe_mk r hr, ←subtype.ext_iff, subtype.coe_mk],
    apply (mem_right_transversals_iff_exists_unique_mul_inv_mem.mp hR (f (r * s⁻¹) * s)).unique
      (mul_inv_to_fun_mem hR (f (r * s⁻¹) * s)),
    rw [mul_assoc, ←inv_inv s, ←mul_inv_rev, inv_inv],
    exact to_fun_mul_inv_mem hR (r * s⁻¹) },
end

/-- **Schreier's Lemma**: If `R : set G` is a right_transversal of `H : subgroup G`
  with `1 ∈ R`, and if `G` is generated by `S : set G`, then `H` is generated by the `set`
  `(R * S).image (λ g, g * (to_fun hR g)⁻¹)`. -/
lemma closure_mul_image_eq
  (hR : R ∈ right_transversals (H : set G)) (hR1 : (1 : G) ∈ R) (hS : closure S = ⊤) :
  closure ((R * S).image (λ g, g * (to_fun hR g)⁻¹)) = H :=
begin
  have hU : closure ((R * S).image (λ g, g * (to_fun hR g)⁻¹)) ≤ H,
  { rw closure_le,
    rintros - ⟨g, -, rfl⟩,
    exact mul_inv_to_fun_mem hR g },
  refine le_antisymm hU (λ h hh, _),
  obtain ⟨g, r, hg, hr, rfl⟩ :=
  show h ∈ _, from eq_top_iff.mp (closure_mul_image_mul_eq_top hR hR1 hS) (mem_top h),
  suffices : (⟨r, hr⟩ : R) = (⟨1, hR1⟩ : R),
  { rwa [show r = 1, from subtype.ext_iff.mp this, mul_one] },
  apply (mem_right_transversals_iff_exists_unique_mul_inv_mem.mp hR r).unique,
  { rw [subtype.coe_mk, mul_inv_self],
    exact H.one_mem },
  { rw [subtype.coe_mk, inv_one, mul_one],
    exact (H.mul_mem_cancel_left (hU hg)).mp hh },
end

/-- **Schreier's Lemma**: If `R : set G` is a right_transversal of `H : subgroup G`
  with `1 ∈ R`, and if `G` is generated by `S : set G`, then `H` is generated by the `set`
  `(R * S).image (λ g, g * (to_fun hR g)⁻¹)`. -/
lemma closure_mul_image_eq_top
  (hR : R ∈ right_transversals (H : set G)) (hR1 : (1 : G) ∈ R) (hS : closure S = ⊤) :
  closure ((R * S).image (λ g, ⟨g * (to_fun hR g)⁻¹, mul_inv_to_fun_mem hR g⟩) : set H) = ⊤ :=
begin
  rw [eq_top_iff, ←map_subtype_le_map_subtype, monoid_hom.map_closure, set.image_image],
  exact (map_subtype_le ⊤).trans (ge_of_eq (closure_mul_image_eq hR hR1 hS)),
end

/-- **Schreier's Lemma**: If `R : finset G` is a right_transversal of `H : subgroup G`
  with `1 ∈ R`, and if `G` is generated by `S : finset G`, then `H` is generated by the `finset`
  `(R * S).image (λ g, g * (to_fun hR g)⁻¹)`. -/
lemma closure_mul_image_eq_top' [decidable_eq G] {R S : finset G}
  (hR : (R : set G) ∈ right_transversals (H : set G)) (hR1 : (1 : G) ∈ R)
  (hS : closure (S : set G) = ⊤) :
  closure ((((R * S).image (λ g, ⟨_, mul_inv_to_fun_mem hR g⟩)) : finset H) : set H) = ⊤ :=
begin
  rw [finset.coe_image, finset.coe_mul],
  exact closure_mul_image_eq_top hR hR1 hS,
end

lemma exists_finset_card_le_mul (hH : H.index ≠ 0) {S : finset G} (hS : closure (S : set G) = ⊤) :
  ∃ T : finset H, T.card ≤ H.index * S.card ∧ closure (T : set H) = ⊤ :=
begin
  haveI : decidable_eq G := classical.dec_eq G,
  obtain ⟨R₀, hR : R₀ ∈ right_transversals (H : set G), hR1⟩ := exists_right_transversal (1 : G),
  haveI : fintype (G ⧸ H) := fintype_of_index_ne_zero hH,
  haveI : fintype R₀ := fintype.of_equiv _ (mem_right_transversals.to_equiv hR),
  let R : finset G := set.to_finset R₀,
  replace hR : (R : set G) ∈ right_transversals (H : set G) := by rwa set.coe_to_finset,
  replace hR1 : (1 : G) ∈ R := by rwa set.mem_to_finset,
  refine ⟨_, _, closure_mul_image_eq_top' hR hR1 hS⟩,
  calc _ ≤ (R * S).card : finset.card_image_le
  ... ≤ (R ×ˢ S).card : finset.card_image_le
  ... = R.card * S.card : R.card_product S
  ... = H.index * S.card : congr_arg (* S.card) _,
  calc R.card = fintype.card R : (fintype.card_coe R).symm
  ... = _ : (fintype.card_congr (mem_right_transversals.to_equiv hR)).symm
  ... = fintype.card (G ⧸ H) : quotient_group.card_quotient_right_rel H
  ... = H.index : H.index_eq_card.symm,
end

/-- **Schreier's Lemma**: A finite index subgroup of a finitely generated
  group is finitely generated. -/
lemma fg_of_index_ne_zero [hG : group.fg G] (hH : H.index ≠ 0) : group.fg H :=
begin
  obtain ⟨S, hS⟩ := hG.1,
  obtain ⟨T, -, hT⟩ := exists_finset_card_le_mul hH hS,
  exact ⟨⟨T, hT⟩⟩,
end

lemma rank_le_index_mul_rank [hG : group.fg G] {H : subgroup G} (hH : H.index ≠ 0) :
  @group.rank H _ (fg_of_index_ne_zero hH) ≤ H.index * group.rank G :=
begin
  haveI := fg_of_index_ne_zero hH,
  obtain ⟨S, hS₀, hS⟩ := group.rank_spec G,
  obtain ⟨T, hT₀, hT⟩ := exists_finset_card_le_mul hH hS,
  calc group.rank H ≤ T.card : group.rank_le H hT
  ... ≤ H.index * S.card : hT₀
  ... = H.index * group.rank G : congr_arg ((*) H.index) hS₀,
end

variables (G)

/-- If `G` has `n` commutators `[g₁, g₂]`, then `|G'| ∣ [G : Z(G)] ^ ([G : Z(G)] * n + 1)`,
where `G'` denotes the commutator of `G`. -/
lemma card_commutator_dvd_index_center_pow [finite {g | ∃ g₁ g₂ : G, ⁅g₁, g₂⁆ = g}] :
  nat.card (commutator G) ∣
    (center G).index ^ ((center G).index * nat.card {g | ∃ g₁ g₂ : G, ⁅g₁, g₂⁆ = g} + 1) :=
begin
  -- First handle the case when `Z(G)` has infinite index and `[G : Z(G)]` is defined to be `0`
  by_cases hG : (center G).index = 0,
  { simp_rw [hG, zero_mul, zero_add, pow_one, dvd_zero] },
  -- Rewrite as `|Z(G) ∩ G'| * [G' : Z(G) ∩ G'] ∣ [G : Z(G)] ^ ([G : Z(G)] * n) * [G : Z(G)]`
  rw [←((center G).subgroup_of (commutator G)).card_mul_index, pow_succ'],
  -- We have `h1 : [G' : Z(G) ∩ G'] ∣ [G : Z(G)]`
  have h1 := relindex_dvd_index_of_normal (center G) (commutator G),
  -- So we can reduce to proving `|Z(G) ∩ G'| ∣ [G : Z(G)] ^ ([G : Z(G)] * n)`
  refine mul_dvd_mul _ h1,
  -- We have `h2 : rank (Z(G) ∩ G') ≤ [G' : Z(G) ∩ G'] * rank G'` by Schreier's lemma
  have h2 := rank_le_index_mul_rank (ne_zero_of_dvd_ne_zero hG h1),
  -- We have `h3 : [G' : Z(G) ∩ G'] * rank G' ≤ [G : Z(G)] * n` by `h1` and `rank G' ≤ n`
  have h3 := nat.mul_le_mul (nat.le_of_dvd (nat.pos_of_ne_zero hG) h1) (rank_commutator_le_card G),
  -- So we can reduce to proving `|Z(G) ∩ G'| ∣ [G : Z(G)] ^ rank (Z(G) ∩ G')`
  refine dvd_trans _ (pow_dvd_pow (center G).index (h2.trans h3)),
  -- `Z(G) ∩ G'` is abelian, so it enough to prove that `g ^ [G : Z(G)] = 1` for `g ∈ Z(G) ∩ G'`
  apply card_dvd_exponent_pow_rank' _ (λ g, _),
  -- `Z(G)` is abelian, so `g ∈ Z(G) ∩ G' ≤ G' ≤ ker (transfer : G → Z(G))`
  have := abelianization.commutator_subset_ker (monoid_hom.transfer_center_pow' hG) g.1.2,
  -- `transfer g` is defeq to `g ^ [G : Z(G)]`, so we are done
  simpa only [monoid_hom.mem_ker, subtype.ext_iff] using this,
end

end subgroup
