/-
Copyright (c) 2022 Anatole Dedecker. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl, Patrick Massot, Sébastien Gouëzel, Zhouhang Zhou, Reid Barton,
Anatole Dedecker
-/
import logic.equiv.fin
import topology.uniform_space.uniform_embedding

/-!
# Homeomorphisms

This file defines homeomorphisms between two topological spaces. They are bijections with both
directions continuous. We denote homeomorphisms with the notation `≃ᵤ`.

# Main definitions

* `homeomorph α β`: The type of homeomorphisms from `α` to `β`.
  This type can be denoted using the following notation: `α ≃ᵤ β`.

# Main results

* Pretty much every topological property is preserved under homeomorphisms.
* `homeomorph.homeomorph_of_continuous_open`: A continuous bijection that is
  an open map is a homeomorphism.

-/

open set filter
open_locale topological_space

variables {α : Type*} {β : Type*} {γ : Type*} {δ : Type*}

/-- Uniform isomorphism between `α` and `β` -/
@[nolint has_inhabited_instance] -- not all spaces are homeomorphic to each other
structure uniform_equiv (α : Type*) (β : Type*) [uniform_space α] [uniform_space β]
  extends α ≃ β :=
(uniform_continuous_to_fun  : uniform_continuous to_fun)
(uniform_continuous_inv_fun : uniform_continuous inv_fun)

infix ` ≃ᵤ `:25 := uniform_equiv

namespace uniform_equiv
variables [uniform_space α] [uniform_space β] [uniform_space γ] [uniform_space δ]

instance : has_coe_to_fun (α ≃ᵤ β) (λ _, α → β) := ⟨λe, e.to_equiv⟩

@[simp] lemma uniform_equiv_mk_coe (a : equiv α β) (b c) :
  ((uniform_equiv.mk a b c) : α → β) = a :=
rfl

/-- Inverse of a homeomorphism. -/
protected def symm (h : α ≃ᵤ β) : β ≃ᵤ α :=
{ uniform_continuous_to_fun  := h.uniform_continuous_inv_fun,
  uniform_continuous_inv_fun := h.uniform_continuous_to_fun,
  to_equiv := h.to_equiv.symm }

/-- See Note [custom simps projection]. We need to specify this projection explicitly in this case,
  because it is a composition of multiple projections. -/
def simps.apply (h : α ≃ᵤ β) : α → β := h
/-- See Note [custom simps projection] -/
def simps.symm_apply (h : α ≃ᵤ β) : β → α := h.symm

initialize_simps_projections uniform_equiv
  (to_equiv_to_fun → apply, to_equiv_inv_fun → symm_apply, -to_equiv)

@[simp] lemma coe_to_equiv (h : α ≃ᵤ β) : ⇑h.to_equiv = h := rfl
@[simp] lemma coe_symm_to_equiv (h : α ≃ᵤ β) : ⇑h.to_equiv.symm = h.symm := rfl

lemma to_equiv_injective : function.injective (to_equiv : α ≃ᵤ β → α ≃ β)
| ⟨e, h₁, h₂⟩ ⟨e', h₁', h₂'⟩ rfl := rfl

@[ext] lemma ext {h h' : α ≃ᵤ β} (H : ∀ x, h x = h' x) : h = h' :=
to_equiv_injective $ equiv.ext H

/-- Identity map as a homeomorphism. -/
@[simps apply {fully_applied := ff}]
protected def refl (α : Type*) [uniform_space α] : α ≃ᵤ α :=
{ uniform_continuous_to_fun := uniform_continuous_id,
  uniform_continuous_inv_fun := uniform_continuous_id,
  to_equiv := equiv.refl α }

/-- Composition of two homeomorphisms. -/
protected def trans (h₁ : α ≃ᵤ β) (h₂ : β ≃ᵤ γ) : α ≃ᵤ γ :=
{ uniform_continuous_to_fun  := h₂.uniform_continuous_to_fun.comp h₁.uniform_continuous_to_fun,
  uniform_continuous_inv_fun := h₁.uniform_continuous_inv_fun.comp h₂.uniform_continuous_inv_fun,
  to_equiv := equiv.trans h₁.to_equiv h₂.to_equiv }

@[simp] lemma trans_apply (h₁ : α ≃ᵤ β) (h₂ : β ≃ᵤ γ) (a : α) : h₁.trans h₂ a = h₂ (h₁ a) := rfl

@[simp] lemma uniform_equiv_mk_coe_symm (a : equiv α β) (b c) :
  ((uniform_equiv.mk a b c).symm : β → α) = a.symm :=
rfl

@[simp] lemma refl_symm : (uniform_equiv.refl α).symm = uniform_equiv.refl α := rfl

protected lemma uniform_continuous (h : α ≃ᵤ β) : uniform_continuous h :=
h.uniform_continuous_to_fun

@[continuity]
protected lemma continuous (h : α ≃ᵤ β) : continuous h :=
h.uniform_continuous.continuous

protected lemma uniform_continuous_symm (h : α ≃ᵤ β) : uniform_continuous (h.symm) :=
h.uniform_continuous_inv_fun

@[continuity] -- otherwise `by continuity` can't prove continuity of `h.to_equiv.symm`
protected lemma continuous_symm (h : α ≃ᵤ β) : continuous (h.symm) :=
h.uniform_continuous_symm.continuous

@[simp] lemma apply_symm_apply (h : α ≃ᵤ β) (x : β) : h (h.symm x) = x :=
h.to_equiv.apply_symm_apply x

@[simp] lemma symm_apply_apply (h : α ≃ᵤ β) (x : α) : h.symm (h x) = x :=
h.to_equiv.symm_apply_apply x

protected lemma bijective (h : α ≃ᵤ β) : function.bijective h := h.to_equiv.bijective
protected lemma injective (h : α ≃ᵤ β) : function.injective h := h.to_equiv.injective
protected lemma surjective (h : α ≃ᵤ β) : function.surjective h := h.to_equiv.surjective

/-- Change the homeomorphism `f` to make the inverse function definitionally equal to `g`. -/
def change_inv (f : α ≃ᵤ β) (g : β → α) (hg : function.right_inverse g f) : α ≃ᵤ β :=
have g = f.symm, from funext (λ x, calc g x = f.symm (f (g x)) : (f.left_inv (g x)).symm
                                        ... = f.symm x : by rw hg x),
{ to_fun := f,
  inv_fun := g,
  left_inv := by convert f.left_inv,
  right_inv := by convert f.right_inv,
  uniform_continuous_to_fun := f.uniform_continuous,
  uniform_continuous_inv_fun := by convert f.symm.uniform_continuous }

@[simp] lemma symm_comp_self (h : α ≃ᵤ β) : ⇑h.symm ∘ ⇑h = id :=
funext h.symm_apply_apply

@[simp] lemma self_comp_symm (h : α ≃ᵤ β) : ⇑h ∘ ⇑h.symm = id :=
funext h.apply_symm_apply

@[simp] lemma range_coe (h : α ≃ᵤ β) : range h = univ :=
h.surjective.range_eq

lemma image_symm (h : α ≃ᵤ β) : image h.symm = preimage h :=
funext h.symm.to_equiv.image_eq_preimage

lemma preimage_symm (h : α ≃ᵤ β) : preimage h.symm = image h :=
(funext h.to_equiv.image_eq_preimage).symm

@[simp] lemma image_preimage (h : α ≃ᵤ β) (s : set β) : h '' (h ⁻¹' s) = s :=
h.to_equiv.image_preimage s

@[simp] lemma preimage_image (h : α ≃ᵤ β) (s : set α) : h ⁻¹' (h '' s) = s :=
h.to_equiv.preimage_image s

#check inducing_id

protected lemma uniform_inducing (h : α ≃ᵤ β) : uniform_inducing h :=
uniform_inducing_of_compose h.uniform_continuous h.symm.uniform_continuous $
  by simp only [symm_comp_self, uniform_inducing_id]

lemma induced_eq (h : α ≃ᵤ β) : topological_space.induced h ‹_› = ‹_› := h.inducing.1.symm

protected lemma quotient_map (h : α ≃ᵤ β) : quotient_map h :=
quotient_map.of_quotient_map_compose h.symm.continuous h.continuous $
  by simp only [self_comp_symm, quotient_map.id]

lemma coinduced_eq (h : α ≃ᵤ β) : topological_space.coinduced h ‹_› = ‹_› :=
h.quotient_map.2.symm

protected lemma embedding (h : α ≃ᵤ β) : embedding h :=
⟨h.inducing, h.injective⟩

/-- Homeomorphism given an embedding. -/
noncomputable def of_embedding (f : α → β) (hf : embedding f) : α ≃ᵤ (set.range f) :=
{ continuous_to_fun := continuous_subtype_mk _ hf.continuous,
  continuous_inv_fun := by simp [hf.continuous_iff, continuous_subtype_coe],
  .. equiv.of_injective f hf.inj }

protected lemma second_countable_topology [topological_space.second_countable_topology β]
  (h : α ≃ᵤ β) :
  topological_space.second_countable_topology α :=
h.inducing.second_countable_topology

lemma compact_image {s : set α} (h : α ≃ᵤ β) : is_compact (h '' s) ↔ is_compact s :=
h.embedding.is_compact_iff_is_compact_image.symm

lemma compact_preimage {s : set β} (h : α ≃ᵤ β) : is_compact (h ⁻¹' s) ↔ is_compact s :=
by rw ← image_symm; exact h.symm.compact_image

@[simp] lemma comap_cocompact (h : α ≃ᵤ β) : comap h (cocompact β) = cocompact α :=
(comap_cocompact_le h.continuous).antisymm $
  (has_basis_cocompact.le_basis_iff (has_basis_cocompact.comap h)).2 $ λ K hK,
    ⟨h ⁻¹' K, h.compact_preimage.2 hK, subset.rfl⟩

@[simp] lemma map_cocompact (h : α ≃ᵤ β) : map h (cocompact α) = cocompact β :=
by rw [← h.comap_cocompact, map_comap_of_surjective h.surjective]

protected lemma compact_space [compact_space α] (h : α ≃ᵤ β) : compact_space β :=
{ compact_univ := by { rw [← image_univ_of_surjective h.surjective, h.compact_image],
    apply compact_space.compact_univ } }

protected lemma t0_space [t0_space α] (h : α ≃ᵤ β) : t0_space β :=
h.symm.embedding.t0_space

protected lemma t1_space [t1_space α] (h : α ≃ᵤ β) : t1_space β :=
h.symm.embedding.t1_space

protected lemma t2_space [t2_space α] (h : α ≃ᵤ β) : t2_space β :=
h.symm.embedding.t2_space

protected lemma regular_space [regular_space α] (h : α ≃ᵤ β) : regular_space β :=
h.symm.embedding.regular_space

protected lemma dense_embedding (h : α ≃ᵤ β) : dense_embedding h :=
{ dense   := h.surjective.dense_range,
  .. h.embedding }

@[simp] lemma is_open_preimage (h : α ≃ᵤ β) {s : set β} : is_open (h ⁻¹' s) ↔ is_open s :=
h.quotient_map.is_open_preimage

@[simp] lemma is_open_image (h : α ≃ᵤ β) {s : set α} : is_open (h '' s) ↔ is_open s :=
by rw [← preimage_symm, is_open_preimage]

protected lemma is_open_map (h : α ≃ᵤ β) : is_open_map h := λ s, h.is_open_image.2

@[simp] lemma is_closed_preimage (h : α ≃ᵤ β) {s : set β} : is_closed (h ⁻¹' s) ↔ is_closed s :=
by simp only [← is_open_compl_iff, ← preimage_compl, is_open_preimage]

@[simp] lemma is_closed_image (h : α ≃ᵤ β) {s : set α} : is_closed (h '' s) ↔ is_closed s :=
by rw [← preimage_symm, is_closed_preimage]

protected lemma is_closed_map (h : α ≃ᵤ β) : is_closed_map h := λ s, h.is_closed_image.2

protected lemma open_embedding (h : α ≃ᵤ β) : open_embedding h :=
open_embedding_of_embedding_open h.embedding h.is_open_map

protected lemma closed_embedding (h : α ≃ᵤ β) : closed_embedding h :=
closed_embedding_of_embedding_closed h.embedding h.is_closed_map

protected lemma normal_space [normal_space α] (h : α ≃ᵤ β) : normal_space β :=
h.symm.closed_embedding.normal_space

lemma preimage_closure (h : α ≃ᵤ β) (s : set β) : h ⁻¹' (closure s) = closure (h ⁻¹' s) :=
h.is_open_map.preimage_closure_eq_closure_preimage h.continuous _

lemma image_closure (h : α ≃ᵤ β) (s : set α) : h '' (closure s) = closure (h '' s) :=
by rw [← preimage_symm, preimage_closure]

lemma preimage_interior (h : α ≃ᵤ β) (s : set β) : h⁻¹' (interior s) = interior (h ⁻¹' s) :=
h.is_open_map.preimage_interior_eq_interior_preimage h.continuous _

lemma image_interior (h : α ≃ᵤ β) (s : set α) : h '' (interior s) = interior (h '' s) :=
by rw [← preimage_symm, preimage_interior]

lemma preimage_frontier (h : α ≃ᵤ β) (s : set β) : h ⁻¹' (frontier s) = frontier (h ⁻¹' s) :=
h.is_open_map.preimage_frontier_eq_frontier_preimage h.continuous _

@[to_additive]
lemma _root_.has_compact_mul_support.comp_homeomorph {M} [has_one M] {f : β → M}
  (hf : has_compact_mul_support f) (φ : α ≃ᵤ β) : has_compact_mul_support (f ∘ φ) :=
hf.comp_closed_embedding φ.closed_embedding

@[simp] lemma map_nhds_eq (h : α ≃ᵤ β) (x : α) : map h (𝓝 x) = 𝓝 (h x) :=
h.embedding.map_nhds_of_mem _ (by simp)

lemma symm_map_nhds_eq (h : α ≃ᵤ β) (x : α) : map h.symm (𝓝 (h x)) = 𝓝 x :=
by rw [h.symm.map_nhds_eq, h.symm_apply_apply]

lemma nhds_eq_comap (h : α ≃ᵤ β) (x : α) : 𝓝 x = comap h (𝓝 (h x)) :=
h.embedding.to_inducing.nhds_eq_comap x

@[simp] lemma comap_nhds_eq (h : α ≃ᵤ β) (y : β) : comap h (𝓝 y) = 𝓝 (h.symm y) :=
by rw [h.nhds_eq_comap, h.apply_symm_apply]

/-- If an bijective map `e : α ≃ β` is continuous and open, then it is a homeomorphism. -/
def homeomorph_of_continuous_open (e : α ≃ β) (h₁ : continuous e) (h₂ : is_open_map e) :
  α ≃ᵤ β :=
{ continuous_to_fun := h₁,
  continuous_inv_fun := begin
    rw continuous_def,
    intros s hs,
    convert ← h₂ s hs using 1,
    apply e.image_eq_preimage
  end,
  to_equiv := e }

@[simp] lemma comp_continuous_on_iff (h : α ≃ᵤ β) (f : γ → α) (s : set γ) :
  continuous_on (h ∘ f) s ↔ continuous_on f s :=
h.inducing.continuous_on_iff.symm

@[simp] lemma comp_continuous_iff (h : α ≃ᵤ β) {f : γ → α} :
  continuous (h ∘ f) ↔ continuous f :=
h.inducing.continuous_iff.symm

@[simp] lemma comp_continuous_iff' (h : α ≃ᵤ β) {f : β → γ} :
  continuous (f ∘ h) ↔ continuous f :=
h.quotient_map.continuous_iff.symm

lemma comp_continuous_at_iff (h : α ≃ᵤ β) (f : γ → α) (x : γ) :
  continuous_at (h ∘ f) x ↔ continuous_at f x :=
h.inducing.continuous_at_iff.symm

lemma comp_continuous_at_iff' (h : α ≃ᵤ β) (f : β → γ) (x : α) :
  continuous_at (f ∘ h) x ↔ continuous_at f (h x) :=
h.inducing.continuous_at_iff' (by simp)

lemma comp_continuous_within_at_iff (h : α ≃ᵤ β) (f : γ → α) (s : set γ) (x : γ) :
  continuous_within_at f s x ↔ continuous_within_at (h ∘ f) s x :=
h.inducing.continuous_within_at_iff

@[simp] lemma comp_is_open_map_iff (h : α ≃ᵤ β) {f : γ → α} :
  is_open_map (h ∘ f) ↔ is_open_map f :=
begin
  refine ⟨_, λ hf, h.is_open_map.comp hf⟩,
  intros hf,
  rw [← function.comp.left_id f, ← h.symm_comp_self, function.comp.assoc],
  exact h.symm.is_open_map.comp hf,
end

@[simp] lemma comp_is_open_map_iff' (h : α ≃ᵤ β) {f : β → γ} :
  is_open_map (f ∘ h) ↔ is_open_map f :=
begin
  refine ⟨_, λ hf, hf.comp h.is_open_map⟩,
  intros hf,
  rw [← function.comp.right_id f, ← h.self_comp_symm, ← function.comp.assoc],
  exact hf.comp h.symm.is_open_map,
end

/-- If two sets are equal, then they are homeomorphic. -/
def set_congr {s t : set α} (h : s = t) : s ≃ᵤ t :=
{ continuous_to_fun := continuous_subtype_mk _ continuous_subtype_val,
  continuous_inv_fun := continuous_subtype_mk _ continuous_subtype_val,
  to_equiv := equiv.set_congr h }

/-- Sum of two homeomorphisms. -/
def sum_congr (h₁ : α ≃ᵤ β) (h₂ : γ ≃ᵤ δ) : α ⊕ γ ≃ᵤ β ⊕ δ :=
{ continuous_to_fun  :=
  begin
    convert continuous_sum_rec (continuous_inl.comp h₁.continuous)
      (continuous_inr.comp h₂.continuous),
    ext x, cases x; refl,
  end,
  continuous_inv_fun :=
  begin
    convert continuous_sum_rec (continuous_inl.comp h₁.symm.continuous)
      (continuous_inr.comp h₂.symm.continuous),
    ext x, cases x; refl
  end,
  to_equiv := h₁.to_equiv.sum_congr h₂.to_equiv }

/-- Product of two homeomorphisms. -/
def prod_congr (h₁ : α ≃ᵤ β) (h₂ : γ ≃ᵤ δ) : α × γ ≃ᵤ β × δ :=
{ continuous_to_fun  := (h₁.continuous.comp continuous_fst).prod_mk
    (h₂.continuous.comp continuous_snd),
  continuous_inv_fun := (h₁.symm.continuous.comp continuous_fst).prod_mk
    (h₂.symm.continuous.comp continuous_snd),
  to_equiv := h₁.to_equiv.prod_congr h₂.to_equiv }

@[simp] lemma prod_congr_symm (h₁ : α ≃ᵤ β) (h₂ : γ ≃ᵤ δ) :
  (h₁.prod_congr h₂).symm = h₁.symm.prod_congr h₂.symm := rfl

@[simp] lemma coe_prod_congr (h₁ : α ≃ᵤ β) (h₂ : γ ≃ᵤ δ) :
  ⇑(h₁.prod_congr h₂) = prod.map h₁ h₂ := rfl

section
variables (α β γ)

/-- `α × β` is homeomorphic to `β × α`. -/
def prod_comm : α × β ≃ᵤ β × α :=
{ continuous_to_fun  := continuous_snd.prod_mk continuous_fst,
  continuous_inv_fun := continuous_snd.prod_mk continuous_fst,
  to_equiv := equiv.prod_comm α β }

@[simp] lemma prod_comm_symm : (prod_comm α β).symm = prod_comm β α := rfl
@[simp] lemma coe_prod_comm : ⇑(prod_comm α β) = prod.swap := rfl

/-- `(α × β) × γ` is homeomorphic to `α × (β × γ)`. -/
def prod_assoc : (α × β) × γ ≃ᵤ α × (β × γ) :=
{ continuous_to_fun  := (continuous_fst.comp continuous_fst).prod_mk
    ((continuous_snd.comp continuous_fst).prod_mk continuous_snd),
  continuous_inv_fun := (continuous_fst.prod_mk (continuous_fst.comp continuous_snd)).prod_mk
    (continuous_snd.comp continuous_snd),
  to_equiv := equiv.prod_assoc α β γ }

/-- `α × {*}` is homeomorphic to `α`. -/
@[simps apply {fully_applied := ff}]
def prod_punit : α × punit ≃ᵤ α :=
{ to_equiv := equiv.prod_punit α,
  continuous_to_fun := continuous_fst,
  continuous_inv_fun := continuous_id.prod_mk continuous_const }

/-- `{*} × α` is homeomorphic to `α`. -/
def punit_prod : punit × α ≃ᵤ α :=
(prod_comm _ _).trans (prod_punit _)

@[simp] lemma coe_punit_prod : ⇑(punit_prod α) = prod.snd := rfl

end

/-- `ulift α` is homeomorphic to `α`. -/
def {u v} ulift {α : Type u} [topological_space α] : ulift.{v u} α ≃ᵤ α :=
{ continuous_to_fun := continuous_ulift_down,
  continuous_inv_fun := continuous_ulift_up,
  to_equiv := equiv.ulift }

section distrib

/-- `(α ⊕ β) × γ` is homeomorphic to `α × γ ⊕ β × γ`. -/
def sum_prod_distrib : (α ⊕ β) × γ ≃ᵤ α × γ ⊕ β × γ :=
begin
  refine (homeomorph.homeomorph_of_continuous_open (equiv.sum_prod_distrib α β γ).symm _ _).symm,
  { convert continuous_sum_rec
      ((continuous_inl.comp continuous_fst).prod_mk continuous_snd)
      ((continuous_inr.comp continuous_fst).prod_mk continuous_snd),
    ext1 x, cases x; refl, },
  { exact (is_open_map_sum
    (open_embedding_inl.prod open_embedding_id).is_open_map
    (open_embedding_inr.prod open_embedding_id).is_open_map) }
end

/-- `α × (β ⊕ γ)` is homeomorphic to `α × β ⊕ α × γ`. -/
def prod_sum_distrib : α × (β ⊕ γ) ≃ᵤ α × β ⊕ α × γ :=
(prod_comm _ _).trans $
sum_prod_distrib.trans $
sum_congr (prod_comm _ _) (prod_comm _ _)

variables {ι : Type*} {σ : ι → Type*} [Π i, topological_space (σ i)]

/-- `(Σ i, σ i) × β` is homeomorphic to `Σ i, (σ i × β)`. -/
def sigma_prod_distrib : ((Σ i, σ i) × β) ≃ᵤ (Σ i, (σ i × β)) :=
homeomorph.symm $
homeomorph_of_continuous_open (equiv.sigma_prod_distrib σ β).symm
  (continuous_sigma $ λ i,
    (continuous_sigma_mk.comp continuous_fst).prod_mk continuous_snd)
  (is_open_map_sigma $ λ i,
    (open_embedding_sigma_mk.prod open_embedding_id).is_open_map)

end distrib

/-- If `ι` has a unique element, then `ι → α` is homeomorphic to `α`. -/
@[simps { fully_applied := ff }]
def fun_unique (ι α : Type*) [unique ι] [topological_space α] : (ι → α) ≃ᵤ α :=
{ to_equiv := equiv.fun_unique ι α,
  continuous_to_fun := continuous_apply _,
  continuous_inv_fun := continuous_pi (λ _, continuous_id) }

/-- Homeomorphism between dependent functions `Π i : fin 2, α i` and `α 0 × α 1`. -/
@[simps { fully_applied := ff }]
def {u} pi_fin_two (α : fin 2 → Type u) [Π i, topological_space (α i)] : (Π i, α i) ≃ᵤ α 0 × α 1 :=
{ to_equiv := pi_fin_two_equiv α,
  continuous_to_fun := (continuous_apply 0).prod_mk (continuous_apply 1),
  continuous_inv_fun := continuous_pi $ fin.forall_fin_two.2 ⟨continuous_fst, continuous_snd⟩ }

/-- Homeomorphism between `α² = fin 2 → α` and `α × α`. -/
@[simps { fully_applied := ff }] def fin_two_arrow : (fin 2 → α) ≃ᵤ α × α :=
{ to_equiv := fin_two_arrow_equiv α, ..  pi_fin_two (λ _, α) }

/--
A subset of a topological space is homeomorphic to its image under a homeomorphism.
-/
def image (e : α ≃ᵤ β) (s : set α) : s ≃ᵤ e '' s :=
{ continuous_to_fun := by continuity!,
  continuous_inv_fun := by continuity!,
  ..e.to_equiv.image s, }

end homeomorph

/-- An inducing equiv between topological spaces is a homeomorphism. -/
@[simps] def equiv.to_homeomorph_of_inducing [topological_space α] [topological_space β] (f : α ≃ β)
  (hf : inducing f) :
  α ≃ᵤ β :=
{ continuous_to_fun := hf.continuous,
  continuous_inv_fun := hf.continuous_iff.2 $ by simpa using continuous_id,
  .. f }

namespace continuous
variables [topological_space α] [topological_space β]

lemma continuous_symm_of_equiv_compact_to_t2 [compact_space α] [t2_space β]
  {f : α ≃ β} (hf : continuous f) : continuous f.symm :=
begin
  rw continuous_iff_is_closed,
  intros C hC,
  have hC' : is_closed (f '' C) := (hC.is_compact.image hf).is_closed,
  rwa equiv.image_eq_preimage at hC',
end

/-- Continuous equivalences from a compact space to a T2 space are homeomorphisms.

This is not true when T2 is weakened to T1
(see `continuous.homeo_of_equiv_compact_to_t2.t1_counterexample`). -/
@[simps]
def homeo_of_equiv_compact_to_t2 [compact_space α] [t2_space β]
  {f : α ≃ β} (hf : continuous f) : α ≃ᵤ β :=
{ continuous_to_fun := hf,
  continuous_inv_fun := hf.continuous_symm_of_equiv_compact_to_t2,
  ..f }

end continuous
