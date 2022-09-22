import field_theory.galois
import linear_algebra.linear_independent
universes v u
variables (K L : Type*) [field K] [field L]
  [algebra K L] [normal K L] [is_separable K L] [finite_dimensional K L]

-- corollary of Dedekind's linear independence of characters
lemma helper :
  @linear_independent (L ≃ₐ[K] L) L (L → L) (λ f, f.to_alg_hom) _ _ _ :=
@linear_independent.comp (L →* L) (L ≃ₐ[K] L) L (L → L) (λ f, f : (L →* L) → (L → L))
_ _ _ (linear_independent_monoid_hom L L) (λ f, f.to_alg_hom)
(λ x y h, by ext; exact monoid_hom.ext_iff.1 h _)

instance : distrib_mul_action (L ≃ₐ[K] L) (additive (Lˣ)) :=
{ smul := λ f, units.map (f.to_alg_hom : L →* L),
  one_smul := λ x, by ext; refl,
  mul_smul := λ x y z, by ext; refl,
  smul_add := λ x y z, by ext; exact x.map_mul _ _,
  smul_zero := λ x, by ext; exact x.map_one }

open_locale big_operators

-- Given `f: Gal(L/K) → Lˣ`, the sum `∑ f(φ) • φ` for `φ ∈ Gal(L/K)`, as a function `L → L`.
noncomputable def aux (f : (L ≃ₐ[K] L) → Lˣ) : L → L :=
finsupp.total (L ≃ₐ[K] L) (L → L) L (λ φ, φ.to_alg_hom)
  (finsupp.equiv_fun_on_fintype.symm (λ φ, (f φ : L)))

lemma aux_ne_zero (f : (L ≃ₐ[K] L) → Lˣ) : aux K L f ≠ 0 :=
begin
  have h := linear_independent_iff.1 (helper K L)
    (finsupp.equiv_fun_on_fintype.symm (λ φ, (f φ : L))),
  intro H,
  specialize h H,
  have hm := finsupp.ext_iff.1 h 1,
  dsimp at hm,
  exact units.ne_zero (f 1) hm,
end

theorem hilbert90 (f : (L ≃ₐ[K] L) → Lˣ)
  (hf : ∀ (g h : (L ≃ₐ[K] L)), g (f h) * (f (g * h))⁻¹ * f g = 1) :
  ∃ β : Lˣ, ∀ g : (L ≃ₐ[K] L), f g = β * (units.map (g.to_alg_hom : L →* L) β)⁻¹ :=
begin
  obtain ⟨z, hz⟩ : ∃ z, aux K L f z ≠ 0, from
    not_forall.1 (λ H, aux_ne_zero K L f $ funext $ λ x, H x),
  use units.mk0 (aux K L f z) hz, /- let β = (∑ f(φ) • φ)(z) for some `z` making the RHS nonzero -/
  intro g,
  rw eq_mul_inv_iff_mul_eq,
  ext,
  suffices : ↑(f g) * g (∑ (x : L ≃ₐ[K] L), ↑(f x) * x z) = ∑ (x : L ≃ₐ[K] L), ↑(f x) * x z,
  by { dsimp [aux, finsupp.total, finsupp.sum], simpa },
  simp only [alg_equiv.map_sum, alg_equiv.map_mul],
  have H : ∀ g h, ((f (g * h))⁻¹ : L) * (f g : L) ≠ 0 :=
  λ g h, by simp,
  simp only [mul_assoc, mul_eq_one_iff_eq_inv₀ (H _ _)] at hf,
  simp only [hf, finset.mul_sum, ←mul_assoc],
  simp only [mul_inv_rev, mul_comm _ (f g : L)⁻¹, inv_inv, ←units.coe_inv _,
    units.mul_inv_cancel_left _],
  show ∑ (x : L ≃ₐ[K] L), _ * (g * x) z = _,
  /- The goal is now `∑ f(g * φ) * (g * φ)(z) = ∑ f(φ) * φ(z)`; we apply the fact that we are
    summing the same function over different permutations of the same finite set. -/
  refine @finset.sum_bij _ (L ≃ₐ[K] L) (L ≃ₐ[K] L) _ finset.univ finset.univ
   _ _ (λ i ih, g * i) (λ i ih, finset.mem_univ _)
   (by intros; refl) _ _,
  { intros a b ha hb hab,
    exact (mul_right_inj _).1 hab },
  { intros,
    use [g⁻¹ * b, finset.mem_univ _, (mul_inv_cancel_left _ _).symm] }
 end
