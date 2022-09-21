/-
Copyright (c) 2018 Kenny Lau. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kenny Lau
-/
import algebra.field.basic
import algebra.ring.opposite

/-!
# Field structure on the multiplicative/additive opposite
-/

open_locale nnrat

variables (α : Type*)

@[to_additive] instance [has_nnrat_cast α] : has_nnrat_cast αᵐᵒᵖ := ⟨λ n, mul_opposite.op n⟩
@[to_additive] instance [has_rat_cast α] : has_rat_cast αᵐᵒᵖ := ⟨λ n, mul_opposite.op n⟩

namespace mul_opposite

@[simp, norm_cast, to_additive]
lemma op_nnrat_cast [has_nnrat_cast α] (q : ℚ≥0) : op (q : α) = q := rfl

@[simp, norm_cast, to_additive]
lemma unop_nnrat_cast [has_nnrat_cast α] (q : ℚ≥0) : unop (q : αᵐᵒᵖ) = q := rfl

@[simp, norm_cast, to_additive]
lemma op_rat_cast [has_rat_cast α] (q : ℚ) : op (q : α) = q := rfl

@[simp, norm_cast, to_additive]
lemma unop_rat_cast [has_rat_cast α] (q : ℚ) : unop (q : αᵐᵒᵖ) = q := rfl

instance [division_semiring α] : division_semiring αᵐᵒᵖ :=
{ nnrat_cast := λ q, op q,
  nnrat_cast_eq := λ q, by { rw [nnrat.cast_def, op_div, op_nat_cast, op_nat_cast, div_eq_mul_inv],
    exact commute.cast_nat_right _ _ },
  .. mul_opposite.group_with_zero α, .. mul_opposite.semiring α }

instance [division_ring α] : division_ring αᵐᵒᵖ :=
{ rat_cast := λ q, op q,
  rat_cast_mk := λ a b hb h, by { rw [rat.cast_def, op_div, op_nat_cast, op_int_cast],
    exact int.commute_cast _ _ },
  ..mul_opposite.group_with_zero α, ..mul_opposite.ring α }

instance [semifield α] : semifield αᵐᵒᵖ :=
{ .. mul_opposite.division_semiring α, .. mul_opposite.comm_semiring α }

instance [field α] : field αᵐᵒᵖ :=
{ .. mul_opposite.division_ring α, .. mul_opposite.comm_ring α }

end mul_opposite

namespace add_opposite

instance [division_semiring α] : division_semiring αᵃᵒᵖ :=
{ nnrat_cast := λ q, op q,
  nnrat_cast_eq := λ q, by { rw [nnrat.cast_def, op_div, op_nat_cast, op_nat_cast], convert rfl, },
  ..add_opposite.group_with_zero α, ..add_opposite.semiring α, ..add_opposite.has_nnrat_cast _ }

instance [division_ring α] : division_ring αᵃᵒᵖ :=
{ ..add_opposite.group_with_zero α, ..add_opposite.ring α }

instance [semifield α] : semifield αᵃᵒᵖ :=
{ ..add_opposite.division_semiring α, ..add_opposite.comm_semiring α }

instance [field α] : field αᵃᵒᵖ :=
{ ..add_opposite.division_ring α, ..add_opposite.comm_ring α }

end add_opposite
