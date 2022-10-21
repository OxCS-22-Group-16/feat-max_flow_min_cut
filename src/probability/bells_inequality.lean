/-
Copyright (c) 2022 Ian Jauslin and Alex Kontorovich. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Ian Jauslin, Alex Kontorovich
-/
import probability.conditional_probability
import measure_theory.measure.finite_measure_weak_convergence

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
variables {Ω : Type u} {m : measurable_space Ω} (ℙ : probability_measure Ω)

def pm_one_space : set ℝ := {-1, 1}
--λ (n:ℤ), n=1 ∨ n=-1 --{ (n:ℤ) | ((n=1) ∨ (n=-1))} -- FAILS???

section preliminaries

def p_one_space : set ℝ := {1}

lemma pm_one_space_vals {r : ℝ} (hr : r ∈ pm_one_space) :
  r = 1 ∨ r = -1 :=
begin
  cases hr,
  { right,
    exact hr, },
  { left,
    simpa [hr], },
end

lemma pm_one_func_vals (Za : Ω → pm_one_space) (ω : Ω) :
  (Za ω : ℝ) = 1 ∨ (Za ω : ℝ)  = -1 :=
begin
  apply pm_one_space_vals,
  simp only [subtype.coe_prop],
end

lemma neq_one_pm_one_space {Za : Ω → pm_one_space} {ω : Ω} (hω : (Za ω : ℝ) ≠ 1) :
  (Za ω : ℝ)  = -1 :=
begin
  cases pm_one_func_vals Za ω,
  { exfalso,
    exact hω h, },
  { exact h, },
end

lemma correlation_to_probability [has_union (Type u)] (Za Zb : Ω → pm_one_space)
  (Za_measurable : measurable Za) (Zb_measurable : measurable Zb) :
  ∫ ω, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω) = 1 - 2 * (ℙ {ω | (Za ω : ℝ) ≠ Zb ω }) :=
begin
  let Ωp := {ω : Ω | (Za ω : ℝ) = 1},
  let Ωm := {ω : Ω | (Za ω : ℝ) = -1},

  have pm_univ : Ωp ∪ Ωm = set.univ,
  { ext x,
    split,
    { intros,
      simp, },
    { intros,
      rw set.union_def,
      simp only [set.mem_set_of_eq],
      exact pm_one_func_vals _ _, }, },
      
  have pm_disjoint : disjoint Ωp Ωm,
  { rw disjoint_iff,
    ext x,
    simp only [set.inf_eq_inter, set.mem_inter_iff, set.mem_set_of_eq, set.bot_eq_empty,
      set.mem_empty_iff_false, iff_false, not_and],
    intros h,
    rw h,
    norm_num, },
  have Ωp_is : Ωp = (Za : Ω → ℝ) ⁻¹' {(1:ℝ)},
  { 
},
  have Ωp_measurable : measurable_set Ωp ,
  { convert measurable_set_preimage _ _,
},

  have : ∫ ω, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω) =
    ∫ ω in Ωp, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω) +
    ∫ ω in Ωm, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω),
    --∫ ω in Ωm, (Za ω : ℝ) * (Zb ω) ∂(ℙ:measure Ω),
  { convert measure_theory.integral_union pm_disjoint _ _ _,
    { rw pm_univ,
      exact measure.restrict_univ.symm, },
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
