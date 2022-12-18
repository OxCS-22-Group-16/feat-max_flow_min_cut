/-
Copyright (c) 2022 Anatole Dedecker. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Anatole Dedecker
-/
import topology.uniform_space.equicontinuity

/-!
# Ascoli Theorem

## Main definitions
## Main statements
## Notation
## Implementation details
## References
## Tags
-/

open set filter uniform_space function
open_locale filter topological_space uniform_convergence uniformity

lemma supr_sUnion {α β : Type*} [complete_lattice β] {S : set (set α)} {p : α → β} :
  (⨆ x ∈ ⋃₀ S, p x) = ⨆ (s ∈ S) (x ∈ s), p x :=
by rw [sUnion_eq_Union, supr_Union, ← supr_subtype'']

lemma infi_sUnion {α β : Type*} [complete_lattice β] {S : set (set α)} {p : α → β} :
  (⨅ x ∈ ⋃₀ S, p x) = ⨅ (s ∈ S) (x ∈ s), p x :=
@supr_sUnion α βᵒᵈ _ _ _

lemma forall_sUnion {α : Type*} {S : set (set α)} {p : α → Prop} :
  (∀ x ∈ ⋃₀ S, p x) ↔ ∀ (s ∈ S) (x ∈ s), p x :=
by simp_rw [← infi_Prop_eq, infi_sUnion]

lemma totally_bounded_pi {ι : Type*} {α : ι → Type*} [Π i, uniform_space (α i)]
  {t : set ι} {s : Π i, set (α i)} (hs : ∀ i ∈ t, totally_bounded (s i)) :
  totally_bounded (t.pi s) :=
sorry

lemma cauchy_of_ne_bot {α : Type*} [uniform_space α] {l : filter α} [hl : l.ne_bot] :
  cauchy l ↔ l ×ᶠ l ≤ 𝓤 α :=
by simp only [cauchy, hl, true_and]

lemma cauchy_pi {ι : Type*} {α : ι → Type*} [Π i, uniform_space (α i)]
  {l : filter (Π i, α i)} [l.ne_bot] : cauchy l ↔ ∀ i, cauchy (map (eval i) l) :=
by simp_rw [cauchy_of_ne_bot, prod_map_map_eq, map_le_iff_le_comap, Pi.uniformity, le_infi_iff]

lemma cauchy_infi {ι : Sort*} {α : Type*} {u : ι → uniform_space α}
  {l : filter α} [l.ne_bot] : @@cauchy (⨅ i, u i) l ↔ ∀ i, @@cauchy (u i) l :=
by simp_rw [cauchy_of_ne_bot, infi_uniformity', le_infi_iff]

lemma cauchy_map_iff_comap {α β : Type*} {u : uniform_space β} {f : α → β} {l : filter α} :
  cauchy (map f l) ↔ @@cauchy (comap f u) l :=
begin
  simp only [cauchy, map_ne_bot_iff, prod_map_map_eq, map_le_iff_le_comap, uniformity_comap rfl],
  refl
end

variables {ι X α β : Type*} [topological_space X] [uniform_space α] [uniform_space β]
  {F : ι → X → α} {G : ι → β → α}

lemma theorem1 [compact_space X] (hF : equicontinuous F) :
  (uniform_fun.uniform_space X α).comap F =
  (Pi.uniform_space (λ _, α)).comap F :=
begin
  refine le_antisymm (uniform_space.comap_mono $ le_iff_uniform_continuous_id.mpr $
    uniform_fun.uniform_continuous_to_fun) _,
  change comap _ (𝓤 _) ≤ comap _ (𝓤 _),
  simp_rw [Pi.uniformity, filter.comap_infi, filter.comap_comap, function.comp],
  refine ((uniform_fun.has_basis_uniformity X α).comap (prod.map F F)).ge_iff.mpr _,
  intros U hU,
  rcases comp_comp_symm_mem_uniformity_sets hU with ⟨V, hV, Vsymm, hVU⟩,
  let Ω : X → set X := λ x, {y | ∀ i, (F i x, F i y) ∈ V},
  rcases compact_space.elim_nhds_subcover Ω (λ x, hF x V hV) with ⟨S, Scover⟩,
  have : (⋂ s ∈ S, {ij : ι × ι | (F ij.1 s, F ij.2 s) ∈ V}) ⊆
    (prod.map F F) ⁻¹' uniform_fun.gen X α U,
  { rintro ⟨i, j⟩ hij x,
    rw mem_Inter₂ at hij,
    rcases mem_Union₂.mp (Scover.symm.subset $ mem_univ x) with ⟨s, hs, hsx⟩,
    exact hVU (prod_mk_mem_comp_rel (prod_mk_mem_comp_rel
      (Vsymm.mk_mem_comm.mp (hsx i)) (hij s hs)) (hsx j)) },
  exact mem_of_superset
    (S.Inter_mem_sets.mpr $ λ x hxS, mem_infi_of_mem x $ preimage_mem_comap hV) this,
end

-- TODO: this is too long
lemma theorem1' {𝔖 : set (set X)} (h𝔖 : ∀ K ∈ 𝔖, is_compact K)
  (hF : ∀ K ∈ 𝔖, equicontinuous ((K.restrict : (X → α) → (K → α)) ∘ F)) :
  (uniform_on_fun.uniform_space X α 𝔖).comap F =
    (⨅ K ∈ 𝔖, ⨅ x ∈ K, ‹uniform_space α›.comap (eval x)).comap F :=
begin
  rw [uniform_on_fun.uniform_space],
  simp_rw [uniform_space.comap_infi, ← uniform_space.comap_comap],
  refine infi_congr (λ K, infi_congr $ λ hK, _),
  haveI : compact_space K := is_compact_iff_compact_space.mp (h𝔖 K hK),
  simp_rw [theorem1 (hF K hK), @uniform_space.comap_comap _ _ _ _ F,
            Pi.uniform_space, of_core_eq_to_core, uniform_space.comap_infi, infi_subtype],
  refine infi_congr (λ x, infi_congr $ λ hx, congr_arg _ _),
  rw ← uniform_space.comap_comap,
  exact congr_fun (congr_arg _ rfl) _,
end

lemma theorem1'' {𝔖 : set (set X)} (hcover : ⋃₀ 𝔖 = univ) (h𝔖 : ∀ K ∈ 𝔖, is_compact K)
  (hF : ∀ K ∈ 𝔖, equicontinuous ((K.restrict : (X → α) → (K → α)) ∘ F)) :
  (uniform_on_fun.uniform_space X α 𝔖).comap F = (Pi.uniform_space (λ _, α)).comap F :=
by simp_rw [theorem1' h𝔖 hF, Pi.uniform_space, of_core_eq_to_core, ←infi_sUnion, hcover, infi_true]

lemma ascoli₀ {𝔖 : set (set X)} {F : ι → X →ᵤ[𝔖] α} {l : filter ι} [l.ne_bot]
  (h1 : ∀ A ∈ 𝔖, is_compact A)
  (h2 : ∀ A ∈ 𝔖, equicontinuous (λ i, set.restrict A (F i)))
  (h3 : ∀ x ∈ ⋃₀ 𝔖, cauchy (map (eval x ∘ F) l)) :
  cauchy (map F l) :=
begin
  have : @@cauchy (⨅ K ∈ 𝔖, ⨅ x ∈ K, ‹uniform_space α›.comap (eval x)) (map F l),
  { simp_rw [cauchy_infi, ← cauchy_map_iff_comap, ← forall_sUnion],
    exact h3 },
  rw [cauchy_of_ne_bot, prod_map_map_eq, map_le_iff_le_comap] at ⊢ this,
  exact this.trans (theorem1' h1 h2).ge
end

lemma ascoli {𝔖 : set (set X)} {F : ι → X →ᵤ[𝔖] α}
  (h1 : ∀ A ∈ 𝔖, is_compact A)
  (h2 : ∀ A ∈ 𝔖, equicontinuous (λ i, set.restrict A (F i)))
  (h3 : ∀ x ∈ ⋃₀ 𝔖, totally_bounded (range (λ i, F i x))) :
  totally_bounded (range F) :=
begin
  simp_rw totally_bounded_iff_ultrafilter at ⊢ h3,
  intros f hf,
  have : F '' univ ∈ f,
  { rwa [image_univ, ← ultrafilter.mem_coe, ← le_principal_iff] },
  rw ← ultrafilter.of_comap_inf_principal_eq_of_map this,
  set g := ultrafilter.of_comap_inf_principal this,
  refine ascoli₀ h1 h2 (λ x hx, h3 x hx (g.map (eval x ∘ F)) $ le_principal_iff.mpr $ range_mem_map)
end
