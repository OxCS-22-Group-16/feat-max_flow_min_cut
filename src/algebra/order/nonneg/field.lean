/-
Copyright (c) 2021 Floris van Doorn. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Floris van Doorn
-/
-- import algebra.order.archimedean
import algebra.order.field
import algebra.order.nonneg.ring

/-!
# Semifield structure on the type of nonnegative elements

This file defines instances and prove some properties about the nonnegative elements
`{x : α // 0 ≤ x}` of an arbitrary type `α`.

Currently we only state instances and states some `simp`/`norm_cast` lemmas.

When `α` is `ℝ`, this will give us some properties about `ℝ≥0`.

## Main declarations

* `{x : α // 0 ≤ x}` is a `canonically_linear_ordered_semifield` if `α` is a `linear_ordered_field`.

## Implementation Notes

Instead of `{x : α // 0 ≤ x}` we could also use `set.Ici (0 : α)`, which is definitionally equal.
However, using the explicit subtype has a big advantage: when writing and element explicitly
with a proof of nonnegativity as `⟨x, hx⟩`, the `hx` is expected to have type `0 ≤ x`. If we would
use `Ici 0`, then the type is expected to be `x ∈ Ici 0`. Although these types are definitionally
equal, this often confuses the elaborator. Similar problems arise when doing cases on an element.

The disadvantage is that we have to duplicate some instances about `set.Ici` to this subtype.
-/

open set
open_locale nnrat

variables {α : Type*}

section linear_ordered_semifield
variables [linear_ordered_semifield α] {a : α}

lemma nnrat.cast_nonneg (q : ℚ≥0) : (0 : α) ≤ q :=
by { rw nnrat.cast_def, exact div_nonneg q.num.cast_nonneg q.denom.cast_nonneg }

lemma nnqsmul_nonneg (ha : 0 ≤ a) (q : ℚ≥0) : 0 ≤ q • a :=
by { rw nnrat.smul_def, exact mul_nonneg q.cast_nonneg ha }

end linear_ordered_semifield

namespace nonneg

section linear_ordered_semifield
variables [linear_ordered_semifield α] {x y : α}

instance has_inv : has_inv {x : α // 0 ≤ x} := ⟨λ x, ⟨x⁻¹, inv_nonneg.2 x.2⟩⟩

@[simp, norm_cast]
protected lemma coe_inv (a : {x : α // 0 ≤ x}) : ((a⁻¹ : {x : α // 0 ≤ x}) : α) = a⁻¹ := rfl

@[simp] lemma inv_mk (hx : 0 ≤ x) : (⟨x, hx⟩ : {x : α // 0 ≤ x})⁻¹ = ⟨x⁻¹, inv_nonneg.2 hx⟩ := rfl

instance has_div : has_div {x : α // 0 ≤ x} := ⟨λ x y, ⟨x / y, div_nonneg x.2 y.2⟩⟩

@[simp, norm_cast] protected lemma coe_div (a b : {x : α // 0 ≤ x}) :
  ((a / b : {x : α // 0 ≤ x}) : α) = a / b := rfl

@[simp] lemma mk_div_mk (hx : 0 ≤ x) (hy : 0 ≤ y) :
  (⟨x, hx⟩ : {x : α // 0 ≤ x}) / ⟨y, hy⟩ = ⟨x / y, div_nonneg hx hy⟩ := rfl

instance has_zpow : has_pow {x : α // 0 ≤ x} ℤ := ⟨λ a n, ⟨a ^ n, zpow_nonneg a.2 _⟩⟩

@[simp, norm_cast] protected lemma coe_zpow (a : {x : α // 0 ≤ x}) (n : ℤ) :
  ((a ^ n : {x : α // 0 ≤ x}) : α) = a ^ n := rfl

@[simp] lemma mk_zpow (hx : 0 ≤ x) (n : ℤ) :
  (⟨x, hx⟩ : {x : α // 0 ≤ x}) ^ n = ⟨x ^ n, zpow_nonneg hx n⟩ := rfl

instance : has_nnrat_cast {x : α // 0 ≤ x} := ⟨λ q, ⟨q, q.cast_nonneg⟩⟩

@[simp, norm_cast] protected lemma coe_nnrat_cast (q : ℚ≥0) : ((q : {x : α // 0 ≤ x}) : α) = q :=
rfl

@[simp] lemma mk_nnrat_cast (q : ℚ≥0) : (⟨q, q.cast_nonneg⟩ : {x : α // 0 ≤ x}) = q := rfl

instance has_nnqsmul : has_smul ℚ≥0 {x : α // 0 ≤ x} := ⟨λ q a, ⟨q • a, nnqsmul_nonneg a.2 _⟩⟩

@[simp, norm_cast] protected lemma coe_nnqsmul (q : ℚ≥0) (a : {x : α // 0 ≤ x}) :
  (↑(q • a) : α) = q • a := rfl

@[simp] lemma nnqsmul_mk (q : ℚ≥0) (hx : 0 ≤ x) :
  (q • ⟨x, hx⟩ : {x : α // 0 ≤ x}) = ⟨q • x, nnqsmul_nonneg hx _⟩ := rfl

instance linear_ordered_semifield : linear_ordered_semifield {x : α // 0 ≤ x} :=
subtype.coe_injective.linear_ordered_semifield _ nonneg.coe_zero nonneg.coe_one nonneg.coe_add
    nonneg.coe_mul nonneg.coe_inv nonneg.coe_div (λ _ _, rfl) (λ _ _, rfl) nonneg.coe_pow nonneg.coe_zpow
    nonneg.coe_nat_cast nonneg.coe_nnrat_cast (λ _ _, rfl) (λ _ _, rfl)

end linear_ordered_semifield

instance canonically_linear_ordered_semifield [linear_ordered_field α] :
  canonically_linear_ordered_semifield {x : α // 0 ≤ x} :=
{ ..nonneg.linear_ordered_semifield, ..nonneg.canonically_ordered_comm_semiring }

instance linear_ordered_comm_group_with_zero [linear_ordered_field α] :
  linear_ordered_comm_group_with_zero {x : α // 0 ≤ x} :=
infer_instance

end nonneg
