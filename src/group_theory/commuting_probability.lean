/-
Copyright (c) 2022 Thomas Browning. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Thomas Browning
-/
import data.finset.pointwise
import data.real.basic
import group_theory.complement
import group_theory.finiteness
import group_theory.group_action.conj_act
import group_theory.group_action.quotient
import group_theory.index
import group_theory.schreier
import group_theory.solvable

/-!
# Commuting Probability
This file introduces the commuting probability of finite groups.

## Main definitions
* `comm_prob`: The commuting probability of a finite type with a multiplication operation.

## Todo
* Neumann's theorem.
-/

noncomputable theory
open_locale classical
open_locale big_operators
open_locale pointwise

open fintype

variables (M : Type*) [fintype M] [has_mul M]

/-- The commuting probability of a finite type with a multiplication operation -/
def comm_prob : ℚ := card {p : M × M // p.1 * p.2 = p.2 * p.1} / card M ^ 2

lemma comm_prob_def : comm_prob M = card {p : M × M // p.1 * p.2 = p.2 * p.1} / card M ^ 2 :=
rfl

lemma comm_prob_pos [h : nonempty M] : 0 < comm_prob M :=
h.elim (λ x, div_pos (nat.cast_pos.mpr (card_pos_iff.mpr ⟨⟨(x, x), rfl⟩⟩))
  (pow_pos (nat.cast_pos.mpr card_pos) 2))

lemma comm_prob_le_one : comm_prob M ≤ 1 :=
begin
  refine div_le_one_of_le _ (sq_nonneg (card M)),
  rw [←nat.cast_pow, nat.cast_le, sq, ←card_prod],
  apply set_fintype_card_le_univ,
end

variables {M}

lemma comm_prob_eq_one_iff [h : nonempty M] : comm_prob M = 1 ↔ commutative ((*) : M → M → M) :=
begin
  change (card {p : M × M | p.1 * p.2 = p.2 * p.1} : ℚ) / _ = 1 ↔ _,
  rw [div_eq_one_iff_eq, ←nat.cast_pow, nat.cast_inj, sq, ←card_prod,
      set_fintype_card_eq_univ_iff, set.eq_univ_iff_forall],
  { exact ⟨λ h x y, h (x, y), λ h x, h x.1 x.2⟩ },
  { exact pow_ne_zero 2 (nat.cast_ne_zero.mpr card_ne_zero) },
end

variables (G : Type*) [group G] [fintype G]

lemma card_comm_eq_card_conj_classes_mul_card [h : fintype (conj_classes G)] :
  card {p : G × G // p.1 * p.2 = p.2 * p.1} = @card (conj_classes G) h * card G :=
by convert calc card {p : G × G // p.1 * p.2 = p.2 * p.1} = card (Σ g, {h // g * h = h * g}) :
  card_congr (equiv.subtype_prod_equiv_sigma_subtype (λ g h : G, g * h = h * g))
... = ∑ g, card {h // g * h = h * g} : card_sigma _
... = ∑ g, card (mul_action.fixed_by (conj_act G) G g) : sum_equiv conj_act.to_conj_act.to_equiv
  _ _ (λ g, card_congr' $ congr_arg _ $ funext $ λ h, mul_inv_eq_iff_eq_mul.symm.to_eq)
... = card (quotient (mul_action.orbit_rel (conj_act G) G)) * card G :
  mul_action.sum_card_fixed_by_eq_card_orbits_mul_card_group (conj_act G) G
... = card (quotient (is_conj.setoid G)) * card G :
  have this : mul_action.orbit_rel (conj_act G) G = is_conj.setoid G :=
    setoid.ext (λ g h, (setoid.comm' _).trans is_conj_iff.symm),
  by cc

lemma comm_prob_def' : comm_prob G = card (conj_classes G) / card G :=
begin
  rw [comm_prob, card_comm_eq_card_conj_classes_mul_card, nat.cast_mul, sq],
  exact mul_div_mul_right (card (conj_classes G)) (card G) (nat.cast_ne_zero.mpr card_ne_zero),
end

variables {G} (H : subgroup G)

lemma subgroup.comm_prob_subgroup_le : comm_prob H ≤ comm_prob G * H.index ^ 2 :=
begin
  /- After rewriting with `comm_prob_def`, we reduce to showing that `G` has at least as many
    commuting pairs as `H`. -/
  rw [comm_prob_def, comm_prob_def, div_le_iff, mul_assoc, ←mul_pow, ←nat.cast_mul,
      H.index_mul_card, div_mul_cancel, nat.cast_le],
  { apply card_le_of_injective _ _,
    exact λ p, ⟨⟨p.1.1, p.1.2⟩, subtype.ext_iff.mp p.2⟩,
    exact λ p q h, by simpa only [subtype.ext_iff, prod.ext_iff] using h },
  { exact pow_ne_zero 2 (nat.cast_ne_zero.mpr card_ne_zero) },
  { exact pow_pos (nat.cast_pos.mpr card_pos) 2 },
end

lemma subgroup.comm_prob_quotient_le [H.normal] : comm_prob (G ⧸ H) ≤ comm_prob G * card H :=
begin
  /- After rewriting with `comm_prob_def'`, we reduce to showing that `G` has at least as many
    conjugacy classes as `G ⧸ H`. -/
  rw [comm_prob_def', comm_prob_def', div_le_iff, mul_assoc, ←nat.cast_mul, mul_comm (card H),
      ←subgroup.card_eq_card_quotient_mul_card_subgroup, div_mul_cancel, nat.cast_le],
  { apply card_le_of_surjective,
    show function.surjective (conj_classes.map (quotient_group.mk' H)),
    exact (conj_classes.map_surjective quotient.surjective_quotient_mk') },
  { exact nat.cast_ne_zero.mpr card_ne_zero },
  { exact nat.cast_pos.mpr card_pos },
end

variables (G)

lemma inv_card_commutator_le_comm_prob : (↑(card (commutator G)))⁻¹ ≤ comm_prob G :=
(inv_pos_le_iff_one_le_mul (by exact nat.cast_pos.mpr card_pos)).mpr
  (le_trans (ge_of_eq (comm_prob_eq_one_iff.mpr (abelianization.comm_group G).mul_comm))
    (commutator G).comm_prob_quotient_le)

section neumann

open subgroup

variables (ε : ℝ)

def weak_neumann_subgroup (ε : ℝ) : subgroup G :=
closure ({g : G | ↑(nat.card (centralizer (zpowers g))) ≥ ε / 2 * nat.card G})

namespace weak_neumann_subgroup

def commutator_bound : ℝ → ℕ := sorry

def index_bound : ℝ → ℕ := λ ε, nat.ceil (2 / ε : ℝ)

lemma card_commutator_le (h : ↑(comm_prob G) ≥ ε) :
  nat.card (commutator (weak_neumann_subgroup G ε)) ≤ commutator_bound ε :=
begin
  sorry,
end

lemma index_le (h : ↑(comm_prob G) ≥ ε) :
  (weak_neumann_subgroup G ε).index ≤ index_bound ε :=
begin
  sorry,
end

instance characteristic : (weak_neumann_subgroup G ε).characteristic :=
begin
  sorry
end

end weak_neumann_subgroup

@[derive normal] def strong_neumann_subgroup (ε : ℝ) : subgroup G :=
(commutator (weak_neumann_subgroup G ε)).centralizer.map (weak_neumann_subgroup G ε).subtype

namespace strong_neumann_subgroup

def commutator_bound : ℝ → ℕ := weak_neumann_subgroup.commutator_bound

def index_bound : ℝ → ℕ :=
λ ε, weak_neumann_subgroup.index_bound ε * (weak_neumann_subgroup.commutator_bound ε).factorial

lemma _root_.subgroup.card_dvd_of_le' {G : Type*} [group G] {H K : subgroup G} (h : H ≤ K) :
  nat.card H ∣ nat.card K := sorry

lemma card_commutator_le (h : ↑(comm_prob G) ≥ ε) :
  nat.card (commutator (strong_neumann_subgroup G ε)) ≤ commutator_bound ε :=
begin
  have key : ∀ H : subgroup G, nat.card (commutator H) = nat.card ↥⁅H, H⁆,
  { intro H,
    conv_rhs { rw [←H.subtype_range, monoid_hom.range_eq_map, ←subgroup.map_commutator] },
    exact nat.card_congr
      ((commutator H).equiv_map_of_injective H.subtype subtype.coe_injective).to_equiv },
  rw strong_neumann_subgroup,
  have hK2 := weak_neumann_subgroup.card_commutator_le G ε h,
  rw key at hK2 ⊢,
  exact let h := (commutator (weak_neumann_subgroup G ε)).centralizer.map_subtype_le in
  (nat.le_of_dvd finite.card_pos (subgroup.card_dvd_of_le' (subgroup.commutator_mono h h))).trans hK2,
end

lemma index_le (h : ↑(comm_prob G) ≥ ε) :
  (strong_neumann_subgroup G ε).index ≤ index_bound ε :=
begin
  sorry,
end

lemma commutator_le_center :
  commutator (strong_neumann_subgroup G ε) ≤ (strong_neumann_subgroup G ε).center :=
begin
  rw strong_neumann_subgroup,
  rw [commutator, commutator, ←subgroup.map_subtype_le_map_subtype,
      subgroup.map_commutator, ←monoid_hom.range_eq_map, subgroup.subtype_range],
  have key := commutator_centralizer_commutator_le_center (weak_neumann_subgroup G ε),
  rw [commutator, ←subgroup.map_subtype_le_map_subtype, subgroup.map_commutator] at key,
  refine key.trans _,
  rintros - ⟨g, hg, rfl⟩,
  refine ⟨⟨g, g, λ h hh, hg h, rfl⟩, _, rfl⟩,
  rintros ⟨-, h, hh, rfl⟩,
  exact subtype.ext (show _, from subtype.ext_iff.mp (hg h)),
end

end strong_neumann_subgroup

end neumann
