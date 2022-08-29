/-
Copyright (c) 2022 . All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors:
-/

import group_theory.group_action.basic
import group_theory.group_action.fixing_subgroup
import data.finset.pointwise
import .set

/-!

# Various lemmas on stabilizers of sets

* `stabilizer_compl` : the stabilizer of the complement is the stabilizer of the set.

* `le_stabilizer_iff` : proves inclusion of a *subgroup* `H` in `stabilizer G s`
from inclusions `g • s ⊆ s`  for all `g ∈ H`.

# Instances

* `mul_action.of_stabilizer G s`: the action of `stabilizer G s` on `s`.


## TODO

Put in group_theory.group_action.basic ?

-/

namespace mul_action

open_locale pointwise

variables (G : Type*) [group G] {α : Type*} [mul_action G α]

/-- The stabilizer of the complement is the stabilizer of the set. -/
@[simp] lemma stabilizer_compl {s : set α} : stabilizer G sᶜ = stabilizer G s :=
begin
  have : ∀ (s : set α), stabilizer G s ≤ stabilizer G sᶜ,
  { intros s g h,
    rw [mem_stabilizer_iff, set.smul_compl_set, mem_stabilizer_iff.1 h] },
  refine le_antisymm _ (this _),
  convert this _,
  exact (compl_compl _).symm,
end

/-- The instance that makes the stabilizer of a set acting on that set -/
instance has_smul.stabilizer (s : set α) :
  has_smul ↥(stabilizer G s) ↥s := {
smul := λ ⟨g, hg⟩ ⟨x, hx⟩, ⟨g • x,
  begin
    rw ← mem_stabilizer_iff.mp hg,
    exact set.smul_mem_smul_set hx,
  end⟩, }

@[simp]
lemma has_smul.stabilizer_def  (s : set α)
  (g : stabilizer G s) (x : s) : coe (g • x)  = (g : G) • (x : α) :=
begin
  rw ← subtype.coe_eta g g.prop,
  rw ← subtype.coe_eta x x.prop,
  refl,
end

/-- The mul_action of stabilizer a set on that set -/
instance of_stabilizer (s : set α) :
  mul_action (stabilizer G s) s := {
one_smul := λ ⟨x, hx⟩,
by  rw [← subtype.coe_inj, has_smul.stabilizer_def, subgroup.coe_one, one_smul],
mul_smul := λ ⟨g, hg⟩ ⟨k, hk⟩ ⟨x, hx⟩,
begin
  rw [← subtype.coe_inj, submonoid.mk_mul_mk],
  simp only [has_smul.stabilizer_def, subtype.coe_mk, mul_action.mul_smul],
end }

lemma of_stabilizer_def (s : set α) (g : stabilizer G s) (x : s) :
  (g : G) • (x : α) = g • (x : α) := rfl

lemma of_stabilizer_set_def (s : set α) (g : stabilizer G s) (t : set α) :
  (g : G) • t = g • t :=
begin
refl,
end

/-- To prove inclusion of a *subgroup* in a stabilizer, it is enough to prove inclusions.-/
lemma le_stabilizer_iff (s : set α) (H : subgroup G) :
  H ≤ stabilizer G s ↔ ∀ g ∈ H, g • s ⊆ s :=
begin
  split,
  { intros hyp g hg,
    apply eq.subset,
    rw ← mem_stabilizer_iff,
    exact hyp hg, },
  intro hyp,
  intros g hg,
  rw mem_stabilizer_iff,
  apply subset_antisymm,
  exact hyp g hg,
  intros x hx, use g⁻¹ • x, split,
  apply hyp g⁻¹ (inv_mem hg),
  simp only [set.smul_mem_smul_set_iff, hx],
  simp only [smul_inv_smul],
end

/-- To prove membership to stabilizer of a *finite set*, it is enough to prove inclusion. -/
lemma mem_stabilizer_of_finite_iff (s : set α) [decidable_eq α] [fintype s] (g : G) :
  g ∈ stabilizer G s ↔ g • s ⊆ s :=
begin
  rw mem_stabilizer_iff,
  haveI : fintype (g • s : set α) := fintype.of_finite ↥(g • s),
  split,
  exact eq.subset,
  { -- intro h,
    rw ← set.to_finset_inj , rw ← set.to_finset_mono,
    intro h,
    apply finset.eq_of_subset_of_card_le h,
    apply le_of_eq,
    change _ = (set.image (λ x, g • x) s).to_finset.card,
    have : (set.image (λ x, g • x) s).to_finset = finset.image (λ x, g • x) s.to_finset,
    { rw ← finset.coe_inj, simp only [finset.coe_image, set.coe_to_finset], },
    rw this,
    rw finset.card_image_of_injective,
    exact mul_action.injective g,
  },
end

lemma fixing_subgroup_le_stabilizer (s : set α) :
  fixing_subgroup G s ≤ stabilizer G s :=
begin
  intros k hk,
  rw mem_fixing_subgroup_iff at hk,
  rw mem_stabilizer_iff,
  change (λ x, k • x) '' s = s,
  conv_rhs { rw ← set.image_id s},
  apply set.image_congr ,
  simp only [id.def],
  exact hk,
end

end mul_action
