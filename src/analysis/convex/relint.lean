import analysis.convex.basic
import analysis.normed_space.add_torsor_bases
import analysis.normed_space.basic
import analysis.normed_space.linear_isometry
import data.real.basic
import data.set.pointwise
import linear_algebra.affine_space.pointwise

open_locale pointwise


-- MOVETO topology.constructions, after subtype.topological_space?

def subtype.inclusion {α : Type} [topological_space α] {p q : α → Prop} (h : ∀ a, p a → q a) :
subtype p → subtype q := subtype.map id h

lemma subtype.continuous_inclusion {α : Type} [topological_space α] {p q : α → Prop} (h : ∀ a, p a → q a) :
continuous (subtype.inclusion h) :=
begin
  simp only [continuous_def, is_open_induced_iff, subtype.inclusion, subtype.map, id.def],
  rintro - ⟨U, hU, rfl⟩,
  refine ⟨U, hU, _⟩,
  ext,
  simp only [set.mem_preimage, subtype.coe_mk],
end

def subtype.equiv_inclusion {α : Type} [topological_space α] {p q : α → Prop} (h : ∀ {a}, p a ↔ q a) :
subtype p ≃ subtype q :=
begin
  refine ⟨subtype.inclusion (λ _, h.mp), subtype.inclusion (λ _, h.mpr), _, _⟩;
    simp only [subtype.inclusion, subtype.map, id.def,
      function.left_inverse_iff_comp, function.right_inverse_iff_comp,
      function.funext_iff, subtype.coe_mk,
      subtype.ext_iff, eq_self_iff_true, implies_true_iff],
end

def subtype.homeomorph_inclusion {α : Type} [topological_space α] {p q : α → Prop} (h : ∀ a, p a ↔ q a) :
subtype p ≃ₜ subtype q :=
begin
  refine ⟨subtype.equiv_inclusion h, _, _⟩ ;
    simp only [auto_param_eq, subtype.equiv_inclusion] ;
    apply subtype.continuous_inclusion,
end

-- MOVETO data.set.pointwise

lemma set.vadd_vsub_vadd_cancel_left {V : Type} [add_comm_group V]
  (x : V) (A B : set V) :
(x +ᵥ A) -ᵥ (x +ᵥ B) = A -ᵥ B :=
begin
  ext, split,
  { rintro ⟨-, -, ⟨a, ha, rfl⟩, ⟨b, hb, rfl⟩, rfl⟩,
    rw [vadd_vsub_vadd_cancel_left x],
    exact ⟨a, b, ha, hb, rfl⟩, },
  { rintro ⟨a, b, ha, hb, rfl⟩,
    rw [←vadd_vsub_vadd_cancel_left x],
    exact ⟨_, _, ⟨a, ha, rfl⟩, ⟨b, hb, rfl⟩, rfl⟩ },
end

-- MOVETO linear_algebra.affine_space.affine_subspace

lemma affine_subspace.neg_vadd_mem_iff {V R : Type} [ring R]
  [add_comm_group V] [module R V]
  (E : affine_subspace R V) (x y : V) :
(-x) +ᵥ y ∈ E ↔ y ∈ x +ᵥ E :=
begin
  split,
  {
    intro h,
    refine ⟨-x +ᵥ y, h, _⟩,
    simp only [vadd_eq_add, affine_equiv.coe_coe, affine_equiv.const_vadd_apply,
      add_neg_cancel_left],
  },
  {
    rintro ⟨z, hz, rfl⟩,
    simpa only [affine_equiv.coe_coe, affine_equiv.const_vadd_apply, vadd_eq_add,
      neg_add_cancel_left] using hz,
  },
end

lemma affine_span_eq_vector_span {V : Type} (R : Type) [ring R] [add_comm_group V] [module R V]
  {A : set V} {x : V} (hxA : x ∈ A) :
(affine_span R (-x +ᵥ A) : set V) = vector_span R A :=
begin
  suffices hs : (affine_span R (-x +ᵥ A)).direction = vector_span R A,
  {
    rw [←affine_subspace.pointwise_vadd_span, ←direction_affine_span],
    ext y, split,
    { rintro ⟨y, hy, rfl⟩,
      simp only [affine_equiv.coe_coe, affine_equiv.const_vadd_apply, vadd_eq_add],
      rw [←sub_eq_neg_add, affine_subspace.coe_direction_eq_vsub_set_right],
      { refine ⟨y, hy, rfl⟩ },
      { apply subset_affine_span ; assumption } },
    { rintro h,
    refine ⟨y + x, _, _⟩,
    { rw [affine_subspace.mem_coe],
      refine affine_subspace.vadd_mem_of_mem_direction h _,
      { apply subset_affine_span ; assumption } },
    simp only [affine_equiv.coe_coe, affine_equiv.const_vadd_apply, vadd_eq_add,
      neg_add_cancel_comm_assoc], }
  },
  simp only [direction_affine_span, vector_span_def, set.vadd_vsub_vadd_cancel_left],
end

lemma affine_span_eq_vector_span' {V : Type} (R : Type) [ring R] [add_comm_group V] [module R V]
  {A : set V} (hzm : (0 : V) ∈ A) :
(affine_span R A : set V) = vector_span R A :=
begin
  convert affine_span_eq_vector_span R hzm,
  simp only [neg_zero, zero_vadd],
end

def affine_subspace.inclusion {R V P : Type} [ring R] [add_comm_group V] [module R V]
  [add_torsor V P] (E : affine_subspace R P) : E → P := coe

def blabb {R V P : Type} [ring R] [add_comm_group V] [module R V]
  [add_torsor V P] (E : affine_subspace R P) [nonempty E] : add_torsor E.direction E := E.to_add_torsor

def affine_subspace.inclusion_aff {R V P : Type} [ring R] [add_comm_group V] [module R V]
  [add_torsor V P] (E : affine_subspace R P) [nonempty E] : E →ᵃ[R] P :=
begin
  refine ⟨E.inclusion, E.direction.subtype, by tauto⟩,
end

instance blubb {𝕜 V P : Type} [normed_field 𝕜] [seminormed_add_comm_group V]
  [normed_space 𝕜 V] [pseudo_metric_space P] [normed_add_torsor V P]
  {E : affine_subspace 𝕜 P} [nonempty E] : normed_add_torsor E.direction E :=
{ to_add_torsor := E.to_add_torsor,
  dist_eq_norm' :=
  begin
    intros x y,
    simp only [subtype.dist_eq, submodule.coe_norm, affine_subspace.coe_vsub],
    apply dist_eq_norm_vsub,
  end }

def affine_subspace.inclusion_ai {𝕜 V P : Type} [normed_field 𝕜] [seminormed_add_comm_group V]
  [normed_space 𝕜 V] [pseudo_metric_space P] [normed_add_torsor V P]
  (E : affine_subspace 𝕜 P) [nonempty E] : E →ᵃⁱ[𝕜] P :=
begin
  refine ⟨E.inclusion_aff, by tauto⟩,
end

-- BEGIN intrinsic_interior.lean

section experiment

variables (R : Type) {V P : Type} [ring R] [seminormed_add_comm_group V] [module R V]
  [pseudo_metric_space P] [normed_add_torsor V P]

def intrinsic_interior' (R : Type) {V P : Type} [ring R] [seminormed_add_comm_group V] [module R V]
  [pseudo_metric_space P] [normed_add_torsor V P] -- have to redeclare variables to ensure that
                                                  -- all typeclasses are used
  (A : set P) :=
(affine_span R A).inclusion '' interior ((affine_span R A).inclusion ⁻¹' A)

lemma intrinsic_interior'_def (R : Type) {V P : Type} [ring R] [seminormed_add_comm_group V] [module R V]
  [pseudo_metric_space P] [normed_add_torsor V P]
  (A : set P) :
intrinsic_interior' R A =
(affine_span R A).inclusion '' interior ((affine_span R A).inclusion ⁻¹' A) := rfl

lemma isometry_range_intrinsic_interior {𝕜 V V₂ P P₂: Type}
  [normed_field 𝕜] [seminormed_add_comm_group V] [seminormed_add_comm_group V₂] [normed_space 𝕜 V]
  [normed_space 𝕜 V₂] [pseudo_metric_space P] [pseudo_metric_space P₂] [normed_add_torsor V P]
  [normed_add_torsor V₂ P₂]
  (φ : P →ᵃⁱ[𝕜] P₂) (A : set P) :
φ '' intrinsic_interior' 𝕜 A = intrinsic_interior' 𝕜 (φ '' A) :=
begin
  -- TODO: by_cases
  haveI : nonempty (affine_span 𝕜 A) := sorry,
  haveI : nonempty ((affine_span 𝕜 A).map φ.to_affine_map) := sorry,
  simp only [intrinsic_interior'_def, ←φ.coe_to_affine_map],
  rw [intrinsic_interior'_def],
  rw [←affine_subspace.map_span φ.to_affine_map A],
  let f : (affine_span 𝕜 A) →ᵃⁱ[𝕜] (affine_span 𝕜 A).map φ.to_affine_map := sorry,
  have : φ.to_affine_map ∘ (affine_span 𝕜 A).inclusion = ((affine_span 𝕜 A).map φ.to_affine_map).inclusion ∘ f := sorry,
  rw [←set.image_comp, this, set.image_comp],
  have : f '' interior ((affine_span 𝕜 A).inclusion ⁻¹' A) = interior (f '' ((affine_span 𝕜 A).inclusion ⁻¹' A)) := sorry,
  rw [this],
  congr' 2,
  admit,
end

end experiment

variables (𝕜 : Type) [ring 𝕜]

section definitions

variables (R : Type) [ring R] {V : Type} [add_comm_group V] [module R V] [topological_space V]

/-- The intrinsic interior of a set is its interior considered as a set in its affine span. -/
def intrinsic_interior
  (A : set V) :=
(coe : affine_span R A → V) '' interior ((coe : affine_span R A → V) ⁻¹' A)

lemma intrinsic_interior_def (A : set V) :
intrinsic_interior R A =
(coe : affine_span R A → V) '' interior ((coe : affine_span R A → V) ⁻¹' A) := rfl

/-- The intrinsic frontier of a set is its frontier considered as a set in its affine span. -/
def intrinsic_frontier (A : set V) : set V := coe '' frontier ((coe : affine_span R A → V) ⁻¹' A)

lemma intrinsic_interior_eq_' (R : Type) {V : Type} [ring R] [seminormed_add_comm_group V] [module R V]
  (A : set V) :
intrinsic_interior R A = intrinsic_interior' R A := rfl

lemma intrinsic_frontier_def (A : set V) :
intrinsic_frontier R A =
(coe : affine_span R A → V) '' frontier ((coe : affine_span R A → V) ⁻¹' A) := rfl

/-- The intrinsic closure of a set is its closure considered as a set in its affine span. -/
def intrinsic_closure (A : set V) : set V := coe '' closure ((coe : affine_span R A → V) ⁻¹' A)

lemma intrinsic_closure_def (A : set V) :
intrinsic_closure R A =
(coe : affine_span R A → V) '' closure ((coe : affine_span R A → V) ⁻¹' A) := rfl

end definitions

section basic

variables (R : Type) [ring R] {V : Type} [add_comm_group V] [module R V] [topological_space V]

@[simp] lemma intrinsic_closure_eq_closure (𝕜 : Type)
  [nontrivially_normed_field 𝕜] [complete_space 𝕜]
  {V : Type} [normed_add_comm_group V] [normed_space 𝕜 V] [finite_dimensional 𝕜 V]
  (A : set V) : intrinsic_closure 𝕜 A = closure A :=
begin
  simp only [intrinsic_closure_def],
  ext x,
  simp only [mem_closure_iff, set.mem_image],
  split,
  { rintro ⟨x, h, rfl⟩ o ho hxo,
    obtain ⟨z, hz₁, hz₂⟩ := h ((coe : affine_span 𝕜 A → V) ⁻¹' o)
                   (continuous_induced_dom.is_open_preimage o ho) hxo,
    exact ⟨z, hz₁, hz₂⟩ },
  {
    intro h,
    refine ⟨⟨x, _⟩, _⟩,
    { by_contradiction hc,
    obtain ⟨z, hz₁, hz₂⟩ := h
      (affine_span 𝕜 A)ᶜ
      (affine_subspace.closed_of_finite_dimensional (affine_span 𝕜 A)).is_open_compl
      hc,
    exact hz₁ (subset_affine_span 𝕜 A hz₂), },
    refine ⟨_, subtype.coe_mk _ _⟩,
    intros o ho hxo,
    have ho' := ho,
    rw [is_open_induced_iff] at ho,
    obtain ⟨o, ho, rfl⟩ := ho,
    rw [set.mem_preimage, subtype.coe_mk] at hxo,
    obtain ⟨w, hwo, hwA⟩ := h _ ho hxo,
    have : w ∈ affine_span 𝕜 A := subset_affine_span 𝕜 A hwA,
    refine ⟨⟨w, subset_affine_span 𝕜 A hwA⟩, hwo, hwA⟩,
  },
end

@[simp] lemma intrinsic_closure_diff_intrinsic_interior (A : set V) :
intrinsic_closure R A \ intrinsic_interior R A = intrinsic_frontier R A :=
begin
  rw [intrinsic_frontier_def, intrinsic_closure_def, intrinsic_interior_def,
    ←set.image_diff subtype.coe_injective],
  refl,
end

@[simp] lemma closure_diff_intrinsic_interior  (𝕜 : Type)
  [nontrivially_normed_field 𝕜] [complete_space 𝕜]
  {V : Type} [normed_add_comm_group V] [normed_space 𝕜 V] [finite_dimensional 𝕜 V]
  (A : set V) :
closure A \ intrinsic_interior 𝕜 A = intrinsic_frontier 𝕜 A :=
begin
  simp only [←intrinsic_closure_eq_closure 𝕜],
  exact intrinsic_closure_diff_intrinsic_interior 𝕜 A,
end

lemma intrinsic_interior_subset (A : set V) : intrinsic_interior R A ⊆ A :=
set.image_subset_iff.mpr interior_subset

lemma intrinsic_frontier_subset {A : set V} (hA : is_closed A) : intrinsic_frontier R A ⊆ A :=
set.image_subset_iff.mpr (hA.preimage continuous_induced_dom).frontier_subset

@[simp] lemma intrinsic_interior_empty : intrinsic_interior R (∅ : set V) = ∅ :=
set.subset_empty_iff.mp $ intrinsic_interior_subset R _

@[simp] lemma intrinsic_frontier_empty : intrinsic_frontier R (∅ : set V) = ∅ :=
set.subset_empty_iff.mp $ intrinsic_frontier_subset R is_closed_empty

@[simp] lemma intrinsic_interior_singleton (x : V) : intrinsic_interior R ({x} : set V) = {x} :=
sorry

end basic

lemma intrinsic_interior_vadd_subset {V : Type}
  [add_comm_group V] [module 𝕜 V] [topological_space V] [has_continuous_const_vadd V V]
  (A : set V) (x : V) :
intrinsic_interior 𝕜 (x +ᵥ A) ⊆ x +ᵥ intrinsic_interior 𝕜 A :=
begin
  simp only [intrinsic_interior_def],
  rintro - ⟨y, hy, rfl⟩,
  refine ⟨y - x, _, _⟩, swap,
  { apply add_sub_cancel'_right },
  refine ⟨⟨y - x, _⟩, _, rfl⟩,
  { change ↑y - x ∈ affine_span 𝕜 A,
    rw [←affine_subspace.vadd_mem_pointwise_vadd_iff, affine_subspace.pointwise_vadd_span],
    swap, exact x,
    simp only [vadd_eq_add, add_sub_cancel'_right],
    exact y.property },
  obtain ⟨y, yprop⟩ := y,
  rw [←affine_subspace.pointwise_vadd_span] at yprop,
  simp only [mem_interior_iff_mem_nhds, mem_nhds_induced] at hy ⊢,
  simp only [mem_nhds_iff, subtype.coe_mk, exists_prop] at hy ⊢,
  obtain ⟨t, ⟨u, ut, uopen, yu⟩, ht⟩ := hy,
  refine ⟨(-x) +ᵥ u, ⟨(-x) +ᵥ u, subset_refl _, _, _⟩, _⟩,
  { apply uopen.vadd, apply_instance, },
  { refine ⟨y, yu, _⟩,
    rw [vadd_eq_add, ←sub_eq_neg_add], },

  rintro ⟨z, hz₁⟩ hz₂,
  simp only [set.mem_preimage, subtype.coe_mk] at hz₂ ⊢,
  obtain ⟨z, hz₂, rfl⟩ := hz₂,
  change (-x) +ᵥ z ∈ affine_span 𝕜 A at hz₁,
  rw [affine_subspace.neg_vadd_mem_iff, affine_subspace.pointwise_vadd_span] at hz₁,
  let w : affine_span 𝕜 (x +ᵥ A) := ⟨z, hz₁⟩,
  have hw: w ∈ (coe : affine_span 𝕜 (x +ᵥ A) → V) ⁻¹' t := ut hz₂,
  rw [←set.mem_vadd_set_iff_neg_vadd_mem],
  exact ht hw,
end

lemma intrinsic_interior_vadd {V : Type}
  [add_comm_group V] [module 𝕜 V] [topological_space V] [has_continuous_const_vadd V V]
  (A : set V) (x : V) :
intrinsic_interior 𝕜 (x +ᵥ A) = x +ᵥ intrinsic_interior 𝕜 A :=
begin
  refine subset_antisymm (by apply intrinsic_interior_vadd_subset) _,
  suffices hs : intrinsic_interior 𝕜 ((-x) +ᵥ (x +ᵥ A)) ⊆ (-x) +ᵥ intrinsic_interior 𝕜 (x +ᵥ A),
  { simp only [neg_vadd_vadd] at hs,
    rintro - ⟨y, hy, rfl⟩,
    obtain ⟨z, hz, rfl⟩ := hs hy,
    simpa only [vadd_eq_add, add_neg_cancel_left] using hz },
  apply intrinsic_interior_vadd_subset,
end

lemma intrinsic_interior_vector_span {V : Type} [add_comm_group V] [module 𝕜 V] [topological_space V]
  {A : set V} (hzm : (0 : V) ∈ A) :
intrinsic_interior 𝕜 A = (coe : vector_span 𝕜 A → V) '' interior ((coe : vector_span 𝕜 A → V) ⁻¹' A) :=
begin
  have : ∀ v : V, v ∈ vector_span 𝕜 A ↔ v ∈ affine_span 𝕜 A,
  {
    intros v,
    simp only [←set_like.mem_coe, ←affine_subspace.mem_coe],
    rw [affine_span_eq_vector_span' 𝕜 hzm],
  },
  let φ : vector_span 𝕜 A ≃ₜ affine_span 𝕜 A := subtype.homeomorph_inclusion this,
  rw [intrinsic_interior_def],
  ext y,
  simp only [set.mem_image],
  split,
  all_goals { rintro ⟨y, hy, rfl⟩,
              refine ⟨φ.symm y, _, rfl⟩ <|> refine ⟨φ y, _, rfl⟩,
              have := set.mem_image_of_mem _ hy,
              rw [homeomorph.image_interior] at this,
              convert this using 2,
              rw [←homeomorph.preimage_symm, ←set.preimage_comp],
              refl },
end

lemma subset_vector_span_of_zero_mem {V : Type} [add_comm_group V] [module 𝕜 V]
  {A : set V} (hzm : (0 : V) ∈ A) :
A ⊆ vector_span 𝕜 A :=
begin
  refine subset_trans _ (vsub_set_subset_vector_span _ _),
  intros a ha,
  exact ⟨a, 0, ha, hzm, sub_zero _⟩,
end

@[protected]
lemma coe_preimage_vsub {V R : Type} [ring R]
  [add_comm_group V] [module R V]
  {A : set V} {E : submodule R V} (hAE : A ⊆ E) :
(coe : E → V) ⁻¹' (A -ᵥ A) = ((coe : E → V) ⁻¹' A) -ᵥ ((coe : E → V) ⁻¹' A) :=
begin
  ext, split,
  { rintro ⟨x₁, x₂, hx₁, hx₂, h⟩,
    refine ⟨⟨x₁, hAE hx₁⟩, ⟨x₂, hAE hx₂⟩, hx₁, hx₂, _⟩,
    ext,
    exact h, },
  { rintro ⟨x₁, x₂, hx₁, hx₂, rfl⟩,
    refine ⟨↑x₁, ↑x₂, hx₁, hx₂, rfl⟩, },
end

@[protected]
lemma coe_vector_span_preimage_spans_top {V : Type} [add_comm_group V] [module 𝕜 V]
  {A : set V} (hzm : (0 : V) ∈ A) :
vector_span 𝕜 ((coe : vector_span 𝕜 A → V) ⁻¹' A) = ⊤ :=
begin
  refine eq.trans _ submodule.span_span_coe_preimage,
  rw [coe_preimage_vsub],
  { refl },
  { exact subset_vector_span_of_zero_mem 𝕜 hzm },
end

lemma nonempty_intrinsic_interior_of_nonempty_of_convex
  {V : Type} [normed_add_comm_group V] [normed_space ℝ V]
  [finite_dimensional ℝ V]
  {A : set V}
(Ane : A.nonempty) (Acv : convex ℝ A) :
(intrinsic_interior ℝ A).nonempty :=
begin
  obtain ⟨x, hx⟩ := Ane,
  have hzm : (0 : V) ∈ -x +ᵥ A :=⟨x, hx, add_left_neg x⟩,
  rw [←vadd_neg_vadd x A, intrinsic_interior_vadd],
  apply set.nonempty.vadd_set,
  rw [intrinsic_interior_vector_span ℝ hzm, set.nonempty_image_iff,
    convex.interior_nonempty_iff_affine_span_eq_top,
    affine_subspace.affine_span_eq_top_iff_vector_span_eq_top_of_nonempty],
  { exact coe_vector_span_preimage_spans_top ℝ hzm },
  { exact ⟨0, hzm⟩ },
  { rw [←submodule.coe_subtype],
    exact (Acv.vadd _).linear_preimage _ },
end
