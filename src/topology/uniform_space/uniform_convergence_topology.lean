/-
Copyright (c) 2022 Anatole Dedecker. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Anatole Dedecker
-/
import topology.uniform_space.uniform_convergence
import topology.uniform_space.pi

/-!
# Topology and uniform structure of uniform convergence

This files endows `α → β` with the topologies / uniform structures of
- uniform convergence on `α` (in the `uniform_convergence` namespace)
- uniform convergence on a specified family `𝔖` of sets of `α`
  (in the `uniform_convergence_on` namespace), also called `𝔖`-convergence

Usual examples of the second construction include :
- the topology of compact convergence, when `𝔖` is the set of compacts of `α`
- the strong topology on the dual of a TVS `E`, when `𝔖` is the set of Von Neuman bounded subsets
  of `E`
- the weak-* topology on the dual of a TVS `E`, when `𝔖` is the set of singletons of `E`.

## Main definitions

* `uniform_convergence.gen` : basis sets for the uniformity of uniform convergence
* `uniform_convergence.uniform_space` : uniform structure of uniform convergence
* `uniform_convergence_on.uniform_space` : uniform structure of 𝔖-convergence

## Main statements

* `uniform_convergence.uniform_continuous_eval` : evaluation is uniformly continuous
* `uniform_convergence.t2_space` : the topology of uniform convergence on `α → β` is T2 if
  `β` is T2.
* `uniform_convergence.tendsto_iff_tendsto_uniformly` : `uniform_convergence.uniform_space` is
  indeed the uniform structure of uniform convergence

* `uniform_convergence_on.uniform_continuous_eval_of_mem` : evaluation at a point contained in a
  set of `𝔖` is uniformly continuous
* `uniform_convergence.t2_space` : the topology of `𝔖`-convergence on `α → β` is T2 if
  `β` is T2 and `𝔖` covers `α`
* `uniform_convergence_on.tendsto_iff_tendsto_uniformly_on` :
  `uniform_convergence_on.uniform_space` is indeed the uniform structure of `𝔖`-convergence

## Implementation details

We do not declare these structures as instances, since they would conflict with `Pi.uniform_space`.

## TODO

* Show that the uniform structure of `𝔖`-convergence is exactly the structure of `𝔖'`-convergence,
  where `𝔖'` is the bornology generated by `𝔖`.
* Add a type synonym for `α → β` endowed with the structures of uniform convergence

## References

* [N. Bourbaki, *General Topology*][bourbaki1966]

## Tags

uniform convergence
-/


noncomputable theory
open_locale topological_space classical uniformity filter

local attribute [-instance] Pi.uniform_space

open set filter

namespace uniform_convergence

variables (α β : Type*) {γ ι : Type*}
variables {F : ι → α → β} {f : α → β} {s s' : set α} {x : α} {p : filter ι} {g : ι → α}

/-- Basis sets for the uniformity of uniform convergence -/
protected def gen (V : set (β × β)) : set ((α → β) × (α → β)) :=
  {uv : (α → β) × (α → β) | ∀ x, (uv.1 x, uv.2 x) ∈ V}

variables [uniform_space β]

protected lemma is_basis_gen :
  is_basis (λ V : set (β × β), V ∈ 𝓤 β) (uniform_convergence.gen α β) :=
⟨⟨univ, univ_mem⟩, λ U V hU hV, ⟨U ∩ V, inter_mem hU hV, λ uv huv,
  ⟨λ x, (huv x).left, λ x, (huv x).right⟩⟩⟩

/-- Filter basis for the uniformity of uniform convergence -/
protected def uniformity_basis : filter_basis ((α → β) × (α → β)) :=
(uniform_convergence.is_basis_gen α β).filter_basis

/-- Core of the uniform structure of uniform convergence -/
protected def uniform_core : uniform_space.core (α → β) :=
uniform_space.core.mk_of_basis (uniform_convergence.uniformity_basis α β)
  (λ U ⟨V, hV, hVU⟩ f, hVU ▸ λ x, refl_mem_uniformity hV)
  (λ U ⟨V, hV, hVU⟩, hVU ▸ ⟨uniform_convergence.gen α β (prod.swap ⁻¹' V),
    ⟨prod.swap ⁻¹' V, tendsto_swap_uniformity hV, rfl⟩, λ uv huv x, huv x⟩)
  (λ U ⟨V, hV, hVU⟩, hVU ▸ let ⟨W, hW, hWV⟩ := comp_mem_uniformity_sets hV in
    ⟨uniform_convergence.gen α β W, ⟨W, hW, rfl⟩, λ uv ⟨w, huw, hwv⟩ x, hWV
      ⟨w x, by exact ⟨huw x, hwv x⟩⟩⟩)

/-- Uniform structure of uniform convergence -/
protected def uniform_space : uniform_space (α → β) :=
uniform_space.of_core (uniform_convergence.uniform_core α β)

protected lemma has_basis_uniformity :
  (@uniformity (α → β) (uniform_convergence.uniform_space α β)).has_basis (λ V, V ∈ 𝓤 β)
  (uniform_convergence.gen α β) :=
(uniform_convergence.is_basis_gen α β).has_basis

/-- Topology of uniform convergence -/
protected def topological_space : topological_space (α → β) :=
(uniform_convergence.uniform_space α β).to_topological_space

protected lemma has_basis_nhds :
  (@nhds (α → β) (uniform_convergence.topological_space α β) f).has_basis (λ V, V ∈ 𝓤 β)
  (λ V, {g | (g, f) ∈ uniform_convergence.gen α β V}) :=
begin
  letI : uniform_space (α → β) := uniform_convergence.uniform_space α β,
  exact nhds_basis_uniformity (uniform_convergence.has_basis_uniformity α β)
end

variables {α}

lemma uniform_continuous_eval (x : α) : @uniform_continuous _ _
  (uniform_convergence.uniform_space α β) _ (function.eval x) :=
begin
  change _ ≤ _,
  rw [map_le_iff_le_comap,
      (uniform_convergence.has_basis_uniformity α β).le_basis_iff ((𝓤 _).basis_sets.comap _)],
  exact λ U hU, ⟨U, hU, λ uv huv, huv x⟩
end

variables {β}

lemma t2_space [t2_space β] : @t2_space _ (uniform_convergence.topological_space α β) :=
{ t2 :=
  begin
    letI : uniform_space (α → β) := uniform_convergence.uniform_space α β,
    letI : topological_space (α → β) := uniform_convergence.topological_space α β,
    intros f g h,
    obtain ⟨x, hx⟩ := not_forall.mp (mt funext h),
    exact separated_by_continuous (uniform_continuous_eval β x).continuous hx
  end }

protected lemma le_Pi : uniform_convergence.uniform_space α β ≤ Pi.uniform_space (λ _, β) :=
begin
  rw [le_iff_uniform_continuous_id, uniform_continuous_pi],
  intros x,
  exact uniform_continuous_eval β x
end

protected lemma tendsto_iff_tendsto_uniformly :
  tendsto F p (@nhds _ (uniform_convergence.topological_space α β) f) ↔
  tendsto_uniformly F f p :=
begin
  letI : uniform_space (α → β) := uniform_convergence.uniform_space α β,
  rw [(uniform_convergence.has_basis_nhds α β).tendsto_right_iff, tendsto_uniformly],
  split;
  { intros h U hU,
    filter_upwards [h (prod.swap ⁻¹' U) (tendsto_swap_uniformity hU)],
    exact λ n, id }
end

variable {α}

protected lemma uniform_continuous_comp_left [uniform_space γ] (f : β → γ)
  (hf : uniform_continuous f) : @uniform_continuous _ _
  (uniform_convergence.uniform_space α β) (uniform_convergence.uniform_space α γ) ((∘) f) :=
begin
  rw [uniform_continuous, (uniform_convergence.has_basis_uniformity α β).tendsto_iff
      (uniform_convergence.has_basis_uniformity α γ)],
  exact λ U hU, ⟨_, hf hU, λ uv, id⟩
end

protected lemma bar₁ [uniform_space γ] :
  @uniform_continuous (α → β × γ) ((α → β) × (α → γ))
    (@uniform_convergence.uniform_space _ _ prod.uniform_space)
    (@prod.uniform_space _ _
      (uniform_convergence.uniform_space _ _) (uniform_convergence.uniform_space _ _))
    (equiv.arrow_prod_equiv_prod_arrow β γ α) :=
begin
  sorry
end

protected lemma foo₁ {β : ι → Type*} [Π i, uniform_space (β i)] :
  @uniform_continuous (α → Π i, β i) (Π i, α → β i)
    (@uniform_convergence.uniform_space _ _ (Pi.uniform_space _))
    (@Pi.uniform_space _ (λ i, α → β i) (λ i, uniform_convergence.uniform_space α (β i)))
    function.swap :=
begin
  letI : uniform_space (Π i, β i) := Pi.uniform_space _,
  rw [uniform_continuous_pi],
  exact λ i, uniform_convergence.uniform_continuous_comp_left (function.eval i)
    (Pi.uniform_continuous_proj _ i),
end

protected lemma foo₂ {β : ι → Type*} [Π i, uniform_space (β i)] :
  @uniform_continuous (Π i, α → β i) (α → Π i, β i)
    (@Pi.uniform_space _ (λ i, α → β i) (λ i, uniform_convergence.uniform_space α (β i)))
    (@uniform_convergence.uniform_space _ _ (Pi.uniform_space _))
    function.swap :=
begin
  letI : uniform_space (Π i, β i) := Pi.uniform_space _,
  rw [uniform_continuous, (uniform_convergence.has_basis_uniformity _ _).tendsto_right_iff],
  intros U hU,
  rw [Pi.uniformity],
  sorry,
  --exact λ i, uniform_convergence.uniform_continuous_comp_left (function.eval i)
  --  (Pi.uniform_continuous_proj _ i),
end

end uniform_convergence

namespace uniform_convergence_on

variables (α β : Type*) {γ ι : Type*} [uniform_space β] (𝔖 : set (set α))
variables {F : ι → α → β} {f : α → β} {s s' : set α} {x : α} {p : filter ι} {g : ι → α}

/-- Uniform structure of uniform convergence on the sets of `𝔖`. -/
protected def uniform_space : uniform_space (α → β) :=
⨅ (s : set α) (hs : s ∈ 𝔖), uniform_space.comap (λ f, s.restrict f)
  (uniform_convergence.uniform_space s β)

/-- Topology of uniform convergence on the sets of `𝔖`. -/
protected def topological_space : topological_space (α → β) :=
(uniform_convergence_on.uniform_space α β 𝔖).to_topological_space

protected lemma topological_space_eq :
  uniform_convergence_on.topological_space α β 𝔖 = ⨅ (s : set α) (hs : s ∈ 𝔖),
  topological_space.induced (λ f, s.restrict f) (uniform_convergence.topological_space s β) :=
begin
  simp only [uniform_convergence_on.topological_space, to_topological_space_infi,
    to_topological_space_infi, to_topological_space_comap],
  refl
end

protected lemma uniform_continuous_restrict (h : s ∈ 𝔖) :
  @uniform_continuous _ _ (uniform_convergence_on.uniform_space α β 𝔖)
  (uniform_convergence.uniform_space s β) s.restrict :=
begin
  change _ ≤ _,
  rw [uniform_convergence_on.uniform_space, map_le_iff_le_comap, uniformity, infi_uniformity],
  refine infi_le_of_le s _,
  rw infi_uniformity,
  exact infi_le _ h,
end

protected lemma uniform_space_antitone : antitone (uniform_convergence_on.uniform_space α β) :=
λ 𝔖₁ 𝔖₂ h₁₂, infi_le_infi_of_subset h₁₂

variables {α}

lemma uniform_continuous_eval_of_mem {x : α} (hxs : x ∈ s) (hs : s ∈ 𝔖) :
  @uniform_continuous _ _ (uniform_convergence_on.uniform_space α β 𝔖) _ (function.eval x) :=
begin
  change _ ≤ _,
  rw [map_le_iff_le_comap, ((𝓤 _).basis_sets.comap _).ge_iff,
      uniform_convergence_on.uniform_space, infi_uniformity'],
  intros U hU,
  refine mem_infi_of_mem s _,
  rw infi_uniformity',
  exact mem_infi_of_mem hs (mem_comap.mpr
    ⟨ uniform_convergence.gen s β U,
      (uniform_convergence.has_basis_uniformity s β).mem_of_mem hU,
      λ uv huv, huv ⟨x, hxs⟩ ⟩)
end

variables {β}

lemma t2_space_of_covering [t2_space β] (h : ⋃₀ 𝔖 = univ) :
  @t2_space _ (uniform_convergence_on.topological_space α β 𝔖) :=
{ t2 :=
  begin
    letI : uniform_space (α → β) := uniform_convergence_on.uniform_space α β 𝔖,
    letI : topological_space (α → β) := uniform_convergence_on.topological_space α β 𝔖,
    intros f g hfg,
    obtain ⟨x, hx⟩ := not_forall.mp (mt funext hfg),
    obtain ⟨s, hs, hxs⟩ : ∃ s ∈ 𝔖, x ∈ s := mem_sUnion.mp (h.symm ▸ true.intro),
    exact separated_by_continuous (uniform_continuous_eval_of_mem β 𝔖 hxs hs).continuous hx
  end }

protected lemma le_Pi_of_covering (h : ⋃₀ 𝔖 = univ) :
  uniform_convergence_on.uniform_space α β 𝔖 ≤ Pi.uniform_space (λ _, β) :=
begin
  rw [le_iff_uniform_continuous_id, uniform_continuous_pi],
  intros x,
  obtain ⟨s, hs, hxs⟩ : ∃ s ∈ 𝔖, x ∈ s := mem_sUnion.mp (h.symm ▸ true.intro),
  exact uniform_continuous_eval_of_mem β 𝔖 hxs hs
end

protected lemma tendsto_iff_tendsto_uniformly_on :
  tendsto F p (@nhds _ (uniform_convergence_on.topological_space α β 𝔖) f) ↔
  ∀ s ∈ 𝔖, tendsto_uniformly_on F f p s :=
begin
  letI : uniform_space (α → β) := uniform_convergence_on.uniform_space α β 𝔖,
  rw [uniform_convergence_on.topological_space_eq, nhds_infi, tendsto_infi],
  refine forall_congr (λ s, _),
  rw [nhds_infi, tendsto_infi],
  refine forall_congr (λ hs, _),
  rw [nhds_induced, tendsto_comap_iff, tendsto_uniformly_on_iff_tendsto_uniformly_comp_coe,
      uniform_convergence.tendsto_iff_tendsto_uniformly],
  refl
end

end uniform_convergence_on
