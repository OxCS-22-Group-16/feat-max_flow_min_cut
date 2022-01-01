/-
Copyright (c) 2021 Yaël Dillies. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yaël Dillies
-/
import algebra.big_operators.ring
import data.finset.locally_finite

/-!
# Incidence algebras
-/

open finset
open_locale big_operators

variables (𝕜 α : Type*)

/-- The `𝕜`-incidence algebra over `α`. -/
structure incidence_algebra [has_zero 𝕜] [has_le α] :=
(to_fun : α → α → 𝕜)
(eq_zero_of_not_le' {a b : α} : ¬ a ≤ b → to_fun a b = 0)

namespace incidence_algebra
section zero
variables [has_zero 𝕜] [has_le α]

instance fun_like : fun_like (incidence_algebra 𝕜 α) α (λ _, α → 𝕜) :=
⟨to_fun, λ f g h, by { cases f, cases g, congr' }⟩

variables {𝕜 α}

lemma eq_zero_of_not_le {f : incidence_algebra 𝕜 α} {a b : α} : ¬ a ≤ b → f a b = 0 :=
eq_zero_of_not_le' _

lemma le_of_ne_zero {f : incidence_algebra 𝕜 α} {a b : α} : f a b ≠ 0 → a ≤ b :=
not_imp_comm.1 eq_zero_of_not_le

-- completely uninteresting lemmas about coercion to function, that all homs need
section coes

-- Fallback `has_coe_to_fun` instance to help the elaborator
instance : has_coe_to_fun (incidence_algebra 𝕜 α) (λ _, α → α → 𝕜) := ⟨to_fun⟩

-- this must come after the coe_to_fun definitions
initialize_simps_projections incidence_algebra (to_fun → apply)

@[simp] lemma to_fun_eq_coe (f : incidence_algebra 𝕜 α) : f.to_fun = f := rfl

@[simp] lemma coe_mk (f : α → α → 𝕜) (h) : (mk f h : α → α → 𝕜) = f := rfl

protected lemma congr_fun {f g : incidence_algebra 𝕜 α} (h : f = g) (a b : α) : f a b = g a b :=
congr_arg (λ f : incidence_algebra 𝕜 α, f a b) h

protected lemma congr_arg (f : incidence_algebra 𝕜 α) {a₁ a₂ b₁ b₂ : α} (ha : a₁ = a₂)
  (hb : b₁ = b₂) :
  f a₁ b₁ = f a₂ b₂ :=
congr_arg2 f ha hb

lemma coe_inj ⦃f g : incidence_algebra 𝕜 α⦄ (h : (f : α → α → 𝕜) = g) : f = g :=
by { cases f, cases g, cases h, refl }

@[ext] lemma ext ⦃f g : incidence_algebra 𝕜 α⦄ (h : ∀ a b, f a b = g a b) : f = g :=
coe_inj $ funext $ λ a, funext $ h a

lemma ext_iff {f g : incidence_algebra 𝕜 α} : f = g ↔ ∀ a b, f a b = g a b :=
⟨incidence_algebra.congr_fun, λ h, ext h⟩

@[simp] lemma mk_coe (f : incidence_algebra 𝕜 α) (h) : mk f h = f := ext $ λ _ _, rfl

end coes

variables {𝕜 α}

instance : has_zero (incidence_algebra 𝕜 α) := ⟨⟨λ _ _, 0, λ _ _ _, rfl⟩⟩

@[simp] lemma zero_apply (a b : α) : (0 : incidence_algebra 𝕜 α) a b = 0 := rfl

end zero

section add
variables [add_zero_class 𝕜] [has_le α]

instance : has_add (incidence_algebra 𝕜 α) :=
⟨λ f g, ⟨f + g, λ a b h, by simp_rw [pi.add_apply, eq_zero_of_not_le h, zero_add]⟩⟩

@[simp] lemma add_apply (f g : incidence_algebra 𝕜 α) (a b : α) :
  (f + g) a b = f a b + g a b := rfl

end add

instance [add_monoid 𝕜] [has_le α] : add_monoid (incidence_algebra 𝕜 α) :=
{ add := (+),
  add_assoc := λ f g h, by { ext, exact add_assoc _ _ _ },
  zero := 0,
  zero_add := λ f, by { ext, exact zero_add _ },
  add_zero := λ f, by { ext, exact add_zero _ } }

section one
variables [preorder α] [decidable_eq α] [has_zero 𝕜] [has_one 𝕜]

instance : has_one (incidence_algebra 𝕜 α) :=
⟨⟨λ a b, if a = b then 1 else 0, λ a b h, ite_eq_right_iff.2 $ λ H, (h H.le).elim⟩⟩

@[simp] lemma one_apply (a b : α) : (1 : incidence_algebra 𝕜 α) a b = if a = b then 1 else 0 := rfl

end one

section mul
variables [preorder α] [locally_finite_order α] [add_comm_monoid 𝕜] [has_mul 𝕜]

instance : has_mul (incidence_algebra 𝕜 α) :=
⟨λ f g, ⟨λ a b, ∑ x in Icc a b, f a x * g x b, λ a b h, by rw [Icc_eq_empty h, sum_empty]⟩⟩

@[simp] lemma mul_apply (f g : incidence_algebra 𝕜 α) (a b : α) :
  (f * g) a b = ∑ x in Icc a b, f a x * g x b := rfl

end mul

instance [non_assoc_semiring 𝕜] [decidable_eq α] [preorder α] [locally_finite_order α] :
  monoid (incidence_algebra 𝕜 α) :=
{ mul := (*),
  mul_assoc := λ f g h, begin
    ext a b,
    simp only [mul_apply, sum_mul, mul_sum],
    sorry
  end,
  one := (1),
  one_mul := λ f, begin
    ext a b,
    simp_rw [mul_apply, one_apply, sum_boole_mul],
    exact ite_eq_left_iff.2 (not_imp_comm.1 $ λ h, left_mem_Icc.2 $ le_of_ne_zero $ ne.symm h),
  end,
  mul_one := λ f, begin
    ext a b,
    simp_rw [mul_apply, one_apply, eq_comm, sum_mul_boole],
    convert (ite_eq_left_iff.2 $ not_imp_comm.1 $
      λ h, right_mem_Icc.2 $ le_of_ne_zero $ ne.symm h).symm,
  end }

section zeta
variables [has_zero 𝕜] [has_one 𝕜] [has_le α] [@decidable_rel α (≤)]

def zeta : incidence_algebra 𝕜 α := ⟨λ a b, if a ≤ b then 1 else 0, λ a b h, if_neg h⟩

variables {𝕜 α}

@[simp] lemma zeta_apply (a b : α) : zeta 𝕜 α a b = if a ≤ b then 1 else 0 := rfl

lemma zeta_of_le {a b : α} (h : a ≤ b) : zeta 𝕜 α a b = 1 := if_pos h

end zeta

lemma zeta_mul_zeta [add_comm_monoid 𝕜] [mul_one_class 𝕜] [preorder α] [locally_finite_order α]
  [@decidable_rel α (≤)] (a b : α) :
  (zeta 𝕜 α * zeta 𝕜 α) a b = (Icc a b).card :=
begin
  rw [mul_apply, card_eq_sum_ones, nat.cast_sum, nat.cast_one],
  refine sum_congr rfl (λ x hx, _),
  rw mem_Icc at hx,
  rw [zeta_of_le hx.1, zeta_of_le hx.2, one_mul],
end

section mu
variables [add_comm_group 𝕜] [has_one 𝕜] [preorder α] [locally_finite_order α] [decidable_eq α]

def mu_aux (a : α) : α → 𝕜
| b := if h : a = b then 1 else
  -∑ x in (Ico a b).attach,
    have (Icc a x).card < (Icc a b).card, from card_lt_card sorry,
    mu_aux x
using_well_founded { rel_tac := λ _ _, `[exact ⟨_, measure_wf (λ b, (Icc a b).card)⟩] }

lemma mu_aux_apply (a b : α) : mu_aux 𝕜 α a b =
  if a = b then 1 else -∑ x in (Ico a b).attach, mu_aux 𝕜 α a x :=
begin
  convert has_well_founded.wf.fix_eq _ _,
  refl,
end

def mu : incidence_algebra 𝕜 α := ⟨mu_aux 𝕜 α, λ a b, not_imp_comm.1 $ λ h, begin
  rw mu_aux_apply at h,
  split_ifs at h with hab hab,
  exact le_of_eq hab,
  rw [neg_eq_zero] at h,
  have := exists_ne_zero_of_sum_ne_zero h,
  rcases this with ⟨⟨x, hx⟩, hn, hnn⟩,
  rw [mem_Ico] at hx,
  transitivity x,
  exact hx.1,
  exact hx.2.le,
end⟩

variables {𝕜 α}

lemma mu_apply (a b : α) : mu 𝕜 α a b = if a = b then 1 else -∑ x in Ico a b, mu 𝕜 α a x :=
by rw [mu, coe_mk, mu_aux_apply, sum_attach]

lemma mu_apply_of_eq {a b : α} (h : a = b) : mu 𝕜 α a b = 1 :=
by rw [mu_apply, if_pos h]

@[simp]
lemma mu_apply_self (a : α) : mu 𝕜 α a a = 1 := mu_apply_of_eq rfl

lemma mu_apply_of_ne {a b : α} (h : a ≠ b) : mu 𝕜 α a b = -∑ x in Ico a b, mu 𝕜 α a x :=
by rw [mu_apply, if_neg h]

lemma mu_spec_of_ne_right {a b : α} (h : a ≠ b) : ∑ (x : α) in Icc a b, (mu 𝕜 α) a x = 0 :=
begin
  have : mu 𝕜 α a b = _ := mu_apply_of_ne h,
  sorry,
end

lemma mu_spec_of_ne_left {a b : α} (h : a ≠ b) : ∑ (x : α) in Icc a b, (mu 𝕜 α) x b = 0 :=
begin
  have : mu 𝕜 α a b = _ := mu_apply_of_ne h,
  sorry,
end

end mu

section mu_zeta
variables [add_comm_group 𝕜] [mul_one_class 𝕜] [partial_order α] [locally_finite_order α]
  [decidable_eq α] [@decidable_rel α (≤)]

lemma mu_mul_zeta : mu 𝕜 α * zeta 𝕜 α = 1 :=
begin
  ext a b,
  rw [mul_apply, one_apply],
  split_ifs with he,
  { simp [he], },
  { simp only [mul_one, zeta_apply, mul_ite],
    conv in (ite _ _ _) {
      rw [if_pos (mem_Icc.mp H).2], },
    rw mu_spec_of_ne_right he, },
end

lemma zeta_mul_mu : zeta 𝕜 α * mu 𝕜 α = 1 :=
begin
  ext a b,
  rw [mul_apply, one_apply],
  split_ifs with he,
  { simp [he], },
  { simp [mul_one, zeta_apply, mul_ite],
    conv in (ite _ _ _) {
      rw [if_pos (mem_Icc.mp H).1], },
  rw mu_spec_of_ne_left he, },
end

end mu_zeta

section euler
variables [add_comm_group 𝕜] [has_one 𝕜] [preorder α] [bounded_order α] [locally_finite_order α]
  [decidable_eq α]

/-- The Euler characteristic of a finite bounded order. -/
def euler_char : 𝕜 := mu 𝕜 α ⊥ ⊤

end euler
end incidence_algebra
