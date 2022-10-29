/-
Copyright (c) 2022 Antoine Chambert-Loir. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Antoine Chambert-Loir
-/


-- import tactic.basic tactic.group
-- import group_theory.solvable
import group_theory.group_action.sub_mul_action
import group_theory.specific_groups.alternating
-- import group_theory.perm.cycle.concrete

import .for_mathlib.alternating
import .index_normal

-- import .for_mathlib.group_theory__subgroup__basic

import .primitive
import .multiple_transitivity

import .perm_iwasawa

import .V4

open_locale pointwise
-- open_locale classical

open mul_action

section junk

variables {α G H : Type*} [group G] [group H] [mul_action G α] {N : subgroup G}

lemma subgroup.map_subgroup_of_eq {K : subgroup N} : (K.map N.subtype).subgroup_of N = K :=
begin
  dsimp [subgroup.subgroup_of],
  rw subgroup.comap_map_eq ,
  simp only [subgroup.ker_subtype, sup_bot_eq],
end

lemma mul_action.stabilizer_subgroup_of_eq {a : α} :
  stabilizer N a = (stabilizer G a).subgroup_of N :=
begin
  ext n,
  simp only [subgroup.mem_subgroup_of, mem_stabilizer_iff],
  refl,
end

example (K K' : subgroup G) : K < K' ↔ (K ≤ K' ∧ K ≠ K') := lt_iff_le_and_ne

lemma subgroup.map_iff_mono_of_injective {f : G →* H} {K K' : subgroup G}
  (hf : function.injective f) :
  K ≤ K' ↔ subgroup.map f K ≤ subgroup.map f K' :=
begin
  split,
  exact subgroup.map_mono,
  { intro h,
    intros x hx,
    suffices : f x ∈ subgroup.map f K',
    { simp only [subgroup.mem_map] at this,
      obtain ⟨y, hy, hx⟩ := this,
      rw ← hf hx,  exact hy, },
    apply h,
    rw subgroup.mem_map,
    use ⟨x, hx, rfl⟩, },
end

lemma subgroup.map_strict_mono_of_injective {f : G →* H} {K K' : subgroup G}
  (hf : function.injective f) :
  K < K' ↔ subgroup.map f K < subgroup.map f K' :=
begin
  simp only [lt_iff_le_not_le],
  simp_rw ← subgroup.map_iff_mono_of_injective hf,
end

lemma subgroup.map_injective_of_injective {f : G →* H} {K K' : subgroup G}
  (hf : function.injective f) :
  subgroup.map f K = subgroup.map f K' ↔ K = K' :=
begin
  simp only [le_antisymm_iff, ← subgroup.map_iff_mono_of_injective hf],
end


end junk

variables  {α : Type*} [fintype α] [decidable_eq α]

namespace alternating_group

open_locale classical

lemma is_pretransitive_of_fixing_subgroup (s : set α) (h0 : s.nontrivial)
  (hα : fintype.card s < fintype.card (sᶜ : set α))  :
  is_pretransitive (fixing_subgroup (alternating_group α) s)
    (sub_mul_action.of_fixing_subgroup (alternating_group α) s) :=
begin
  rw is_pretransitive_iff_is_one_pretransitive,
  refine remaining_transitivity' _ _ _ _ (fintype.card α - 2) _ _ _,
  simp only [part_enat.of_fintype α, part_enat.coe_le_coe, tsub_le_self],
  { rw add_comm,
  rw ← fintype.card_add_compl s,
  have  h1' : 2 < fintype.card (sᶜ : set α),
  { apply lt_of_le_of_lt _ hα,
    rw [nat.succ_le_iff, fintype.one_lt_card_iff_nontrivial, set.nontrivial_coe_sort],
    exact h0, },
  rw [nat.add_sub_assoc (le_of_lt h1'), add_le_add_iff_left,
    nat.le_sub_iff_right (le_of_lt h1')],
  exact h1' },
  -- Here, we needed to add an instance in multiple_transitivity.lean to apply the following lemma
  exact mul_action.alternating_group_is_fully_minus_two_pretransitive α,
end


lemma stabilizer_ne_top' (s : set α) (hs : s.nonempty) (hsc : sᶜ.nontrivial) :
  stabilizer (alternating_group α) s ≠ ⊤ :=
begin
  obtain ⟨a, ha⟩ := hs,
  obtain ⟨b, hb, c, hc, hbc⟩ := hsc,
  rw set.mem_compl_iff at hb hc,
  have hac : a ≠ c, { intro h, apply hc, rw ← h, exact ha },
  have hab : a ≠ b, { intro h, apply hb, rw ← h, exact ha },

  intro h, apply hc,

  -- let gc := cycle.form_perm ↑[a,b,c] (begin rw cycle.nodup_coe_iff, simp [hab, hac, hbc] end ),
  let g := equiv.swap a b * equiv.swap a c,
  have hg : g ∈ alternating_group α,
  { rw equiv.perm.mem_alternating_group,
    apply equiv.perm.is_three_cycle.sign,
    apply equiv.perm.is_three_cycle_swap_mul_swap_same hab hac hbc,  },
  suffices : g • s = s,
  { rw ← this,
    use a,
    split, exact ha,
    dsimp [g],
    rw equiv.swap_apply_left,
    rw equiv.swap_apply_of_ne_of_ne hac.symm hbc.symm, },
  change (⟨g, hg⟩ : alternating_group α) • s = s,
  rw ← mul_action.mem_stabilizer_iff, erw h, apply subgroup.mem_top,
end

lemma stabilizer_ne_top (s : set α) (hs : s.nonempty) (hsc : sᶜ.nonempty)
  (hssc : s.nontrivial ∨ (sᶜ : set α).nontrivial) :
  stabilizer (alternating_group α) s ≠ ⊤ :=
begin
  cases hssc with hs' hsc',
  { rw ← stabilizer_compl,
    rw ← compl_compl s at hs',
    exact stabilizer_ne_top' sᶜ hsc hs', },
  exact stabilizer_ne_top' s hs hsc',
end

-- open_locale classical

example (s t : set α) (h : s ⊆ t) : fintype.card s ≤ fintype.card t :=
begin
exact set.card_le_of_subset h
end

example (s : finset α) : fintype.card (s : set α) = s.card :=
begin
  simp only [finset.coe_sort_coe, fintype.card_coe],
end


-- Il va falloir, soit que t ait ≥ 3 éléments, soit que tᶜ en ait ≥ 2.
-- autrement dit : fintype.card α ≥ 4.
-- La condition est nécessaire :
-- dans le cas α = {1, 2, 3}, t = {1,2} ou t = {1}, le résultat est faux
lemma moves_in (hα : 4 ≤ fintype.card α) (t : set α) :
  ∀ (a ∈ t) (b ∈ t), ∃ (g ∈ stabilizer (equiv.perm α) t ⊓ alternating_group α), g • a = b :=
begin
  intros a ha b hb,
  cases em (a = b) with hab hab,
  { -- a = b, on prend g = 1,
    use 1,
    simp only [hab, subgroup.one_mem, one_smul, eq_self_iff_true, and_self], },
  rw ← ne.def at hab,
  cases le_or_gt (fintype.card t) 2 with ht ht',
  { -- fintype.card t ≤ 2, alors on prend le produit d'un swap (a b) avec un swap dans tᶜ
    have h : 1 < fintype.card (tᶜ : set α),
    { by_contradiction,
      rw not_lt at h,
      rw [← not_lt] at hα,
      apply hα,
      rw ← fintype.card_add_compl t,
      apply nat.lt_succ_of_le,
      apply add_le_add ht h, } ,
    rw fintype.one_lt_card_iff at h,
    obtain ⟨⟨c, hc⟩, ⟨d, hd⟩, hcd⟩ := h,
    simp only [ne.def, subtype.mk_eq_mk] at hcd,
    use equiv.swap a b * equiv.swap c d,
    split,
    { simp only [subgroup.mem_inf],
      split,
      { rw mem_stabilizer_of_finite_iff,
        rintros _ ⟨x, hx, rfl⟩,
        simp only [equiv.perm.smul_def, equiv.perm.coe_mul, function.comp_app],
        have hx_ne : ∀ (u ∈ tᶜ), x ≠ u := λ u hu h,
          set.mem_compl hu (begin rw ← h, exact hx, end),
        rw equiv.swap_apply_of_ne_of_ne (hx_ne c hc) (hx_ne d hd),
        cases em (x = a) with hxa hxa',
        { rw [hxa, equiv.swap_apply_left], exact hb, },
        cases em (x = b) with hxb hxb',
        { rw [hxb, equiv.swap_apply_right], exact ha, },
        rw equiv.swap_apply_of_ne_of_ne hxa' hxb', exact hx, },
      { simp only [equiv.perm.mem_alternating_group, equiv.perm.sign_mul],
        rw equiv.perm.sign_swap hab, rw equiv.perm.sign_swap hcd,
        simp only [int.units_mul_self], }, },
    simp only [equiv.perm.smul_def, equiv.perm.coe_mul, function.comp_app],
    rw set.mem_compl_iff t at hc hd,
    have hac : a ≠ c, intro h, apply hc, rw ← h, exact ha,
    have had : a ≠ d, intro h, apply hd, rw ← h, exact ha,
    rw equiv.swap_apply_of_ne_of_ne hac had,
    rw equiv.swap_apply_left, },
  { -- fintype t ≥ 3, alors on prend un 3-cycle dans t
    suffices : ∃ c ∈ t, c ≠ a ∧ c ≠ b,
    obtain ⟨c, hc, hca, hcb⟩ := this,
    use equiv.swap a c * equiv.swap a b,
    split,
    { simp only [subgroup.mem_inf],
      split,
      { rw mem_stabilizer_of_finite_iff,
        rintros _ ⟨x, hx, rfl⟩,
        simp only [equiv.perm.smul_def, equiv.perm.coe_mul, function.comp_app],
        cases em (x = a) with hxa hxa',
        { rw [hxa, equiv.swap_apply_left],
          rw equiv.swap_apply_of_ne_of_ne hab.symm hcb.symm,
          exact hb, },
        rw ← ne.def at hxa',
        cases em (x = b) with hxb hxb',
        { rw [hxb, equiv.swap_apply_right, equiv.swap_apply_left], exact hc,},
        rw ← ne.def at hxb',
        rw equiv.swap_apply_of_ne_of_ne hxa' hxb',
        cases em (x = c) with hxc hxc',
        { rw [hxc, equiv.swap_apply_right], exact ha, },
        rw ← ne.def at hxc',
        rw equiv.swap_apply_of_ne_of_ne hxa' hxc',
        exact hx, },
      { simp only [equiv.perm.mem_alternating_group, equiv.perm.sign_mul],
        rw equiv.perm.sign_swap hab, rw equiv.perm.sign_swap (ne.symm hca),
        simp only [int.units_mul_self], }, },
    { simp only [equiv.perm.smul_def, equiv.perm.coe_mul, function.comp_app],
      rw equiv.swap_apply_left,
      rw equiv.swap_apply_of_ne_of_ne (ne.symm hab) (ne.symm hcb), },
    suffices : (t \ {a, b}).nonempty,
    { obtain ⟨c, h⟩ := this,
      simp only [set.mem_diff, set.mem_insert_iff, set.mem_singleton_iff, not_or_distrib] at h,
      use c,
      apply and.intro h.left,
      exact h.right, },
    rw set.nonempty_diff,
    intro ht,
    rw [gt_iff_lt, ← not_le] at ht', apply ht',
    rw ← finset.card_doubleton hab,
    simp only [← fintype.card_coe, ← finset.coe_sort_coe],
    apply set.card_le_of_subset,
    simp only [finset.coe_insert, finset.coe_singleton],
    exact ht },
end

lemma moves_in' (hα : 4 ≤ fintype.card α) (G : subgroup (equiv.perm α)) (t : set α)
  (hGt : stabilizer (equiv.perm α) t ⊓ (alternating_group α) ≤ G) :
  ∀ (a ∈ t) (b ∈ t), ∃ (g : G), g • a = b :=
begin
  intros a ha b hb,
  obtain ⟨g, hg, H⟩ := moves_in hα t a ha b hb,
  use g, apply hGt,  exact hg, exact H,
end


lemma has_three_cycle_of_stabilizer' (s : set α) (hs : 2 < fintype.card s) :
 -- (G : subgroup (equiv.perm α)) :
 --  (hG : stabilizer (equiv.perm α) s ⊓ alternating_group α < G) :
  ∃ (g : equiv.perm α), g.is_three_cycle ∧ g ∈ stabilizer (equiv.perm α) s :=
begin
  rw fintype.two_lt_card_iff at hs,
  obtain ⟨⟨a, ha⟩,⟨b,hb⟩, ⟨c, hc⟩, hab, hac, hbc⟩ := hs,
  rw [ne.def, subtype.mk_eq_mk, ← ne.def] at hab hac hbc,
  use (equiv.swap a b) * (equiv.swap a c),
  split,
  apply equiv.perm.is_three_cycle_swap_mul_swap_same hab hac hbc,
  rw ← stabilizer_compl,
  rw mem_stabilizer_of_finite_iff,
  rintros _ ⟨x, hx, rfl⟩,
  simp only [equiv.perm.smul_def, equiv.perm.coe_mul, function.comp_app],
  rw set.mem_compl_iff at hx,
  suffices h : ∀ (u ∈ s), x ≠ u,
  { rw equiv.swap_apply_of_ne_of_ne (h a ha) (h c hc),
    rw equiv.swap_apply_of_ne_of_ne (h a ha) (h b hb),
    exact hx, },
  { intros u hu h, apply hx, rw h, exact hu, },
end

lemma has_three_cycle_of_stabilizer [decidable_eq α] (s : set α) (hα : 4 < fintype.card α) :
  ∃ (g : equiv.perm α), g.is_three_cycle ∧ g ∈ stabilizer (equiv.perm α) s :=
begin
  cases nat.lt_or_ge 2 (fintype.card s) with hs hs,
  exact has_three_cycle_of_stabilizer' s hs,
  obtain ⟨g, hg, hg'⟩ := has_three_cycle_of_stabilizer' sᶜ _,
  { use g, rw stabilizer_compl at hg', exact ⟨hg, hg'⟩, },
  { rw lt_iff_not_le at hα ⊢,
    intro hs', apply hα,
    rw ← fintype.card_add_compl s,
    suffices : 2 + 2 ≤ 4,
    { apply le_trans _ this,
      apply nat.add_le_add, exact hs,
      apply le_trans _ hs', apply le_of_eq,
      simp only [fintype.card_of_finset, set.mem_compl_iff], },
    norm_num, },
end

lemma is_maximal_stab'_temp (s : set α) (hα : 4 < fintype.card α)
 -- (h0 : s.nonempty) (h1 : sᶜ.nonempty)
 -- (hs : fintype.card s < fintype.card (sᶜ : set α))
  (G : subgroup (equiv.perm α)) (hG : (stabilizer (equiv.perm α) s) ⊓ (alternating_group α) ≤ G) :
  is_preprimitive G α → alternating_group α ≤ G :=
begin
  intro hG',
  -- intros s h0 h1 hα G hG,
  -- G : subgroup (equiv.perm α))
  -- hG : stabilizer (equiv.perm α) s ⊓ (alternating_group α) < G)
  -- We need to prove that alternating_group α ≤ ⊤
  -- G contains a three_cycle
  obtain ⟨g, hg3, hg⟩ := has_three_cycle_of_stabilizer s hα,
  -- By Jordan's theorem, it suffices to prove that G acts primitively
  apply jordan_three_cycle hG' hg3,
  { apply hG,
    simp only [subgroup.mem_inf, hg, true_and],
    exact equiv.perm.is_three_cycle.mem_alternating_group hg3, },
end

lemma stabilizer.is_preprimitive (s : set α) (hs : (sᶜ : set α).nontrivial):
  is_preprimitive (stabilizer (alternating_group α) s) s :=
begin
  let φ : stabilizer (alternating_group α) s → equiv.perm s := mul_action.to_perm,
  let f : s →ₑ[φ] s := {
  to_fun := id,
  map_smul' := λ ⟨g, hg⟩ ⟨x, hx⟩, by simp only [id.def, equiv.perm.smul_def, to_perm_apply], },
  have hf : function.bijective f := function.bijective_id,
  rw is_preprimitive_of_bijective_map_iff _ hf,
  exact equiv.perm.is_preprimitive s,

  -- function.surjective φ
  suffices : ∃ k : equiv.perm (sᶜ : set α), equiv.perm.sign k = -1,
  obtain ⟨k, hk_sign⟩ := this,
  have hks : (equiv.perm.of_subtype k) • s = s,
  { rw ← mem_stabilizer_iff,
    apply equiv.perm.of_subtype.mem_stabilizer', },

  -- function.surjective φ
  { intro g,
    have hgs : (equiv.perm.of_subtype g) • s = s,
    apply equiv.perm.of_subtype.mem_stabilizer,

    have hminus_one_ne_one : (-1 : units ℤ) ≠ 1,
    { intro h, rw [← units.eq_iff, units.coe_one, units.coe_neg_one] at h, norm_num at h, },

    let g' := ite (equiv.perm.sign g = 1)
      (equiv.perm.of_subtype g)
      (equiv.perm.of_subtype g * (equiv.perm.of_subtype k)),

    use g',

    rw equiv.perm.mem_alternating_group,
    cases int.units_eq_one_or (equiv.perm.sign g) with hsg hsg;
    { dsimp [g'], -- rw hsg,
      simp only [hsg, eq_self_iff_true, if_true, hminus_one_ne_one, if_false,
        equiv.perm.sign_of_subtype,
        equiv.perm.sign_mul, mul_neg, mul_one, neg_neg, hsg, hk_sign], },

    rw mem_stabilizer_iff,
    change (ite (equiv.perm.sign g = 1)
      (equiv.perm.of_subtype g)
      (equiv.perm.of_subtype g * (equiv.perm.of_subtype k))) • s = s,
    cases int.units_eq_one_or (equiv.perm.sign g) with hsg hsg,
    { simp only [hsg,  eq_self_iff_true, if_true],
      exact hgs, },
    { simp only [hsg, hminus_one_ne_one, if_false],
      rw mul_smul, rw hks, exact hgs, },

    dsimp [φ],
    cases int.units_eq_one_or (equiv.perm.sign g) with hsg hsg,
    { dsimp [g'], simp only [hsg, eq_self_iff_true, if_true, hminus_one_ne_one, if_false],
      ext,
      simp only [to_perm_apply, has_smul.smul_stabilizer_def, subtype.coe_mk],
      change equiv.perm.of_subtype g ↑x = ↑(g x),
      exact equiv.perm.of_subtype_apply_coe g x, },
    { dsimp [g'], simp only [hsg, eq_self_iff_true, if_true, hminus_one_ne_one, if_false],
      ext,
      simp only [to_perm_apply, has_smul.smul_stabilizer_def, subtype.coe_mk],
      change ((equiv.perm.of_subtype g) * (equiv.perm.of_subtype k)) ↑x = ↑(g x),
      rw equiv.perm.mul_apply ,
      rw equiv.perm.of_subtype_apply_of_not_mem k _,
      exact equiv.perm.of_subtype_apply_coe g x,
      rw set.not_mem_compl_iff, exact x.prop, }, },

  -- ∃ k : equiv.perm (sᶜ : set α), equiv.perm.sign k = -1,
  obtain ⟨a, ha, b, hb, hab⟩ := hs,
  use equiv.swap ⟨a, ha⟩ ⟨b, hb⟩,
  rw equiv.perm.sign_swap _,
  rw ← function.injective.ne_iff (subtype.coe_injective),
  simp only [subtype.coe_mk], exact hab,
end

example (s t : set α) (a : α) (ha : a ∈ s ⊓ t) : a ∈ s :=
begin
  apply @inf_le_left _ _ s t,  exact ha,
end

lemma stabilizer.is_preprimitive' (s : set α) (hsc : sᶜ.nontrivial)
  (G : subgroup (equiv.perm α)) (hG : stabilizer (equiv.perm α) s ⊓ alternating_group α ≤ G) :
  is_preprimitive (stabilizer G s) s :=
begin
  let φ : stabilizer (alternating_group α) s → stabilizer G s := λ g,
  begin
    use (g : alternating_group α), apply hG, rw subgroup.mem_inf,
    split,
    { let h := g.prop, rw mem_stabilizer_iff at h ⊢, exact h, },
    { exact set_like.coe_mem ↑g, },
    { rw mem_stabilizer_iff, let h := g.prop, rw mem_stabilizer_iff at h, exact h, },
  end,
  let f : s →ₑ[φ] s := {
    to_fun := id,
    map_smul' := λ ⟨⟨m, hm'⟩, hm⟩ ⟨a, ha⟩, rfl, },
  have hf : function.surjective f := function.surjective_id,
  apply is_preprimitive_of_surjective_map hf,
  apply stabilizer.is_preprimitive,
  exact hsc,
end



lemma is_maximal_stab'_temp' (s : set α) (h0 : s.nontrivial) (h1 : sᶜ.nontrivial)
  (hα : fintype.card s < fintype.card (sᶜ : set α)) (h4 : 4 ≤ fintype.card α)
  (G : subgroup (equiv.perm α))
  (hG : (stabilizer (equiv.perm α) s) ⊓ (alternating_group α) < G ⊓ (alternating_group α)) :
  is_preprimitive G α :=
begin
  -- G acts transitively
  haveI : is_pretransitive G α,
  { have hG' : stabilizer (equiv.perm α) s ⊓ alternating_group α ≤ G :=
    le_trans (le_of_lt hG) (inf_le_left),
    apply is_pretransitive.of_partition G s,
    { intros a ha b hb,
      obtain ⟨g, hg, H⟩ := alternating_group.moves_in h4 s a ha b hb,
      use g,
      apply hG',
      exact hg,
      exact H, },
    { intros a ha b hb,
      obtain ⟨g, hg, H⟩ := alternating_group.moves_in h4 sᶜ a ha b hb,
      use g,
      apply hG',
      rw stabilizer_compl at hg, exact hg,
      exact H, },
    { intro h,
      apply (lt_iff_le_not_le.mp hG).right,
      --  G ⊓ alternating_group α ≤ stabilizer (equiv.perm α) s ⊓ alternating_group α,
      rw le_inf_iff,
      split,
      { intro g, rw subgroup.mem_inf, rintro ⟨hg, hg'⟩,
        rw mem_stabilizer_iff,
        rw ← subgroup.coe_mk G g hg,
        change (⟨g, hg⟩ : ↥G) • s = s,
        rw ← mem_stabilizer_iff,
        change _ ∈ stabilizer ↥G s,
        rw h, exact subgroup.mem_top ⟨g, hg⟩, },
      { exact inf_le_right, }, }, },

  apply is_preprimitive.mk,

  /- The proof needs 4 steps -/
  /- Step 1 : No block is equal to sᶜ
     This uses that fintype.card s < fintype.card sᶜ.
     In the equality case, fintype.card s = fintype.card sᶜ, it is possible that B = sᶜ,
     then G is the wreath product,
     this is case (b) of the O'Nan-Scott classification of max'l subgroups of the symmetric group -/
  have hB_ne_sc : ∀ (B : set α) (hB : is_block G B), ¬(B = sᶜ),
  { intros B hB hBsc,
    obtain ⟨b, hb⟩ := h1.nonempty, rw ← hBsc at hb,
    obtain ⟨a, ha⟩ := h0.nonempty,
    obtain ⟨k, hk⟩ := exists_smul_eq G b a,
    suffices : fintype.card (B : set α) ≤ fintype.card s,
    { apply nat.lt_irrefl (fintype.card B),
      apply lt_of_le_of_lt this,
      simp_rw hBsc, exact hα, },
    rw ← smul_set_card_eq k B,
    apply set.card_le_of_subset ,
    change k • B ⊆ s,
    rw [← set.disjoint_compl_right_iff_subset, ← hBsc],
    apply or_iff_not_imp_left.mp (is_block.def_one.mp hB k),
    intro h,
    apply set.not_mem_empty a,
    rw ← set.inter_compl_self s,
    split,
      exact ha,
      rw [← hk, ← hBsc, ← h, set.smul_mem_smul_set_iff], exact hb },

  /- Step 2 : A block contained in sᶜ is a subsingleton-/
  have hB_not_le_sc : ∀ (B : set α) (hB : is_block G B) (hBsc : B ⊆ sᶜ), B.subsingleton,
  { intros B hB hBsc,
    suffices : B = coe '' (coe ⁻¹' B : set (sᶜ : set α)),
    rw this,
    apply set.subsingleton.image ,

    suffices : is_trivial_block (coe ⁻¹' B : set (sᶜ : set α)),
    apply or.resolve_right this,

    intro hB',
    apply hB_ne_sc B hB,
    apply set.subset.antisymm hBsc,
    intros x hx,
    rw [← subtype.coe_mk x hx, ← set.mem_preimage],
    rw [hB', set.top_eq_univ], apply set.mem_univ,

    { -- is_trivial_block (coe ⁻¹' B : set (sᶜ : set α)),
      suffices : is_preprimitive (stabilizer G (sᶜ : set α)) (sᶜ : set α),
      refine is_preprimitive.has_trivial_blocks this _,

      -- is_block (coe ⁻¹' B : set (sᶜ : set α))
      let φ' : stabilizer G (sᶜ: set α) → G := coe,
      let f' : (sᶜ : set α) →ₑ[φ'] α := {
        to_fun := coe,
        map_smul' := λ m x, by simp only [φ', has_smul.smul_stabilizer_def], },
      apply mul_action.is_block_preimage f' hB,

      apply stabilizer.is_preprimitive',
      rw ← stabilizer_compl at hG,
      rw compl_compl, exact h0,
      rw stabilizer_compl,
      apply le_trans (le_of_lt hG),
      exact inf_le_left, },

    { -- B = coe '' (coe ⁻¹' B : set (sᶜ : set α)),
      apply set.subset.antisymm,
      intros x hx,
      use ⟨x, hBsc hx⟩,
      simp only [hx, set.mem_preimage, subtype.coe_mk, eq_self_iff_true, and_self],
      exact set.image_preimage_subset coe B, }, },

  /- Step 3 : A block contained in s is a subsingleton -/
  have hB_not_le_s : ∀ (B : set α) (hB : is_block G B), (B ⊆ s) → B.subsingleton,
  { intros B hB hBs,

    suffices hB_coe : B = coe '' (coe ⁻¹' B : set ↥s),

    suffices : is_trivial_block (coe ⁻¹' B : set s),
    cases this with hB' hB',
    { -- trivial case
      rw hB_coe,
      apply set.subsingleton.image,
      exact hB', },
    { -- coe ⁻¹' B = s
      have hBs' : B = s,
      { apply set.subset.antisymm hBs,
        intros x hx,
        rw ← subtype.coe_mk x hx,
        rw ← set.mem_preimage,
        rw hB',
        rw set.top_eq_univ,
        apply set.mem_univ, },

    have : ∃ g' ∈ G, g' • s ≠ s,
    { by_contradiction,
      apply  (ne_of_lt hG),
      push_neg at h,
      apply le_antisymm,
      exact le_of_lt hG,
      intros g' hg',
      rw subgroup.mem_inf at hg' ⊢,

      rw mem_stabilizer_iff, apply and.intro (h g' hg'.left),
      exact hg'.right, },
    obtain ⟨g', hg', hg's⟩ := this,
    cases is_block.def_one.mp hB ⟨g', hg'⟩ with h h,
    { -- case g' • B = B : absurd, since B = s and choice of g'
      exfalso,
      apply hg's, rw ← hBs', exact h, },
    { -- case g' • B disjoint from B

      suffices : (g' • B).subsingleton,
      apply set.subsingleton_of_image _ B this,
      apply function.bijective.injective,
      apply mul_action.bijective,

      apply hB_not_le_sc ((⟨g', hg'⟩ : G) • B),
      exact is_block_of_block _ hB,
      rw ← hBs',
      apply disjoint.subset_compl_right ,
      exact h, }, },

    { -- is_trivial_block (coe ⁻¹' B : set s),
      suffices : is_preprimitive (stabilizer G s) (s : set α),
      refine is_preprimitive.has_trivial_blocks this _,

      -- is_block (coe ⁻¹' B : set s)
      let φ' : stabilizer G s → G := coe,
      let f' : s →ₑ[φ'] α := {
        to_fun := coe,
      map_smul' := λ ⟨m, hm⟩ x, by simp only [φ', has_smul.smul_stabilizer_def], },
      apply mul_action.is_block_preimage f' hB,

      apply stabilizer.is_preprimitive' s h1,
      apply le_trans (le_of_lt hG), exact inf_le_left, },

    { -- B = coe '' (coe ⁻¹' B : set ↥s),
      apply set.subset.antisymm,
      intros x hx,
      use ⟨x, hBs hx⟩,
      simp only [hx, set.mem_preimage, subtype.coe_mk, eq_self_iff_true, and_self],
      exact set.image_preimage_subset coe B, }, },

  intros B hB,
  unfold is_trivial_block,

  rw or_iff_not_imp_left ,
  intro hB',

  obtain ⟨a, ha, ha'⟩ := set.not_subset_iff_exists_mem_not_mem.mp
    (λ h, hB' ((hB_not_le_sc B hB) h)),
  rw set.not_mem_compl_iff at ha',

  obtain ⟨b, hb, hb'⟩ := set.not_subset_iff_exists_mem_not_mem.mp
    (λ h, hB' ((hB_not_le_s B hB) h)),
  rw ← set.mem_compl_iff at hb',

  have hsc_le_B : sᶜ ⊆ B,
  {  intros x hx',
    suffices : ∃ (k : fixing_subgroup (alternating_group α) s), k • b = x,
    obtain ⟨⟨k, hk⟩, hkbx : k • b = x⟩ := this,
    suffices : k • B = B,
    rw [← hkbx, ← this, set.smul_mem_smul_set_iff],
    exact hb,
    { -- k • B = B,
      apply or_iff_not_imp_right.mp (is_block.def_one.mp hB ⟨k, _⟩),
      { rw set.not_disjoint_iff_nonempty_inter,
        change (k • B ∩ B).nonempty,
        use a,
        split,
          rw mem_fixing_subgroup_iff at hk,
          rw ← hk a ha',
          exact set.smul_mem_smul_set ha,
          exact ha, },
      { -- ↑k ∈ G
        apply le_trans (le_of_lt hG), exact inf_le_left,

        rw subgroup.mem_inf, split,

      suffices hk' : k ∈ stabilizer (alternating_group α) s,
      { simpa [mem_stabilizer_iff] using hk', },
      apply mul_action.fixing_subgroup_le_stabilizer, exact hk,
      exact k.prop, }, },
    { -- ∃ (k : fixing_subgroup (alternating_group α) s), k • b = x,
      haveI : is_pretransitive (fixing_subgroup (alternating_group α) s)
        (sub_mul_action.of_fixing_subgroup (alternating_group α) s) :=
        is_pretransitive_of_fixing_subgroup s h0 hα,
      obtain ⟨k, hk⟩ := exists_smul_eq (fixing_subgroup (alternating_group α) s)
        (⟨b, hb'⟩ : sub_mul_action.of_fixing_subgroup (alternating_group α) s)
        ⟨x, hx'⟩,
      use k,
      rw [← subtype.coe_inj, sub_mul_action.coe_smul] at hk,
      exact hk,
      }, },

  -- Conclusion of the proof : B = ⊤
  rw eq_top_iff,
  intros x _,
  obtain ⟨b, hb⟩ := h1.nonempty,
  obtain ⟨⟨g, hg⟩, hgbx : g • b = x⟩ := exists_smul_eq G b x,
  suffices : g • B = B,
  { rw [← hgbx, ← this, set.smul_mem_smul_set_iff],
    exact hsc_le_B hb, },
  -- g • B = B,
  apply or_iff_not_imp_right.mp (is_block.def_one.mp hB ⟨g, hg⟩),
  rw set.not_disjoint_iff_nonempty_inter,
  change (g • B ∩ B).nonempty,
  apply aux_pigeonhole,

  -- card B + card (g • B) = card B + card B
  -- ... ≥ card sᶜ + card sᶜ
  -- ... > card s + card s ᶜ = card α
  rw ← fintype.card_add_compl s,
  apply nat.lt_of_lt_of_le,
  { apply nat.add_lt_add_right _ (fintype.card (sᶜ : set α)),
    use (fintype.card (sᶜ : set α)),
    exact hα, },
  apply nat.add_le_add,
  { apply le_trans (set.card_le_of_subset hsc_le_B),
    apply le_of_eq,
    rw ← set.coe_to_finset B,
    simp only [← set.to_finset_card],
    change _ = ((λ x, g • x) '' ↑(B.to_finset)).to_finset.card,
    simp_rw ← finset.coe_image ,
    simp only [finset.to_finset_coe],
    rw finset.card_image_of_injective _ (mul_action.injective g) },
  exact set.card_le_of_subset hsc_le_B,
end

example (a b : ℕ) (ha :  2 ≤ a) (hab : a < b) : a + 1 ≤ a + b - 2 :=
begin
  rw nat.add_sub_assoc (le_trans ha (le_of_lt hab)),
  rw add_le_add_iff_left,
  rw nat.le_sub_iff_right (le_trans ha (le_of_lt hab)),
  rw ← nat.succ_eq_one_add,
  rw nat.succ_le_iff,
  exact lt_of_le_of_lt ha hab,
end

theorem is_maximal_stab' -- (hα : 4 < fintype.card α)
  (s : set α) (h0' : s.nontrivial) (h1' : sᶜ.nontrivial)
  (hs : fintype.card s < fintype.card (sᶜ : set α)) :
  subgroup.is_maximal (stabilizer (alternating_group α) s) :=
begin
  suffices hα : 4 < fintype.card α,
-- h0 : s.nonempty, h1  : sᶜ.nonempty
/-   have h1' : sᶜ.nontrivial,
  { rw [← set.nontrivial_coe, ← fintype.one_lt_card_iff_nontrivial],
    apply lt_of_le_of_lt _ hs,
    rw [nat.succ_le_iff, fintype.card_pos_iff, set.nonempty_coe_sort],
    exact h0, },
 -/
 --  cases em(s.nontrivial) with h0' h0',
  -- We start with the case where s.nontrivial
  split, split,
  -- stabilizer (alternating_group α) s ≠ ⊤
  exact stabilizer_ne_top' s h0'.nonempty h1',
  -- ∀ (G : subgroup (alternating_group α)), stabilizer (alternating_group α) s < b) → b = ⊤
  { intros G' hG',
    suffices : alternating_group α ≤ G'.map (alternating_group α).subtype,
    { rw eq_top_iff, intros g hg,
      obtain ⟨g', hg', hgg'⟩ := this g.prop,
      simp only [subgroup.coe_subtype, set_like.coe_eq_coe] at hgg',
      rw ← hgg', exact hg', },

    apply is_maximal_stab'_temp s hα,

    rw [← subgroup.subgroup_of_map_subtype, subgroup.map_subtype_le_map_subtype],
    rw mul_action.stabilizer_subgroup_of_eq at hG',
    exact le_of_lt hG',

    apply is_maximal_stab'_temp' s h0' h1' hs (le_of_lt hα),
    rw lt_iff_le_not_le,
    split,
    { intro g,
      simp only [subgroup.mem_inf],
      rintro ⟨hg, hg'⟩,
      refine and.intro _ hg',
      simp only [subgroup.mem_map, subgroup.coe_subtype, exists_prop],
      use ⟨g, hg'⟩,
      split,
      { apply le_of_lt hG',
        simpa only [mem_stabilizer_iff] using hg, },
      refl,  },
    { intro h,
      rw lt_iff_le_not_le at hG', apply hG'.right,
      intros g' hg',
      rw mem_stabilizer_iff,
      change (g' : equiv.perm α) • s = s, rw ← mem_stabilizer_iff,
      apply @inf_le_left (subgroup (equiv.perm α)) _ , apply h,
      rw subgroup.mem_inf,
      apply and.intro _ g'.prop,
      simp only [subgroup.mem_map,
        subgroup.coe_subtype, set_like.coe_eq_coe, exists_prop, exists_eq_right],
      exact hg', }, },

    -- hα : 4 < fintype.card α
    have h0 : 2 ≤ fintype.card s,
    rw [nat.succ_le_iff, fintype.one_lt_card_iff_nontrivial, set.nontrivial_coe_sort],
    exact h0',
    change 2 + 2 < _,
    rw ← fintype.card_add_compl s,
    apply lt_of_le_of_lt,
    exact nat.add_le_add_right h0 2,
    apply nat.add_lt_add_left,
    exact lt_of_le_of_lt h0 hs,
/-   -- ¬s.nontrivial
  simp only [set.not_nontrivial_iff] at h0',
  suffices : ∃ (a : α), s = ({a} : set α),
  obtain ⟨a, rfl⟩ := this,
  have : stabilizer (alternating_group α) ({a} : set α) = stabilizer (alternating_group α) a,
  { ext g, simp only [mem_stabilizer_iff, set.smul_set_singleton, set.singleton_eq_singleton_iff], },
  rw this,
  haveI : nontrivial α := set.nontrivial_of_nontrivial h1',
  apply has_maximal_stabilizers_of_preprimitive,
  apply alternating_group.is_preprimitive,
  apply le_trans _ (le_of_lt hα), norm_num,
  { obtain ⟨a, ha⟩ := h0,
    use a, exact set.subsingleton.eq_singleton_of_mem h0' ha, }, -/
end


lemma three_le {c n : ℕ} (h : 1 ≤ n) (h' : n < c) (hh' : c ≠ 2 * n) : 3 ≤ c :=
begin
  cases nat.eq_or_lt_of_le h with h h,
  { rw ← h at h' hh',
    cases nat.eq_or_lt_of_le h' with h' h',
    { exfalso, apply hh' h'.symm, },
    exact h',  },
  rw nat.succ_le_iff,
  exact lt_of_le_of_lt h h',
end

/-- stabilizer (alternating_group α) s is a maximal subgroup of alternating_group α,
provided s ≠ ⊥, s ≠ ⊤ and fintype.card α ≠ 2 * fintype.card ↥s) -/
theorem stabilizer.is_maximal (s : set α) (h0 : s.nonempty) (h1 : sᶜ.nonempty)
  (hs : fintype.card α ≠ 2 * fintype.card ↥s) :
  subgroup.is_maximal (stabilizer (alternating_group α) s) :=
begin
  have hα : 3 ≤ fintype.card α,
  { rw [← set.nonempty_coe_sort, ← fintype.card_pos_iff, ← nat.succ_le_iff] at h0 h1,
    refine three_le h0 _ hs,
    rw [← tsub_pos_iff_lt,  ←  fintype.card_compl_set], exact h1, },
  haveI : nontrivial α,
  { rw ← fintype.one_lt_card_iff_nontrivial, apply lt_of_lt_of_le _ hα, norm_num, },

  have h : ∀ (t : set α) (h0 : t.nonempty) (h0': t.subsingleton),
    (stabilizer (alternating_group α) t).is_maximal,
  { intros t ht ht',
    suffices : ∃ (a : α), t = ({a} : set α),
    obtain ⟨a, rfl⟩ := this,
    have : stabilizer (alternating_group α) ({a} : set α) = stabilizer (alternating_group α) a,
    { ext g, simp only [mem_stabilizer_iff, set.smul_set_singleton, set.singleton_eq_singleton_iff], },
    rw this,
    apply has_maximal_stabilizers_of_preprimitive,
    apply alternating_group.is_preprimitive hα,
    { obtain ⟨a, ha⟩ := ht,
      use a, exact set.subsingleton.eq_singleton_of_mem ht' ha, }, },

  cases em (s.nontrivial) with h0' h0',
  cases em (sᶜ.nontrivial) with h1' h1',
  -- h0' : s.nontrivial, h1' : sᶜ.nontrivial
  cases nat.lt_trichotomy (fintype.card s) (fintype.card (sᶜ : set α)) with hs' hs',
  { exact is_maximal_stab' s h0' h1' hs', },
  cases hs' with hs' hs',
  { exfalso, apply hs,
    rw [← fintype.card_add_compl s, ← hs', ← two_mul], },
  { rw ← compl_compl s at h0',
    rw ← stabilizer_compl,
    apply is_maximal_stab' sᶜ h1' h0',
    simp_rw compl_compl s,
    convert hs', },
  -- h0' : s.nontrivial, h1' : ¬(s.nontrivial)
  { simp only [set.not_nontrivial_iff] at h1',
    rw ← stabilizer_compl, exact h sᶜ h1 h1', },
  -- h0' : ¬(s.nontrivial),
  { simp only [set.not_nontrivial_iff] at h0',
    exact h s h0 h0', },
end

/- theorem nat.finset_is_preprimitive_of' (n : ℕ) (h_one_le : 1 ≤ n) (hn : n < fintype.card α)
  (hα : fintype.card α ≠ 2 * n) : is_preprimitive (alternating_group α) (n.finset α) :=
begin
  have hα' : 3 ≤ fintype.card α := three_le h_one_le hn hα,
  haveI : nontrivial α,
  { rw ← fintype.one_lt_card_iff_nontrivial, exact lt_of_le_of_lt h_one_le hn },
  have h : (fintype.card α - n) + n = fintype.card α, sorry,


  cases nat.eq_or_lt_of_le hn with hn1 hn2,
  { -- n.succ = fintype.card α
    rw is_preprimitive_of_bijective_map_iff (function.surjective_id)
      (nat.finset_compl_bijective α (alternating_group α) n h),
    have hn1' : fintype.card α - n = 1,
    { rw ← hn1, rw nat.succ_sub, simp only [tsub_self], apply le_of_eq, refl, },

    let f : α →[alternating_group α] nat.finset α (fintype.card α - n) := {
      to_fun := λ x, ⟨{x},
    begin
     change ({x} : finset α).card = fintype.card α - n,
     rw finset.card_singleton x, rw hn1',
    end⟩,
      map_smul' := λ g x, rfl },
    suffices hf : function.surjective f,
    { apply is_preprimitive_of_surjective_map hf,
      exact alternating_group.is_preprimitive hα', },
    rintro ⟨s, hs⟩,
    change s.card = fintype.card α - n at hs,
    rw hn1' at hs,
    rw finset.card_eq_one at hs,
    obtain ⟨a, ha⟩ := hs,
    use a,
    simp only [ha, equivariant_map.coe_mk], },
  { -- n.succ < fintype.card α
    haveI ht : is_pretransitive (alternating_group α) (n.finset α),
    { rw is_pretransitive_of_bijective_map_iff (function.surjective_id)
        (nat.finset_compl_bijective α (alternating_group α) n h),
      apply nat.finset_is_pretransitive_of_multiply_pretransitive,
      apply is_multiply_pretransitive_of_higher,
      sorry,
      sorry,
      sorry,
      sorry, },

    sorry, },
--     apply nat.finset_is_pretransitive_of_multiply_pretransitive, },
end -/

/-- The action of alternating_group α on the n-element subsets of α is preprimitive
provided 0 < n < #α and #α ≠ 2*n -/
theorem nat.finset_is_preprimitive_of_alt (n : ℕ) (h_one_le : 1 ≤ n) (hn : n < fintype.card α)
  (hα : fintype.card α ≠ 2 * n) : is_preprimitive (alternating_group α) (n.finset α) :=
begin
  have hα' : 3 ≤ fintype.card α := three_le h_one_le hn hα,
  haveI : nontrivial α,
  { rw ← fintype.one_lt_card_iff_nontrivial, exact lt_of_le_of_lt h_one_le hn },
  cases nat.eq_or_lt_of_le h_one_le with h_one h_one_lt,
  { -- n = 1 :
    let f : α →[alternating_group α] nat.finset α 1 := {
      to_fun := λ x, ⟨{x}, finset.card_singleton x⟩,
      map_smul' := λ g x, rfl },
    rw ← h_one,
    suffices hf : function.surjective f,
    { apply is_preprimitive_of_surjective_map hf,
      exact alternating_group.is_preprimitive hα', },
    rintro ⟨s, hs⟩,
    change s.card = 1 at hs,
    rw finset.card_eq_one at hs,
    obtain ⟨a, ha⟩ := hs,
    use a,
    simp only [ha, equivariant_map.coe_mk], refl, },

  -- h_one_lt : 1 < n
  haveI ht : is_pretransitive (alternating_group α) (n.finset α),
  { -- apply nat.finset_is_pretransitive_of_multiply_pretransitive,
    have : (fintype.card α - n) + n = fintype.card α,
    { apply nat.sub_add_cancel , exact le_of_lt hn, },
    rw is_pretransitive_of_bijective_map_iff (function.surjective_id)
      (nat.finset_compl_bijective α (alternating_group α) n this),
    apply nat.finset_is_pretransitive_of_multiply_pretransitive,
    have h' : fintype.card α - n ≤ fintype.card α - 2,
    { apply nat.sub_le_sub_left , exact h_one_lt, },

    apply is_multiply_pretransitive_of_higher (alternating_group α) α _ h',
    rw part_enat.card_eq_coe_fintype_card, simp only [part_enat.coe_le_coe, tsub_le_self],
    exact alternating_group_is_fully_minus_two_pretransitive α, },

  haveI : nontrivial (n.finset α) :=
    nat.finset_nontrivial α n (lt_trans (nat.lt_succ_self 0) h_one_lt) hn,
  obtain ⟨sn : n.finset α⟩ := nontrivial.to_nonempty,
  let s := sn.val,
  let hs : s.card = n := sn.prop,
  -- have hs : (s : finset α).card = n := s.prop,
  rw ← maximal_stabilizer_iff_preprimitive (alternating_group α) sn,
  have : stabilizer (alternating_group α) sn = stabilizer (alternating_group α) (s : set α),
  { ext g,
    simp only [mem_stabilizer_iff],
    rw ← subtype.coe_inj,
    change g • s = s ↔ _,
    rw [← finset.coe_smul_finset, ← finset.coe_inj], },
  rw this,
  apply stabilizer.is_maximal (s : set α),
  { simp only [finset.coe_nonempty, ← finset.card_pos, hs],
    apply lt_trans one_pos h_one_lt, },
  { simp only [← finset.coe_compl, finset.coe_nonempty, ← finset.card_compl_lt_iff_nonempty,
      compl_compl, hs],
    exact hn, },
  { simp only [finset.coe_sort_coe, fintype.card_coe, hs],
    exact hα, },
  apply_instance,
end



lemma mul_aut_smul_subgroup_of_eq {G : Type*} [group G] {N H : subgroup G} (f : mul_aut G) (f' : mul_aut N)
  (hff' : ∀ (n : N), f n = f' n) :
  (f • H).subgroup_of N = f' • (H.subgroup_of N) :=
begin
  dsimp [has_smul.smul, mul_distrib_mul_action.to_monoid_hom],
  -- change (subgroup.map f.to_monoid_hom H).subgroup_of N = subgroup.map f'.to_monoid_hom _,
  ext,
  simp only [subgroup.mem_subgroup_of, subgroup.mem_map,
    mul_equiv.coe_to_monoid_hom, monoid_hom.coe_mk, exists_prop],
  split,
  { rintro ⟨y, hy, hyx⟩,
    use y,
    { -- y ∈ N
      suffices : y = (f'.symm x),
      { rw this, apply set_like.coe_mem, },
      rw [← mul_equiv.apply_eq_iff_eq f, hyx, hff', subtype.coe_inj,
        mul_equiv.apply_symm_apply], },
    apply and.intro hy,
    apply subtype.coe_injective,
    rw ← hff' _,
    exact hyx, },
  { rintro ⟨y, hy, rfl⟩,
    use ↑y,
    apply and.intro hy,
    apply hff', },
end

lemma Iw_conj_sign (s : finset α) (g : equiv.perm α) (k : equiv.perm s) :
  equiv.perm.sign ((Iw_conj s g) k) = equiv.perm.sign k :=
begin
  let e : s ≃ (g • s : finset α) :=
  begin
    apply equiv.subtype_equiv g,
    { intro a,
      rw [← finset.smul_mem_smul_finset_iff g, equiv.perm.smul_def], },
  end,
  suffices : ∀ k, (Iw_conj s g) k = (equiv.perm_congr e) k,
  { rw this,
    dsimp only [equiv.perm_congr, equiv.equiv_congr],
    simp only [equiv.coe_fn_mk],
    rw equiv.perm.sign_symm_trans_trans k e, },
  { intro k, refl, },
end

lemma Iw_conj_symm_sign   (s : finset α) (g : equiv.perm α) (k : equiv.perm (g • s : finset α)) :
  equiv.perm.sign ((Iw_conj s g).symm k) = equiv.perm.sign k :=
begin
  let e : s ≃ (g • s : finset α) :=
  begin
    apply equiv.subtype_equiv g,
    { intro a,
      rw [← finset.smul_mem_smul_finset_iff g, equiv.perm.smul_def], },
  end,
  suffices : ∀ k, (Iw_conj s g).symm k = (equiv.perm_congr e.symm) k,
  { rw this,
    dsimp only [equiv.perm_congr, equiv.equiv_congr],
    simp only [equiv.coe_fn_mk],
    rw equiv.perm.sign_symm_trans_trans k e.symm, },
  { intro k, refl, },
end


lemma Iw_is_conj_alt (s : finset α) (g : alternating_group α) :
  (subgroup.map
    (equiv.perm.of_subtype : equiv.perm ((g • s) : finset α) →* (equiv.perm α))
    (alternating_group ((g • s) : finset α))).subgroup_of (alternating_group α) =
  (mul_aut.conj g) •
  (subgroup.map
    (equiv.perm.of_subtype : equiv.perm s →* equiv.perm α)
    (alternating_group s)).subgroup_of (alternating_group α) :=
begin
  rw ← mul_aut_smul_subgroup_of_eq (mul_aut.conj ↑g) (mul_aut.conj g),
  apply congr_arg,

  suffices : subgroup.map (equiv.perm.of_subtype :
    equiv.perm (g • s : finset α) →* equiv.perm α) (alternating_group (g • s : finset α))
    = subgroup.map ((equiv.perm.of_subtype).comp (Iw_conj s g).to_monoid_hom)
      (alternating_group (s : finset α)),
  { rw this,
    change _ = subgroup.map (mul_aut.conj ↑g).to_monoid_hom _,
    rw subgroup.map_map,
    apply congr_arg2,
    apply Iw_is_conj',
    refl, },

  { simp only [← subgroup.map_map],
      apply congr_arg,
      ext k,
      simp only [subgroup.mem_map, equiv.perm.mem_alternating_group,
        mul_equiv.coe_to_monoid_hom, exists_prop],
      split,
      { intro hk,
        use (Iw_conj s ↑ g).symm k,
        simp only [Iw_conj_symm_sign, mul_equiv.apply_symm_apply],
        exact ⟨equiv.perm.mem_alternating_group.mp hk, rfl⟩, },

      { rintro ⟨x, hx, hx'⟩,
        rw ← hx',
        apply  equiv.perm.mem_alternating_group.mpr,
        simp only [Iw_conj_sign],
        exact hx, }, },

  { -- ∀ n…
   intro n, refl, },
end


lemma is_three_cycle_is_of_subtype (g : alternating_group α) (hg : equiv.perm.is_three_cycle (g : equiv.perm α)) :
  ∃ (s : finset α), (s.card = 3) ∧ g ∈ (subgroup.map
    (equiv.perm.of_subtype : equiv.perm s →* equiv.perm α)
    (alternating_group s)).subgroup_of (alternating_group α) :=
begin
  use (g : equiv.perm α).support,
  split,
  exact equiv.perm.is_three_cycle.card_support hg,
  rw subgroup.mem_subgroup_of,
  simp only [subgroup.mem_map],

  let k : equiv.perm (g : equiv.perm α).support := equiv.perm.subtype_perm (g : equiv.perm α) (λ a, by simp only [equiv.perm.apply_mem_support]),
  use k,
  suffices : equiv.perm.of_subtype k = g,
  split,
  -- because `rw equiv.perm.mem_alternating_group` does not work
  rw @equiv.perm.mem_alternating_group (g : equiv.perm α).support _ _,
  rw [← equiv.perm.sign_of_subtype, this],
  exact equiv.perm.is_three_cycle.sign hg,
  exact this,
  { -- k.of_subtype = g
    apply equiv.perm.of_subtype_subtype_perm,
    { intro a, simp only [equiv.perm.mem_support, imp_self] }, },
end


lemma subgroup.map_closure_eq {G H : Type*} [group G] [group H] (f : H →* G) (s : set H) :
  subgroup.map f (subgroup.closure s) = subgroup.closure (set.image f s) :=
begin
  apply symm,
  apply subgroup.closure_eq_of_le,
  { intro g, rintro ⟨k, hk, rfl⟩,
    exact ⟨k, subgroup.subset_closure hk, rfl⟩, },
  { rw subgroup.map_le_iff_le_comap,
    rw subgroup.closure_le ,
    intros g hg,
    simp only [subgroup.coe_comap, set.mem_preimage, set_like.mem_coe],
    apply subgroup.subset_closure,
    apply set.mem_image_of_mem, exact hg, },
end


lemma subgroup.closure_subgroup_of_eq {G : Type*} [group G] (N : subgroup G) (s : set G) (hs : s ≤ ↑N) :
  subgroup.closure (N.subtype ⁻¹' s) = (subgroup.closure s).subgroup_of N :=
begin
  dsimp only [subgroup.subgroup_of],
  have hN : function.injective N.subtype,
    by simp only [subgroup.coe_subtype, subtype.coe_injective],
  apply subgroup.map_injective hN,
  rw subgroup.map_closure_eq,
  suffices : (N.subtype) '' ((N.subtype) ⁻¹' s) = s,
  rw this,
  rw subgroup.map_comap_eq,
  simp only [subgroup.subtype_range, right_eq_inf, subgroup.closure_le],
  exact hs,

  rw [set.image_preimage_eq_inter_range, subgroup.coe_subtype, subtype.range_coe_subtype,
    set.inter_eq_left_iff_subset],
  exact hs,
end


lemma closure_three_cycles_alternating_eq_top :
  subgroup.closure
  { g : alternating_group α | equiv.perm.is_three_cycle (g : equiv.perm α)} = ⊤ :=
begin
  suffices : function.injective (alternating_group α).subtype,
  apply subgroup.map_injective this,
  rw subgroup.map_closure_eq,
  suffices : (alternating_group α).subtype '' { g : alternating_group α | equiv.perm.is_three_cycle (g : equiv.perm α)}
    = {g : equiv.perm α | equiv.perm.is_three_cycle g },
  rw this,
  rw equiv.perm.closure_three_cycles_eq_alternating,
  rw [← subgroup.comap_top _, subgroup.map_comap_eq, subgroup.subtype_range, inf_top_eq],
  { ext g,
    simp only [subgroup.coe_subtype, set.mem_image, set.mem_set_of_eq],
    split,
    rintro ⟨k, hk, rfl⟩, exact hk,
    intro hg,
    use g,
    rw equiv.perm.mem_alternating_group,
    exact equiv.perm.is_three_cycle.sign hg,
    exact ⟨hg, rfl⟩, },
  simp only [subgroup.coe_subtype, subtype.coe_injective],
end


lemma is_three_cycles_exists_of_subtype (g : alternating_group α) (hg : equiv.perm.is_three_cycle (g : equiv.perm α)) :
  ∃ (s : finset α), (s.card = 3) ∧ g ∈ (subgroup.map
    (equiv.perm.of_subtype : equiv.perm s →* equiv.perm α)
    (alternating_group s)).subgroup_of (alternating_group α) :=
begin
  use (g : equiv.perm α).support,
  split,
  exact equiv.perm.is_three_cycle.card_support hg,
  rw subgroup.mem_subgroup_of,
  simp only [subgroup.mem_map],

  let k : equiv.perm (g : equiv.perm α).support := equiv.perm.subtype_perm (g : equiv.perm α) (λ a, by simp only [equiv.perm.apply_mem_support]),
  use k,
  suffices : equiv.perm.of_subtype k = g,
  split,
  -- because `rw equiv.perm.mem_alternating_group` does not work
  rw @equiv.perm.mem_alternating_group (g : equiv.perm α).support _ _,
  rw [← equiv.perm.sign_of_subtype, this],
  exact equiv.perm.is_three_cycle.sign hg,
  exact this,
  { -- k.of_subtype = g
    apply equiv.perm.of_subtype_subtype_perm,
    { intro a, simp only [equiv.perm.mem_support, imp_self] }, },
end


lemma Iw_is_generator_alt : supr (λ (s : { s : finset α // s.card = 3}),
     (subgroup.map equiv.perm.of_subtype
      (alternating_group (s : finset α))).subgroup_of (alternating_group α)) =  ⊤ :=
begin
  rw ← closure_three_cycles_alternating_eq_top,
  have lemma1 : {g : alternating_group α | (g : equiv.perm α).is_three_cycle} =
    (alternating_group α).subtype ⁻¹' {g : equiv.perm α | g.is_three_cycle },
    { ext g, simp only [subgroup.coe_subtype, set.preimage_set_of_eq], },
  have lemma2 : {g : equiv.perm α | g.is_three_cycle} ≤ alternating_group α,
  { intros k hk,
    -- simp only [set_like.mem_coe],
    apply equiv.perm.is_three_cycle.mem_alternating_group,
    exact hk, },

  apply le_antisymm,
  { -- supr ≤ closure
    rw lemma1,
    rw subgroup.closure_subgroup_of_eq (alternating_group α) _ lemma2,
    rw equiv.perm.closure_three_cycles_eq_alternating,
    rw supr_le_iff,
    rintro ⟨s, hs⟩,
    dsimp only [subgroup.subgroup_of],
    refine subgroup.comap_mono _,
    intro g,
    rintro ⟨k, hk, rfl⟩,
    simp only [set_like.mem_coe] at hk,
    rw equiv.perm.mem_alternating_group,
    rw equiv.perm.sign_of_subtype,
    exact equiv.perm.mem_alternating_group.mp hk, },
  { -- closure ≤ supr
    rw subgroup.closure_le,
    intros g hg,
    obtain ⟨s, hs3, hsg⟩ := is_three_cycles_exists_of_subtype g hg,
    simp only [set_like.mem_coe],
    apply subgroup.mem_supr_of_mem,
    swap, exact ⟨s, hs3⟩,
    exact hsg, },
end


def Iw3 : iwasawa_structure (alternating_group α) (nat.finset α 3) :=
{ T := λ (s : nat.finset α 3), (subgroup.map
    (equiv.perm.of_subtype : equiv.perm (s : finset α) →* equiv.perm α)
    (alternating_group (s : finset α))).subgroup_of (alternating_group α),
  is_comm := λ ⟨s, hs⟩,
  begin
    apply subgroup.subgroup_of_is_commutative _,
    haveI : (alternating_group (s : finset α)).is_commutative := { is_comm :=
    begin
      apply alternating_group.is_commutative_of_order_three,
      rw fintype.card_coe, exact hs,
    end },
    apply subgroup.map_is_commutative (alternating_group (s : finset α)),
  end,
  is_conj := λ g ⟨s, hs⟩, Iw_is_conj_alt s g,
  is_generator := Iw_is_generator_alt,
}

lemma finset.mem_doubleton_iff (a b x : α) : x ∈ ({a, b} : finset α) ↔ (x = a ∨ x = b) :=
begin
  rw [finset.mem_insert, finset.mem_singleton],
end


/-- If α has at least 5 elements, but not 6,
then the only nontrivial normal sugroup of (perm α) is the alternating_group. -/
theorem alternating_group.normal_subgroups {α : Type*} [decidable_eq α] [fintype α]
  (hα : 5 ≤ fintype.card α) (hα' : fintype.card α ≠ 6)
  {N : subgroup (alternating_group α)} (hnN : N.normal) (ntN : nontrivial N) : N = ⊤ :=
begin
  rw eq_top_iff,
  rw ← alternating_group_is_perfect hα,

  have hprim : is_preprimitive (alternating_group α) (nat.finset α 3),
  { apply nat.finset_is_preprimitive_of_alt,
    norm_num,
    apply lt_of_lt_of_le _ hα, norm_num,
    exact hα', },
  apply commutator_le_iwasawa hprim Iw3 hnN ,

  -- N acts nontrivially
  intro h,
  obtain ⟨g, hgN, hg_ne⟩ := N.nontrivial_iff_exists_ne_one.mp ntN,
  have hg_ne' : (to_perm g : equiv.perm α) ≠ 1,
  { intro hg_ne', apply hg_ne,
    ext, simp only [subgroup.coe_one, ← hg_ne'],
    refl, },

  obtain ⟨s, hs⟩ := @nat.finset.mul_action_faithful α _ _ _ _ 3 _ _ _ g hg_ne',
  apply hs,
  suffices : s ∈ fixed_points N (nat.finset α 3),
  rw mem_fixed_points at this, exact this ⟨g, hgN⟩,
  rw h, rw set.top_eq_univ, apply set.mem_univ,
  norm_num,
  apply lt_of_lt_of_le _ hα, norm_num,
end

/-
def Iw4 : iwasawa_structure (alternating_group α) (nat.finset α 4) :=
{ T := λ (s : nat.finset α 4), (subgroup.map
    (equiv.perm.of_subtype : equiv.perm (s : finset α) →* equiv.perm α)
    (alternating_group (s : finset α))).subgroup_of (alternating_group α),
  is_comm := λ ⟨s, hs⟩,
  begin
    apply subgroup.subgroup_of_is_commutative _,
    haveI : (alternating_group (s : finset α)).is_commutative := { is_comm :=
    begin
      apply alternating_group.is_commutative_of_order_three,
      rw fintype.card_coe, exact hs,
    end },
    apply subgroup.map_is_commutative (alternating_group (s : finset α)),
  end,
  is_conj := λ g ⟨s, hs⟩, Iw_is_conj_alt s g,
  is_generator := Iw_is_generator_alt,
}
-/


/-- If α has at least 5 elements, but not 8,
then the only nontrivial normal sugroup of (perm α) is the alternating_group. -/
theorem alternating_group.normal_subgroups' {α : Type*} [decidable_eq α] [fintype α]
  (hα : 5 ≤ fintype.card α) (hα' : fintype.card α ≠ 8)
  {N : subgroup (alternating_group α)} (hnN : N.normal) (ntN : nontrivial N) : N = ⊤ :=
begin
  rw eq_top_iff,
  rw ← alternating_group_is_perfect hα,

  have hprim : is_preprimitive (alternating_group α) (nat.finset α 4),
  { apply nat.finset_is_preprimitive_of_alt,
    norm_num,
    apply lt_of_lt_of_le _ hα, norm_num,
    exact hα', },
  apply commutator_le_iwasawa hprim Iw4 hnN ,

  -- N acts nontrivially
  intro h,
  obtain ⟨g, hgN, hg_ne⟩ := N.nontrivial_iff_exists_ne_one.mp ntN,
  have hg_ne' : (to_perm g : equiv.perm α) ≠ 1,
  { intro hg_ne', apply hg_ne,
    ext, simp only [subgroup.coe_one, ← hg_ne'],
    refl, },

  obtain ⟨s, hs⟩ := @nat.finset.mul_action_faithful α _ _ _ _ 3 _ _ _ g hg_ne',
  apply hs,
  suffices : s ∈ fixed_points N (nat.finset α 3),
  rw mem_fixed_points at this, exact this ⟨g, hgN⟩,
  rw h, rw set.top_eq_univ, apply set.mem_univ,
  norm_num,
  apply lt_of_lt_of_le _ hα, norm_num,
end



#exit

/-
def Iw_t (s : finset α) : (equiv.perm s) →* (equiv.perm α) := equiv.perm.of_subtype

def Iw_T (s : finset α) :=
  (subgroup.map (Iw_t s) (alternating_group s)).subgroup_of (alternating_group α)

example {G : Type*} [group G] (N : subgroup G) (hN : N.normal) :
  has_smul N (subgroup G) := {
smul := λ n K,  subgroup.map (mul_aut.conj ↑n).to_monoid_hom K
  }


example {G : Type*} [group G] (N : subgroup G) (hN : N.normal) :
  mul_action N (subgroup G) := {
    one_smul := sorry,
    mul_smul := sorry,
  }

/-
  f : G →* G
  N, K ≤ G
  j : N →* G


   f (j⁻¹ K) = j⁻¹ (f (K))
-/ -/


lemma map_comap_equiv {G : Type*} [group G] (N K : subgroup G) (f : G ≃* G) (f' : N ≃* N)
  (hff' : ∀ (y : N), f ↑y = f' y) :
  subgroup.map f'.to_monoid_hom (subgroup.comap N.subtype K) =
    subgroup.comap N.subtype (subgroup.map f.to_monoid_hom K)  :=
begin
  ext x,
  simp only [subgroup.mem_map, subgroup.mem_comap, subgroup.coe_subtype, exists_prop],
  split,
  { rintro ⟨y, hy, rfl⟩,
    use ↑y, apply and.intro hy,exact hff' y, },
  { rintro ⟨z, hz, hz'⟩,
    simp only [mul_equiv.coe_to_monoid_hom] at hz',
    use z,
--     use f'.symm x,
--    simp only [mul_equiv.coe_to_monoid_hom, mul_equiv.apply_symm_apply, eq_self_iff_true, and_true],
    { -- z ∈ N
      suffices : z = f'.symm x,
      rw this, apply set_like.coe_mem,
      apply mul_equiv.injective f,
      rw hz', rw hff', simp only [mul_equiv.apply_symm_apply],  },
    -- z ∈ K
    apply and.intro hz,
    -- f' z = x
    simp only [← subtype.coe_inj, ← hz', mul_equiv.coe_to_monoid_hom, ← hff'],
    refl, },
end


example {G : Type*} [group G] (N : subgroup G) (g : N) (K : subgroup G) :
  (mul_aut.conj g) • K.subgroup_of N = (mul_aut.conj (g : G) • K).subgroup_of N :=
begin
  change subgroup.map _ _ = (subgroup.map _ K).subgroup_of N,
  simp only [subgroup.subgroup_of],
  simp only [mul_distrib_mul_action.to_monoid_End_apply],
  apply map_comap_equiv,
  { intro y,refl, },
end


lemma IwT_is_conj (s : finset α) (g : alternating_group α) :
  Iw_T (g • s) = mul_aut.conj g • (Iw_T s) :=
begin
  unfold Iw_T,
  let ts := Iw_t s, let tgs := Iw_t (g • s),
  let Ts := Iw_T s, let Tgs := Iw_T (g • s),
  let kg : ↥s ≃ ↥(g • s) := equiv.subtype_equiv g (
    begin
      intro a,
      rw ← finset.smul_mem_smul_finset_iff g,
      refl,
    end),
  let pg : equiv.perm (↥s) → equiv.perm ↥(g • s) := λ k, (kg.symm.trans k).trans kg,
  let pg' : equiv.perm ↥(g • s) → equiv.perm ↥s := λ k, (kg.trans k).trans kg.symm,
  have hpgg' : ∀ k, k = pg (pg' k) ,
  { intro k,
    change k = (kg.symm.trans ((kg.trans k).trans kg.symm)).trans kg,
    simp only [← equiv.trans_assoc, equiv.symm_trans_self, equiv.refl_trans],
    rw [equiv.trans_assoc, equiv.symm_trans_self, equiv.trans_refl], },
/-   have hpg'g : ∀ k, k = pg' (pg k) ,
  { intro k,
    change k = (kg.trans ((kg.symm.trans k).trans kg)).trans kg.symm,
    simp only [← equiv.trans_assoc, equiv.self_trans_symm, equiv.refl_trans],
    rw [equiv.trans_assoc, equiv.self_trans_symm, equiv.trans_refl], }, -/


  simp only [subgroup.subgroup_of],
  change _ = subgroup.map _ _,
  simp only [mul_distrib_mul_action.to_monoid_End_apply],
  change _ = subgroup.map (mul_aut.conj g).to_monoid_hom _,
  rw map_comap_equiv _ _
    (mul_aut.conj (g: equiv.perm α)) (mul_aut.conj g),
  apply congr_arg,
  rw subgroup.map_map,


  have : (mul_aut.conj ↑g).to_monoid_hom.comp (Iw_t s) =
    λ k, (Iw_t (↑g • s)) (Iw_c s ↑g k),

  ext,
  let hzz :=  Iw_conj' s ↑g,
  simp only [Iw_t] at hzz,

  sorry,
  {intro y, refl,},


  have this1 :
    (mul_aut.conj g) • (Iw_t s).range = ((mul_aut.conj g).to_monoid_hom.comp (Iw_t s)).range,
    simp only [←  monoid_hom.map_range], refl,
  rw this1,

  suffices this2 : tgs.range = ((mul_aut.conj g).to_monoid_hom.comp ts).range,
  rw this2,

  let pg : equiv.perm (↥s) → equiv.perm ↥(g • s) := λ k, (kg.symm.trans k).trans kg,
  let pg' : equiv.perm ↥(g • s) → equiv.perm ↥s := λ k, (kg.trans k).trans kg.symm,
  have hpgg' : ∀ k, k = pg (pg' k) ,
  { intro k,
    change k = (kg.symm.trans ((kg.trans k).trans kg.symm)).trans kg,
    simp only [← equiv.trans_assoc, equiv.symm_trans_self, equiv.refl_trans],
    rw [equiv.trans_assoc, equiv.symm_trans_self, equiv.trans_refl], },
/-   have hpg'g : ∀ k, k = pg' (pg k) ,
  { intro k,
    change k = (kg.trans ((kg.symm.trans k).trans kg)).trans kg.symm,
    simp only [← equiv.trans_assoc, equiv.self_trans_symm, equiv.refl_trans],
    rw [equiv.trans_assoc, equiv.self_trans_symm, equiv.trans_refl], }, -/


  ext,
  split,
  rintro ⟨k,rfl⟩, use pg' k, conv_rhs {rw hpgg' k}, rw Iw_conj',
  rintro ⟨k, rfl⟩, use pg k, rw Iw_conj',


end

example (G : Type*) [group G] (H K : subgroup G) (hH : H.is_commutative) :
  (H.subgroup_of K).is_commutative :=
begin
  resetI,
  apply subgroup.subgroup_of_is_commutative H,
end
