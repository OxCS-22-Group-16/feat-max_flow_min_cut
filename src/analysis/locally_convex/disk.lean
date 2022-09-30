/-
Copyright (c) 2022 Moritz Doll. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Moritz Doll
-/
import analysis.locally_convex.balanced_core_hull
import analysis.locally_convex.with_seminorms
import analysis.convex.combination
import analysis.convex.gauge

/-!
# Absolutely convex sets

A set is called absolutely convex or disked if it is convex and balanced.

## Main definitions

* `maximal_seminorm_family`: the seminorm family induced by all open absolutely convex neighborhoods
of zero.

## Main statements

* `with_maximal_seminorm_family`: the topology of a locally convex space is induced by the family
`maximal_seminorm_family`.

## Todo

* Define the disked hull

## Tags

disks, convex, balanced
-/


open normed_field set
open_locale big_operators nnreal pointwise topological_space

variables {𝕜 E F G ι : Type*}

section nontrivially_normed_field

variables {s : set E}

variables [nontrivially_normed_field 𝕜] [add_comm_group E] [module 𝕜 E]
variables [module ℝ E] [smul_comm_class ℝ 𝕜 E]

lemma balanced_convex_hull_of_balanced (hs : balanced 𝕜 s) : balanced 𝕜 (convex_hull ℝ s) :=
begin
  rw balanced_iff_smul_mem,
  intros a ha x hx,
  rw convex_hull_eq at hx ⊢,
  simp only [exists_prop, exists_and_distrib_left, mem_set_of_eq] at hx ⊢,
  rcases hx with ⟨ι, t, f, f', h, hsum, hpos, hx⟩,
  use [ι, t, f, a • f'],
  refine ⟨λ i hi, hs.smul_mem ha (h _ hi), hsum, hpos, _⟩,
  rw ←hx,
  simp_rw [finset.center_mass, finset.smul_sum],
  refine finset.sum_congr rfl (λ y hy, _),
  simp_rw [pi.smul_apply, ←mul_smul, smul_comm],
end

variables (𝕜 E)

variables [topological_space E] [locally_convex_space ℝ E] [has_continuous_smul 𝕜 E]

lemma nhds_basis_abs_convex : (𝓝 (0 : E)).has_basis
  (λ (s : set E), s ∈ 𝓝 (0 : E) ∧ balanced 𝕜 s ∧ convex ℝ s) id :=
begin
  refine (locally_convex_space.convex_basis_zero ℝ E).to_has_basis (λ s hs, _)
    (λ s hs, ⟨s, ⟨hs.1, hs.2.2⟩, rfl.subset⟩),
  refine ⟨convex_hull ℝ (balanced_core 𝕜 s), _, convex_hull_min (balanced_core_subset s) hs.2⟩,
  refine ⟨filter.mem_of_superset (balanced_core_mem_nhds_zero hs.1) (subset_convex_hull ℝ _), _⟩,
  refine ⟨balanced_convex_hull_of_balanced (balanced_core_balanced s), _⟩,
  exact convex_convex_hull ℝ (balanced_core 𝕜 s),
end

variables [has_continuous_smul ℝ E] [topological_add_group E]

lemma nhds_basis_abs_convex_open : (𝓝 (0 : E)).has_basis
  (λ (s : set E), (0 : E) ∈ s ∧ is_open s ∧ balanced 𝕜 s ∧ convex ℝ s) id :=
begin
  refine (nhds_basis_abs_convex 𝕜 E).to_has_basis _ _,
  { rintros s ⟨hs_nhds, hs_balanced, hs_convex⟩,
    refine ⟨interior s, _, interior_subset⟩,
    exact ⟨mem_interior_iff_mem_nhds.mpr hs_nhds, is_open_interior,
      hs_balanced.interior (mem_interior_iff_mem_nhds.mpr hs_nhds), hs_convex.interior⟩ },
  rintros s ⟨hs_zero, hs_open, hs_balanced, hs_convex⟩,
  exact ⟨s, ⟨hs_open.mem_nhds hs_zero, hs_balanced, hs_convex⟩, rfl.subset⟩,
end

end nontrivially_normed_field

section absolutely_convex_sets

variables [topological_space E] [add_comm_monoid E] [has_zero E] [semi_normed_ring 𝕜]
variables [has_smul 𝕜 E] [has_smul ℝ E]

variables (𝕜 E)

/-- The type of absolutely convex open sets. -/
def abs_convex_open_sets :=
{ s : set E // (0 : E) ∈ s ∧ is_open s ∧ balanced 𝕜 s ∧ convex ℝ s }

instance abs_convex_open_sets.has_coe : has_coe (abs_convex_open_sets 𝕜 E) (set E) := ⟨subtype.val⟩

namespace abs_convex_open_sets

variables {𝕜 E}

lemma coe_zero_mem (s : abs_convex_open_sets 𝕜 E) : (0 : E) ∈ (s : set E) := s.2.1

lemma coe_is_open (s : abs_convex_open_sets 𝕜 E) : is_open (s : set E) := s.2.2.1

lemma coe_nhds (s : abs_convex_open_sets 𝕜 E) : (s : set E) ∈ 𝓝 (0 : E) :=
s.coe_is_open.mem_nhds s.coe_zero_mem

lemma coe_balanced (s : abs_convex_open_sets 𝕜 E) : balanced 𝕜 (s : set E) := s.2.2.2.1

lemma coe_convex (s : abs_convex_open_sets 𝕜 E) : convex ℝ (s : set E) := s.2.2.2.2

end abs_convex_open_sets

instance : nonempty (abs_convex_open_sets 𝕜 E) :=
begin
  rw ←exists_true_iff_nonempty,
  dunfold abs_convex_open_sets,
  rw subtype.exists,
  exact ⟨set.univ, ⟨mem_univ 0, is_open_univ, balanced_univ, convex_univ⟩, trivial⟩,
end

end absolutely_convex_sets

variables [is_R_or_C 𝕜]
variables [add_comm_group E] [topological_space E]
variables [module 𝕜 E] [module ℝ E] [is_scalar_tower ℝ 𝕜 E]
variables [has_continuous_smul ℝ E]

variables (𝕜 E)

/-- The family of seminorms defined by the gauges of absolute convex open sets. -/
noncomputable
def gauge_seminorm_family : seminorm_family 𝕜 E (abs_convex_open_sets 𝕜 E) :=
λ s, gauge_seminorm s.coe_balanced s.coe_convex (absorbent_nhds_zero s.coe_nhds)

variables {𝕜 E}

lemma gauge_seminorm_family_ball (s : abs_convex_open_sets 𝕜 E) :
  (gauge_seminorm_family 𝕜 E s).ball 0 1 = (s : set E) :=
begin
  dunfold gauge_seminorm_family,
  rw seminorm.ball_zero_eq,
  simp_rw gauge_seminorm_to_fun,
  exact gauge_lt_one_eq_self_of_open s.coe_convex s.coe_zero_mem s.coe_is_open,
end

section

variables [topological_add_group E] [has_continuous_smul 𝕜 E]
variables [smul_comm_class ℝ 𝕜 E] [locally_convex_space ℝ E]

/-- The topology of a locally convex space is induced by the maximal seminorm family. -/
lemma with_gauge_seminorm_family : with_seminorms (gauge_seminorm_family 𝕜 E) :=
begin
  refine seminorm_family.with_seminorms_of_has_basis _ _,
  refine filter.has_basis.to_has_basis (nhds_basis_abs_convex_open 𝕜 E) (λ s hs, _) (λ s hs, _),
  { refine ⟨s, ⟨_, rfl.subset⟩⟩,
    rw seminorm_family.basis_sets_iff,
    refine ⟨{⟨s, hs⟩}, 1, one_pos, _⟩,
    simp only [finset.sup_singleton],
    rw gauge_seminorm_family_ball,
    simp only [subtype.coe_mk] },
  refine ⟨s, ⟨_, rfl.subset⟩⟩,
  rw seminorm_family.basis_sets_iff at hs,
  rcases hs with ⟨t, r, hr, hs⟩,
  rw seminorm.ball_finset_sup_eq_Inter _ _ _ hr at hs,
  rw hs,
  -- We have to show that the intersection contains zero, is open, balanced, and convex
  refine ⟨mem_Inter₂.mpr (λ _ _, by simp [seminorm.mem_ball_zero, hr]),
    is_open_bInter (to_finite _) (λ _ _, _),
    balanced_Inter₂ (λ _ _, seminorm.balanced_ball_zero _ _),
    convex_Inter₂ (λ _ _, seminorm.convex_ball _ _ _)⟩,
  -- The only nontrivial part is to show that the ball is open
  have hr' : r = ∥(r : 𝕜)∥ * 1 := by simp [abs_of_pos hr],
  have hr'' : (r : 𝕜) ≠ 0 := by simp [ne_of_gt hr],
  rw hr',
  rw ←seminorm.smul_ball_zero (norm_pos_iff.mpr hr''),
  refine is_open.smul₀ _ hr'',
  rw gauge_seminorm_family_ball,
  exact abs_convex_open_sets.coe_is_open _,
end

end

def seminorm.restrict_real (p : seminorm 𝕜 E) : seminorm ℝ E :=
{ to_fun := p,
  smul' := λ a x,
  begin
    convert p.smul' (a : 𝕜) x,
    { exact is_R_or_C.real_smul_eq_coe_smul a x },
    { simp }
  end,
  ..p }

@[simp] lemma seminorm.restrict_real_ball (p : seminorm 𝕜 E) :
  p.restrict_real.ball = p.ball :=
rfl

lemma seminorm.continuous_at_zero {p : seminorm 𝕜 E} (hp : is_open $ p.ball 0 1) :
  continuous_at p 0 :=
begin
  change continuous_at p.restrict_real 0,
  rw ← p.restrict_real_ball at hp,
  refine metric.nhds_basis_ball.tendsto_right_iff.mpr _,
  intros ε hε,
  rw p.restrict_real.map_zero,
  suffices : p.restrict_real.ball 0 ε ∈ (𝓝 0 : filter E),
  { rwa seminorm.ball_zero_eq_preimage_ball at this },
  have := hp.smul₀ hε.ne.symm,
  rw [seminorm.smul_ball_zero (norm_pos_iff.mpr hε.ne.symm),
      real.norm_of_nonneg hε.le, mul_one] at this,
  exact this.mem_nhds (show (0 : E) ∈ p.ball 0 ε, by simp [hε]),
end

lemma seminorm.norm_sub_le (p : seminorm 𝕜 E) {x y : E} : ∥p x - p y∥ ≤ p (x - y) :=
begin
  rw [real.norm_eq_abs, abs_sub_le_iff, sub_le_iff_le_add', sub_le_iff_le_add'],
  exact ⟨p.le_insert' _ _, p.le_insert _ _⟩
end

lemma seminorm.uniform_continuous {E' : Type*} [add_comm_group E']
  [module 𝕜 E'] [module ℝ E'] [is_scalar_tower ℝ 𝕜 E'] {p : seminorm 𝕜 E'} [uniform_space E']
  [uniform_add_group E'] [has_continuous_smul ℝ E'] (hp : is_open $ p.ball 0 1) :
  uniform_continuous p :=
begin
  have hp : filter.tendsto p (𝓝 0) (𝓝 0) := p.map_zero ▸ (seminorm.continuous_at_zero hp).tendsto,
  rw [uniform_continuous, uniformity_eq_comap_nhds_zero_swapped,
      metric.uniformity_eq_comap_nhds_zero, filter.tendsto_comap_iff],
  exact tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds
    (hp.comp filter.tendsto_comap) (λ xy, dist_nonneg) (λ xy, p.norm_sub_le)
end

variables (𝕜 E)

def cont_seminorms : Type* := subtype (continuous ∘ coe_fn : seminorm 𝕜 E → Prop)

instance cont_seminorms.has_coe : has_coe (cont_seminorms 𝕜 E) (seminorm 𝕜 E) := ⟨subtype.val⟩

instance : nonempty (cont_seminorms 𝕜 E) := ⟨⟨0, by exact continuous_zero⟩⟩

def maximal_seminorm_family : seminorm_family 𝕜 E (cont_seminorms 𝕜 E) := coe

variables {𝕜 E}

lemma with_maximal_seminorm_family [topological_add_group E] [has_continuous_smul 𝕜 E]
  [smul_comm_class ℝ 𝕜 E] [locally_convex_space ℝ E] :
  with_seminorms (maximal_seminorm_family 𝕜 E) :=
begin
  letI := topological_add_group.to_uniform_space E,
  haveI : uniform_add_group E := topological_add_group_is_uniform,
  rw seminorm_family.with_seminorms_iff_nhds_eq_infi,
  refine le_antisymm (le_infi $ λ i, filter.map_le_iff_le_comap.mp $ i.1.map_zero ▸ i.2.tendsto 0)
    ((nhds_basis_abs_convex_open 𝕜 E).ge_iff.mpr $ λ t ht,
    filter.mem_infi_of_mem
      ⟨gauge_seminorm ht.2.2.1 ht.2.2.2 (absorbent_nhds_zero $ ht.2.1.mem_nhds ht.1), _⟩ $
    filter.mem_comap.mpr ⟨metric.ball 0 1, metric.ball_mem_nhds _ zero_lt_one, _⟩),
  { refine (seminorm.uniform_continuous _).continuous,
    rw gauge_seminorm_family_ball },
  change gauge_seminorm _ _ _ ⁻¹' metric.ball 0 1 ⊆ t,
  rw [← seminorm.ball_zero_eq_preimage_ball, seminorm.ball_zero_eq],
  simp_rw gauge_seminorm_to_fun,
  exact subset_of_eq (gauge_lt_one_eq_self_of_open ht.2.2.2 ht.1 ht.2.1)
end
