/-
Copyright (c) 2022 Bolton Bailey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Bolton Bailey
-/

import information_theory.hamming
import linear_algebra.linear_independent
import linear_algebra.affine_space.affine_subspace
import linear_algebra.finite_dimensional

/-!
# Block Codes

TODO
-/


def linear_code (𝓓 F : Type) [fintype 𝓓] [field F] := submodule F ( 𝓓 -> F )

namespace linear_code

variables {𝓓 F : Type} [fintype 𝓓] [field F] [decidable_eq F]

def length (C : linear_code 𝓓 F) : ℕ := fintype.card 𝓓

def codewords (C : linear_code 𝓓 F) := C.carrier

noncomputable def dimension (C : linear_code 𝓓 F) : ℕ := set.finrank F C.codewords

noncomputable def distance (C : linear_code 𝓓 F) : ℕ :=
Inf (set.image (λ w : hamming (λ i : 𝓓, F), hamming_dist w 0) C.codewords)

end linear_code

section reed_solomon

variables {F : Type} [field F]

def reed_solomon (k : ℕ) (D : finset F) : linear_code D F :=
{ carrier := {w | ∃ p : polynomial F, p.nat_degree ≤ k ∧ w = (λ x, polynomial.eval x p)},
  add_mem' :=
    begin
      intros a b ha hb,
      rw set.mem_set_of at ha hb ⊢,
      rcases ha with ⟨pa, hap⟩,
      rcases hb with ⟨pb, hbp⟩,
      use pa + pb,
      split,
      {
        apply le_trans (polynomial.nat_degree_add_le _ _),
        simp only [max_le_iff],
        simp [hap.left, hbp.left],
      },
      {
        rw [hap.right, hbp.right],
        funext,
        simp,
      },
    end,
  zero_mem' :=
  begin
    rw set.mem_set_of,
    use 0,
    simp,
    funext,
    simp,
  end,
  smul_mem' :=
    begin
      intros c a ha,
      rw set.mem_set_of at ha ⊢,
      rcases ha with ⟨pa, hap⟩,
      -- rcases hb with ⟨pb, hbp⟩,
      use c • pa,
      split,
      {
        -- apply le_trans (polynomial.nat_degree_add_le _ _),
        -- simp only [max_le_iff],
        rw polynomial.smul_eq_C_mul,
        by_cases c = 0, simp [h],
        rw polynomial.nat_degree_C_mul h,
        simp [hap.left],
      },
      {
        rw [hap.right],
        funext,
        simp,
      },
    end }

end reed_solomon
