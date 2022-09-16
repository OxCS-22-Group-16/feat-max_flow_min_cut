/-
Copyright (c) 2022 María Inés de Frutos-Fernández. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: María Inés de Frutos-Fernández
-/
import analysis.special_functions.pow
import analysis.normed.ring.seminorm
import topology.metric_space.basic
import topology.algebra.order.monotone_convergence

/-!
# Smoothing procedures for seminorms

This file contains several ring seminorm constructions that will be used in the proof that a rank 1
nonarchimedean valuation on a complete field can be uniquely extended to any algebraic extension.

## Main declarations

* `seminorm_from_const`: Given a power-multiplicative ring seminorm `f` on a ring `R` and an
  element `c ∈ R` with `f c ≠ 0`, the real-valued function sending `x ∈ R` to the limit of
  `(f (x * c^n))/((f c)^n)` is a power-multiplicative ring seminorm on `R` satisfying some
  multiplicativity conditions [BGR84, Proposition 1.3.2/2].


## References

* [S. Bosch, U. Güntzer, R. Remmert, *Non-Archimedean Analysis*][bosch-guntzer-remmert]

## Tags
ring_seminorm, ring_norm
-/


noncomputable theory

open_locale topological_space

section defs

/-- A function `f : α → β` is power-multiplicative if for all `a ∈ α` and all positive `n ∈ ℕ`,
  `f (a ^ n) = (f a) ^ n`. -/
def is_pow_mul {α : Type*} [has_pow α ℕ] {β : Type*} [has_pow β ℕ]  (f : α → β) :=
∀ (a : α) {n : ℕ} (hn : 1 ≤ n), f (a ^ n) = (f a) ^ n

/-- A function `f : α → β` is nonarchimedean if it satisfies the inequality
  `f (a + b) ≤ max (f a) (f b)` for all `a, b ∈ α`. -/
def is_nonarchimedean {α : Type*} [has_add α] {β : Type*} [linear_order β] (f : α → β) : Prop :=
∀ r s, f (r + s) ≤ max (f r) (f s)

end defs

section seminorm_from_const
/- In this section we prove Proposition 1.3.2/2 in
[S. Bosch, U. Güntzer, R. Remmert, *Non-Archimedean Analysis*][bosch-guntzer-remmert]. -/

section ring

variables {R : Type*} [comm_ring R] (c : R) (f : ring_seminorm R) (hf1 : f 1 ≤ 1)
  (hc : 0 ≠ f c) (hpm : is_pow_mul f)

/-- For a ring seminorm `f` on `R` and `c ∈ R`, the sequence given by `(f (x * c^n))/((f c)^n)`. -/
def seminorm_from_const_seq (x : R) : ℕ → ℝ :=
λ n, (f (x * c^n))/((f c)^n)

lemma seminorm_from_const_nonneg (x : R) (n : ℕ) : 0 ≤ seminorm_from_const_seq c f x n :=
div_nonneg (map_nonneg f (x * c ^ n)) (pow_nonneg (map_nonneg f c) n)

lemma seminorm_from_const_is_bounded (x : R) :
  bdd_below (set.range (seminorm_from_const_seq c f x)) :=
begin
  use 0,
  rw mem_lower_bounds,
  rintros r ⟨n, hn⟩,
  rw ← hn,
  exact seminorm_from_const_nonneg c f x n,
end

variable {f}

lemma seminorm_from_const_seq_zero (hf : f 0 = 0) :
  seminorm_from_const_seq c f 0 = 0 :=
begin
  simp only [seminorm_from_const_seq],
  ext n,
  rw [zero_mul, hf, zero_div],
  refl,
end

variable {c}

include hc hpm

lemma seminorm_from_const_seq_one (n : ℕ) (hn : 1 ≤ n) :
  seminorm_from_const_seq c f 1 n = 1 :=
begin
  simp only [seminorm_from_const_seq],
  rw [one_mul, hpm _ hn, div_self (pow_ne_zero n (ne.symm hc))],
end

include hf1

lemma seminorm_from_const_seq_antitone (x : R) :
  antitone (seminorm_from_const_seq c f x) :=
begin
  intros m n hmn,
  simp only [seminorm_from_const_seq],
  nth_rewrite 0 ← nat.add_sub_of_le hmn,
  rw [pow_add, ← mul_assoc],
  have hc_pos : 0 < f c := lt_of_le_of_ne (map_nonneg f _) hc,
  apply le_trans ((div_le_div_right (pow_pos hc_pos _)).mpr (map_mul_le_mul f _ _)),
  by_cases heq : m = n,
  { have : n - m = 0,
    { rw heq, exact nat.sub_self n, },
    rw [this, heq, div_le_div_right (pow_pos hc_pos _), pow_zero],
    conv_rhs{rw ← mul_one (f (x * c ^ n))},
    exact mul_le_mul_of_nonneg_left hf1 (map_nonneg f _) },
  { have h1 : 1 ≤ n - m,
    { rw [nat.one_le_iff_ne_zero, ne.def, nat.sub_eq_zero_iff_le, not_le],
    exact lt_of_le_of_ne hmn heq,},
    rw [hpm c h1, mul_div_assoc, div_eq_mul_inv, pow_sub₀ _ (ne.symm hc) hmn, mul_assoc,
      mul_comm (f c ^ m)⁻¹, ← mul_assoc (f c ^ n), mul_inv_cancel (pow_ne_zero n (ne.symm hc)),
      one_mul, div_eq_mul_inv] }
end

omit hc hpm hf1

variables (f c)

/-- The limit of the sequence `seminorm_from_const`. -/
def seminorm_from_const_seq_lim (x : R) : ℝ :=
classical.some (real.exists_is_glb (set.range_nonempty (seminorm_from_const_seq c f x))
  (seminorm_from_const_is_bounded c f x))

/-- The real-valued function sending `x ∈ R` to the limit of `(f (x * c^n))/((f c)^n)`. -/
def seminorm_from_const_def : R → ℝ := λ x, seminorm_from_const_seq_lim c f x

include hc hpm hf1

variables {f c}

lemma seminorm_from_const_seq_lim_is_limit (x : R) :
  filter.tendsto ((seminorm_from_const_seq c f x)) filter.at_top
    (𝓝 (seminorm_from_const_seq_lim c f x)) :=
tendsto_at_top_is_glb (seminorm_from_const_seq_antitone hf1 hc hpm x)
  (classical.some_spec ((real.exists_is_glb (set.range_nonempty (seminorm_from_const_seq c f x))
    (seminorm_from_const_is_bounded c f x))))

lemma seminorm_from_const_zero : seminorm_from_const_def c f 0 = 0 :=
tendsto_nhds_unique (seminorm_from_const_seq_lim_is_limit hf1 hc hpm 0)
  (by simpa [seminorm_from_const_seq_zero c (map_zero _)] using tendsto_const_nhds)

lemma seminorm_from_const_is_norm_one_class : seminorm_from_const_def c f 1 = 1 :=
begin
  apply tendsto_nhds_unique_of_eventually_eq (seminorm_from_const_seq_lim_is_limit hf1 hc hpm 1)
    tendsto_const_nhds,
  simp only [filter.eventually_eq, filter.eventually_at_top, ge_iff_le],
  exact ⟨1,  seminorm_from_const_seq_one hc hpm⟩,
end

lemma seminorm_from_const_mul (x y : R) :
  seminorm_from_const_def c f (x * y) ≤
    seminorm_from_const_def c f x * seminorm_from_const_def c f y :=
begin
  have hlim : filter.tendsto (λ n, seminorm_from_const_seq c f (x * y) (2 *n)) filter.at_top
    (𝓝 (seminorm_from_const_seq_lim c f (x * y) )),
  { refine filter.tendsto.comp (seminorm_from_const_seq_lim_is_limit hf1 hc hpm (x * y)) _,
    apply filter.tendsto_at_top_at_top_of_monotone,
    { intros n m hnm, simp only [mul_le_mul_left, nat.succ_pos', hnm], },
    { rintro n, use n, linarith, }},
  apply le_of_tendsto_of_tendsto' hlim (filter.tendsto.mul
    (seminorm_from_const_seq_lim_is_limit hf1 hc hpm x)
    (seminorm_from_const_seq_lim_is_limit hf1 hc hpm y)),
  intro n,
  simp only [seminorm_from_const_seq],
  rw [div_mul_div_comm, ← pow_add, two_mul, div_le_div_right
    (pow_pos (lt_of_le_of_ne (map_nonneg f _) hc) _),
    pow_add, ← mul_assoc, mul_comm (x * y), ← mul_assoc, mul_assoc, mul_comm (c^n)],
  exact map_mul_le_mul f (x * c ^ n) (y * c ^ n),
end

lemma seminorm_from_const_neg (x : R)  :
  seminorm_from_const_def c f (-x) = seminorm_from_const_def c f x  :=
begin
  apply tendsto_nhds_unique_of_eventually_eq (seminorm_from_const_seq_lim_is_limit hf1 hc hpm (-x))
    (seminorm_from_const_seq_lim_is_limit hf1 hc hpm x),
  simp only [filter.eventually_eq, filter.eventually_at_top],
  use 0,
  intros n hn,
  simp only [seminorm_from_const_seq],
  rw [neg_mul, map_neg_eq_map],
end

lemma seminorm_from_const_add (x y : R)  :
  seminorm_from_const_def c f (x + y) ≤
    seminorm_from_const_def c f x +  seminorm_from_const_def c f y :=
begin
  apply le_of_tendsto_of_tendsto' (seminorm_from_const_seq_lim_is_limit hf1 hc hpm (x + y))
    (filter.tendsto.add (seminorm_from_const_seq_lim_is_limit hf1 hc hpm x)
    (seminorm_from_const_seq_lim_is_limit hf1 hc hpm y)),
  intro n,
  have h_add : f ((x + y) * c ^ n) ≤ (f (x * c ^ n)) + (f (y * c ^ n)),
  { rw add_mul, exact map_add_le_add f _ _ },
  simp only [seminorm_from_const_seq],
  rw div_add_div_same,
  exact (div_le_div_right (pow_pos (lt_of_le_of_ne (map_nonneg f _) hc) _)).mpr h_add,
end

/-- The function `seminorm_from_const` is a `ring_seminorm` on `R`. -/
def seminorm_from_const :
  ring_seminorm R  :=
{ to_fun    := seminorm_from_const_def c f,
  map_zero' := seminorm_from_const_zero hf1 hc hpm,
  add_le'   := seminorm_from_const_add hf1 hc hpm,
  neg'      := seminorm_from_const_neg hf1 hc hpm,
  mul_le'   := seminorm_from_const_mul hf1 hc hpm }

lemma seminorm_from_const_is_norm_le_one_class :
  seminorm_from_const hf1 hc hpm 1 ≤ 1 :=
le_of_eq (seminorm_from_const_is_norm_one_class hf1 hc hpm)

lemma seminorm_from_const_is_nonarchimedean (hna : is_nonarchimedean f) :
  is_nonarchimedean (seminorm_from_const hf1 hc hpm)  :=
begin
  intros x y,
  apply le_of_tendsto_of_tendsto' (seminorm_from_const_seq_lim_is_limit hf1 hc hpm (x + y))
    (filter.tendsto.max (seminorm_from_const_seq_lim_is_limit hf1 hc hpm x)
    (seminorm_from_const_seq_lim_is_limit hf1 hc hpm y)),
  intro n,
  have hmax : f ((x + y) * c ^ n) ≤ max (f (x * c ^ n)) (f (y * c ^ n)),
  { rw add_mul, exact hna _ _ },
  rw le_max_iff at hmax ⊢,
  cases hmax; [left, right];
  exact (div_le_div_right (pow_pos (lt_of_le_of_ne (map_nonneg f c) hc) _)).mpr hmax,
end

lemma seminorm_from_const_is_pow_mult : is_pow_mul (seminorm_from_const hf1 hc hpm) :=
begin
  intros x m hm,
  simp only [seminorm_from_const],
  have hpow := filter.tendsto.pow (seminorm_from_const_seq_lim_is_limit hf1 hc hpm x) m,
  have hlim : filter.tendsto (λ n, seminorm_from_const_seq c f (x^m) (m*n)) filter.at_top
    (𝓝 (seminorm_from_const_seq_lim c f (x^m) )),
  { refine filter.tendsto.comp (seminorm_from_const_seq_lim_is_limit hf1 hc hpm (x^m)) _,
    apply filter.tendsto_at_top_at_top_of_monotone,
    { intros n k hnk, exact mul_le_mul_left' hnk m, },
    { rintro n, use n, exact le_mul_of_one_le_left' hm, }},
  apply tendsto_nhds_unique hlim,
  convert filter.tendsto.pow (seminorm_from_const_seq_lim_is_limit hf1 hc hpm x) m,
  ext n,
  simp only [seminorm_from_const_seq],
  rw [div_pow, ← hpm _ hm, ← pow_mul, mul_pow, ← pow_mul, mul_comm m n],
end

lemma seminorm_from_const_le_seminorm (x : R) : seminorm_from_const hf1 hc hpm x ≤ f x :=
begin
  apply le_of_tendsto (seminorm_from_const_seq_lim_is_limit hf1 hc hpm x),
  simp only [filter.eventually_at_top, ge_iff_le],
  use 1,
  rintros n hn,
  apply le_trans ((div_le_div_right (pow_pos (lt_of_le_of_ne (map_nonneg f c) hc) _)).mpr
    (map_mul_le_mul _ _ _)),
  rw [hpm c hn, mul_div_assoc, div_self (pow_ne_zero n hc.symm), mul_one],
end

lemma seminorm_from_const_apply_of_is_mult {x : R} (hx : ∀ y : R, f (x * y) = f x * f y) :
  seminorm_from_const hf1 hc hpm x = f x :=
begin
  have hlim : filter.tendsto (seminorm_from_const_seq c f x) filter.at_top (𝓝 (f x)),
  { have hseq : seminorm_from_const_seq c f x = λ n, f x,
    { ext n,
      by_cases hn : n = 0,
      { simp only [seminorm_from_const_seq],
        rw [hn, pow_zero, pow_zero, mul_one, div_one], },
      { simp only [seminorm_from_const_seq],
        rw [hx (c ^n), hpm _ (nat.one_le_iff_ne_zero.mpr hn), mul_div_assoc,
          div_self (pow_ne_zero n hc.symm), mul_one], }},
    simpa [hseq] using tendsto_const_nhds, },
  exact tendsto_nhds_unique (seminorm_from_const_seq_lim_is_limit hf1 hc hpm x) hlim,
end

lemma seminorm_from_const_is_mul_of_is_mul {x : R} (hx : ∀ y : R, f (x * y) = f x * f y) (y : R) :
  seminorm_from_const hf1 hc hpm (x * y) =
    seminorm_from_const hf1 hc hpm x * seminorm_from_const hf1 hc hpm y :=
begin
  have hlim : filter.tendsto (seminorm_from_const_seq c f (x * y)) filter.at_top
    (𝓝 (seminorm_from_const hf1 hc hpm x * seminorm_from_const hf1 hc hpm y)),
  { rw seminorm_from_const_apply_of_is_mult hf1 hc hpm hx,
    have hseq : seminorm_from_const_seq c f (x * y) = λ n, f x * seminorm_from_const_seq c f y n,
    { ext n,
      simp only [seminorm_from_const_seq],
      rw [mul_assoc, hx, mul_div_assoc], },
    simpa [hseq]
      using filter.tendsto.const_mul _(seminorm_from_const_seq_lim_is_limit hf1 hc hpm y) },
  exact tendsto_nhds_unique (seminorm_from_const_seq_lim_is_limit hf1 hc hpm (x * y)) hlim,
end

lemma seminorm_from_const_apply_c : seminorm_from_const hf1 hc hpm c = f c :=
begin
  have hlim : filter.tendsto (seminorm_from_const_seq c f c) filter.at_top (𝓝 (f c)),
  { have hseq : seminorm_from_const_seq c f c = λ n, f c,
    { ext n,
      simp only [seminorm_from_const_seq],
      rw [← pow_succ, hpm _ le_add_self, pow_succ, mul_div_assoc, div_self (pow_ne_zero n hc.symm),
        mul_one], },
    simpa [hseq] using tendsto_const_nhds },
    exact tendsto_nhds_unique (seminorm_from_const_seq_lim_is_limit hf1 hc hpm c) hlim,
end

lemma seminorm_from_const_c_is_mul (x : R) :
  seminorm_from_const hf1 hc hpm (c * x) =
    seminorm_from_const hf1 hc hpm c * seminorm_from_const hf1 hc hpm x :=
begin
  have hlim : filter.tendsto (λ n, seminorm_from_const_seq c f x (n + 1)) filter.at_top
    (𝓝 (seminorm_from_const_seq_lim c f x)),
  { refine filter.tendsto.comp (seminorm_from_const_seq_lim_is_limit hf1 hc hpm x) _,
    apply filter.tendsto_at_top_at_top_of_monotone,
    { intros n m hnm,
      exact add_le_add_right hnm 1, },
    { rintro n, use n, linarith, }},
  rw seminorm_from_const_apply_c hf1 hc hpm,
  apply tendsto_nhds_unique (seminorm_from_const_seq_lim_is_limit hf1 hc hpm (c * x)),
  have hterm : seminorm_from_const_seq c f (c * x) =
    (λ n, f c * (seminorm_from_const_seq c f x (n + 1))),
  { simp only [seminorm_from_const_seq],
    ext n,
    rw [mul_comm c, pow_succ, pow_succ, mul_div, div_eq_mul_inv _ (f c * f c ^ n), mul_inv,
      ← mul_assoc, mul_comm (f c), mul_assoc _ (f c), mul_inv_cancel hc.symm,
      mul_one, mul_assoc, div_eq_mul_inv] },
  simpa [hterm] using filter.tendsto.mul tendsto_const_nhds hlim,
end

end ring

section field

variables {K : Type*} [field K] (k : K) {g : ring_seminorm K} (hg1 : g 1 ≤ 1)
  (hg_k : g k ≠ 0) (hg_pm : is_pow_mul g)

/-- If `K` is a field, the function `seminorm_from_const` is a `ring_norm` on `K`. -/
def seminorm_from_const_ring_norm_of_field : ring_norm K :=
g.to_ring_norm (ring_seminorm.ne_zero_iff.mpr ⟨k, hg_k⟩)

end field

end seminorm_from_const
