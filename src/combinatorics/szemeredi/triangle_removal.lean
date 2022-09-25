/-
Copyright (c) 2022 Yaël Dillies, Bhavik Mehta. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies, Bhavik Mehta
-/
import .regularity_lemma
import .triangle_counting

/-!
# Triangle removal lemma

In this file, we prove the triangle removal lemma.
-/

namespace tactic
open positivity

variables {α : Type*}

private lemma int_floor_nonneg [linear_ordered_ring α] [floor_ring α] {a : α} (ha : 0 ≤ a) :
  0 ≤ ⌊a⌋ := int.floor_nonneg.2 ha
private lemma int_floor_nonneg_of_pos [linear_ordered_ring α] [floor_ring α] {a : α} (ha : 0 < a) :
  0 ≤ ⌊a⌋ := int_floor_nonneg ha.le

/-- Extension for the `positivity` tactic: `int.floor` is nonnegative if its input is. -/
@[positivity]
meta def positivity_floor : expr → tactic strictness
| `(⌊%%a⌋) := do
      strictness_a ← core a,
      match strictness_a with
      | positive p := nonnegative <$> mk_app ``int_floor_nonneg_of_pos [p]
      | nonnegative p := nonnegative <$> mk_app ``int_floor_nonneg [p]
      end
| e := pp e >>= fail ∘ format.bracket "The expression `" "` is not of the form `⌊a⌋`"

private lemma nat_ceil_pos [linear_ordered_semiring α] [floor_semiring α] {a : α} :
  0 < a → 0 < ⌈a⌉₊ := nat.ceil_pos.2
private lemma int_ceil_pos [linear_ordered_ring α] [floor_ring α] {a : α} : 0 < a → 0 < ⌈a⌉ :=
int.ceil_pos.2

/-- Extension for the `positivity` tactic: `ceil` and `int.ceil` are positive/nonnegative if
their input is. -/
@[positivity]
meta def positivity_ceil : expr → tactic strictness
| `(⌈%%a⌉₊) := do
      positive p ← core a, -- We already know `0 ≤ n` for all `n : ℕ`
      positive <$> mk_app ``nat_ceil_pos [p]
| `(⌈%%a⌉) := do
      strictness_a ← core a,
      match strictness_a with
      | positive p := positive <$> mk_app ``int_ceil_pos [p]
      | nonnegative p := nonnegative <$> mk_app ``int.ceil_nonneg [p]
      end
| e := pp e >>= fail ∘ format.bracket "The expression `" "` is not of the form `⌈a⌉₊` nor `⌈a⌉`"

/-- Extension for the `positivity` tactic: `a - b` is positive if `b < a` and nonnegative if
`b ≤ a`. Note, this only tries to find the appropriate assumption in context. -/
@[positivity]
meta def positivity_sub : expr → tactic strictness
| `(%%a - %%b) :=
  (do
    p ← to_expr ``(%%b < %%a) >>= find_assumption,
    positive <$> mk_app ``tsub_pos_of_lt [p] <|> positive <$> mk_app ``sub_pos_of_lt [p]) <|>
  do
    p ← to_expr ``(%%b ≤ %%a) >>= find_assumption,
    nonnegative <$> mk_app ``sub_nonneg_of_le [p]
| e := pp e >>= fail ∘ format.bracket "The expression `" "` is not of the form `a - b`"

example {a b : ℕ} (h : b < a) : 0 < a - b := by positivity
example {a b : ℤ} (h : b < a) : 0 < a - b := by positivity
example {a b : ℤ} (h : b ≤ a) : 0 ≤ a - b := by positivity

end tactic

local attribute [protected] nat.div_mul_div_comm

open finset fintype nat szemeredi_regularity
open_locale classical

variables {α : Type*} [fintype α] {G : simple_graph α} {ε : ℝ}

namespace simple_graph

/-- An explicit form for the constant in the triangle removal lemma. -/
noncomputable def triangle_removal_bound (ε : ℝ) : ℝ :=
min (1 / (2 * ⌈4/ε⌉₊^3)) ((1 - ε/4) * (ε/(16 * bound (ε/8) ⌈4/ε⌉₊))^3)

lemma triangle_removal_bound_pos (hε : 0 < ε) (hε₁ : ε ≤ 1) : 0 < triangle_removal_bound ε :=
by { have : ε / 4 < 1 := by linarith, unfold triangle_removal_bound, positivity }

lemma triangle_removal_bound_mul_cube_lt (hε : 0 < ε) : triangle_removal_bound ε * ⌈4/ε⌉₊^3 < 1 :=
begin
  have : triangle_removal_bound ε ≤ _ := min_le_left _ _,
  refine (mul_le_mul_of_nonneg_right this $ by positivity).trans_lt _,
  rw [←div_div, div_mul_cancel],
  { norm_num },
  exact ne_of_gt (by positivity),
end

lemma card_bound [nonempty α] {ε : ℝ} {X : finset α} {P : finpartition (univ : finset α)}
  (hP₁ : P.is_equipartition) (hP₃ : P.parts.card ≤ bound (ε / 8) ⌈4/ε⌉₊) (hX : X ∈ P.parts) :
  (card α : ℝ) / (2 * bound (ε / 8) ⌈4 / ε⌉₊) ≤ X.card :=
begin
  refine le_trans _ (cast_le.2 $ hP₁.average_le_card_part hX),
  rw div_le_iff',
  { norm_cast,
    exact (annoying_thing (P.parts_nonempty $ univ_nonempty.ne_empty).card_pos
      P.card_parts_le_card).le.trans (mul_le_mul_right' (mul_le_mul_left' hP₃ _) _) },
  positivity,
end

lemma triangle_removal_aux [nonempty α] {ε : ℝ} (hε : 0 < ε) {P : finpartition univ}
  (hP₁ : P.is_equipartition) (hP₃ : P.parts.card ≤ bound (ε / 8) ⌈4/ε⌉₊)
  {t : finset α} (ht : t ∈ (G.reduced_graph ε P).clique_finset 3) :
  triangle_removal_bound ε * ↑(card α) ^ 3 ≤ (G.clique_finset 3).card :=
begin
  rw [mem_clique_finset_iff, is_3_clique_iff] at ht,
  obtain ⟨x, y, z, ⟨xy, X, hX, Y, hY, xX, yY, nXY, uXY, dXY⟩,
                ⟨xz, X', hX', Z, hZ, xX', zZ, nXZ, uXZ, dXZ⟩,
                ⟨yz, Y', hY', Z', hZ', yY', zZ', nYZ, uYZ, dYZ⟩, rfl⟩ := ht,
  cases P.disjoint.elim hX hX' (not_disjoint_iff.2 ⟨x, xX, xX'⟩),
  cases P.disjoint.elim hY hY' (not_disjoint_iff.2 ⟨y, yY, yY'⟩),
  cases P.disjoint.elim hZ hZ' (not_disjoint_iff.2 ⟨z, zZ, zZ'⟩),
  have dXY := P.disjoint hX hY nXY,
  have dXZ := P.disjoint hX hZ nXZ,
  have dYZ := P.disjoint hY hZ nYZ,
  have : 2 * (ε/8) = ε/4, by ring,
  have i := triangle_counting2 G (by rwa this) uXY dXY (by rwa this) uXZ dXZ (by rwa this) uYZ dYZ,
  refine le_trans _ i,
  rw [this, triangle_removal_bound],
  refine (mul_le_mul_of_nonneg_right (min_le_right (_:ℝ) _) $ by positivity).trans _,
  rw [mul_assoc, ←mul_pow, div_mul_eq_mul_div, (show (16:ℝ) = 8 * 2, by norm_num), mul_assoc (8:ℝ),
    ←div_mul_div_comm, mul_pow, ←mul_assoc],
  suffices : ((card α : ℝ) / (2 * bound (ε / 8) ⌈4 / ε⌉₊)) ^ 3 ≤ X.card * Y.card * Z.card,
  { refine (mul_le_mul_of_nonneg_left this $ _).trans_eq (by ring),
    have : ε / 4 ≤ 1 := ‹ε / 4 ≤ _›.trans (by exact_mod_cast G.edge_density_le_one _ _),
    positivity },
  rw [pow_succ, sq, mul_assoc],
  refine mul_le_mul (card_bound hP₁ hP₃ hX) _ (by positivity) (by positivity),
  exact mul_le_mul (card_bound hP₁ hP₃ hY) (card_bound hP₁ hP₃ hZ) (by positivity) (by positivity),
end

lemma reduced_edges_card_aux [nonempty α] {ε : ℝ} {P : finpartition (univ : finset α)} (hε : 0 < ε)
  (hP : P.is_equipartition) (hPε : P.is_uniform G (ε/8)) (hP' : 4 / ε ≤ P.parts.card) :
  2 * (G.edge_finset.card - (reduced_graph G ε P).edge_finset.card : ℝ) < 2 * ε * (card α ^2 : ℕ) :=
begin
  have i : univ.filter (λ xy : α × α, (G.reduced_graph ε P).adj xy.1 xy.2) ⊆
    univ.filter (λ xy, G.adj xy.1 xy.2),
  { exact monotone_filter_right _ (λ xy hxy, reduced_graph_le hxy) },
  rw mul_sub,
  norm_cast,
  rw [double_edge_finset_card_eq, double_edge_finset_card_eq, ←cast_sub (card_le_of_subset i),
    ←card_sdiff i],
  push_cast,
  refine (cast_le.2 $
    (card_le_of_subset reduced_double_edges).trans $ card_union_le _ _).trans_lt _,
  rw cast_add,
  refine (add_le_add (cast_le.2 $ card_union_le _ _) $
    sum_sparse (by positivity) P hP).trans_lt _,
  rw [cast_add, add_right_comm],
  refine (add_le_add_left (internal_killed_card' hε hP hP') _).trans_lt _,
  rw add_assoc,
  refine (add_lt_add_right (sum_irreg_pairs_le_of_uniform' (by positivity) P hP hPε) _).trans_eq _,
  ring,
end

lemma triangle_removal_2 {ε : ℝ} (hε : 0 < ε) (hε₁ : ε ≤ 1) (hG : G.far_from_triangle_free ε) :
  triangle_removal_bound ε * (card α)^3 ≤ (G.clique_finset 3).card :=
begin
  let l : ℕ := ⌈4 / ε⌉₊,
  have hl : 4/ε ≤ l := le_ceil (4/ε),
  casesI is_empty_or_nonempty α,
  { simp [fintype.card_eq_zero] },
  cases le_total (card α) l with hl' hl',
  { refine (mul_le_mul_of_nonneg_left (pow_le_pow_of_le_left (cast_nonneg _) (cast_le.2 hl') _)
      (triangle_removal_bound_pos hε hε₁).le).trans _,
    apply (triangle_removal_bound_mul_cube_lt hε).le.trans,
    simp only [one_le_cast],
    exact (hG.clique_finset_nonempty hε).card_pos },
  obtain ⟨P, hP₁, hP₂, hP₃, hP₄⟩ := szemeredi_regularity G l (by positivity : 0 < ε / 8) hl',
  have : 4/ε ≤ P.parts.card := hl.trans (cast_le.2 hP₂),
  have k := reduced_edges_card_aux hε hP₁ hP₄ this,
  rw mul_assoc at k,
  replace k := lt_of_mul_lt_mul_left k zero_le_two,
  obtain ⟨t, ht⟩ := hG.clique_finset_nonempty' reduced_graph_le k,
  exact triangle_removal_aux hε hP₁ hP₃ ht,
end

/-- If there are not too many triangles, then you can remove some edges to remove all triangles. -/
lemma triangle_removal {ε : ℝ} (hε : 0 < ε) (hε₁ : ε ≤ 1)
  (hG : ((G.clique_finset 3).card : ℝ) < triangle_removal_bound ε * (card α)^3) :
  ∃ G' ≤ G,
    (G.edge_finset.card - G'.edge_finset.card : ℝ) < ε * (card α^2 : ℕ) ∧ G'.clique_free 3 :=
begin
  by_contra,
  push_neg at h,
  exact hG.not_le (triangle_removal_2 hε hε₁ $ far_from_triangle_free_iff.2 $
    λ G' hG hG', le_of_not_lt $ λ i, h G' hG i hG'),
end

end simple_graph

namespace tactic
open positivity simple_graph

/-- Extension for the `positivity` tactic: `simple_graph.triangle_removal_bound ε` is positive if
`0 < ε ≤ 1`. Note this looks for `ε ≤ 1` in the context. -/
@[positivity]
meta def positivity_triangle_removal_bound : expr → tactic strictness
| `(triangle_removal_bound %%ε) := do
  positive p₀ ← core ε,
  p₁ ← to_expr ``(%%ε ≤ 1) >>= find_assumption,
  positive <$> mk_app ``triangle_removal_bound_pos [p₀, p₁]
| e := pp e >>= fail ∘ format.bracket "The expression `"
         "` isn't of the form `simple_graph.triangle_removal_bound ε`"

example (ε : ℝ) (hε₀ : 0 < ε) (hε₁ : ε ≤ 1) : 0 < triangle_removal_bound ε := by positivity

end tactic
