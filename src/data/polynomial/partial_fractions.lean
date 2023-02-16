/-
Copyright (c) Sidharth Hariharan. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kevin Buzzard, Sidharth Hariharan
-/
import data.polynomial.div
import data.zmod.basic
import logic.function.basic
import ring_theory.localization.fraction_ring
import tactic.field_simp
import tactic.linear_combination

/-!

# Partial fractions

These results were formalised by the Xena Project, at the suggestion
of Patrick Massot.


# The main theorem

* `div_eq_quo_add_sum_rem_div`: General partial fraction decomposition theorem for polynomials over
  an integral domain R :
  If f, g₁, g₂, ..., gₙ ∈ R[X] and the gᵢs are all monic and pairwise coprime, then ∃ q, r₁, ..., rₙ
  ∈ R[X] such that f / g₁g₂...gₙ = q + r₁/g₁ + ... + rₙ/gₙ and for all i, deg(rᵢ) < deg(gᵢ).

* The result is formalized here in slightly more generality, using finsets. That is, if ι is an
  arbitrary index type, g denotes a map from ι to R[X], and if s is an arbitrary finite subset of ι,
  with g i monic for all i ∈ s and for all i,j ∈ s, i ≠ j → g i is coprime to g j, then we have
  ∃ q ∈ R[X] , r : ι → R[X] such that ∀ i ∈ s, deg(r i) < deg(g i) and
  f / ∏ g i = q + ∑ (r i) / (g i), where the product and sum are over s.

* The proof is done by proving the two-denominator case and then performing finset induction for an
  arbitrary (finite) number of denominators.

## Scope for Expansion

* Proving uniqueness of the decomposition

-/


variables (R : Type) [comm_ring R] [is_domain R]

open_locale polynomial

open polynomial

variables (K : Type) [field K] [algebra R[X] K] [is_fraction_ring R[X] K]

section two_denominators

/--
Let R be an integral domain and f, g₁, g₂ ∈ R[X]. Let g₁ and g₂ be monic and coprime.
Then, ∃ q, r₁, r₂ ∈ R[X] such that f / g₁g₂ = q + r₁/g₁ + r₂/g₂ and deg(r₁) < deg(g₁) and
deg(r₂) < deg(g₂).
-/
lemma div_eq_quo_add_rem_div_add_rem_div (f : R[X]) {g₁ g₂ : R[X]}
  (hg₁ : g₁.monic) (hg₂ : g₂.monic) (hcoprime : is_coprime g₁ g₂) :
  ∃ q r₁ r₂ : R[X], r₁.degree < g₁.degree ∧ r₂.degree < g₂.degree ∧
  (↑f : K) / (↑g₁ * ↑g₂) = ↑q + ↑r₁ / ↑g₁ + ↑r₂ / ↑g₂ :=
begin
  rcases hcoprime with ⟨c, d, hcd⟩,
  refine ⟨(f * d) /ₘ g₁ + (f * c) /ₘ g₂, (f * d) %ₘ g₁, (f * c) %ₘ g₂,
    (degree_mod_by_monic_lt _ hg₁), (degree_mod_by_monic_lt _ hg₂), _⟩,
  have hg₁' : (↑g₁ : K) ≠ 0,
  { norm_cast, exact hg₁.ne_zero_of_ne zero_ne_one, },
  have hg₂' : (↑g₂ : K) ≠ 0,
  { norm_cast, exact hg₂.ne_zero_of_ne zero_ne_one, },
  have hfc := mod_by_monic_add_div (f * c) hg₂,
  have hfd := mod_by_monic_add_div (f * d) hg₁,
  field_simp,
  norm_cast,
  linear_combination (-1) * f * hcd + (-1) * g₁ * hfc + (-1) * g₂ * hfd,
end

end two_denominators

section n_denominators

open_locale big_operators classical

/--
Let R be an integral domain and f ∈ R[X]. Let s be a finite index set.
Then, a fraction of the form f / ∏ (g i) can be rewritten as q + ∑ (r i) / (g i), where
deg(r i) < deg(g i), provided that the g i are monic and pairwise coprime.
-/
lemma div_eq_quo_add_sum_rem_div (f : R[X]) {ι : Type*} {g : ι → R[X]} {s : finset ι}
  (hg : ∀ i ∈ s, (g i).monic)
  (hcop : set.pairwise ↑s (λ i j, is_coprime (g i) (g j))) :
  ∃ (q : R[X]) (r : ι → R[X]), (∀ i ∈ s, (r i).degree < (g i).degree) ∧
  (↑f : K) / ∏ i in s, ↑(g i) = ↑q + ∑ i in s, ↑(r i) / ↑(g i) :=
begin
  induction s using finset.induction_on with a b hab Hind f generalizing f,
  { refine ⟨f, (λ (i : ι), (0 : R[X])), λ i, _, by simp⟩,
    rintro ⟨⟩, },
  obtain ⟨q₀, r₁, r₂, hdeg₁, hdeg₂, (hf : (↑f : K) / _ = _)⟩ :=
    div_eq_quo_add_rem_div_add_rem_div R K f
    (_ : monic (g a))
    (_ : monic ∏ (i : ι) in b, (g i))
    _,
  { obtain ⟨q, r, hrdeg, IH⟩ := Hind (λ i hi, hg i (finset.mem_insert_of_mem hi))
      (set.pairwise.mono ( finset.coe_subset.2 $ λ i hi, finset.mem_insert_of_mem hi) hcop) r₂,
    refine ⟨q₀ + q, λ i, if i = a then r₁ else r i, _, _⟩,
    { intro i,
      split_ifs with h1,
      { cases h1,
        intro _,
        exact hdeg₁, },
      { intro hi,
        exact hrdeg i (finset.mem_of_mem_insert_of_ne hi h1), }, },
    norm_cast at ⊢ hf IH,
    rw [finset.prod_insert hab, hf, IH, finset.sum_insert hab, if_pos rfl],
    transitivity (↑(q₀ + q : R[X]) : K) + (↑r₁ / ↑(g a) + ∑ (i : ι) in b, ↑(r i) / ↑(g i)),
    { push_cast, ring, },
    congr' 2,
    refine finset.sum_congr rfl (λ x hxb, _),
    rw if_neg,
    rintro rfl,
    exact hab hxb },
  { exact hg a (b.mem_insert_self a), },
  { exact monic_prod_of_monic _ _ (λ i hi, hg i (finset.mem_insert_of_mem hi)), },
  { refine is_coprime.prod_right (λ i hi, hcop (finset.mem_coe.2 (b.mem_insert_self a))
     (finset.mem_coe.2 (finset.mem_insert_of_mem hi)) _),
    rintro rfl,
    exact hab hi, },
end

-- To be removed
lemma zero_eq_quo_add_sum_rem_div_unique {ι : Type*} (s : finset ι) {g : ι → R[X]}
  (hg : ∀ i ∈ s, (g i).monic) (hcop : (s : set ι).pairwise (λ i j, is_coprime (g i) (g j)))
  (q q' : R[X]) (r r' : ι → R[X]) (hdeg : ∀ i, (r i).degree < (g i).degree)
  (hdeg' : ∀ i, (r' i).degree < (g i).degree)
  (hsum : (0 : K) = ↑q + ∑ i in s, ↑(r i) / ↑(g i))
  (hsum' : (0 : K) = ↑q' + ∑ i in s, ↑(r' i) / ↑(g i)) :
    q = q' ∧ ∀ i ∈ s, r i = r' i :=
begin
  have hsimp : (0 : K) = (0 : K) / (∏ i in s, ↑(g i)) := by rw [zero_div],
  rw [hsimp, div_eq_iff _] at hsum hsum',
  { simp only [add_mul, finset.sum_mul] at hsum hsum',

    sorry, },
  { norm_cast,
    exact (monic_prod_of_monic s g (λ i hi, hg i hi)).ne_zero },
  { norm_cast,
    exact (monic_prod_of_monic s g (λ i hi, hg i hi)).ne_zero },
end

-- Dividing by a term in a product inside a sum
lemma finset.sum_prod_div {s : finset R[X]} (hnz : ∀ (n : R[X]), n ∈ s → n ≠ 0 ) :
  ∑ n in s, (↑ (∏ k in s, k) / ↑ n) = ∑ n in s, (∏ k in s.erase n, (↑ k : K) ) :=
begin
  apply finset.sum_congr,
  { refl, },
  { intros x hx,
    rw div_eq_iff _,
    { rw s.prod_erase_mul _,
      norm_cast,
      exact hx },
    { norm_cast,
      exact hnz x hx, } }
end

.

lemma zero_eq_quo_add_sum_rem_div_zero {ι : Type*} (s : finset ι) {g : ι → R[X]}
  (hg : ∀ i ∈ s, (g i).monic) (hcop : (s : set ι).pairwise (λ i j, is_coprime (g i) (g j)))
  (q q' : R[X]) (r r' : ι → R[X]) (hdeg : ∀ i, (r i).degree < (g i).degree)
  (hsum : (0 : K) = ↑q + ∑ i in s, ↑(r i) / ↑(g i)) :
    q = 0 ∧ ∀ i ∈ s, r i = 0 :=
begin
  have hzero : (0 : K) = (0 : K) / (∏ i in s, ↑(g i)) := by rw [zero_div],
  rw [hzero, div_eq_iff _] at hsum,
  { simp only [add_mul, finset.sum_mul] at hsum,
    let h : ι → ι → R[X] := (λ i j , if i = j then r j else g j),
    have hdivprod : ∀ x ∈ s, (g x) ∣ (∏ i in s, (g i)) :=
      λ x, finset.dvd_prod_of_mem (λ (x : ι), g x),
    have hpsimp : ∀ x ∈ s, (∏ i in s, ↑ (g i)) / ↑ (g x) = ∏ i in s.filter (λ j, j ≠ x) , ↑ (g i),
    { intros x hxs,
      refine unit.ext,
      -- what has all this other stuff got to do with anything...
      exact div_inv_monoid.to_has_div unit,
      exact comm_ring.to_comm_monoid unit,
      exact algebra_map.has_lift_t R[X] unit,
      exact algebra_map.has_lift_t R[X] unit,
      exact comm_ring.to_comm_monoid unit,
      exact algebra_map.has_lift_t R[X] unit },
    --rw ← finset.prod_apply at hsum,
    --field_simp [hdivprod, hsimp, (λ (x : ι) (hxs : x ∈ s), (hg x hxs).ne_zero)] at hsum,
    field_simp at hsum,
    --rw finset.p
    -- ring_nf at hsum,
    --simp [mul_add, add_mul] at hsum,
    --rw finset.prod_filter finset.dvd_prod_of_mem (λ (x : ι), g x) g at hsum,
    sorry,
     },
  { norm_cast,
    exact (monic_prod_of_monic s g (λ i hi, hg i hi)).ne_zero },
end

#check finsupp

-- Will eventually extend the zero case
lemma div_eq_quo_add_sum_rem_div_unique' {f : R[X]} {ι : Type*} (s : finset ι) {g : ι → R[X]}
  (hg : ∀ i ∈ s, (g i).monic) (hcop : (s : set ι).pairwise (λ i j, is_coprime (g i) (g j)))
  (q q' : R[X]) (r r' : ι → R[X]) (hdeg : ∀ i, (r i).degree < (g i).degree)
  (hdeg' : ∀ i, (r' i).degree < (g i).degree)
  (hf : (↑f : K) / ∏ i in s, ↑(g i) = ↑q + ∑ i in s, ↑(r i) / ↑(g i))
  (hf' : (↑f : K) / ∏ i in s, ↑(g i) = ↑q' + ∑ i in s, ↑(r' i) / ↑(g i)) :
    q = q' ∧ ∀ i ∈ s, r i = r' i :=
begin
  -- cases approach discarded in favour of separate lemmas. code below can maybe be reused,
  -- but will be removed eventually...
  cases em (f = 0),
  { -- How do we clear denominators?
    rw div_eq_iff _ at hf hf',
    { simp only [add_mul, finset.sum_mul, h] at hf hf',
      push_cast at hf hf',

      have hgr : ∀ i : ι, i ∈ s → g i ∣ r i,
      { intros i his,
        have hg0 : (g i) ∣ 0 := dvd_zero ↑(g i),
        sorry },
      sorry },
    { norm_cast,
      exact (monic_prod_of_monic s g hg).ne_zero },
    { norm_cast,
      exact (monic_prod_of_monic s g hg).ne_zero } },
  {
    sorry }
end

-- To be removed (does this even make sense?!!?!?!)
lemma div_eq_quo_add_sum_rem_div_unique {f : R[X]} {ι : Type*} (s : finset ι) {g : ι → R[X]}
  (hg : ∀ i ∈ s, (g i).monic) (hcop : (s : set ι).pairwise (λ i j, is_coprime (g i) (g j)))
  (q : R[X]) (r : ι → R[X]) (hdeg : ∀ i, (r i).degree < (g i).degree)
  (hf : (↑f : K) / ∏ i in s, ↑(g i) = ↑q + ∑ i in s, ↑(r i) / ↑(g i)) :
    q = (div_eq_quo_add_sum_rem_div R K f hg hcop).some ∧
    ∀ i ∈ s, r i = (div_eq_quo_add_sum_rem_div R K f hg hcop).some_spec.some i :=
begin
  let q₀ := (div_eq_quo_add_sum_rem_div R K f hg hcop).some,
  let r₀ := (div_eq_quo_add_sum_rem_div R K f hg hcop).some_spec.some,
  obtain ⟨hdeg₀, hf₀⟩ : (∀ i ∈ s, (r₀ i).degree < ((λ (i : ι), g i) i).degree) ∧
    ↑f / ∏ i in s, ↑((λ (i : ι), g i) i) = ↑q₀ + ∑ i in s, ↑(r₀ i) / ↑((λ (i : ι), g i) i) :=
    (div_eq_quo_add_sum_rem_div R K f hg hcop).some_spec.some_spec,
  change q = q₀ ∧ ∀ i ∈ s, r i = r₀ i,

  induction s using finset.induction_on with a b hab Hind f generalizing f,
  { split,
    { simp only [finset.prod_empty, div_one, finset.sum_empty, add_zero,
                is_fraction_ring.coe_inj] at hf₀,
      rw hf₀ at hf,
      simp only [finset.prod_empty, div_one, finset.sum_empty,
                add_zero, is_fraction_ring.coe_inj] at hf,
      exact hf.symm, },
    { simp only [finset.not_mem_empty, is_empty.forall_iff, implies_true_iff], }, },
  { obtain ⟨q', r₁, r₂, hdeg₁, hdeg₂, (hf' : (↑f : K) / _ = _)⟩ :=
    div_eq_quo_add_rem_div_add_rem_div R K f
    (_ : monic (g a))
    (_ : monic ∏ (i : ι) in b, (g i))
    _,
    { specialize Hind (λ i hi, hg i (finset.mem_insert_of_mem hi)),
      have myhcop : (b : set ι).pairwise (λ (i j : ι), is_coprime (g i) (g j)) :=
      λ x hx y hy hxy, hcop (finset.mem_insert_of_mem hx) (finset.mem_insert_of_mem hy) hxy,

      --field_simp at hf' hf₀ hf,

      --specialize Hind (λ i hi, hg i (finset.mem_insert_of_mem hi)),
      sorry },
    { exact hg a (b.mem_insert_self a), },
    { exact monic_prod_of_monic _ _ (λ i hi, hg i (finset.mem_insert_of_mem hi)), },
    { refine is_coprime.prod_right (λ i hi, hcop (finset.mem_coe.2 (b.mem_insert_self a))
      (finset.mem_coe.2 (finset.mem_insert_of_mem hi)) _),
      rintro rfl,
      exact hab hi, }, }
  -- split,
  -- { --rw hf at hf₀,
  --   have htriv : g = λ (i : ι), g i := rfl,
  --   rw ← htriv at hf₀,

  --   sorry },
  -- {
  --   sorry },
end

end n_denominators
