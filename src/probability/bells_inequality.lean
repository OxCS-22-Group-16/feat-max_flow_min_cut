/-
Copyright (c) 2022 Ian Jauslin and Alex Kontorovich. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Jauslin, Alex Kontorovich
-/
import probability.conditional_probability
import measure_theory.measure.probability_measure

/-!
# Bell's Inequality

This file proves Bell's Inequality in several forms.

## Main Statements

* `bells_inequality` says ...
-/

noncomputable theory

open_locale ennreal probability_theory

open measure_theory measurable_space probability_theory

namespace probability_theory

universe u

variables [has_add ℤˣ] [has_sub ℤˣ]

-- for some reason, this breaks everything
--variables [add_group ℝ]

section preliminaries

lemma pm_one_space_vals (r : ℤˣ) :
  (r:ℝ) = 1 ∨ (r:ℝ) = -1 :=
begin
  cases int.units_eq_one_or r with hh hh;
  rw hh; simp,
end

lemma pm_one_space_le (r : ℤˣ) :
  (r:ℝ) ≤ 1 :=
begin
  cases int.units_eq_one_or r with hh hh;
  rw hh; simp,
end

lemma pm_one_space_ge (r : ℤˣ) :
  (r:ℝ) ≥ -1 :=
begin
  cases int.units_eq_one_or r with hh hh;
  rw hh; simp,
end

lemma pm_one_space_ge_le (r : ℤˣ) :
  |(r:ℝ)| ≤ 1 :=
begin
  apply abs_le.mpr,
  split,
  apply pm_one_space_ge r,
  apply pm_one_space_le r,
end

-- the CHSH inequality proved for intgers that are +/-1
lemma CHSH_inequality_of_int_units
  (A₀ A₁ B₀ B₁ : ℤˣ)
  :
  (A₀:ℝ) * B₀ + A₀ * B₁ + A₁ * B₀ - A₁ * B₁ ≤ 2
  :=
  begin
    -- split into cases for A₀ and A₁
    cases pm_one_space_vals A₀ with hp0 hm0,
    { cases pm_one_space_vals A₁ with hp1 hm1,
      { rw hp0,
        rw hp1,
        simp only [one_mul],
        ring_nf,
        simp only [mul_le_iff_le_one_right, zero_lt_bit0, zero_lt_one],
        exact pm_one_space_le B₀,
      },
      { rw hp0,
        rw hm1,
        simp only [one_mul],
        ring_nf,
        simp only [mul_le_iff_le_one_right, zero_lt_bit0, zero_lt_one],
        exact pm_one_space_le B₁,
      },
    },
    { cases pm_one_space_vals A₁ with hp1 hm1,
      { rw hm0,
        rw hp1,
        simp only [neg_mul, one_mul, neg_add_cancel_comm, tsub_le_iff_right],
        -- group B₁'s together
        apply le_of_sub_nonneg,
        ring_nf,
        apply le_add_of_sub_left_le,
        ring_nf,
        -- put minus sign on other side
        apply neg_le_of_neg_le,
        have tpos: ((2:ℝ) >0),
        { simp only [gt_iff_lt, zero_lt_bit0, zero_lt_one],
        },
        -- divide by 2
        have almost : (-2)/2 ≤ (B₁:ℝ) ,
        { simp only [neg_div_self, ne.def, bit0_eq_zero, one_ne_zero, not_false_iff],
          exact pm_one_space_ge B₁,
        },
        exact (div_le_iff' tpos).mp almost,
      },
      { rw hm0,
        rw hm1,
        simp only [neg_mul, one_mul, sub_neg_eq_add],
        ring_nf,
        -- put minus sign on other side
        apply neg_le_of_neg_le,
        have tpos: ((2:ℝ) >0),
        { simp only [gt_iff_lt, zero_lt_bit0, zero_lt_one],
        },
        -- divide by 2
        have almost : (-2)/2 ≤ (B₀:ℝ) ,
        { simp only [neg_div_self, ne.def, bit0_eq_zero, one_ne_zero, not_false_iff],
          exact pm_one_space_ge B₀,
        },
        exact (div_le_iff' tpos).mp almost,
      },
    }
  end


lemma integrable_mul_of_units_int
  {Ω : Type u} [measurable_space Ω]
  (ℙ : probability_measure Ω)
  (Za Zb : Ω → ℤˣ)
  (sm_a : strongly_measurable (λ ω , (Za ω : ℝ)))
  (sm_b : strongly_measurable (λ ω , (Zb ω : ℝ)))
  :
  integrable (λ ω:Ω , (Za ω :ℝ) * Zb ω) (ℙ:measure Ω)
  :=
  begin
    dsimp [integrable],
    split,
    exact strongly_measurable.ae_strongly_measurable (strongly_measurable.mul sm_a sm_b),
    { apply has_finite_integral_of_bounded _,
      apply is_probability_measure.to_is_finite_measure (ℙ:measure Ω),
      use (1:ℝ),
      apply ae_of_all,
      intro a,
      simp,
      apply mul_le_one (pm_one_space_ge_le (Za a)) _ (pm_one_space_ge_le (Zb a)),
      exact abs_nonneg (Zb a:ℝ),
    },
  end
lemma integrable_mul_of_units_int_neg
  {Ω : Type u} [measurable_space Ω]
  (ℙ : probability_measure Ω)
  (Za Zb : Ω → ℤˣ)
  (sm_a : strongly_measurable (λ ω , (Za ω : ℝ)))
  (sm_b : strongly_measurable (λ ω , (Zb ω : ℝ)))
  :
  integrable (λ ω:Ω , -(Za ω :ℝ) * Zb ω) (ℙ:measure Ω)
  :=
  begin
    dsimp [integrable],
    split,
    have : strongly_measurable (λ ω , (-Za ω:ℝ)):= strongly_measurable.neg (sm_a),
    exact strongly_measurable.ae_strongly_measurable (strongly_measurable.mul this sm_b),
    { apply has_finite_integral_of_bounded _,
      apply is_probability_measure.to_is_finite_measure (ℙ:measure Ω),
      use (1:ℝ),
      apply ae_of_all,
      intro a,
      simp,
      rw abs_mul,
      apply mul_le_one (pm_one_space_ge_le (Za a)) _ (pm_one_space_ge_le (Zb a)),
      exact abs_nonneg (Zb a:ℝ),
    },
  end


end preliminaries

-- Bell's inequality: 1964 version
theorem bells_inequality_1964 
  {Ω : Type u} [measurable_space Ω]
  (ℙ : probability_measure Ω)
  -- ℕ should be replaced with {1,2,3}
  (Za : ℕ → Ω → ℤˣ)
  (Zb : ℕ → Ω → ℤˣ)
  (Za_measurable : ∀ i:ℕ , strongly_measurable (λ ω , (Za i ω : ℝ)))
  (Zb_measurable : ∀ i:ℕ , strongly_measurable (λ ω , (Zb i ω : ℝ)))
  (anticorrelation : ∀ i:ℕ , ∫ ω , (Za i ω : ℝ)*(Zb i ω) ∂(ℙ:measure Ω) = -1)
  :
  | (∫ ω, (Za 1 ω : ℝ) * (Zb 2 ω) ∂(ℙ:measure Ω) ) 
    - (∫ ω, (Za 1 ω : ℝ) * (Zb 3 ω) ∂(ℙ:measure Ω) ) |
    ≤ 1 + (∫ ω, (Za 2 ω : ℝ) * (Zb 3 ω) ∂(ℙ:measure Ω) )
  :=

begin
  -- first do upper bound
  have : 
    (∫ ω, (Za 1 ω : ℝ) * (Zb 2 ω) ∂(ℙ:measure Ω) ) 
    - (∫ ω, (Za 1 ω : ℝ) * (Zb 3 ω) ∂(ℙ:measure Ω) )  
    ≤ 1 + (∫ ω, (Za 2 ω : ℝ) * (Zb 3 ω) ∂(ℙ:measure Ω) ),
  { 

    let f := λ ω:Ω , -(Za 2 ω :ℝ)*(Zb 2 ω) - (Za 2 ω)*(Zb 3 ω) 
                        + (Za 1 ω)*(Zb 2 ω) - (Za 1 ω)*(Zb 3 ω) - 2,

    have ineq : ∀ ω: Ω, f ω ≤ 0 ,
    { intro ω,
      dsimp only [f],
      -- will be sent to CHSH_inquality_of_int_units
      set a:=- (Za 2 ω),
      -- lift opposites
      have : (Za 2 ω : ℝ) = -(a:ℝ) ,
      { simp only [coe_coe, units.coe_neg, int.cast_neg, neg_neg],
      },
      rw this,
      -- get rid of first - -
      simp only [neg_neg],
      -- get rid of second - -
      have : (-a:ℝ)*(Zb 3 ω) = -(a*(Zb 3 ω):ℝ) := neg_mul _ _,
      rw this,
      simp only [sub_neg_eq_add],

      -- need to turn x<=2 to x-2<=0
      exact sub_nonpos_of_le (CHSH_inequality_of_int_units a (Za 1 ω) (Zb 2 ω) (Zb 3 ω)),
    },

    -- integrate chsh
    have int_chsh : ∫ ω , f ω ∂(ℙ:measure Ω) ≤ 0 := integral_nonpos ineq,
    -- expand definition of f
    dsimp [f] at int_chsh,

    have split_int : 
    (∫ ω, -(Za 2 ω : ℝ) * (Zb 2 ω) ∂(ℙ:measure Ω) ) 
    - (∫ ω, (Za 2 ω : ℝ) * (Zb 3 ω) ∂(ℙ:measure Ω) ) 
    + (∫ ω, (Za 1 ω : ℝ) * (Zb 2 ω) ∂(ℙ:measure Ω) )  
    - (∫ ω, (Za 1 ω : ℝ) * (Zb 3 ω) ∂(ℙ:measure Ω) )  
    - (∫ ω, 2 ∂(ℙ:measure Ω) )  
    ≤ 0,
    {
      -- prove all the required integrabilities
      let f1 := (λ ω , -(Za 2 ω : ℝ) * (Zb 2 ω)),
      let f2 := (λ ω , (Za 2 ω : ℝ) * (Zb 3 ω)),
      let f3 := (λ ω , (Za 1 ω : ℝ) * (Zb 2 ω)),
      let f4 := (λ ω , (Za 1 ω : ℝ) * (Zb 3 ω)),
      have i_1: integrable f1 (ℙ:measure Ω) := integrable_mul_of_units_int_neg ℙ (Za 2) (Zb 2) (Za_measurable 2) (Zb_measurable 2),
      have i_2: integrable f2 (ℙ:measure Ω) := integrable_mul_of_units_int ℙ (Za 2) (Zb 3) (Za_measurable 2) (Zb_measurable 3),
      have i_3: integrable f3 (ℙ:measure Ω) := integrable_mul_of_units_int ℙ (Za 1) (Zb 2) (Za_measurable 1) (Zb_measurable 2),
      have i_4: integrable f4 (ℙ:measure Ω) := integrable_mul_of_units_int ℙ (Za 1) (Zb 3) (Za_measurable 1) (Zb_measurable 3),
      dsimp [f1] at i_1,
      dsimp [f2] at i_2,
      dsimp [f3] at i_3,
      dsimp [f4] at i_4,

      have i_12: integrable (λ ω , f1 ω - f2 ω) (ℙ:measure Ω) := integrable.sub i_1 i_2,
      have i_123: integrable (λ ω , f1 ω - f2 ω + f3 ω) (ℙ:measure Ω) := integrable.add i_12 i_3,
      have i_1234: integrable (λ ω , f1 ω - f2 ω + f3 ω - f4 ω) (ℙ:measure Ω) := integrable.sub i_123 i_4,
      dsimp [f1,f2,f3,f4] at i_1234,
      dsimp [f1,f2,f3] at i_123,
      dsimp [f1,f2] at i_12,

      have i_c: integrable (λ ω:Ω, (2:ℝ)) (ℙ:measure Ω) := integrable_const _,

      rw [integral_sub i_1234 i_c] at int_chsh,
      rw [integral_sub i_123 i_4] at int_chsh,
      rw [integral_add i_12 i_3] at int_chsh,
      rw [integral_sub i_1 i_2] at int_chsh,

      exact int_chsh,
    },
    
    have anticor : ∫ ω, -(Za 2 ω : ℝ) * (Zb 2 ω) ∂(ℙ:measure Ω) = 1,
    {
      have : ∫ ω, -(Za 2 ω : ℝ) * (Zb 2 ω) ∂(ℙ:measure Ω) = ∫ ω, -((Za 2 ω : ℝ) * (Zb 2 ω)) ∂(ℙ:measure Ω) ,
      { simp only [neg_mul], },
      rw this,
      rw integral_neg _,
      rw anticorrelation,
      ring_nf,
    },

    have int_2 : ∫ ω, (2:ℝ) ∂(ℙ:measure Ω) = 2 ,
    { simp only [integral_const, measure_univ, ennreal.one_to_real, algebra.id.smul_eq_mul, one_mul], },
    rw [anticor,int_2] at split_int,
    ring_nf at split_int,
    apply sub_nonpos.mp,
    ring_nf,
    linarith,
    -- almost done!
    sorry,
  },

  sorry,
end


-- Bell's inequality: 1971 version
theorem bells_inequality_1971 {Ω : Type u} {m : measurable_space Ω}
  -- parameter space for experiments
  {Aa Ab : Type u}
  -- shared variable space
  {Λ : Type u}
  {mm : measurable_space Λ}

  -- random variables
  (Xa : Ω → ℤˣ)
  (Xb : Ω → ℤˣ)
  (Xa_measurable : measurable Xa)
  (Xb_measurable : measurable Xb)

  -- probability distribution on outcomes of experiments that depends on two parameters α∈Aa and β∈Ab
  (ℙ : Aa → Ab → (probability_measure Ω))
  -- factorized probabilities
  (ℙa : Aa → (probability_measure Ω))
  (ℙb : Ab → (probability_measure Ω))
  -- probability distribution on shared variable
  (P_lam : probability_measure Ω)

  -- shared variable
  (lam : Ω → Λ)
  (lam_measurable : measurable lam)

  -- locality assumption
  (locality : ∀ lam_val:Λ, ∀ α:Aa, ∀ β:Ab , ∀ ω : set Ω ,
    ((probability_theory.cond ((ℙ α β):measure Ω) (lam ⁻¹' {lam_val})) ω) = 
      ((probability_theory.cond ((ℙa α):measure Ω) (lam ⁻¹' {lam_val})) ω)*
      ((probability_theory.cond ((ℙb β):measure Ω) (lam ⁻¹' {lam_val})) ω )
  )
  :
  ∀ α : Aa , ∀ α' : Aa, ∀ β : Ab , ∀ β' : Ab ,
  | (∫ ω, (Xa ω : ℝ) * (Xb ω) ∂((ℙ α β):measure Ω) ) 
    - (∫ ω, (Xa ω : ℝ) * (Xb ω) ∂((ℙ α β'):measure Ω) ) |
  + | (∫ ω, (Xa ω : ℝ) * (Xb ω) ∂((ℙ α' β):measure Ω) ) 
    - (∫ ω, (Xa ω : ℝ) * (Xb ω) ∂((ℙ α' β'):measure Ω) ) |
    ≤ 2
  :=

begin
  sorry,
end

#exit

def pm_one_space := ℤˣ

lemma pm_one_space_vals (r : ℤˣ) :
  (r : ℝ) = 1 ∨ (r : ℝ) = -1 :=
begin
  cases int.units_eq_one_or r with hh hh;
  rw hh; simp,
end

instance int.units.measurable_space : measurable_space ℤˣ := ⊤
-- units.measurable_space


section preliminaries

lemma pm_one_func_vals_ℝ (Za : Ω → ℤˣ) (ω : Ω) :
  ((Za ω) : ℝ) = 1 ∨ ((Za ω) : ℝ)  = -1 :=
begin
  apply pm_one_space_vals,
end

lemma pm_one_func_vals (Za : Ω → ℤˣ) (ω : Ω) :
  Za ω = 1 ∨ Za ω  = -1 := int.units_eq_one_or _

lemma neq_one_pm_one_space_ℝ {Za : Ω → ℤˣ} {ω : Ω} (hω : (Za ω : ℝ) ≠ 1) :
  (Za ω : ℝ)  = -1 :=
begin
  cases pm_one_func_vals_ℝ Za ω,
  { exfalso,
    exact hω h, },
  { exact h, },
end

lemma one_ne_neg_one_Z_units : (1 : ℤˣ) ≠ -1 .

lemma neq_one_pm_one_space {Za : Ω → ℤˣ} {ω : Ω} (hω : Za ω = 1) :
  ¬ Za ω = -1 :=
begin
  cases pm_one_func_vals Za ω,
  { rw h,
    exact one_ne_neg_one_Z_units, },
  { exfalso,
    rw hω at h,
    exact one_ne_neg_one_Z_units h, },
end

lemma correlation_to_probability [has_union (Type u)]
 (Za Zb : Ω → ℤˣ)
  (Za_measurable : measurable Za) (Zb_measurable : measurable Zb) :
  ∫ ω, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω) = 1 - 2 * (ℙ {ω | (Za ω : ℝ) ≠ Zb ω }) :=
begin
--  let Ωp := {ω : Ω | (Za ω : ℝ) = 1},
--  let Ωm := {ω : Ω | (Za ω : ℝ) = -1},
  let Ωp := Za ⁻¹' {1},
  let Ωm := Za ⁻¹' {-1},

  have pm_univ : Ωp ∪ Ωm = set.univ,
  { ext x,
    split,
    { intros,
      simp, },
    { intros,
      rw set.union_def,
      simp only [set.mem_set_of_eq, set.mem_preimage, set.mem_singleton_iff],
      --have := pm_one_func_vals,
      exact_mod_cast pm_one_func_vals Za x, }, },

  have pm_disjoint : disjoint Ωp Ωm,
  { rw disjoint_iff,
    ext x,
    simp only [set.inf_eq_inter, set.mem_inter_iff, set.mem_preimage, set.mem_singleton_iff,
      set.bot_eq_empty, set.mem_empty_iff_false, iff_false, not_and],
    apply neq_one_pm_one_space, },

  have Ωp_measurable : measurable_set Ωp ,
  { convert measurable_set_preimage Za_measurable _,
    simp, },

  have Ωm_measurable : measurable_set Ωm ,
  { convert measurable_set_preimage Za_measurable _,
    simp, },

  have : ∫ ω, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω) =
    ∫ ω in Ωp, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω) +
    ∫ ω in Ωm, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω),
    --∫ ω in Ωm, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω),
  { convert measure_theory.integral_union pm_disjoint _ _ _,
    { rw pm_univ,
      exact measure.restrict_univ.symm, },
    { exact Ωm_measurable, },
    {

    },
    repeat {sorry},
    -- have : Ωp ∪ Ωm = set.univ := sorry,
  },
  rw this, clear this,
  let Ωpp := {ω : Ω | (Za ω : ℝ) = 1 ∧ (Zb ω : ℝ) = 1},
  let Ωpm := {ω : Ω | (Za ω : ℝ) = 1 ∧ (Zb ω : ℝ) = -1},
  have : ∫ ω in Ωp, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω) =
    ∫ ω in Ωpp, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω) +
    ∫ ω in Ωpm, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω),
  { convert measure_theory.integral_union _ _ _ _,
    repeat {sorry}, },
  rw this, clear this,
  let Ωmp := {ω : Ω | (Za ω : ℝ) = -1 ∧ (Zb ω : ℝ) = 1},
  let Ωmm := {ω : Ω | (Za ω : ℝ) = -1 ∧ (Zb ω : ℝ) = -1},
  have : ∫ ω in Ωm, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω) =
    ∫ ω in Ωmp, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω) +
    ∫ ω in Ωmm, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω),
  { convert measure_theory.integral_union _ _ _ _,
    repeat {sorry}, },
  rw this, clear this,


  set s := {ω : Ω | (Za ω : ℝ) ≠ Zb ω},
  have : ∀ ω ∈ s, (Za ω : ℝ) * (Zb ω) = -1,
  { intros ω hω,
    have Za_neq_Zb : (Za ω : ℝ) ≠ Zb ω := set.mem_def.mp hω,
    by_cases ha : (Za ω : ℝ) = 1;
    by_cases hb : (Zb ω : ℝ) = 1,
    { exfalso,
      rw ← hb at ha,
      exact Za_neq_Zb ha, },
    { rw [ha, neq_one_pm_one_space hb],
      ring, },
    { rw [hb, neq_one_pm_one_space ha],
      ring, },
    { exfalso,
      have := neq_one_pm_one_space ha,
      rw ← neq_one_pm_one_space hb at this,
      exact Za_neq_Zb this, }, },

  sorry,
end

/- prove that s.indicator f a = s.indicator 1 a when f a = 1 on s
lemma indicator_eq_indicator_one [α : Type*] (f : Ω → α) (h : ∀ x : α , x∈ s → f x = c):
  s.indicator f = s.indicator (λ x , c) :=
  begin
    --have : s.indicator f a = 0 ∨ s.indicator f a = f a := set.indicator_eq_zero_or_self s f a,
    have : a ∈ s ∨ a ∉ s:= sorry,

    -- go through both cases
    cases this with zero nonzero , {
      have : s.indicator f a = f a := set.indicator_of_mem zero f,
      have eq1 : s.indicator f a = c := eq.trans this ((h a) zero),
      have eq2 : s.indicator (λ x , c) a = c := set.indicator_of_mem zero (λ x , c),
      exact eq.trans eq1 (eq.symm eq2),
    },
    {
      have eq1 : s.indicator f a = 0 := set.indicator_of_not_mem nonzero f,
      have eq2 : s.indicator (λ x , c) a = 0 := set.indicator_of_not_mem nonzero (λ x , c),
      exact eq.trans eq1 (eq.symm eq2),
    },
  end
-/

/-
-- Prove that C(i,j)=1-2*P(Zi≠ Zj)
lemma correlation_to_probability [Ω : Type] [has_mem Ω Type] [measurable_space Ω]
  (Za : Ω → ℤ )
  (Zb : Ω → ℤ )
  (P : measure_theory.probability_measure Ω)
  -- restrict values to ± 1
  (ha: ∀ ω : Ω , Za ω = 1 ∨ Za ω = -1)
  (hb: ∀ ω : Ω , Zb ω = 1 ∨ Zb ω = -1)
  -- I have no clue why this does not work
  : ∫ ω , (Za ω :ℝ)*(Zb ω :ℝ) ∂↑P = 1-2*(P {ω | Za ω ≠ Zb ω })
  :=
  begin
    let Cij:=∫ ω , (Za ω : ℝ)*(Zb ω : ℝ) ∂↑P,

    -- first step: prove that C(i,j)=P(Zi*Zj=1)-P(Zi*Zj=-1)
    have : Cij = (P {ω | Za ω * Zb ω =1}) - (P {ω | Za ω * Zb ω =-1}) ,
    {
      -- set Za = Zb
      let eqs := {ω | Za ω = Zb ω},

      -- prove that Za Zb=1 in eqs
      have in_eq : ∀ ω ∈ eqs , Za ω * Zb ω =1  , {
        intros ω hω,
        -- prove that Za = Zb
        have equal : Za ω = Zb ω := set.mem_set_of.mp hω,

        -- split cases for Za = ± 1
        cases ha ω with ap1 am1 , {
          have eq1 : Zb ω = 1 := eq.trans (eq.symm equal) ap1,
          -- this should be trivial
          sorry,
        },
        {
          have eq1 : Zb ω = -1 := eq.trans (eq.symm equal) am1,
          -- this should be trivial
          sorry,
        },
      },

      -- prove that Za Zb=-1 in complement of eqs
      have in_compl : ∀ ω ∈ eqsᶜ , Za ω * Zb ω =-1  , {
        intros ω hω,
        -- prove that Za ≠ Zb
        have : ω ∈ {ω | Za ω ≠ Zb ω } ,{
          have : eqsᶜ = {ω | Za ω ≠ Zb ω }:= set.compl_set_of (λ ω , Za ω = Zb ω),
          exact hω,
        },
        have different : Za ω ≠ Zb ω := set.mem_set_of.mp this,

        -- split cases for Za = ± 1
        cases ha ω with ap1 am1 , {
          have neq1 : Zb ω ≠ 1 := ne.trans_eq (ne.symm different) ap1,
          have : Zb ω = 1 ∨ Zb ω = -1 := hb ω,
          have : Zb ω = -1 := or.resolve_left this neq1,
          -- this should be trivial
          sorry,
        },
        {
          have neq1 : Zb ω ≠ -1 := ne.trans_eq (ne.symm different) am1,
          have : Zb ω = 1 ∨ Zb ω = -1 := hb ω,
          have : Zb ω = 1 := or.resolve_right this neq1,
          -- this should be trivial
          sorry,
        },
      },

      -- split integral
      let int1:=∫ ω in eqs, (Za ω : ℝ)*(Zb ω : ℝ) ∂↑P,
      let int2:=∫ ω in eqsᶜ, (Za ω : ℝ)*(Zb ω : ℝ) ∂↑P,


      -- assumptions to split integral
      have hfs : measure_theory.integrable (λ ω , (Za ω : ℝ)*(Zb ω : ℝ)) ↑P:= sorry,
      have measurable_eqs : measurable_set eqs := sorry,

      -- split
      have : Cij=int1+int2 := eq.symm (measure_theory.integral_add_compl measurable_eqs hfs),

      have : int1=P eqs , {
        have : int1 = ∫ ω in eqs, 1 ∂↑P , {
          have int_ind : int1 = ∫ ω , eqs.indicator (λ ω , (Za ω : ℝ)*(Zb ω : ℝ)) ω  ∂↑P := eq.symm (measure_theory.integral_indicator measurable_eqs),
          have : ∀ ω : Ω , eqs.indicator (λ ω , Za ω*Zb ω) ω = eqs.indicator (λ ω , 1) ω , {
            intro ω,
            -- ???????????????
            have : eqs.indicator (λ ω , Za ω*Zb ω) ω = eqs.indicator (λ x , 1) ω := indicator_eq_indicator_one eqs (λ ω , Za ω*Zb ω) (ω:Ω) (1:ℤ) in_eq,
          },
        },
        exact measure_theory.set_integral_const 1,
        sorry,
      },

      sorry,
    },
    sorry,
  end

-/
end preliminaries

/-- **Bell's Inequality** -/
theorem bells_inequality : true :=
begin
  exact trivial,
end


end probability_theory
