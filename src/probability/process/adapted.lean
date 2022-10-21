/-
Copyright (c) 2021 Kexing Ying. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kexing Ying, Rémy Degenne
-/
import probability.process.filtration

/-!
# Adapted and progressively measurable processes

This file defines some standard definition from the theory of stochastic processes including
filtrations and stopping times. These definitions are used to model the amount of information
at a specific time and are the first step in formalizing stochastic processes.

## Main definitions

* `measure_theory.adapted`: a sequence of functions `u` is said to be adapted to a
  filtration `f` if at each point in time `i`, `u i` is `f i`-strongly measurable
* `measure_theory.prog_measurable`: a sequence of functions `u` is said to be progressively
  measurable with respect to a filtration `f` if at each point in time `i`, `u` restricted to
  `set.Iic i × Ω` is strongly measurable with respect to the product `measurable_space` structure
  where the σ-algebra used for `Ω` is `f i`.

## Main results

* `adapted.prog_measurable_of_continuous`: a continuous adapted process is progressively measurable.

## Tags

adapted, progressively measurable

-/

open filter order topological_space
open_locale classical measure_theory nnreal ennreal topological_space big_operators

namespace measure_theory

variables {Ω β ι : Type*} {m : measurable_space Ω} [topological_space β] [preorder ι]
  {u v : ι → Ω → β} {f : filtration ι m}

/-- A sequence of functions `u` is adapted to a filtration `f` if for all `i`,
`u i` is `f i`-measurable. -/
def adapted (f : filtration ι m) (u : ι → Ω → β) : Prop :=
∀ i : ι, strongly_measurable[f i] (u i)

namespace adapted

@[protected, to_additive] lemma mul [has_mul β] [has_continuous_mul β]
  (hu : adapted f u) (hv : adapted f v) :
  adapted f (u * v) :=
λ i, (hu i).mul (hv i)

@[protected, to_additive] lemma div [has_div β] [has_continuous_div β]
  (hu : adapted f u) (hv : adapted f v) :
  adapted f (u / v) :=
λ i, (hu i).div (hv i)

@[protected, to_additive] lemma inv [group β] [topological_group β] (hu : adapted f u) :
  adapted f u⁻¹ :=
λ i, (hu i).inv

@[protected] lemma smul [has_smul ℝ β] [has_continuous_smul ℝ β] (c : ℝ) (hu : adapted f u) :
  adapted f (c • u) :=
λ i, (hu i).const_smul c

@[protected] lemma strongly_measurable {i : ι} (hf : adapted f u) :
  strongly_measurable[m] (u i) :=
(hf i).mono (f.le i)

lemma strongly_measurable_le {i j : ι} (hf : adapted f u) (hij : i ≤ j) :
  strongly_measurable[f j] (u i) :=
(hf i).mono (f.mono hij)

end adapted

lemma adapted_const (f : filtration ι m) (x : β) : adapted f (λ _ _, x) :=
λ i, strongly_measurable_const

variable (β)
lemma adapted_zero [has_zero β] (f : filtration ι m) : adapted f (0 : ι → Ω → β) :=
λ i, @strongly_measurable_zero Ω β (f i) _ _
variable {β}

lemma filtration.adapted_natural [metrizable_space β] [mβ : measurable_space β] [borel_space β]
  {u : ι → Ω → β} (hum : ∀ i, strongly_measurable[m] (u i)) :
  adapted (filtration.natural u hum) u :=
begin
  assume i,
  refine strongly_measurable.mono _ (le_supr₂_of_le i (le_refl i) le_rfl),
  rw strongly_measurable_iff_measurable_separable,
  exact ⟨measurable_iff_comap_le.2 le_rfl, (hum i).is_separable_range⟩
end

/-- Progressively measurable process. A sequence of functions `u` is said to be progressively
measurable with respect to a filtration `f` if at each point in time `i`, `u` restricted to
`set.Iic i × Ω` is measurable with respect to the product `measurable_space` structure where the
σ-algebra used for `Ω` is `f i`.
The usual definition uses the interval `[0,i]`, which we replace by `set.Iic i`. We recover the
usual definition for index types `ℝ≥0` or `ℕ`. -/
def prog_measurable [measurable_space ι] (f : filtration ι m) (u : ι → Ω → β) : Prop :=
∀ i, strongly_measurable[subtype.measurable_space.prod (f i)] (λ p : set.Iic i × Ω, u p.1 p.2)

lemma prog_measurable_const [measurable_space ι] (f : filtration ι m) (b : β) :
  prog_measurable f ((λ _ _, b) : ι → Ω → β) :=
λ i, @strongly_measurable_const _ _ (subtype.measurable_space.prod (f i)) _ _

namespace prog_measurable

variables [measurable_space ι]

protected lemma adapted (h : prog_measurable f u) : adapted f u :=
begin
  intro i,
  have : u i = (λ p : set.Iic i × Ω, u p.1 p.2) ∘ (λ x, (⟨i, set.mem_Iic.mpr le_rfl⟩, x)) := rfl,
  rw this,
  exact (h i).comp_measurable measurable_prod_mk_left,
end

protected lemma comp {t : ι → Ω → ι} [topological_space ι] [borel_space ι] [metrizable_space ι]
  (h : prog_measurable f u) (ht : prog_measurable f t)
  (ht_le : ∀ i ω, t i ω ≤ i) :
  prog_measurable f (λ i ω, u (t i ω) ω) :=
begin
  intro i,
  have : (λ p : ↥(set.Iic i) × Ω, u (t (p.fst : ι) p.snd) p.snd)
    = (λ p : ↥(set.Iic i) × Ω, u (p.fst : ι) p.snd) ∘ (λ p : ↥(set.Iic i) × Ω,
      (⟨t (p.fst : ι) p.snd, set.mem_Iic.mpr ((ht_le _ _).trans p.fst.prop)⟩, p.snd)) := rfl,
  rw this,
  exact (h i).comp_measurable ((ht i).measurable.subtype_mk.prod_mk measurable_snd),
end

section arithmetic

@[to_additive] protected lemma mul [has_mul β] [has_continuous_mul β]
  (hu : prog_measurable f u) (hv : prog_measurable f v) :
  prog_measurable f (λ i ω, u i ω * v i ω) :=
λ i, (hu i).mul (hv i)

@[to_additive] protected lemma finset_prod' {γ} [comm_monoid β] [has_continuous_mul β]
  {U : γ → ι → Ω → β} {s : finset γ} (h : ∀ c ∈ s, prog_measurable f (U c)) :
  prog_measurable f (∏ c in s, U c) :=
finset.prod_induction U (prog_measurable f) (λ _ _, prog_measurable.mul)
  (prog_measurable_const _ 1) h

@[to_additive] protected lemma finset_prod {γ} [comm_monoid β] [has_continuous_mul β]
  {U : γ → ι → Ω → β} {s : finset γ} (h : ∀ c ∈ s, prog_measurable f (U c)) :
  prog_measurable f (λ i a, ∏ c in s, U c i a) :=
by { convert prog_measurable.finset_prod' h, ext i a, simp only [finset.prod_apply], }

@[to_additive] protected lemma inv [group β] [topological_group β] (hu : prog_measurable f u) :
  prog_measurable f (λ i ω, (u i ω)⁻¹) :=
λ i, (hu i).inv

@[to_additive] protected lemma div [group β] [topological_group β]
  (hu : prog_measurable f u) (hv : prog_measurable f v) :
  prog_measurable f (λ i ω, u i ω / v i ω) :=
λ i, (hu i).div (hv i)

end arithmetic

end prog_measurable

lemma prog_measurable_of_tendsto' {γ} [measurable_space ι] [pseudo_metrizable_space β]
  (fltr : filter γ) [fltr.ne_bot] [fltr.is_countably_generated] {U : γ → ι → Ω → β}
  (h : ∀ l, prog_measurable f (U l)) (h_tendsto : tendsto U fltr (𝓝 u)) :
  prog_measurable f u :=
begin
  assume i,
  apply @strongly_measurable_of_tendsto (set.Iic i × Ω) β γ (measurable_space.prod _ (f i))
   _ _ fltr _ _ _ _ (λ l, h l i),
  rw tendsto_pi_nhds at h_tendsto ⊢,
  intro x,
  specialize h_tendsto x.fst,
  rw tendsto_nhds at h_tendsto ⊢,
  exact λ s hs h_mem, h_tendsto {g | g x.snd ∈ s} (hs.preimage (continuous_apply x.snd)) h_mem,
end

lemma prog_measurable_of_tendsto [measurable_space ι] [pseudo_metrizable_space β]
  {U : ℕ → ι → Ω → β}
  (h : ∀ l, prog_measurable f (U l)) (h_tendsto : tendsto U at_top (𝓝 u)) :
  prog_measurable f u :=
prog_measurable_of_tendsto' at_top h h_tendsto

/-- A continuous and adapted process is progressively measurable. -/
theorem adapted.prog_measurable_of_continuous
  [topological_space ι] [metrizable_space ι] [second_countable_topology ι]
  [measurable_space ι] [opens_measurable_space ι]
  [pseudo_metrizable_space β]
  (h : adapted f u) (hu_cont : ∀ ω, continuous (λ i, u i ω)) :
  prog_measurable f u :=
λ i, @strongly_measurable_uncurry_of_continuous_of_strongly_measurable _ _ (set.Iic i) _ _ _ _ _ _ _
  (f i) _ (λ ω, (hu_cont ω).comp continuous_induced_dom) (λ j, (h j).mono (f.mono j.prop))

/-- TODO -/
noncomputable
def discrete_topology.metric_space (α) [topological_space α] [discrete_topology α] :
  metric_space α :=
{ dist := λ x y, if y = x then 0 else 1,
  dist_self := λ x, by simp_rw [dist, if_pos rfl],
  dist_comm := λ x y, by simp_rw [dist, @eq_comm _ x],
  dist_triangle := λ x y z,
    begin
      simp_rw [dist],
      by_cases hzx : z = x,
      { rw if_pos hzx,
        refine add_nonneg _ _; { split_ifs; simp, }, },
      { rw if_neg hzx,
        by_cases hzy : z = y,
        { rw [if_pos hzy, add_zero, if_neg],
          refine λ hyx, hzx (hzy.trans hyx), },
        { simp only [hzy, if_false, le_add_iff_nonneg_left],
          split_ifs; simp, }, },
    end,
  eq_of_dist_eq_zero := λ x y hxy,
    begin
      simp only [ite_eq_left_iff, one_ne_zero] at hxy,
      by_contra,
      exact hxy (ne.symm h),
    end }

lemma discrete_topology.dist_def {α} [topological_space α] [discrete_topology α] (x y : α) :
  (discrete_topology.metric_space α).dist x y = if y = x then 0 else 1 := rfl

instance discrete_topology.metrizable_space (α) [topological_space α] [discrete_topology α] :
  metrizable_space α :=
begin
  letI m : metric_space α := discrete_topology.metric_space α,
  refine ⟨⟨m, _⟩⟩,
  rw discrete_topology.eq_bot α,
  change (uniform_space_of_dist dist dist_self dist_comm dist_triangle).to_topological_space = ⊥,
  rw ← to_topological_space_bot,
  congr,
  rw [uniform_space_of_dist, uniform_space.core_of_dist],
  suffices : (⨅ ε > 0, principal {p : α × α | dist p.fst p.snd < ε}) = principal id_rel,
  { ext1, exact this, },
  have h_set_eq_ite : ∀ ε (hε_pos : ε > 0),
    {p : α × α | dist p.fst p.snd < ε} = ite (ε ≤ 1) id_rel set.univ,
  { intros ε hε_pos,
    cases le_or_lt ε 1 with hε_one hε_one,
    { ext1 p,
      simp only [if_pos hε_one, set.mem_set_of_eq],
      refine ⟨λ h, _, λ h, _⟩,
      { suffices : dist p.fst p.snd = 0, by rwa dist_eq_zero at this,
        rw discrete_topology.dist_def at h ⊢,
        split_ifs with h_ne,
        { refl, },
        { rw if_neg h_ne at h,
          exact absurd hε_one (not_le.mpr h), }, },
      { rw [id_rel, set.mem_set_of_eq] at h,
        rw [h, dist_self], exact hε_pos, }, },
    { ext1 p,
      simp only [set.mem_set_of_eq, not_le.mpr hε_one, if_false, set.mem_univ, iff_true],
      refine lt_of_le_of_lt _ hε_one,
      rw discrete_topology.dist_def,
      split_ifs,
      exacts [zero_le_one, le_rfl],}, },
  have : (⨅ ε > 0, principal {p : α × α | dist p.fst p.snd < ε})
    = (⨅ ε > (0 : ℝ), ite (ε ≤ 1) (principal id_rel) ⊤),
  { congr,
    ext1 ε,
    congr,
    ext1 hε,
    simp_rw h_set_eq_ite ε hε,
    split_ifs,
    { refl, },
    { exact principal_univ, }, },
  rw this,
  refine le_antisymm _ _,
  { refine (infi_le _ 1).trans _,
    simp only [gt_iff_lt, zero_lt_one, le_refl, if_true, cinfi_pos], },
  { refine le_infi (λ ε, _),
    by_cases hε : 0 < ε,
    { simp only [hε, gt_iff_lt, cinfi_pos],
      split_ifs,
      { exact le_rfl, },
      { exact le_top, }, },
    { simp only [hε, gt_iff_lt, infi_false, le_top], }, },
end

lemma adapted.prog_measurable_of_discrete {ι} [preorder ι]
  [topological_space ι] [discrete_topology ι] [second_countable_topology ι]
  [measurable_space ι] [opens_measurable_space ι]
  {f : filtration ι m} {u : ι → Ω → β} [pseudo_metrizable_space β]
  (h : adapted f u) :
  prog_measurable f u :=
h.prog_measurable_of_continuous (λ _, continuous_of_discrete_topology)

/-- TODO -/
lemma adapted.prog_measurable' {ι} [linear_order ι] [locally_finite_order ι] [order_bot ι]
  [no_max_order ι] [measurable_space ι] [measurable_singleton_class ι] [decidable_eq ι]
  [succ_order ι]  -- todo remove
  [add_comm_monoid β] [has_continuous_add β]
  {f : filtration ι m} {u : ι → Ω → β} (h : adapted f u) :
  prog_measurable f u :=
begin
  intro i,
  have : (λ p : ↥(set.Iic i) × Ω, u ↑(p.fst) p.snd)
    = λ p : ↥(set.Iic i) × Ω, ∑ j in finset.Iio (order.succ i), if ↑p.fst = j then u j p.snd else 0,
  { ext1 p,
    rw finset.sum_ite_eq,
    have hp_mem : (p.fst : ι) ∈ finset.Iio (order.succ i),
    { have h' : ↑p.fst ≤ i := p.fst.prop,
      exact finset.mem_Iio.mpr (h'.trans_lt (order.lt_succ i)), },
    simp only [hp_mem, if_true], },
  rw this,
  refine finset.strongly_measurable_sum _ (λ j hj, strongly_measurable.ite _ _ _),
  { suffices h_meas : measurable[measurable_space.prod _ (f i)]
        (λ a : ↥(set.Iic i) × Ω, (a.fst : ι)),
      from h_meas (measurable_set_singleton j),
    exact measurable_fst.subtype_coe, },
  { have h_le : j ≤ i := order.lt_succ_iff.mp (finset.mem_Iio.mp hj),
    exact (strongly_measurable.mono (h j) (f.mono h_le)).comp_measurable measurable_snd, },
  { exact strongly_measurable_const, },
end

/-- For filtrations indexed by `ℕ`, `adapted` and `prog_measurable` are equivalent. This lemma
provides `adapted f u → prog_measurable f u`. See `prog_measurable.adapted` for the reverse
direction, which is true more generally. -/
lemma adapted.prog_measurable_of_nat {f : filtration ℕ m} {u : ℕ → Ω → β}
  [pseudo_metrizable_space β]
  (h : adapted f u) : prog_measurable f u :=
h.prog_measurable_of_discrete

-- this dot notation will make more sense once we have a more general definition for predictable
lemma predictable.adapted {f : filtration ℕ m} {u : ℕ → Ω → β}
  (hu : adapted f (λ n, u (n + 1))) (hu0 : strongly_measurable[f 0] (u 0)) :
  adapted f u :=
λ n, match n with
  | 0 := hu0
  | n + 1 := (hu n).mono (f.mono n.le_succ)
end

end measure_theory
